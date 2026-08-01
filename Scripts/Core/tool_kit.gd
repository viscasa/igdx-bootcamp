class_name ToolKit extends RefCounted

## The acaraki's three tools, each with a limited daily allowance.
##
## The limit is the design. An unlimited cutter means the player cuts
## whenever they hesitate, and the spatial puzzle evaporates. A limited one
## turns every use into a question — "is this really the hardest fit I'll
## face today?" — which is a decision, not a chore.
##
## Allowances are per DAY, not per order, so the player must ration across
## customers instead of spending a fresh budget on every one.

enum Kind {
	PIPISAN,   ## cut a piece into two halves
	TUMBUK,    ## compact a piece into a squarer footprint
}

const NAMES := {
	Kind.PIPISAN: "Pipisan",
	Kind.TUMBUK: "Tumbuk",
}

const HINTS := {
	Kind.PIPISAN: "belah jadi dua",
	Kind.TUMBUK: "padatkan bentuk",
}

## Starting allowance per day. Deliberately tight: three cuts is enough to
## rescue a bad board, not enough to trivialise one.
const BASE_USES := {
	Kind.PIPISAN: 3,
	Kind.TUMBUK: 2,
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

## Splits a shape into two halves along its longer axis.
## Returns [] when the shape is too small to be worth cutting — a 1x1 grain
## of rice has nothing to divide.
static func cut(cells: Array[Vector2i]) -> Array:
	if cells.size() < 2:
		return []

	var size := GridLogic.shape_size(cells)
	var horizontal := size.x >= size.y
	var axis_len := size.x if horizontal else size.y
	if axis_len < 2:
		# Thin but long the other way — cut across the other axis instead.
		horizontal = not horizontal
		axis_len = size.y if not horizontal else size.x
		if axis_len < 2:
			return []

	var mid := axis_len / 2
	var a: Array[Vector2i] = []
	var b: Array[Vector2i] = []

	for c in cells:
		var coord := c.x if horizontal else c.y
		if coord < mid:
			a.append(c)
		else:
			b.append(c)

	if a.is_empty() or b.is_empty():
		return []

	return [GridLogic.normalize(a), GridLogic.normalize(b)]


## Compacts a shape toward a squarer footprint without losing cells.
## 2x3 becomes 3x2 only if that is genuinely tighter; the real work is
## pulling a sprawling shape (1x4) into a blockier one (2x2).
##
## Cell COUNT is preserved, which matters now that potency is measured in
## cells — pressing must never change how potent an ingredient is.
static func press(cells: Array[Vector2i]) -> Array[Vector2i]:
	var n := cells.size()
	if n <= 1:
		return cells.duplicate()

	# Target the squarest rectangle that can hold n cells.
	var best_w := n
	var best_score := 2147483647
	for w in range(1, n + 1):
		var h := int(ceil(float(n) / w))
		var waste := w * h - n
		# Prefer low waste first, then the squarest aspect.
		var score := waste * 100 + absi(w - h)
		if score < best_score:
			best_score = score
			best_w = w

	var out: Array[Vector2i] = []
	for i in range(n):
		out.append(Vector2i(i % best_w, i / best_w))
	return out


## True when pressing would actually change the footprint. Used to stop the
## player from burning a use on a shape that is already compact.
static func press_changes_shape(cells: Array[Vector2i]) -> bool:
	var before := GridLogic.shape_size(cells)
	var after := GridLogic.shape_size(press(cells))
	return before != after
