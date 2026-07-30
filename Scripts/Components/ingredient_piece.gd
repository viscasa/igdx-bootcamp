class_name IngredientPiece extends Node2D

## A draggable ingredient. Drawn with primitives — no art needed for the
## prototype. Ported in spirit from Waste Crusher's block_piece.gd.

const CELL := 34

enum State { IN_TRAY, DRAGGING, IN_KUALI }

var data: IngredientData
var piece_id: int = -1
var cells: Array[Vector2i] = []
var state: State = State.IN_TRAY
var grid_pos: Vector2i = Vector2i(-1, -1)

var _lifted: bool = false


func setup(d: IngredientData, id: int) -> void:
	data = d
	piece_id = id
	cells = d.shape_cells.duplicate()
	queue_redraw()


func size_cells() -> Vector2i:
	return GridLogic.shape_size(cells)


func pixel_size() -> Vector2:
	return Vector2(size_cells()) * CELL


func rotate_cw() -> void:
	cells = GridLogic.rotate_cw(cells)
	queue_redraw()


func set_lifted(v: bool) -> void:
	_lifted = v
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE * (1.08 if v else 1.0), 0.1)
	queue_redraw()


func _draw() -> void:
	if not data:
		return

	var base := data.color
	var shadow := Color(0, 0, 0, 0.25)

	for c in cells:
		var p := Vector2(c) * CELL

		if _lifted:
			draw_rect(Rect2(p + Vector2(3, 5), Vector2(CELL, CELL)), shadow)

		draw_rect(Rect2(p, Vector2(CELL, CELL)), base)
		# Bevel so adjacent cells of one piece still read as separate cells.
		draw_rect(Rect2(p, Vector2(CELL, 3)), base.lightened(0.35))
		draw_rect(Rect2(p + Vector2(0, CELL - 3), Vector2(CELL, 3)), base.darkened(0.3))
		draw_rect(Rect2(p, Vector2(CELL, CELL)), base.darkened(0.45), false, 2.0)

	# Bitterness pips — a visual cue that this ingredient needs sweetening.
	if data.bitterness >= 4 and not cells.is_empty():
		var origin := Vector2(cells[0]) * CELL + Vector2(6, 6)
		for i in range(mini(data.bitterness, 5)):
			draw_circle(origin + Vector2(i * 7, 0), 2.5, Color(0.1, 0.1, 0.1, 0.7))
