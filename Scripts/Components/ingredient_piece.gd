class_name IngredientPiece extends Node2D

const CELL := 34

enum State { IN_TRAY, DRAGGING, IN_KUALI }

var data: IngredientData
var piece_id: int = -1
var cells: Array[Vector2i] = []:
	set(value):
		cells = value
		_sync_visual()
var state: State = State.IN_TRAY
var grid_pos: Vector2i = Vector2i(-1, -1)
var was_cut: bool = false
var _lifted := false


func _ready() -> void:
	_sync_visual()


func setup(d: IngredientData, id: int) -> void:
	data = d
	piece_id = id
	cells = d.shape_cells.duplicate()
	_sync_visual()


func potency() -> int:
	return cells.size()


func size_cells() -> Vector2i:
	return GridLogic.shape_size(cells)


func pixel_size() -> Vector2:
	return Vector2(size_cells()) * CELL


func rotate_cw() -> void:
	cells = GridLogic.rotate_cw(cells)


func set_lifted(value: bool) -> void:
	_lifted = value
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE * (1.08 if value else 1.0), 0.1)
	_sync_visual()


func _sync_visual() -> void:
	if not is_inside_tree():
		return
	var holder := get_node_or_null("Cells")
	if holder == null:
		return
	var base := data.color if data else Color("c4553c")
	var nodes := holder.get_children()
	for i in range(nodes.size()):
		var cell := nodes[i] as IngredientCell
		if cell == null:
			continue
		cell.visible = i < cells.size()
		if i < cells.size():
			cell.position = Vector2(cells[i]) * CELL
			cell.set_cell_color(base)
			cell.set_lifted(_lifted)

	var pips := get_node_or_null("BitternessPips") as Node2D
	if pips:
		var amount := mini(data.bitterness, 5) if data else 0
		pips.visible = amount > 0 and not cells.is_empty()
		if not cells.is_empty():
			pips.position = Vector2(cells[0]) * CELL + Vector2(6, 6)
		for i in range(pips.get_child_count()):
			(pips.get_child(i) as CanvasItem).visible = i < amount
