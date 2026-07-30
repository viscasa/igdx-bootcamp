class_name HeatSlider extends Control

## Vertical heat lever. One lever for the whole panci — that constraint is
## the point: brews with different ideal temperatures must be compromised.

signal heat_changed(value: float)

const W := 42
const H := 190

var panci: Panci
var _dragging: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(W, H + 26)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if mb.pressed:
				_set_from_y(mb.position.y)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_nudge(0.06)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_nudge(-0.06)
	elif event is InputEventMouseMotion and _dragging:
		_set_from_y((event as InputEventMouseMotion).position.y)
		accept_event()


func _nudge(amount: float) -> void:
	if panci:
		panci.heat = clampf(panci.heat + amount, 0.0, 1.0)
		heat_changed.emit(panci.heat)
		queue_redraw()
		panci.queue_redraw()


func _set_from_y(y: float) -> void:
	if not panci:
		return
	# Top of the track is hottest.
	panci.heat = clampf(1.0 - (y - 20.0) / H, 0.0, 1.0)
	heat_changed.emit(panci.heat)
	queue_redraw()
	panci.queue_redraw()


func _process(_delta: float) -> void:
	# Keyboard control so the player can adjust heat mid-drag.
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		_nudge(0.9 * get_process_delta_time())
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		_nudge(-0.9 * get_process_delta_time())


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var track := Rect2(Vector2(8, 20), Vector2(W - 16, H))

	draw_string(font, Vector2(0, 14), "API", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color("c9b892"))

	# Gradient: cool at the bottom, hot at the top.
	var steps := 32
	for i in range(steps):
		var t := float(i) / steps
		var seg := Rect2(
			Vector2(track.position.x, track.position.y + track.size.y * (1.0 - t) - track.size.y / steps),
			Vector2(track.size.x, track.size.y / steps + 1))
		draw_rect(seg, Color("2b2620").lerp(Color("e05a4f"), t))

	draw_rect(track, Color("4a4038"), false, 2.0)

	# Ideal bands for every active brew — shows the compromise directly.
	if panci:
		for b in panci.slots:
			if b == null or b.is_burnt:
				continue
			var w: Vector2 = b.heat_window()
			if w.x > w.y:
				continue
			var y_hi := track.position.y + track.size.y * (1.0 - w.y)
			var y_lo := track.position.y + track.size.y * (1.0 - w.x)
			draw_rect(Rect2(Vector2(track.end.x + 3, y_hi), Vector2(7, y_lo - y_hi)),
				Color(0.4, 0.85, 0.5, 0.8))

		# Handle
		var hy := track.position.y + track.size.y * (1.0 - panci.heat)
		draw_rect(Rect2(Vector2(track.position.x - 5, hy - 5),
			Vector2(track.size.x + 10, 10)), Color("ffd36f"))
		draw_rect(Rect2(Vector2(track.position.x - 5, hy - 5),
			Vector2(track.size.x + 10, 10)), Color("6b5a2b"), false, 1.5)

	draw_string(font, Vector2(0, track.end.y + 16), "W/S", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 11, Color("7a6f60"))
