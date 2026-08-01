extends Node2D

## The kitchen. Mix in the kuali, hit BREW, simmer in the panci.
##
## The pot no longer has to be full. Hitting "Jadikan Ramuan" bottles
## whatever is in there and the jamu is judged on what it actually treats —
## so the player fails on knowledge, not on a stubborn last empty cell.

const CELL := IngredientPiece.CELL

@onready var kuali: KualiGrid = $Kuali
@onready var tray: IngredientTray = $Tray
@onready var drag: DragManager = $DragLayer
@onready var panci: Panci = $Panci
@onready var toolbar: ToolBar = $ToolBar
@onready var shelf: CarryShelf = $CarryShelf
@onready var order_card: OrderCard = $OrderCard
@onready var hud: HUD = $UILayer/HUD
@onready var heat_slider: HeatSlider = $UILayer/HeatSlider

var _last_order: Order = null


func _ready() -> void:
	if not GameState.running and not GameState.game_over:
		GameState.start_run()

	drag.tray = tray
	drag.kuali = kuali
	drag.panci = panci
	tray.kuali = kuali
	heat_slider.panci = panci
	hud.room_hint = "TAB — ke Kasir"
	hud.help_lines = PackedStringArray([
		"Seret bahan ke kuali  ·  SPASI: jadikan ramuan (tak perlu penuh)  ·  W/S: atur api  ·  R: putar",
		"1 Pipisan (belah)  ·  2 Tumbuk (padatkan)  ·  3 Saring (bersihkan ampas)  ·  Q/E: ganti pesanan  ·  C: kosongkan",
	])

	toolbar.tools = GameState.tools
	toolbar.tool_selected.connect(_on_tool_selected)
	shelf.brews = GameState.carried

	panci.set_slot_count(1 if GameState.day <= 2 else mini(1 + GameState.day / 2, 4))
	tray.set_available(IngredientDB.available_on_day(GameState.day))

	panci.brew_ready.connect(_on_brew_ready)
	panci.brew_burnt.connect(_on_brew_burnt)
	kuali.changed.connect(_refresh_preview)
	drag.potion_dropped_outside.connect(_on_potion_parked)

	GameState.queue_changed.connect(_on_queue_changed)
	GameState.carried_changed.connect(_on_carried_changed)

	_restore_simmering()
	_new_session()


func _exit_tree() -> void:
	# Anything still in the pot keeps cooking while the player is away.
	_stash_simmering()
	if GameState.queue_changed.is_connected(_on_queue_changed):
		GameState.queue_changed.disconnect(_on_queue_changed)
	if GameState.carried_changed.is_connected(_on_carried_changed):
		GameState.carried_changed.disconnect(_on_carried_changed)


func _process(_delta: float) -> void:
	hud.queue_redraw()


func _on_carried_changed() -> void:
	shelf.brews = GameState.carried
	shelf.queue_redraw()


func _on_queue_changed() -> void:
	var o := GameState.active_order()
	if o != _last_order:
		_new_session()
	else:
		_refresh_preview()


# ═══════════════ SESSION ═══════════════

func _new_session() -> void:
	kuali.clear_pieces()
	tray.reset_loose()

	var order := GameState.active_order()
	_last_order = order

	var needed := _shapes_needed_for(order)
	var required_area := 0
	for s in needed:
		required_area += (s as Array).size()

	# The pot is chosen to fit the order, not at random — a severe complaint
	# must never land in a pot too small to hold its dose.
	var shape := KualiShape.shape_for(required_area, GameState.rng)
	var budget := KualiShape.residue_budget(shape.size(), GameState.day, required_area)
	var residue := KualiShape.generate_residue(shape, budget, needed, GameState.rng)

	kuali.build(shape, residue)
	_refresh_preview()


## One concrete way to satisfy the order, used ONLY to prove the board can
## be solved — never to constrain what the player may actually place.
##
## With potency in play this has to cover the full dose, not just tick each
## symptom once: a severity-5 complaint may need two ingredients stacked.
func _shapes_needed_for(order: Order) -> Array:
	var out: Array = []
	if order == null:
		return out

	var pool := IngredientDB.available_on_day(GameState.day)

	for s in order.symptoms():
		var need := order.required_potency(s)

		# Largest-first: fewer, bigger pieces are the harder packing case,
		# so proving THAT fits leaves margin for the player's own choices.
		var options: Array[IngredientData] = []
		for ing in pool:
			if ing.treats_symptom(s):
				options.append(ing)
		if options.is_empty():
			continue
		options.sort_custom(func(a: IngredientData, b: IngredientData) -> bool:
			return a.shape_cells.size() > b.shape_cells.size())

		var guard := 0
		while need > 0 and guard < 8:
			guard += 1
			var pick: IngredientData = options[0]
			for ing in options:
				if ing.shape_cells.size() <= need:
					pick = ing
					break
			out.append(pick.shape_cells.duplicate())
			need -= pick.shape_cells.size()

	return out


## Feeds the live dose meters on the order card.
func _refresh_preview() -> void:
	var order := GameState.active_order()
	if order == null:
		order_card.order = null
		order_card.queue_redraw()
		return

	order_card.order = order
	order_card.supplied = RecipeEvaluator.potency(
		kuali.placed_ingredients(), kuali.placed_cell_counts())
	order_card.queue_redraw()


# ═══════════════ BOTTLING ═══════════════

## The pot does not need to be full. What matters is what is in it.
func _bottle_kuali() -> void:
	var ings := kuali.placed_ingredients()
	if ings.is_empty():
		GameState.post("Kuali masih kosong.", Color("e05a4f"))
		return

	if not GameState.can_carry() and not panci.has_space():
		GameState.post("Tangan dan panci penuh — antar dulu.", Color("e05a4f"))
		return

	var order := GameState.active_order()
	var brew := Brew.create(
		ings, order.customer if order else null,
		order.symptoms() if order else [],
		kuali.placed_cell_counts())

	var potion := Potion.new()
	potion.setup(brew)

	if panci.has_space():
		add_child(potion)
		panci.put_anywhere(potion)
		GameState.post("Jamu masuk panci — atur apinya.", Color("6fd48f"))
	else:
		add_child(potion)
		_park(potion)
		GameState.post("Jamu jadi. Seret ke panci untuk direbus.", Color("6fd48f"))

	if not brew.heat_window.x <= brew.heat_window.y:
		GameState.post("Suhu bahan-bahannya bentrok — sulit dimatangkan!",
			Color("d89b3c"))

	_new_session()


func _on_potion_parked(potion: Potion) -> void:
	_park(potion)


func _park(potion: Potion) -> void:
	if potion.get_parent() != self:
		if potion.get_parent():
			potion.get_parent().remove_child(potion)
		add_child(potion)

	var others := 0
	for c in get_children():
		if c is Potion and c != potion and panci.slot_of(c) < 0:
			others += 1

	potion.global_position = $CounterSpot.global_position \
		+ Vector2((others % 3) * 46, 0)
	potion.z_index = 1


func _on_brew_ready(slot: int) -> void:
	var p: Potion = panci.potions[slot]
	if p == null:
		return
	# A finished jamu goes straight into the player's hands so it can be
	# carried to the counter; if their hands are full it waits in the pot.
	if GameState.can_carry():
		GameState.carry(p.brew)
		panci.take(slot)
		p.queue_free()
		GameState.post("Jamu siap — bawa ke kasir (TAB).", Color("6fd48f"))
	else:
		GameState.post("Jamu siap, tapi tanganmu penuh.", Color("d89b3c"))


func _on_brew_burnt(_slot: int) -> void:
	GameState.post("Jamu gosong!", Color("e05a4f"))


## Potions left in the pot must survive the room switch, so their brews are
## parked in GameState and rebuilt on the way back in.
func _stash_simmering() -> void:
	var out: Array = []
	for i in range(panci.potions.size()):
		var p: Potion = panci.potions[i]
		if p != null and p.brew != null:
			out.append([i, p.brew])
	GameState.set_meta("simmering", out)
	GameState.set_meta("heat", panci.heat)


func _restore_simmering() -> void:
	if not GameState.has_meta("simmering"):
		return
	var stash: Array = GameState.get_meta("simmering")
	for entry in stash:
		var slot: int = entry[0]
		var b: Brew = entry[1]
		if slot >= panci.slot_count:
			slot = panci.free_slot()
		if slot < 0:
			continue
		var p := Potion.new()
		p.setup(b)
		add_child(p)
		panci.put(p, slot)
	panci.heat = GameState.get_meta("heat", 0.5)
	GameState.set_meta("simmering", [])


# ═══════════════ TOOLS ═══════════════

## Tools act on the piece under the cursor, so using one is a deliberate
## aim-and-click rather than a mode the player can forget they are in.
func _on_tool_selected(kind: ToolKit.Kind) -> void:
	if not GameState.tools.can_use(kind):
		GameState.post("%s sudah habis hari ini." % ToolKit.display_name(kind),
			Color("e05a4f"))
		return

	match kind:
		ToolKit.Kind.SARING:
			_use_saring()
		ToolKit.Kind.PIPISAN:
			_use_on_piece(kind)
		ToolKit.Kind.TUMBUK:
			_use_on_piece(kind)


func _use_saring() -> void:
	if kuali.scrub_residue():
		GameState.tools.consume(ToolKit.Kind.SARING)
		GameState.post("Ampas dibersihkan satu petak.", Color("6fd48f"))
		toolbar.queue_redraw()
	else:
		GameState.post("Tidak ada ampas untuk dibersihkan.", Color("9a8f80"))


func _use_on_piece(kind: ToolKit.Kind) -> void:
	var piece := _piece_under_mouse()
	if piece == null:
		GameState.post("Arahkan ke bahan di kuali, lalu pakai alatnya.",
			Color("9a8f80"))
		return

	if kind == ToolKit.Kind.PIPISAN:
		_cut(piece)
	else:
		_press(piece)


func _piece_under_mouse() -> IngredientPiece:
	var pos := get_global_mouse_position()
	for id in kuali.pieces:
		var piece: IngredientPiece = kuali.pieces[id]
		for c in piece.cells:
			var r := Rect2(piece.global_position + Vector2(c) * CELL,
				Vector2.ONE * CELL)
			if r.has_point(pos):
				return piece
	return null


## Splits a piece into two halves. Both halves stay in the pot when there
## is room; otherwise the leftover goes back to the shelf rather than
## silently vanishing.
func _cut(piece: IngredientPiece) -> void:
	var halves := ToolKit.cut(piece.cells)
	if halves.is_empty():
		GameState.post("Bahan ini terlalu kecil untuk dibelah.", Color("9a8f80"))
		return

	var anchor := piece.grid_pos
	var data := piece.data

	kuali.remove(piece)
	piece.queue_free()

	var placed := 0
	for h in halves:
		var half := IngredientPiece.new()
		half.setup(data, kuali.next_id())
		half.cells = h
		half.was_cut = true
		add_child(half)

		var spot := kuali.best_fit(half, anchor)
		if spot == KualiGrid.INVALID:
			spot = kuali.first_fit(half)
		if spot == KualiGrid.INVALID:
			half.queue_free()
			continue

		kuali.place(half, spot)
		placed += 1

	GameState.tools.consume(ToolKit.Kind.PIPISAN)
	toolbar.queue_redraw()

	if placed < halves.size():
		GameState.post("Dibelah — satu potong tak muat lagi di kuali.",
			Color("d89b3c"))
	else:
		GameState.post("Bahan dibelah jadi dua.", Color("6fd48f"))


## Compacts a piece into a squarer footprint. Cell count is preserved, so
## potency is untouched — this buys space, never healing power.
func _press(piece: IngredientPiece) -> void:
	if not ToolKit.press_changes_shape(piece.cells):
		GameState.post("Bahan ini sudah padat.", Color("9a8f80"))
		return

	var anchor := piece.grid_pos
	var pressed := ToolKit.press(piece.cells)
	var before := piece.cells.duplicate()

	kuali.remove(piece)
	piece.cells = pressed

	var spot := kuali.best_fit(piece, anchor)
	if spot == KualiGrid.INVALID:
		spot = kuali.first_fit(piece)

	if spot == KualiGrid.INVALID:
		# No room for the new footprint — undo rather than lose the piece.
		piece.cells = before
		kuali.place(piece, anchor)
		GameState.post("Tidak ada ruang untuk bentuk barunya.", Color("d89b3c"))
		return

	kuali.place(piece, spot)
	piece.queue_redraw()
	GameState.tools.consume(ToolKit.Kind.TUMBUK)
	toolbar.queue_redraw()
	GameState.post("Bahan dipadatkan.", Color("6fd48f"))


# ═══════════════ INPUT ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_over:
		if event is InputEventKey and event.pressed:
			GameState.start_run()
			Rooms.go(Rooms.Room.KASIR)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_TAB:
				Rooms.go(Rooms.Room.KASIR)
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_bottle_kuali()
				get_viewport().set_input_as_handled()
			KEY_Q:
				GameState.cycle_active(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				GameState.cycle_active(1)
				get_viewport().set_input_as_handled()
			KEY_1:
				_on_tool_selected(ToolKit.Kind.PIPISAN)
				get_viewport().set_input_as_handled()
			KEY_2:
				_on_tool_selected(ToolKit.Kind.TUMBUK)
				get_viewport().set_input_as_handled()
			KEY_3:
				_on_tool_selected(ToolKit.Kind.SARING)
				get_viewport().set_input_as_handled()
			KEY_C:
				kuali.clear_pieces()
				GameState.post("Kuali dikosongkan.", Color("9a8f80"))
				get_viewport().set_input_as_handled()
