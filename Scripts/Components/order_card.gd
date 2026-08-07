class_name OrderCard extends Node2D

## Every order the player has taken, each with live dose meters showing how
## well the CURRENT pot serves it.
##
## This is the piece that lets potency replace memorisation. The player
## never has to recall "kunyit is 4 cells and he needs 5" — they place a
## piece, watch the bars move, and decide who this brew is for. Knowledge
## of WHICH plant still matters; arithmetic does not.
##
## Showing every order at once is deliberate. One pot serves whoever it
## suits, so a mix aimed at Raka may turn out to cover Ki Wanata too — and
## the player can only notice that if both are on screen while they mix.

const W := 384
const NOTCH := 11.0
const ROW_H := 20.0
## Height budget before the list would collide with the carry shelf below.
const MAX_H := 380.0

var orders: Array[Order] = []
## Symptom -> cells currently supplied by the pot.
var supplied: Dictionary = {}
var mix_cost: int = 0
var heritage_preview: String = ""

var _portrait: Texture2D
## How many orders fitted this frame, for the "N more" line.
var _drawn: int = 0


func _ready() -> void:
	_portrait = load("res://icon.svg")


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_drawn = 0

	draw_string(font, Vector2(0, -10), "TARGET DOSIS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c9b892"))

	if orders.is_empty():
		draw_string(font, Vector2(0, 22), "—  ambil pesanan di kasir",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("7a6f60"))
		return

	var y := 16.0
	_draw_pot_summary(font, y)
	y += 30.0 if heritage_preview != "" else 22.0

	# Stop before running off the bottom of the screen. Orders are drawn
	# in the order they were taken, so the oldest — the one closest to
	# walking out — is always the one you can see.
	for o in orders:
		if y + 32.0 + o.symptoms().size() * ROW_H > MAX_H:
			draw_string(font, Vector2(0, y + 12),
				"… %d pesanan lain (lihat di Kasir)" % (orders.size() - _drawn),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("7a6f60"))
			break
		y = _draw_order(font, o, y)
		y += 8.0
		_drawn += 1


func _draw_pot_summary(font: Font, y: float) -> void:
	if supplied.is_empty():
		draw_string(font, Vector2(0, y), "KUALI KOSONG",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("5a5048"))
		return

	draw_string(font, Vector2(0, y), "BIAYA  %d" % mix_cost,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffd36f"))
	if heritage_preview != "":
		draw_string(font, Vector2(85, y), "★ %s" % heritage_preview,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd36f"))


## Draws one order's header and meters. Returns the y after it.
func _draw_order(font: Font, o: Order, top: float) -> float:
	if _portrait:
		draw_texture_rect(_portrait, Rect2(Vector2(0, top - 10), Vector2(22, 22)),
			false, o.customer.color)

	# Fully served orders say so loudly — that is the cue to hit SELESAI.
	var served := _is_served(o)
	var precise := _is_precise(o)

	draw_string(font, Vector2(28, top + 6), o.customer.display_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color("6fd48f") if served else Color("e8dcc0"))

	if served:
		var verdict := "TEPAT" if precise else "CUKUP"
		draw_string(font, Vector2(W - 62, top + 6), verdict,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color("ffd36f") if precise else Color("6fd48f"))

	# Patience, repeated here so the player never has to walk back to the
	# counter just to check whether they still have time.
	var ratio := o.patience_ratio()
	var pcol := Color("6fa84f")
	if ratio < 0.25:
		pcol = Color("e05a4f")
	elif ratio < 0.5:
		pcol = Color("d89b3c")
	draw_rect(Rect2(Vector2(28, top + 12), Vector2((W - 38) * ratio, 4)), pcol)

	var y := top + 32.0
	for s in o.working_symptoms():
		_draw_meter(font, o, s, Vector2(28, y))
		y += ROW_H

	return y


func _is_served(o: Order) -> bool:
	for s in o.working_symptoms():
		if int(supplied.get(s, 0)) < o.required_potency(s):
			return false
	return true


func _is_precise(o: Order) -> bool:
	if not _is_served(o):
		return false
	for s in o.working_symptoms():
		if int(supplied.get(s, 0)) != o.required_potency(s):
			return false
	return true


func _draw_meter(font: Font, o: Order, s: Symptom.Code, at: Vector2) -> void:
	var need := o.required_potency(s)
	var have := int(supplied.get(s, 0))
	var col := Symptom.color(s)

	# Colour lives in the label text, not in a filled swatch behind it.
	var lw := 92.0
	draw_string(font, at, Symptom.display_name(s),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	# One notch per cell of dose required. Overdosing is allowed and simply
	# does not help — no penalty, so a generous player is never punished.
	var mx := at.x + lw
	for n in range(need):
		var r := Rect2(Vector2(mx + n * (NOTCH + 3), at.y - 9), Vector2(NOTCH, 11))
		draw_rect(r, col if n < have else Color(col, 0.22))

	var done := have >= need
	draw_string(font, Vector2(mx + need * (NOTCH + 3) + 6, at.y),
		"%d/%d dosis" % [have, need], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		(Color("ffd36f") if done and have == need else (
			Color("6fd48f") if done else Color("9a8f80"))))
