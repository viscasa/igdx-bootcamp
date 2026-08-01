class_name OrderCard extends Node2D

## The complaint the kitchen is currently brewing for, with live dose
## meters that fill as ingredients go into the pot.
##
## This is the piece that lets potency replace memorisation. The player
## never has to recall "kunyit is 4 cells and he needs 5" — they place a
## piece, watch the bar move, and decide whether to add more. Knowledge of
## WHICH plant still matters; arithmetic does not.

const W := 400
const NOTCH := 11.0

var order: Order
## Symptom -> cells currently supplied by the pot.
var supplied: Dictionary = {}

var _portrait: Texture2D


func _ready() -> void:
	_portrait = load("res://icon.svg")


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, -10), "PESANAN AKTIF", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 14, Color("c9b892"))

	if order == null:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, 60)), Color("1d1a16"))
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, 60)), Color("3a332c"), false, 1.0)
		draw_string(font, Vector2(10, 34), "(belum ada pesanan — pilih di Kasir)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("5a5048"))
		return

	var h := 78.0 + order.symptoms().size() * 22.0
	var card := Rect2(Vector2.ZERO, Vector2(W, h))
	draw_rect(card, Color("221d18"))
	draw_rect(card, Color("ffd36f"), false, 2.0)

	if _portrait:
		draw_texture_rect(_portrait, Rect2(Vector2(8, 8), Vector2(36, 36)),
			false, order.customer.color)

	draw_string(font, Vector2(52, 26), order.customer.display_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))

	# Patience, repeated here so the player never has to walk back to the
	# counter just to check whether they still have time.
	var pb := Rect2(Vector2(52, 32), Vector2(W - 62, 7))
	draw_rect(pb, Color("15120f"))
	var ratio := order.patience_ratio()
	var pcol := Color("6fa84f")
	if ratio < 0.25:
		pcol = Color("e05a4f")
	elif ratio < 0.5:
		pcol = Color("d89b3c")
	draw_rect(Rect2(pb.position, Vector2(pb.size.x * ratio, pb.size.y)), pcol)

	var y := 62.0
	for s in order.symptoms():
		_draw_meter(font, s, Vector2(10, y))
		y += 22.0


func _draw_meter(font: Font, s: Symptom.Code, at: Vector2) -> void:
	var need := order.required_potency(s)
	var have := int(supplied.get(s, 0))
	var col := Symptom.color(s)
	var label := Symptom.display_name(s)

	var lw := 96.0
	draw_rect(Rect2(at + Vector2(0, -11), Vector2(lw, 15)), col)
	draw_string(font, at + Vector2(5, 0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("15120f"))

	# One notch per cell of dose required. Overdosing is allowed and simply
	# does not help — no penalty, so a generous player is never punished.
	var mx := at.x + lw + 8
	for n in range(need):
		var r := Rect2(Vector2(mx + n * (NOTCH + 3), at.y - 10), Vector2(NOTCH, 13))
		draw_rect(r, Color("15120f"))
		if n < have:
			draw_rect(r, col)
		draw_rect(r, Color("3a332c"), false, 1.0)

	var done := have >= need
	draw_string(font, Vector2(mx + need * (NOTCH + 3) + 6, at.y),
		"%d/%d" % [mini(have, need), need], HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color("6fd48f") if done else Color("9a8f80"))

	if done:
		draw_string(font, Vector2(mx + need * (NOTCH + 3) + 40, at.y), "cukup",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("6fd48f"))
