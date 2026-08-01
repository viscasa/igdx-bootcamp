class_name KualiShape

## Generates pot shapes and residue.
##
## Hard rule: residue must never make an order impossible. A puzzle the
## player cannot solve destroys trust instantly, so we verify solvability
## with a real solver before handing the board over.

## A few hand-made pot silhouettes. Irregular on purpose — a plain
## rectangle would make placement trivial.
const SHAPES := {
	"bulat": [
		Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
		Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1),
		Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2),
		Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(3,3), Vector2i(4,3),
		Vector2i(1,4), Vector2i(2,4), Vector2i(3,4),
	],
	"lonjong": [
		Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0),
		Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1),
		Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(1,3), Vector2i(2,3), Vector2i(3,3), Vector2i(4,3),
	],
	"cekung": [
		Vector2i(0,0), Vector2i(1,0),               Vector2i(4,0), Vector2i(5,0),
		Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1),
		Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(1,3), Vector2i(2,3), Vector2i(3,3), Vector2i(4,3),
	],
	"kecil": [
		Vector2i(1,0), Vector2i(2,0),
		Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1),
		Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2),
		Vector2i(1,3), Vector2i(2,3),
	],
}


static func get_shape(name_: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in SHAPES.get(name_, SHAPES["bulat"]):
		out.append(c)
	return out


static func random_shape(rng: RandomNumberGenerator) -> Array[Vector2i]:
	var keys := SHAPES.keys()
	return get_shape(keys[rng.randi() % keys.size()])


## Pot shapes vary, but a big order must not land in a small pot.
##
## `required_area` is the cells a full-dose recipe needs; we only consider
## pots with real slack on top of that, so the player always has room to
## manoeuvre rather than being forced into the single perfect packing.
## Falls back to the largest pot when nothing is comfortable — better a
## tight board than an impossible one.
static func shape_for(required_area: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	const SLACK := 3

	var fits: Array[String] = []
	var largest := ""
	var largest_size := -1

	for name_ in SHAPES.keys():
		var size: int = (SHAPES[name_] as Array).size()
		if size > largest_size:
			largest_size = size
			largest = name_
		if size >= required_area + SLACK:
			fits.append(name_)

	if fits.is_empty():
		return get_shape(largest)
	return get_shape(fits[rng.randi() % fits.size()])


## Residue count grows with the day but always leaves slack.
static func residue_budget(shape_size: int, day: int, required_area: int) -> int:
	var ratio := clampf(0.0 + (day - 1) * 0.035, 0.0, 0.28)
	var wanted := int(shape_size * ratio)
	var ceiling := shape_size - required_area - 2
	return maxi(mini(wanted, ceiling), 0)


## Picks residue cells, then proves the remaining space is still fillable.
## Retries with fewer cells rather than shipping an unsolvable board.
static func generate_residue(shape: Array[Vector2i], count: int,
		shapes_to_fit: Array, rng: RandomNumberGenerator) -> Array[Vector2i]:
	if count <= 0:
		return []

	for attempt in range(12):
		var picked := _pick_scattered(shape, count, rng)
		if _is_solvable(shape, picked, shapes_to_fit):
			return picked

	# Could not verify — ship a clean board instead of a broken one.
	return []


## Prefer non-adjacent cells: scattered residue is more interesting than
## one solid blob, and less likely to strand a corner.
static func _pick_scattered(shape: Array[Vector2i], count: int,
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	var pool := shape.duplicate()
	_shuffle(pool, rng)

	var picked: Array[Vector2i] = []
	for c in pool:
		if picked.size() >= count:
			break
		var touches := false
		for p in picked:
			if absi(p.x - c.x) <= 1 and absi(p.y - c.y) <= 1:
				touches = true
				break
		if not touches:
			picked.append(c)

	# Relax the spacing rule if we could not place enough.
	if picked.size() < count:
		for c in pool:
			if picked.size() >= count:
				break
			if not picked.has(c):
				picked.append(c)

	return picked


## Backtracking fill check. Grids here are ~20 cells, so this is cheap.
static func _is_solvable(shape: Array[Vector2i], residue: Array[Vector2i],
		shapes_to_fit: Array) -> bool:
	var free: Dictionary = {}
	for c in shape:
		free[c] = true
	for c in residue:
		free.erase(c)

	var total_area := 0
	for cells in shapes_to_fit:
		total_area += (cells as Array).size()

	# The required ingredients must at least fit by area.
	if total_area > free.size():
		return false

	return _try_fit(free, shapes_to_fit, 0)


static func _try_fit(free: Dictionary, shapes: Array, index: int) -> bool:
	if index >= shapes.size():
		return true

	var cells: Array = shapes[index]

	# Try all 4 rotations at every anchor position.
	var variants: Array = []
	var typed: Array[Vector2i] = []
	for c in cells:
		typed.append(c)

	var current := typed
	for r in range(4):
		var key := _cells_key(current)
		var seen := false
		for v in variants:
			if _cells_key(v) == key:
				seen = true
				break
		if not seen:
			variants.append(current.duplicate())
		current = GridLogic.rotate_cw(current)

	for variant in variants:
		for anchor in free.keys():
			var origin: Vector2i = anchor - variant[0]
			var fits := true
			for c in variant:
				if not free.has(origin + c):
					fits = false
					break
			if not fits:
				continue

			for c in variant:
				free.erase(origin + c)
			if _try_fit(free, shapes, index + 1):
				return true
			for c in variant:
				free[origin + c] = true

	return false


static func _cells_key(cells: Array[Vector2i]) -> String:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y)
	var s := ""
	for c in sorted:
		s += "%d,%d;" % [c.x, c.y]
	return s


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
