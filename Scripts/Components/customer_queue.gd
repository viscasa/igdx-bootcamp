class_name CustomerQueue extends Node2D

## The queue at the counter. Draws each waiting customer as a card and acts
## as the drop target for finished jamu.
##
## Living in world space (not the HUD) is what lets the player drop a bottle
## onto a specific person — including the wrong one.

signal order_selected(slot: int)

const CARD_W := 380
const CARD_H := 158
const GAP := 10
const PORTRAIT := 44

var orders: Array[Order] = []
var active_index: int = 0

## Live potency the pot currently supplies, so the player can see how close
## the current mix is to each complaint. Symptom -> supplied cells.
var preview: Dictionary = {}
var preview_slot: int = -1

var _hover_slot: int = -1
var _portrait: Texture2D


func _ready() -> void:
	# The Godot icon stands in for a character portrait in the prototype.
	# Tinted per customer below so the queue still reads at a glance.
	_portrait = load("res://icon.svg")


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var slot := slot_at(get_global_mouse_position())
			if slot >= 0:
				order_selected.emit(slot)
				get_viewport().set_input_as_handled()


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(4, -10), "ANTREAN", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 14, Color("c9b892"))

	if orders.is_empty():
		draw_string(font, Vector2(4, 24), "(menunggu pelanggan…)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5a5048"))
		return

	for i in range(orders.size()):
		_draw_card(font, i)


func _draw_card(font: Font, i: int) -> void:
	var o := orders[i]
	var card := card_rect(i)
	var is_active := i == active_index
	var is_hovered := i == _hover_slot

	# No panels or frames — art will replace this wholesale, so selection
	# state rides on the portrait and the text instead of on chrome that
	# would only have to be torn out later.
	var prect := Rect2(card.position + Vector2(8, 8), Vector2(PORTRAIT, PORTRAIT))
	if _portrait:
		var tint := o.customer.color
		if is_hovered:
			tint = Color("6fd48f")
		elif not is_active:
			tint = tint.darkened(0.45)
		draw_texture_rect(_portrait, prect, false, tint)

	var tx := card.position.x + PORTRAIT + 16
	draw_string(font, Vector2(tx, card.position.y + 22), o.customer.display_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("e8dcc0") if is_active or is_hovered else Color("9a8f80"))
	draw_string(font, Vector2(tx, card.position.y + 38), o.customer.role,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6f60"))

	if is_hovered:
		draw_string(font, card.position + Vector2(CARD_W - 84, 22), "serahkan?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6fd48f"))
	elif is_active:
		draw_string(font, card.position + Vector2(CARD_W - 74, 22), "meracik…",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e8dcc0"))

	# Patience
	var pb := Rect2(card.position + Vector2(8, PORTRAIT + 14), Vector2(CARD_W - 16, 8))
	draw_rect(pb, Color("15120f"))
	var ratio := o.patience_ratio()
	var pcol := Color("6fa84f")
	if ratio < 0.25:
		pcol = Color("e05a4f")
	elif ratio < 0.5:
		pcol = Color("d89b3c")
	draw_rect(Rect2(pb.position, Vector2(pb.size.x * ratio, pb.size.y)), pcol)

	# The complaint — the actual puzzle
	var ly := card.position.y + PORTRAIT + 38
	for line in _wrap(o.dialogue(), 52):
		draw_string(font, Vector2(card.position.x + 8, ly), line,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c9c0ae"))
		ly += 14

	_draw_demand(font, o, i, Vector2(card.position.x + 8, ly + 4))


## Each symptom as a labelled potency meter. This is what replaces recipe
## memorisation: the player reads how much is still needed instead of
## recalling a fixed list.
func _draw_demand(font: Font, o: Order, slot: int, at: Vector2) -> void:
	var show_live := slot == preview_slot
	var x := at.x
	var y := at.y

	for s in o.symptoms():
		var need := o.required_potency(s)
		var have := int(preview.get(s, 0)) if show_live else 0
		var label := Symptom.display_name(s)
		var col := Symptom.color(s)

		# Symptom colour rides on the text itself rather than a filled chip.
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 6
		draw_string(font, Vector2(x, y), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

		# Dose meter: one notch per cell of potency required. These carry
		# real information, so they stay — just without frames.
		var mx := x + lw + 5
		var notch := 9.0
		for n in range(need):
			var nr := Rect2(Vector2(mx + n * (notch + 2), y - 8), Vector2(notch, 9))
			var filled := show_live and n < have
			draw_rect(nr, col if filled else Color(col, 0.22))

		var meter_w := need * (notch + 2)
		if show_live:
			var txt := "%d/%d" % [mini(have, need), need]
			var done := have >= need
			draw_string(font, Vector2(mx + meter_w + 4, y), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
				Color("6fd48f") if done else Color("9a8f80"))
			x = mx + meter_w + 34
		else:
			x = mx + meter_w + 8

		# Wrap to a second row when the card runs out of width.
		if x > CARD_W - 90:
			x = at.x
			y += 18


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
