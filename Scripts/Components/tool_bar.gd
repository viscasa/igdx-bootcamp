class_name ToolBar extends Node2D

## The three tools and how many uses are left today.
##
## The remaining count is drawn large and always visible: rationing only
## creates tension if the player can see the budget shrinking.

signal tool_selected(kind: ToolKit.Kind)

const BTN_W := 116
const BTN_H := 58
const GAP := 8

const ORDER: Array[ToolKit.Kind] = [
	ToolKit.Kind.PIPISAN,
	ToolKit.Kind.TUMBUK,
	ToolKit.Kind.SARING,
]

const KEYS := ["1", "2", "3"]

var tools: ToolKit

var _hover: int = -1


func btn_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (BTN_W + GAP), 0), Vector2(BTN_W, BTN_H))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var was := _hover
		_hover = _index_at(get_global_mouse_position())
		if was != _hover:
			queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var i := _index_at(get_global_mouse_position())
			if i >= 0:
				tool_selected.emit(ORDER[i])
				get_viewport().set_input_as_handled()


func _index_at(global_pos: Vector2) -> int:
	var local := to_local(global_pos)
	for i in range(ORDER.size()):
		if btn_rect(i).has_point(local):
			return i
	return -1


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, -10), "ALAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("c9b892"))

	for i in range(ORDER.size()):
		var kind := ORDER[i]
		var r := btn_rect(i)
		var left := tools.remaining(kind) if tools else 0
		var usable := left > 0

		# No buttons drawn — state is carried by text colour alone, so art
		# can replace this without first unpicking a pile of rectangles.
		var name_col := Color("5a5048")
		if usable:
			name_col = Color("6fd48f") if i == _hover else Color("e8dcc0")

		draw_string(font, r.position + Vector2(0, 14),
			"%s. %s" % [KEYS[i], ToolKit.display_name(kind)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, name_col)

		draw_string(font, r.position + Vector2(0, 29), ToolKit.hint(kind),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7a6f60"))

		# Remaining uses as pips — a budget reads faster than a number.
		var px := r.position.x
		var py := r.position.y + 38
		if left > 0:
			for n in range(left):
				draw_rect(Rect2(Vector2(px + n * 9, py), Vector2(6, 6)),
					Color("c9b892"))
		else:
			draw_string(font, Vector2(px, py + 7), "habis",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("e05a4f"))
