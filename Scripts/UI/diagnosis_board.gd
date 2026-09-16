class_name DiagnosisBoard extends Control

## The customer-facing deduction board. Its scene owns the visible symptom
## cards and three diagnosis slots; this script binds order state and dragging.

signal take_requested(order: Order)

const MAX_DIAGNOSIS := 3
const CLUE_PATIENCE_COST := 0.0
const SCREEN_MARGIN := 24.0

@onready var drag_handle: Control = %DragHandle
@onready var customer_name: Label = %CustomerName
@onready var role_label: Label = %RoleLabel
@onready var close_button: Button = %CloseButton
@onready var diagnosis_slots: HBoxContainer = %DiagnosisSlots
@onready var diagnosis_grid: GridContainer = %DiagnosisGrid
@onready var status_label: Label = %StatusLabel
@onready var clue_button: Button = %ClueButton
@onready var take_button: Button = %TakeButton

var order: Order = null
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _default_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_default_position = position
	WorldAudioManager.set_button_cue(clue_button, &"")
	WorldAudioManager.set_button_cue(take_button, WorldAudioManager.CONFIRM)
	WorldAudioManager.set_button_cue(close_button, WorldAudioManager.MENU_CLOSE)
	drag_handle.gui_input.connect(_on_drag_handle_input)
	for i in range(diagnosis_grid.get_child_count()):
		var button := diagnosis_grid.get_child(i) as Button
		if button:
			button.pressed.connect(_toggle.bind(i))
	for i in range(diagnosis_slots.get_child_count()):
		var slot = diagnosis_slots.get_child(i)
		slot.pressed.connect(_remove_slot.bind(i))
	clue_button.pressed.connect(_ask_clue)
	take_button.pressed.connect(_take)
	close_button.pressed.connect(close)
	_show_empty()


func set_order(next: Order) -> void:
	order = next
	visible = order != null
	if visible and GameState.diagnosis_board_position_set:
		position = GameState.diagnosis_board_position
	_refresh()


func close() -> void:
	set_order(null)


func _show_empty() -> void:
	visible = false
	status_label.text = ""
	clue_button.disabled = true
	take_button.disabled = true
	for child in diagnosis_grid.get_children():
		(child as Button).disabled = true
	_refresh_slots()


func _refresh() -> void:
	if order == null:
		_show_empty()
		return

	customer_name.text = order.customer.display_name
	%Dialogue.text = order.current_dialogue()
	role_label.text = order.customer.role
	clue_button.disabled = false
	clue_button.text = "TANYA LAGI" if order.clue_uses >= 1 else "TANYA PELANGGAN"
	take_button.disabled = order.diagnosis.is_empty()
	take_button.text = "SIMPAN CATATAN" if GameState.has_taken(order) \
		else "AMBIL PESANAN"

	for i in range(diagnosis_grid.get_child_count()):
		var button := diagnosis_grid.get_child(i) as Button
		if button == null:
			continue
		var code := i as Symptom.Code
		button.disabled = false
		button.visible = IngredientDB.supports_symptom(code)
		button.text = Symptom.display_name(code)
		button.set_pressed_no_signal(code in order.diagnosis)
		var icon_color := Symptom.color(code).lightened(0.08)
		for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			button.add_theme_color_override(state, icon_color)

	_refresh_slots()
	status_label.text = "%d/3 tanda dipasang" % order.diagnosis.size()


func _refresh_slots() -> void:
	for i in range(diagnosis_slots.get_child_count()):
		var slot := diagnosis_slots.get_child(i) as Button
		if slot == null:
			continue
		if order != null and i < order.diagnosis.size():
			slot.disabled = false
			var code := order.diagnosis[i]
			var source := diagnosis_grid.get_child(int(code)) as Button
			slot.icon = source.icon
			slot.text = Symptom.display_name(code)
			slot.modulate = Color.WHITE
		else:
			slot.disabled = true
			slot.icon = null
			slot.text = "Dugaan %d" % (i + 1)
			slot.modulate = Color(1.0, 1.0, 1.0, 0.62)


func _toggle(code: int) -> void:
	if order == null:
		return
	if not order.toggle_diagnosis(code as Symptom.Code, MAX_DIAGNOSIS):
		_refresh()
		WorldAudioManager.play_ui(WorldAudioManager.LOCK)
		status_label.text = "Tiga slot sudah penuh"
		_shake_slots()
		return
	_refresh()


func _ask_clue() -> void:
	if order == null:
		return
	order.patience_left = maxf(order.patience_left - CLUE_PATIENCE_COST, 1.0)
	order.next_clue()
	WorldAudioManager.play_ui(WorldAudioManager.DIALOGUE_BLIP,
		Vector2(0.94, 1.06), -1.0, 45)
	GameState.post("Pelanggan memberi petunjuk baru.", Color("ffd36f"))
	GameState.queue_changed.emit()
	_refresh()


func _remove_slot(index: int) -> void:
	if order != null and index < order.diagnosis.size():
		_toggle(order.diagnosis[index])


func _take() -> void:
	if order == null or order.diagnosis.is_empty():
		return
	take_requested.emit(order)
	_refresh()


func _on_drag_handle_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.double_click:
		position = _default_position
		GameState.diagnosis_board_position_set = false
		_dragging = false
		accept_event()
		return
	_dragging = mouse.pressed
	if _dragging:
		_drag_offset = get_global_mouse_position() - global_position
		z_index = 100
	else:
		_finish_drag()
	accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - _drag_offset
		_clamp_to_viewport()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			_dragging = false
			_finish_drag()
			get_viewport().set_input_as_handled()


func _finish_drag() -> void:
	z_index = 0
	_clamp_to_viewport()
	GameState.diagnosis_board_position = position
	GameState.diagnosis_board_position_set = true


func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var rect := get_global_rect()
	var correction := Vector2.ZERO
	if rect.position.x < SCREEN_MARGIN:
		correction.x = SCREEN_MARGIN - rect.position.x
	elif rect.end.x > viewport_size.x - SCREEN_MARGIN:
		correction.x = viewport_size.x - SCREEN_MARGIN - rect.end.x
	if rect.position.y < SCREEN_MARGIN:
		correction.y = SCREEN_MARGIN - rect.position.y
	elif rect.end.y > viewport_size.y - SCREEN_MARGIN:
		correction.y = viewport_size.y - SCREEN_MARGIN - rect.end.y
	global_position += correction


func _shake_slots() -> void:
	var original := diagnosis_slots.position
	var tween := create_tween()
	for offset in [Vector2(-7, 0), Vector2(7, 0), Vector2(-4, 0), Vector2.ZERO]:
		tween.tween_property(diagnosis_slots, "position", original + offset, 0.045)
