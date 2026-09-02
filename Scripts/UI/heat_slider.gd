class_name HeatSlider extends Control

signal heat_changed(value: float)

var panci: Panci
var _dragging := false

@onready var track: Control = $Track
@onready var handle: ColorRect = $Handle
@onready var speed_label: Label = $Speed


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_visual()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse.pressed
			if mouse.pressed:
				_set_from_y(mouse.position.y)
			accept_event()
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_nudge(0.06)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_nudge(-0.06)
	elif event is InputEventMouseMotion and _dragging:
		_set_from_y((event as InputEventMouseMotion).position.y)
		accept_event()


func _nudge(amount: float) -> void:
	if panci:
		panci.heat = clampf(panci.heat + amount, 0.0, 1.0)
		heat_changed.emit(panci.heat)
		_sync_visual()
		panci.refresh_visuals()


func _set_from_y(y: float) -> void:
	if not panci:
		return
	panci.heat = clampf(1.0 - (y - track.position.y) / track.size.y, 0.0, 1.0)
	heat_changed.emit(panci.heat)
	_sync_visual()
	panci.refresh_visuals()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		_nudge(0.9 * delta)
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		_nudge(-0.9 * delta)
	_sync_visual()


func _sync_visual() -> void:
	if not is_node_ready() or panci == null:
		return
	var y := track.position.y + track.size.y * (1.0 - panci.heat)
	handle.position.y = y - handle.size.y * 0.5
	speed_label.position.y = y - speed_label.size.y * 0.5
	speed_label.text = "x%.1f" % panci.cook_speed()
