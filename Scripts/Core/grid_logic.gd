class_name GridLogic

## Pure grid math. No nodes, no side effects — easy to test and reason about.
##
## Grid is a Dictionary[Vector2i, int]:
##   key   = cell position
##   value = piece_id (0 = empty/available, >0 = occupied)
## Cells NOT in the dictionary are outside the kuali (holes).
##
## Ported unchanged from Waste Crusher (bgdjam-2026).


## Can a shape occupy (gx, gy) without overlapping or leaving the kuali?
static func can_place(grid: Dictionary, cells: Array[Vector2i], gx: int, gy: int) -> bool:
	for c in cells:
		var cell := Vector2i(gx + c.x, gy + c.y)
		if not grid.has(cell):
			return false  # outside the kuali
		if grid[cell] != 0:
			return false  # already occupied
	return true


## Write piece_id into every cell of the shape. Call can_place() first.
static func place(grid: Dictionary, cells: Array[Vector2i], gx: int, gy: int, piece_id: int) -> void:
	for c in cells:
		grid[Vector2i(gx + c.x, gy + c.y)] = piece_id


## Clear every cell holding piece_id.
static func remove(grid: Dictionary, piece_id: int) -> void:
	for cell in grid:
		if grid[cell] == piece_id:
			grid[cell] = 0


static func is_full(grid: Dictionary) -> bool:
	for cell in grid:
		if grid[cell] == 0:
			return false
	return true


static func count_empty(grid: Dictionary) -> int:
	var n := 0
	for cell in grid:
		if grid[cell] == 0:
			n += 1
	return n


## Bounding box of all active cells. Returns Rect2i(pos, size).
static func bounds(grid: Dictionary) -> Rect2i:
	if grid.is_empty():
		return Rect2i()

	var min_x := 2147483647
	var min_y := 2147483647
	var max_x := -2147483648
	var max_y := -2147483648
	for cell in grid:
		var c := cell as Vector2i
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


## Normalize a cell list so its top-left sits at (0, 0).
static func normalize(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		return []

	var min_x := cells[0].x
	var min_y := cells[0].y
	for c in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)

	var out: Array[Vector2i] = []
	for c in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	return out


## Rotate cells 90° clockwise: (x, y) → (maxY - y, x), then normalize.
static func rotate_cw(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		return []

	var max_y := cells[0].y
	for c in cells:
		max_y = maxi(max_y, c.y)

	var rotated: Array[Vector2i] = []
	for c in cells:
		rotated.append(Vector2i(max_y - c.y, c.x))

	return normalize(rotated)


## Size of the bounding box a cell list occupies.
static func shape_size(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO

	var max_x := 0
	var max_y := 0
	for c in cells:
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	return Vector2i(max_x + 1, max_y + 1)
