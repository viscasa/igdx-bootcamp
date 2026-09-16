extends CanvasLayer

var active := false
var step := 0
var lesson_order: Order
var pulse := 0.0
var opened_serat := false
var cut_lesson_seen := false
var cut_start := 0
var intro_page := 0

@onready var overlay: Control = $Overlay
@onready var shade: ColorRect = $Overlay/Shade
@onready var card: Control = $Overlay/Card
@onready var label: Label = $Overlay/Card/Text
@onready var continue_hint: Label = $Overlay/Card/ContinueHint
@onready var skip_button: Button = $Overlay/Card/Skip


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	skip_button.pressed.connect(finish)
	GameState.day_started.connect(func(day: int):
		if day == 1:
			finish()
			cut_lesson_seen = false)


func start() -> void:
	if GameState.queue.is_empty():
		return
	lesson_order = GameState.queue[0]
	step = 0
	intro_page = 0
	opened_serat = false
	active = true
	GameState.tutorial_hold = true


func finish() -> void:
	active = false
	GameState.tutorial_hold = false
	if is_instance_valid(overlay):
		overlay.hide()


func cooking_allowed() -> bool:
	return not active or step == 8


func _rect(node: CanvasItem) -> Rect2:
	if node is Control:
		return node.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, node.size)
	return Rect2(node.get_global_transform_with_canvas().origin - Vector2(80, 80), Vector2(160, 160))


func _label_text_rect(text_label: Label) -> Rect2:
	# Wrapped dialogue occupies multiple lines; its laid-out Control is the
	# reliable visible bound. Single-line HUD labels can be tightened to glyphs.
	if text_label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return _rect(text_label)
	var font := text_label.get_theme_font("font")
	var font_size := text_label.get_theme_font_size("font_size")
	var text_size := font.get_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_size.y = font.get_height(font_size)
	var text_position := Vector2.ZERO
	match text_label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			text_position.x = (text_label.size.x - text_size.x) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			text_position.x = text_label.size.x - text_size.x
	match text_label.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			text_position.y = (text_label.size.y - text_size.y) * 0.5
		VERTICAL_ALIGNMENT_BOTTOM:
			text_position.y = text_label.size.y - text_size.y
	return text_label.get_global_transform_with_canvas() * Rect2(text_position, text_size)


func _customer_rect(queue: CustomerQueue, slot: int) -> Rect2:
	if slot >= 0 and slot < queue.orders.size():
		for child in queue.get_children():
			if child is CustomerFigure and child.order == queue.orders[slot]:
				var visual_rect := Rect2()
				for layer in child.customer_visual.get_children():
					if layer is Sprite2D and layer.visible and layer.texture != null:
						var layer_rect: Rect2 = layer.get_global_transform_with_canvas() * layer.get_rect()
						visual_rect = layer_rect if not visual_rect.has_area() else visual_rect.merge(layer_rect)
				if visual_rect.has_area():
					return visual_rect
	var local_rect := queue.card_rect(slot)
	if not local_rect.has_area():
		var bounds := queue.get_node("InteractionBounds") as Control
		local_rect = Rect2(bounds.position, bounds.size)
	return queue.get_global_transform_with_canvas() * local_rect


func _show(text: String, targets: Array[Rect2], allow_anywhere: bool = false) -> void:
	label.text = text
	continue_hint.visible = allow_anywhere
	var bounds := get_viewport().get_visible_rect().size
	var material := shade.material as ShaderMaterial
	var padded: Array[Rect2] = []
	for target in targets.slice(0, 4):
		padded.append(target.grow(14.0))
	material.set_shader_parameter("viewport_size", bounds)
	for i in range(4):
		var target := padded[i] if i < padded.size() else Rect2()
		material.set_shader_parameter(["target_a", "target_b", "target_c", "target_d"][i],
			Vector4(target.position.x, target.position.y, target.size.x, target.size.y))
	material.set_shader_parameter("pulse", pulse)
	# Pick the edge that overlaps the highlighted targets least.
	var top := Rect2(Vector2((bounds.x - 780) * 0.5, 16), Vector2(780, 145))
	var bottom := Rect2(Vector2(top.position.x, bounds.y - 161), top.size)
	var top_overlap := 0.0
	var bottom_overlap := 0.0
	for target in padded:
		top_overlap += top.intersection(target).get_area()
		bottom_overlap += bottom.intersection(target).get_area()
	card.position = bottom.position if bottom_overlap < top_overlap else top.position
	overlay.show()


func _can_advance_anywhere() -> bool:
	return (step == 0 and intro_page in [0, 2]) or (step == 1 and lesson_order != null and lesson_order.clue_uses > 0)


func _advance_explanation() -> void:
	if step == 0:
		if intro_page == 0:
			intro_page = 1
		elif intro_page == 2:
			step = 1
	elif step == 1 and lesson_order != null and lesson_order.clue_uses > 0:
		step = 2


func _input(event: InputEvent) -> void:
	if not active or not _can_advance_anywhere():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if skip_button.get_global_rect().has_point(event.position):
			return
		_advance_explanation()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	pulse += delta * 3.0
	var scene := get_tree().current_scene
	if scene == null or not scene.has_node("UILayer/SeratBook"):
		overlay.hide()
		return
	if not active:
		if not cut_lesson_seen and GameState.intro_seen and scene.has_node("Pipisan") and scene.drag.is_dragging():
			var piece: IngredientPiece = scene.drag._piece
			if piece != null and scene.pipisan.zone().grow(65).has_point(scene.pipisan.to_local(scene.get_global_mouse_position())):
				active = true
				step = 12
				cut_start = scene.pipisan.uses_left()
				cut_lesson_seen = true
				GameState.tutorial_hold = true
		return
	if GameState.phase != GameState.Phase.SHIFT:
		finish()
		return
	var book = scene.get_node("UILayer/SeratBook")
	var hud = scene.get_node("UILayer/HUD")
	var kitchen := scene.has_node("Pipisan")
	var board = scene.get_node_or_null("UILayer/DiagnosisBoard")
	if step < 3 and kitchen:
		_show("Kembali ke kasir untuk mendengar pelanggan pertama.", [_rect(hud.room_button)])
		return
	match step:
		0:
			if intro_page == 0:
				_show(
					"Setiap hari, beberapa pelanggan akan datang. Layani semuanya untuk menyelesaikan hari.",
					[_label_text_rect(hud.rep_label)], true)
			elif intro_page == 1:
				_show(
					"Ini Raka, pelanggan pertamamu. Klik Raka untuk mendengar keluhannya.",
					[_customer_rect(scene.queue_view, 0)])
				if board.order == lesson_order:
					intro_page = 2
			else:
				_show(
					"Jamu tepat menaikkan Reputasi. Jamu salah atau pelanggan yang pergi menurunkannya. Jika mencapai 0, kedai tutup.",
					[_label_text_rect(hud.get_node("%RunStatus"))], true)
		1:
			var dialogue := board.get_node("Margin/Content/Dialogue") as Label
			if lesson_order.clue_uses == 0:
				_show("Klik Tanya. Jawaban Raka akan berubah.", [_rect(board.clue_button), _label_text_rect(dialogue)])
			else:
				_show("Dialog Raka berubah dan memberi petunjuk baru tentang keluhannya.", [_label_text_rect(dialogue)], true)
		2:
			_show("Perut Raka melilit. Pilih Pencernaan, cek slot dugaan, lalu Ambil Pesanan.", [_rect(board.diagnosis_grid.get_child(Symptom.Code.PENCERNAAN)), _rect(board.diagnosis_slots), _rect(board.take_button)])
			if GameState.has_taken(lesson_order):
				board.close()
				step = 3
		3:
			_show("Buka Serat untuk mencari bahan yang cocok.", [_rect(hud.kamus_button)])
			if book.visible:
				step = 4
		4:
			if not book.visible and not opened_serat:
				_show("Buka Serat lagi untuk melihat petunjuk Pencernaan.", [_rect(hud.kamus_button)])
				return
			_show("Pilih Pencernaan, baca penjelasannya, lalu tutup buku.", [_rect(book.symptom_grid.get_child(Symptom.Code.PENCERNAAN)), _rect(book.get_node("Book/Margin/Layout/Columns/Detail")), _rect(book.close_button)])
			if book._focused_symptom == Symptom.Code.PENCERNAAN:
				opened_serat = true
			if opened_serat and not book.visible:
				step = 5
		5:
			_show("Pergi ke dapur untuk meracik.", [_rect(hud.room_button)])
			if kitchen:
				step = 6
		6, 7, 8, 9:
			if not kitchen:
				_show("Kembali ke dapur untuk melanjutkan racikan.", [_rect(hud.room_button)])
				return
			if book.visible:
				_show("Selesai membaca? Tutup Serat untuk melanjutkan.", [_rect(book.close_button)])
				return
			if step == 6:
				_show("Ambil kunyit atau asam jawa, masukkan ke kuali, dan pantau kebutuhan pesanan.", [_rect(scene.get_node("IngredientScroll")), _rect(scene.kuali.get_node("PotBackground")), _rect(scene.get_node("TargetScroll"))])
				if int(scene.kuali.current_dose()) > 0:
					step = 7
			elif step == 7:
				_show("Saat dosis cukup, klik Selesai. Racikan akan masuk ke panci kosong.", [_rect(scene.get_node("TargetScroll")), _rect(scene.kuali.get_node("ActionButton")), _rect(scene.get_node("PanciArea"))])
				if scene.panci.active_count() > 0:
					step = 8
			elif step == 8:
				_show("Geser tuas api dan pantau progress panci sampai status SIAP.", [_rect(scene.heat_slider), _rect(scene.get_node("PanciArea"))])
				for potion in scene.panci.potions:
					if potion != null and potion.brew.is_done:
						step = 9
			else:
				_show("Sudah siap! Klik panci; botol jadi akan masuk ke rak.", [_rect(scene.get_node("PanciArea")), scene.shelf.get_global_transform_with_canvas() * scene.shelf.slot_rect(0)])
				if not GameState.carried.is_empty():
					step = 10
		10:
			_show("Bawa jamu kembali ke kasir.", [_rect(hud.room_button)])
			if not kitchen:
				step = 11
		11:
			if kitchen:
				_show("Kembali ke kasir untuk menyerahkan jamu.", [_rect(hud.room_button)])
				return
			_show("Seret botol dari rak ke Raka. Bayaran langsung masuk sebagai uang.", [scene.shelf.get_global_transform_with_canvas() * scene.shelf.slot_rect(0), scene.queue_view.get_global_transform_with_canvas() * scene.queue_view.card_rect(0)])
			if not lesson_order in GameState.queue:
				finish()
				GameState.post("Sekarang giliranmu! Pelanggan belakang juga bisa diklik.", Color("ffd36f"))
		12:
			if not kitchen:
				finish()
				return
			_show("Letakkan bahan melintasi garis pisau. R untuk memutar; ambil kedua hasilnya.", [_rect(scene.pipisan.get_node("CutBed")), _rect(hud.putar_button)])
			if scene.pipisan.uses_left() < cut_start and scene.pipisan.results.is_empty():
				finish()
