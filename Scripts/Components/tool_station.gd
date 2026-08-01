class_name ToolStation extends Node2D

## A physical machine on the bench. Drop an ingredient into its mouth and
## it does its work — no mode to select, no keyboard shortcut to remember.
##
## This replaces the old "press 2, then aim at a piece" flow. Aiming at an
## invisible target is a rule you have to be told; dragging a root into a
## grinding stone is a thing you can see. Ported in spirit from Waste
## Crusher's machine.gd.

signal piece_processed(out_pieces: Array, kind: ToolKit.Kind)

const W := 132
const H := 104
const MOUTH_PAD := 10

@export var kind: ToolKit.Kind = ToolKit.Kind.PIPISAN

var tools: ToolKit

var _hover: bool = false
## Brief flash after a successful use, so the machine visibly "fires".
var _flash: float = 0.0
var _reject: String = ""
var _reject_timer: float = 0.0


func _ready() -> void:
	set_process(true)


func rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(W, H))


## The drop target: where a dragged piece has to be released.
func mouth() -> Rect2:
	return Rect2(Vector2(MOUTH_PAD, 26), Vector2(W - MOUTH_PAD * 2, H - 38))


func accepts_at(global_pos: Vector2) -> bool:
	return mouth().has_point(to_local(global_pos))


func uses_left() -> int:
	return tools.remaining(kind) if tools else 0


func set_hover(v: bool) -> void:
	if _hover != v:
		_hover = v
		queue_redraw()


## Runs the machine on `piece`. Returns the resulting cell-shapes, or an
## empty array when it could not run — the caller then leaves the piece be.
func process_piece(piece: IngredientPiece) -> Array:
	if uses_left() <= 0:
		_complain("%s habis hari ini" % ToolKit.display_name(kind))
		return []

	var out: Array = []

	match kind:
		ToolKit.Kind.PIPISAN:
			out = ToolKit.cut(piece.cells)
			if out.is_empty():
				_complain("terlalu kecil untuk dibelah")
				return []
		ToolKit.Kind.TUMBUK:
			if not ToolKit.press_changes_shape(piece.cells):
				_complain("sudah padat")
				return []
			out = [ToolKit.press(piece.cells)]

	tools.consume(kind)
	_flash = 0.35
	queue_redraw()
	piece_processed.emit(out, kind)
	return out


func _complain(msg: String) -> void:
	_reject = msg
	_reject_timer = 2.0
	queue_redraw()


func _process(delta: float) -> void:
	var dirty := false
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		dirty = true
	if _reject_timer > 0.0:
		_reject_timer -= delta
		if _reject_timer <= 0.0:
			_reject = ""
		dirty = true
	if dirty:
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var left := uses_left()
	var usable := left > 0

	var name_col := Color("e8dcc0") if usable else Color("5a5048")
	if _flash > 0.0:
		name_col = Color("6fd48f")

	draw_string(font, Vector2(0, 12), ToolKit.display_name(kind),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, name_col)
	draw_string(font, Vector2(0, 24), ToolKit.hint(kind),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7a6f60"))

	# The mouth. A dashed opening reads as "put something here" without
	# needing a filled panel that art would have to replace.
	var m := mouth()
	var edge := Color("3a332c")
	if not usable:
		edge = Color("2a2520")
	elif _flash > 0.0:
		edge = Color("6fd48f")
	elif _hover:
		edge = Color("6fd48f")
	_draw_dashed(m, edge, 3.0 if (_hover and usable) else 1.5)

	if not _reject.is_empty():
		draw_string(font, Vector2(m.position.x + 4, m.position.y + m.size.y * 0.5),
			_reject, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e05a4f"))
	elif usable:
		var hint := "lepas bahan di sini" if _hover else "seret bahan ke sini"
		draw_string(font, Vector2(m.position.x, m.position.y + m.size.y * 0.5 + 4),
			hint, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, 10,
			Color("6fd48f") if _hover else Color("5a5048"))

	# Remaining uses as pips — a shrinking budget reads faster than a number.
	var py := H - 8
	if left > 0:
		for n in range(left):
			draw_rect(Rect2(Vector2(n * 10, py), Vector2(7, 6)), Color("c9b892"))
	else:
		draw_string(font, Vector2(0, py + 6), "habis",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e05a4f"))


func _draw_dashed(r: Rect2, col: Color, width: float) -> void:
	var dash := 7.0
	var gap := 5.0
	var step := dash + gap

	var x := r.position.x
	while x < r.end.x:
		var w := minf(dash, r.end.x - x)
		draw_rect(Rect2(Vector2(x, r.position.y), Vector2(w, width)), col)
		draw_rect(Rect2(Vector2(x, r.end.y - width), Vector2(w, width)), col)
		x += step

	var y := r.position.y
	while y < r.end.y:
		var h := minf(dash, r.end.y - y)
		draw_rect(Rect2(Vector2(r.position.x, y), Vector2(width, h)), col)
		draw_rect(Rect2(Vector2(r.end.x - width, y), Vector2(width, h)), col)
		y += step
