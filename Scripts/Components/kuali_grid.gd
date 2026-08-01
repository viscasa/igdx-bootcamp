class_name KualiGrid extends Node2D

## The pot. Holds an irregular grid of cells; the player fills every one.
## Adapted from Waste Crusher's landfill_grid.gd — the key change is that
## completion is graded (BrewResult), not a win/lose boolean.

signal changed
signal filled

const CELL := IngredientPiece.CELL
const INVALID := Vector2i(2147483647, 2147483647)

## How far (in cells) placement will magnet-snap to a valid spot.
@export var snap_radius: float = 1.4

var grid: Dictionary = {}          ## Vector2i -> piece_id (0 = empty)
var pieces: Dictionary = {}        ## piece_id -> IngredientPiece
var residue: Dictionary = {}       ## Vector2i -> true (blocked by leftovers)

var _hover_cells: Array[Vector2i] = []
var _hover_valid: bool = false
var _next_id: int = 1


## `shape` lists every cell that is inside the pot.
func build(shape: Array[Vector2i], residue_cells: Array[Vector2i] = []) -> void:
	grid.clear()
	pieces.clear()
	residue.clear()
	_next_id = 1

	for c in shape:
		grid[c] = 0

	for c in residue_cells:
		if grid.has(c):
			grid[c] = -1        # -1 marks residue: occupied, not a piece
			residue[c] = true

	_hover_cells.clear()
	queue_redraw()
	changed.emit()


func next_id() -> int:
	var id := _next_id
	_next_id += 1
	return id


func cell_at(global_pos: Vector2) -> Vector2i:
	var local := global_pos - global_position
	return Vector2i(floori(local.x / CELL + 0.5), floori(local.y / CELL + 0.5))


func can_place(piece: IngredientPiece, gpos: Vector2i) -> bool:
	return GridLogic.can_place(grid, piece.cells, gpos.x, gpos.y)


## Nearest valid placement to `desired`, or INVALID if none is close enough.
func best_fit(piece: IngredientPiece, desired: Vector2i) -> Vector2i:
	if grid.is_empty():
		return INVALID

	var b := GridLogic.bounds(grid)
	var shape := GridLogic.shape_size(piece.cells)

	var best := INVALID
	var best_dist := INF

	for gx in range(b.position.x - shape.x, b.end.x + 1):
		for gy in range(b.position.y - shape.y, b.end.y + 1):
			var gp := Vector2i(gx, gy)
			if not can_place(piece, gp):
				continue
			var d := Vector2(gp - desired).length_squared()
			if d < best_dist:
				best_dist = d
				best = gp

	if best != INVALID and best_dist > snap_radius * snap_radius:
		return INVALID
	return best


## Any legal spot, ignoring distance. Used by the tools, which must land a
## reshaped piece somewhere rather than drop it on the floor.
func first_fit(piece: IngredientPiece) -> Vector2i:
	if grid.is_empty():
		return INVALID

	var b := GridLogic.bounds(grid)
	var shape := GridLogic.shape_size(piece.cells)

	for gy in range(b.position.y - shape.y, b.end.y + 1):
		for gx in range(b.position.x - shape.x, b.end.x + 1):
			var gp := Vector2i(gx, gy)
			if can_place(piece, gp):
				return gp
	return INVALID


func place(piece: IngredientPiece, gpos: Vector2i) -> void:
	GridLogic.place(grid, piece.cells, gpos.x, gpos.y, piece.piece_id)
	pieces[piece.piece_id] = piece
	piece.state = IngredientPiece.State.IN_KUALI
	piece.grid_pos = gpos

	if piece.get_parent() != self:
		if piece.get_parent():
			piece.get_parent().remove_child(piece)
		add_child(piece)

	piece.position = Vector2(gpos) * CELL
	piece.z_index = 0

	queue_redraw()
	changed.emit()
	if is_full():
		filled.emit()


func remove(piece: IngredientPiece) -> void:
	GridLogic.remove(grid, piece.piece_id)
	pieces.erase(piece.piece_id)
	piece.grid_pos = Vector2i(-1, -1)
	queue_redraw()
	changed.emit()


func is_full() -> bool:
	return GridLogic.is_full(grid)


func empty_count() -> int:
	return GridLogic.count_empty(grid)


func placed_ingredients() -> Array[IngredientData]:
	var out: Array[IngredientData] = []
	for id in pieces:
		out.append(pieces[id].data)
	return out


## Parallel to placed_ingredients(): the real cell count of each piece,
## which differs from the pristine shape once a piece has been cut.
func placed_cell_counts() -> Array[int]:
	var out: Array[int] = []
	for id in pieces:
		out.append((pieces[id] as IngredientPiece).potency())
	return out


func filled_count() -> int:
	return grid.size() - empty_count()


## Cells the player can still reach — residue is walled off permanently.
func usable_count() -> int:
	return grid.size() - residue.size()


func clear_pieces() -> void:
	for id in pieces.keys():
		var p: IngredientPiece = pieces[id]
		if is_instance_valid(p):
			p.queue_free()
	pieces.clear()
	for c in grid:
		if not residue.has(c):
			grid[c] = 0
	queue_redraw()
	changed.emit()


# ───── Hover preview ─────

func update_hover(piece: IngredientPiece) -> void:
	var desired := cell_at(piece.global_position)
	var snapped := best_fit(piece, desired)

	var target := snapped if snapped != INVALID else desired
	_hover_valid = snapped != INVALID or can_place(piece, desired)

	_hover_cells.clear()
	for c in piece.cells:
		_hover_cells.append(target + c)
	queue_redraw()


func clear_hover() -> void:
	_hover_cells.clear()
	queue_redraw()


func _draw() -> void:
	# Pot interior
	for cell in grid:
		var r := Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL))
		if residue.has(cell):
			draw_rect(r, Color("4a4038"))
			draw_line(r.position, r.end, Color("2e2822"), 3.0)
			draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y),
				Color("2e2822"), 3.0)
		else:
			draw_rect(r, Color("2b2620"))
		draw_rect(r, Color("15120f"), false, 2.0)

	# Hover ghost
	if not _hover_cells.is_empty():
		var col := Color(0.35, 0.9, 0.45, 0.4) if _hover_valid else Color(0.9, 0.3, 0.3, 0.4)
		for cell in _hover_cells:
			if grid.has(cell):
				draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), col)
