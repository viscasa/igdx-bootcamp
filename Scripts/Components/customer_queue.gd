class_name CustomerQueue extends Node2D

## Draws waiting customers and acts as the drop target for finished potions.
## Living in world space (not the HUD) is what lets the player drag a bottle
## onto a specific person — including the wrong one.

signal potion_delivered(order: Order, slot: int)

const CARD_W := 340
const CARD_H := 136
const GAP := 8

var orders: Array[Order] = []
var active_index: int = 0

var _hover_slot: int = -1


func card_rect(i: int) -> Rect2:
	return Rect2(Vector2(0, i * (CARD_H + GAP)), Vector2(CARD_W, CARD_H))


## Which customer sits under this global point, or -1.
func slot_at(global_pos: Vector2) -> int:
	var local := to_local(global_pos)
	for i in range(orders.size()):
		if card_rect(i).has_point(local):
			return i
	return -1


func set_hover(slot: int) -> void:
	if _hover_slot != slot:
		_hover_slot = slot
		queue_redraw()


func clear_hover() -> void:
	set_hover(-1)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(4, -10), "ANTREAN", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 14, Color("c9b892"))

	if orders.is_empty():
		draw_string(font, Vector2(4, 24), "(menunggu pelanggan…)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5a5048"))
		return

	for i in range(orders.size()):
		var o := orders[i]
		var card := card_rect(i)
		var is_active := i == active_index
		var is_hovered := i == _hover_slot

		draw_rect(card, Color("2e2519") if is_hovered else
			(Color("262119") if is_active else Color("201c17")))

		if is_hovered:
			draw_rect(card, Color("6fd48f"), false, 3.0)
		elif is_active:
			draw_rect(card, Color("ffd36f"), false, 2.0)
		else:
			draw_rect(card, Color("3a332c"), false, 1.0)

		# Portrait placeholder
		draw_rect(Rect2(card.position + Vector2(8, 8), Vector2(32, 32)), o.customer.color)

		draw_string(font, card.position + Vector2(48, 22), o.customer.display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))
		draw_string(font, card.position + Vector2(48, 38), o.customer.role,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6f60"))

		# "sedang diracik" marker
		if is_active:
			draw_string(font, card.position + Vector2(CARD_W - 74, 22), "meracik…",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffd36f"))

		# Patience
		var pb := Rect2(card.position + Vector2(8, 48), Vector2(CARD_W - 16, 8))
		draw_rect(pb, Color("15120f"))
		var ratio := o.patience_ratio()
		var pcol := Color("6fa84f")
		if ratio < 0.25:
			pcol = Color("e05a4f")
		elif ratio < 0.5:
			pcol = Color("d89b3c")
		draw_rect(Rect2(pb.position, Vector2(pb.size.x * ratio, pb.size.y)), pcol)

		# The complaint — the actual puzzle
		var ly := card.position.y + 74
		for line in _wrap(o.dialogue(), 44):
			draw_string(font, Vector2(card.position.x + 8, ly), line,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c9c0ae"))
			ly += 14

		# Symptom chips
		var sx := card.position.x + 8
		var sy := card.position.y + CARD_H - 12
		for s in o.symptoms():
			var label := Symptom.display_name(s)
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10
			draw_rect(Rect2(Vector2(sx, sy - 10), Vector2(w, 14)), Symptom.color(s))
			draw_string(font, Vector2(sx + 5, sy), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("15120f"))
			sx += w + 4


func _wrap(text: String, width: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() + 1 > width:
			out.append(line)
			line = word
		else:
			line = word if line.is_empty() else line + " " + word
	if not line.is_empty():
		out.append(line)
	return out
