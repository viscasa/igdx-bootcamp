class_name ToolKit extends RefCounted

## The acaraki's tools and their daily allowance.
##
## The limit is the design. An unlimited cutter means the player cuts
## whenever they hesitate, and the spatial puzzle evaporates. A limited one
## turns every use into a question — "is this really the hardest fit I'll
## face today?" — which is a decision, not a chore.
##
## Allowances are per DAY, not per order, so the player must ration across
## customers instead of spending a fresh budget on every one.

enum Kind {
	PIPISAN,   ## split a piece along a chosen column
}

const NAMES := {
	Kind.PIPISAN: "Pipisan",
}

const HINTS := {
	Kind.PIPISAN: "belah bahan",
}

## Starting allowance per day. Deliberately tight: three cuts is enough to
## rescue a bad board, not enough to trivialise one.
const BASE_USES := {
	Kind.PIPISAN: 3,
}

var uses: Dictionary = {}
## Bonus uses granted by boons, kept separate so refill maths stays honest.
var bonus: Dictionary = {}


func _init() -> void:
	refill()


func refill() -> void:
	uses.clear()
	for k in BASE_USES:
		uses[k] = int(BASE_USES[k]) + int(bonus.get(k, 0))


func remaining(kind: Kind) -> int:
	return int(uses.get(kind, 0))


func can_use(kind: Kind) -> bool:
	return remaining(kind) > 0


func consume(kind: Kind) -> bool:
	if not can_use(kind):
		return false
	uses[kind] = remaining(kind) - 1
	return true


func grant_bonus(kind: Kind, amount: int) -> void:
	bonus[kind] = int(bonus.get(kind, 0)) + amount
	uses[kind] = remaining(kind) + amount


static func display_name(kind: Kind) -> String:
	return NAMES.get(kind, "?")


static func hint(kind: Kind) -> String:
	return HINTS.get(kind, "")


# ═══════════════ SHAPE OPERATIONS ═══════════════
# Pure functions on cell lists, so they can be tested without a scene.

## How many columns wide a shape is. The blade always falls vertically, so
## this is the only axis that matters — matching Waste Crusher's cutter,
## where the player rotates the block to choose which way it splits.
static func cut_width(cells: Array[Vector2i]) -> int:
	return GridLogic.shape_size(cells).x


## Can this shape be split at all? Anything one column wide cannot.
static func can_cut(cells: Array[Vector2i]) -> bool:
	return cut_width(cells) > 1


## Splits a shape at `col`: everything left of the column goes to the first
## piece, the rest to the second.
##
## The COLUMN is the point. Waste Crusher lets the player aim the blade by
## sliding the block under it, so cutting is a placement decision rather
## than a button that halves things. Passing the column in keeps that
## decision in the player's hands.
##
## Returns [] when the cut is impossible or would produce an empty half —
## an irregular shape can have a column with no cells in it.
static func cut_at(cells: Array[Vector2i], col: int) -> Array:
	var w := cut_width(cells)
	if w <= 1:
		return []

	var c := clampi(col, 1, w - 1)

	var a: Array[Vector2i] = []
	var b: Array[Vector2i] = []
	for cell in cells:
		if cell.x < c:
			a.append(cell)
		else:
			b.append(cell)

	if a.is_empty() or b.is_empty():
		return []

	return [GridLogic.normalize(a), GridLogic.normalize(b)]


## Convenience for tests and the solvability probe: split down the middle.
static func cut(cells: Array[Vector2i]) -> Array:
	return cut_at(cells, maxi(cut_width(cells) / 2, 1))
