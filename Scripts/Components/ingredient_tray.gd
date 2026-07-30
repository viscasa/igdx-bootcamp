class_name IngredientTray extends Node2D

## The Serat — the player's ingredient shelf. Each ingredient is available
## in unlimited supply; picking one spawns a fresh piece so the shelf never
## empties mid-order.

signal piece_taken(piece: IngredientPiece)

const CELL := IngredientPiece.CELL
const COL_WIDTH := 132
const LABEL_H := 26
const PAD := 10

@export var columns: int = 3

var kuali: KualiGrid
var available: Array[IngredientData] = []

## Layout is computed from each shape's real height, so tall ingredients
## (brotowali 1x4) never overlap the row beneath them.
var _slots: Array[Vector2] = []
var _content_size: Vector2 = Vector2.ZERO

## Slot index -> the sample piece sitting there.
var _samples: Array[IngredientPiece] = []
## Loose pieces the player pulled out and dropped back.
var _loose: Array[IngredientPiece] = []


func set_available(list: Array[IngredientData]) -> void:
	available = list
	_rebuild()


func _rebuild() -> void:
	for p in _samples:
		if is_instance_valid(p):
			p.queue_free()
	_samples.clear()
	_clear_loose()

	_layout()

	for i in range(available.size()):
		var piece := IngredientPiece.new()
		piece.setup(available[i], -1)          # -1: sample, not yet real
		add_child(piece)
		piece.position = _slots[i]
		_samples.append(piece)

	queue_redraw()


## Row-packing that respects each shape's height.
func _layout() -> void:
	_slots.clear()

	var x := PAD
	var y := 30.0
	var col := 0
	var row_h := 0.0

	for ing in available:
		var h := GridLogic.shape_size(ing.shape_cells).y * CELL + LABEL_H

		if col >= columns:
			x = PAD
			y += row_h + PAD
			col = 0
			row_h = 0.0

		_slots.append(Vector2(x, y))
		row_h = maxf(row_h, h)
		x += COL_WIDTH
		col += 1

	_content_size = Vector2(columns * COL_WIDTH + PAD, y + row_h + PAD)


func _clear_loose() -> void:
	for p in _loose:
		if is_instance_valid(p):
			p.queue_free()
	_loose.clear()


func reset_loose() -> void:
	_clear_loose()


## Returns a draggable piece for whatever sits under `pos`.
## Sample pieces are cloned so the shelf stays stocked.
func piece_at(pos: Vector2) -> IngredientPiece:
	for p in _loose:
		if is_instance_valid(p) and _hits(p, pos):
			return p

	for i in range(_samples.size()):
		var s := _samples[i]
		if is_instance_valid(s) and _hits(s, pos):
			var clone := IngredientPiece.new()
			clone.setup(s.data, kuali.next_id())
			add_child(clone)
			clone.global_position = s.global_position
			_loose.append(clone)
			piece_taken.emit(clone)
			return clone

	return null


func _hits(piece: IngredientPiece, pos: Vector2) -> bool:
	for c in piece.cells:
		var r := Rect2(piece.global_position + Vector2(c) * CELL, Vector2.ONE * CELL)
		if r.has_point(pos):
			return true
	return false


## A piece dropped outside the pot goes back to the shelf — it just
## disappears, since the shelf is infinite.
func return_piece(piece: IngredientPiece) -> void:
	_loose.erase(piece)
	piece.queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var panel := Rect2(Vector2(-8, -8), _content_size + Vector2(8, 8))

	draw_rect(panel, Color("1d1a16"))
	draw_rect(panel, Color("4a4038"), false, 2.0)
	draw_string(font, Vector2(4, 12), "SERAT — BAHAN",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c9b892"))

	for i in range(available.size()):
		var ing := available[i]
		var base := _slots[i]
		var shape_h := GridLogic.shape_size(ing.shape_cells).y * CELL
		var label_y := base.y + shape_h + 12

		draw_string(font, Vector2(base.x, label_y), ing.display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e8dcc0"))

		# Symptom swatches double as the searchable index: players match
		# these colours against the customer's symptom chips.
		var x := base.x
		for s in ing.treats:
			draw_rect(Rect2(Vector2(x, label_y + 4), Vector2(13, 6)), Symptom.color(s))
			x += 15
