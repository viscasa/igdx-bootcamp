@tool
extends PanelContainer

const CELL_PITCH := 62.0

@export_group("Board Size")
@export_range(3, 10, 1) var board_width := 10:
	set(value):
		board_width = value
		_request_grid_sync()
@export_range(3, 10, 1) var board_height := 10:
	set(value):
		board_height = value
		_request_grid_sync()

@export_group("Board Visual")
@export var block_texture: Texture2D = preload("res://icon.svg")
@export var placed_color := Color("#55c7f3")
@export var valid_preview_color := Color("#57e3a0")
@export var invalid_preview_color := Color("#ff6b7a")

@onready var grid: GridContainer = $Margin/VBox/GridCenter/Grid

var occupied: Dictionary = {}
var previewed_cells: Array[Vector2i] = []


func _ready() -> void:
	_sync_grid()


func _request_grid_sync() -> void:
	if is_inside_tree():
		call_deferred("_sync_grid")


func _sync_grid() -> void:
	if not is_instance_valid(grid):
		return
	previewed_cells.clear()
	grid.columns = board_width
	var visible_cell_count := board_width * board_height
	for index: int in grid.get_child_count():
		grid.get_child(index).visible = index < visible_cell_count
	if not Engine.is_editor_hint():
		for cell: Vector2i in occupied.keys():
			if not _is_inside(cell):
				occupied.erase(cell)
		_refresh_all_cells()


func cell_from_global_position(piece_top_left: Vector2) -> Vector2i:
	var local_position := piece_top_left - grid.global_position
	return Vector2i(roundi(local_position.x / CELL_PITCH), roundi(local_position.y / CELL_PITCH))


func can_place(piece_cells: Array[Vector2i], origin: Vector2i) -> bool:
	for cell: Vector2i in piece_cells:
		var target := origin + cell
		if not _is_inside(target) or occupied.has(target):
			return false
	return true


func show_preview(piece_cells: Array[Vector2i], origin: Vector2i, valid: bool) -> void:
	clear_preview()
	var preview_color := valid_preview_color if valid else invalid_preview_color
	for cell: Vector2i in piece_cells:
		var target := origin + cell
		if not _is_inside(target):
			continue
		previewed_cells.append(target)
		var button := _button_at(target)
		button.icon = block_texture
		button.modulate = preview_color


func clear_preview() -> void:
	for cell: Vector2i in previewed_cells:
		var button := _button_at(cell)
		if occupied.has(cell):
			button.icon = block_texture
			button.modulate = placed_color
		else:
			button.icon = null
			button.modulate = Color.WHITE
	previewed_cells.clear()


func place_piece(piece_cells: Array[Vector2i], origin: Vector2i) -> int:
	clear_preview()
	for cell: Vector2i in piece_cells:
		occupied[origin + cell] = true
	var cleared := _clear_complete_lines()
	_refresh_all_cells()
	return cleared


func _clear_complete_lines() -> int:
	var rows: Array[int] = []
	var columns: Array[int] = []
	for y: int in board_height:
		var complete := true
		for x: int in board_width:
			if not occupied.has(Vector2i(x, y)):
				complete = false
				break
		if complete:
			rows.append(y)
	for x: int in board_width:
		var complete := true
		for y: int in board_height:
			if not occupied.has(Vector2i(x, y)):
				complete = false
				break
		if complete:
			columns.append(x)
	for cell: Vector2i in occupied.keys():
		if rows.has(cell.y) or columns.has(cell.x):
			occupied.erase(cell)
	return rows.size() + columns.size()


func _refresh_all_cells() -> void:
	for y: int in board_height:
		for x: int in board_width:
			var cell := Vector2i(x, y)
			var button := _button_at(cell)
			if occupied.has(cell):
				button.icon = block_texture
				button.modulate = placed_color
			else:
				button.icon = null
				button.modulate = Color.WHITE


func _button_at(cell: Vector2i) -> Button:
	return grid.get_child(cell.y * board_width + cell.x) as Button


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < board_width and cell.y < board_height
