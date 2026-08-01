class_name ToolStation extends Node2D

## The pipisan: a cutting machine on the bench, ported from Waste Crusher's
## Cutter.
##
## The blade sits at a FIXED x. Sliding an ingredient under it decides where
## the split lands, and a preview line shows exactly where the blade will
## fall. That is the whole mechanic: cutting is an aiming decision, not a
## button that halves things for you.
##
## Cut pieces stay ON the machine until the player drags them off, so the
## bench never spits results at you — you pick them up when you want them.

signal cut_finished

const CELL := IngredientPiece.CELL
const ZONE_W := 5          ## drop zone, in cells
const ZONE_H := 5
const RESULT_GAP := 6.0
const BLADE_DROP := 0.18
const BLADE_LIFT := 0.16

@export var kind: ToolKit.Kind = ToolKit.Kind.PIPISAN

var tools: ToolKit

## The piece currently sitting under the blade, and the halves it became.
var held: IngredientPiece = null
var results: Array[IngredientPiece] = []

var _busy: bool = false
## Column the blade will fall on, chosen by where the player aims.
var _pending_col: int = -1
## Preview state while a piece hovers over the machine.
var _preview_col: int = -1
var _preview_cells: Array[Vector2i] = []
var _preview_origin: Vector2 = Vector2.ZERO
var _blade_y: float = 0.0
var _reject: String = ""
var _reject_timer: float = 0.0


func _ready() -> void:
	set_process(true)


func uses_left() -> int:
	return tools.remaining(kind) if tools else 0


func is_empty() -> bool:
	return held == null and results.is_empty() and not _busy


## Usable only when stocked and clear of a previous cut.
func is_open() -> bool:
	return uses_left() > 0 and is_empty()


# ═══════════════ ZONE ═══════════════

## Where the blade falls, in local space. Everything aims at this line.
func blade_x() -> float:
	return 0.0


func zone() -> Rect2:
	var half := Vector2(ZONE_W, ZONE_H) * CELL * 0.5
	return Rect2(-half, half * 2.0)


func accepts_at(global_pos: Vector2) -> bool:
	return is_open() and zone().has_point(to_local(global_pos))


## True when a dragged piece's body overlaps the machine, which is how
## Waste Crusher decides you meant to use it — you do not have to hit a
## small target, you just have to be over the thing.
func overlaps(piece_global_pos: Vector2, cells: Array[Vector2i]) -> bool:
	if not is_open():
		return false
	var size := GridLogic.shape_size(cells)
	var r := Rect2(to_local(piece_global_pos), Vector2(size) * CELL)
	return zone().intersects(r)


# ═══════════════ AIMING ═══════════════

## Which column the blade lands on if the piece is released here.
##
## Derived from the gap between the blade and the piece's left edge, so
## dragging the ingredient left and right slides the cut across it.
func cut_col_for(cells: Array[Vector2i], piece_global_pos: Vector2) -> int:
	var w := ToolKit.cut_width(cells)
	if w <= 1:
		return 0
	var local_x := to_local(piece_global_pos).x
	var col := int(round((blade_x() - local_x) / float(CELL)))
	return clampi(col, 1, w - 1)


## Position the piece should snap to so the blade lines up with `col`.
func snap_position(cells: Array[Vector2i], piece_global_pos: Vector2) -> Vector2:
	var size := GridLogic.shape_size(cells)
	var col := cut_col_for(cells, piece_global_pos)
	if col <= 0:
		col = 0
	return to_global(Vector2(blade_x() - col * CELL, -size.y * CELL * 0.5))


func set_pending_col(col: int) -> void:
	_pending_col = col


func show_preview(piece: IngredientPiece) -> void:
	if not is_open():
		return
	_preview_cells = piece.cells.duplicate()
	_preview_origin = to_local(piece.global_position)
	_preview_col = cut_col_for(piece.cells, piece.global_position)
	queue_redraw()


func hide_preview() -> void:
	if _preview_col == -1 and _preview_cells.is_empty():
		return
	_preview_col = -1
	_preview_cells.clear()
	queue_redraw()


# ═══════════════ CUTTING ═══════════════

## Takes the piece, drops the blade, and leaves the halves on the machine.
func receive(piece: IngredientPiece) -> bool:
	if not is_open():
		_complain("pipisan penuh" if not is_empty() else "pipisan habis")
		return false

	var col := _pending_col if _pending_col > 0 \
		else cut_col_for(piece.cells, piece.global_position)
	_pending_col = -1

	var halves := ToolKit.cut_at(piece.cells, col)
	if halves.is_empty():
		_complain("tak bisa dibelah di situ")
		return false

	_busy = true
	held = piece
	hide_preview()

	_adopt(piece)
	var size := GridLogic.shape_size(piece.cells)
	piece.position = Vector2(blade_x() - col * CELL, -size.y * CELL * 0.5)
	piece.z_index = 1

	await _swing_blade(size.y * CELL * 0.5)

	# Lay the halves either side of the blade, still on the machine, so the
	# two pieces appear exactly where the cut happened.
	var data := piece.data

	held = null
	piece.queue_free()

	var left_cells: Array[Vector2i] = halves[0]
	var right_cells: Array[Vector2i] = halves[1]

	var a := _make_half(data, left_cells)
	var b := _make_half(data, right_cells)

	var aw := GridLogic.shape_size(left_cells).x * CELL
	var ah := GridLogic.shape_size(left_cells).y * CELL
	var bh := GridLogic.shape_size(right_cells).y * CELL

	# Each half is centred on its own height, so a tall half and a short
	# one still sit level rather than one floating above the bed.
	a.position = Vector2(blade_x() - aw - RESULT_GAP, -ah * 0.5)
	b.position = Vector2(blade_x() + RESULT_GAP, -bh * 0.5)

	results.append(a)
	results.append(b)

	tools.consume(kind)
	_busy = false
	queue_redraw()
	cut_finished.emit()
	return true


func _make_half(data: IngredientData, cells: Array[Vector2i]) -> IngredientPiece:
	var p := IngredientPiece.new()
	p.setup(data, -1)
	p.cells = cells
	p.was_cut = true
	p.z_index = 1
	add_child(p)
	return p


## Is this piece one of ours, so the drag manager can lift it back off?
func owns(piece: IngredientPiece) -> bool:
	return piece == held or piece in results


func release(piece: IngredientPiece) -> void:
	results.erase(piece)
	if held == piece:
		held = null
	queue_redraw()


## Throws away anything still sitting on the bed. Called between orders so
## offcuts never carry over to the next customer.
func clear() -> void:
	for p in results:
		if is_instance_valid(p):
			p.queue_free()
	results.clear()
	if is_instance_valid(held):
		held.queue_free()
	held = null
	_busy = false
	_pending_col = -1
	hide_preview()
	queue_redraw()


## Topmost result under this point, for picking a half back up.
func piece_at(global_pos: Vector2) -> IngredientPiece:
	for p in results:
		if not is_instance_valid(p):
			continue
		for c in p.cells:
			var r := Rect2(p.global_position + Vector2(c) * CELL,
				Vector2.ONE * CELL)
			if r.has_point(global_pos):
				return p
	return null


func _swing_blade(depth: float) -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_method(_set_blade_y, -depth - 10.0, depth, BLADE_DROP)
	await tw.finished

	var back := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	back.tween_method(_set_blade_y, depth, 0.0, BLADE_LIFT)
	await back.finished


func _set_blade_y(v: float) -> void:
	_blade_y = v
	queue_redraw()


func _adopt(node: Node) -> void:
	if node.get_parent() == self:
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)


func _complain(msg: String) -> void:
	_reject = msg
	_reject_timer = 2.0
	queue_redraw()


func _process(delta: float) -> void:
	if _reject_timer > 0.0:
		_reject_timer -= delta
		if _reject_timer <= 0.0:
			_reject = ""
			queue_redraw()


# ═══════════════ DRAW ═══════════════

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var z := zone()
	var left := uses_left()
	var usable := left > 0

	var col := Color("e8dcc0") if usable else Color("5a5048")
	draw_string(font, Vector2(z.position.x, z.position.y - 16),
		ToolKit.display_name(kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	draw_string(font, Vector2(z.position.x, z.position.y - 4),
		ToolKit.hint(kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7a6f60"))

	# Drop zone
	_draw_dashed(z, Color("3a332c") if usable else Color("2a2520"), 1.5)

	# The blade rail: a permanent vertical line so the player can see where
	# the cut will land before they even pick something up.
	var rail := Color("6a6155") if usable else Color("2e2822")
	draw_rect(Rect2(Vector2(blade_x() - 1, z.position.y), Vector2(2, z.size.y)),
		rail)

	# Blade head, animated during a cut.
	var head := Vector2(blade_x(), z.position.y + _blade_y)
	draw_rect(Rect2(head + Vector2(-9, -5), Vector2(18, 10)),
		Color("c9b892") if usable else Color("4a4038"))

	if not _preview_cells.is_empty() and _preview_col > 0:
		_draw_cut_preview()

	if not _reject.is_empty():
		draw_string(font, Vector2(z.position.x, z.end.y + 14), _reject,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e05a4f"))
	elif usable and is_empty():
		draw_string(font, Vector2(z.position.x, z.end.y + 14),
			"seret bahan ke sini", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("5a5048"))
	elif not results.is_empty():
		draw_string(font, Vector2(z.position.x, z.end.y + 14),
			"ambil potongannya", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("6fd48f"))

	# Remaining uses
	var py := z.end.y + 20
	if left > 0:
		for n in range(left):
			draw_rect(Rect2(Vector2(z.position.x + n * 10, py), Vector2(7, 6)),
				Color("c9b892"))
	else:
		draw_string(font, Vector2(z.position.x, py + 8), "habis",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e05a4f"))


## Highlights the seam the blade will open, so the aim is unmistakable.
func _draw_cut_preview() -> void:
	var size := GridLogic.shape_size(_preview_cells)
	var top := _preview_origin.y
	var h := size.y * CELL

	var x := blade_x()
	var dash := 6.0
	var y := top
	while y < top + h:
		draw_rect(Rect2(Vector2(x - 1.5, y), Vector2(3, minf(dash, top + h - y))),
			Color("6fd48f"))
		y += dash * 2.0


func _draw_dashed(r: Rect2, col: Color, width: float) -> void:
	var dash := 7.0
	var step := dash + 5.0

	var x := r.position.x
	while x < r.end.x:
		var w := minf(dash, r.end.x - x)
		draw_rect(Rect2(Vector2(x, r.position.y), Vector2(w, width)), col)
		draw_rect(Rect2(Vector2(x, r.end.y - width), Vector2(w, width)), col)
		x += step

	var y := r.position.y
	while y < r.end.y:
		var hh := minf(dash, r.end.y - y)
		draw_rect(Rect2(Vector2(r.position.x, y), Vector2(width, hh)), col)
		draw_rect(Rect2(Vector2(r.end.x - width, y), Vector2(width, hh)), col)
		y += step
