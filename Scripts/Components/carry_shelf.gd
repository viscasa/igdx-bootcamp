class_name CarryShelf extends Node2D

## The jamu currently in the player's hands, shown in both rooms.
##
## Capacity is deliberately small (GameState.CARRY_LIMIT). A player who
## could carry ten bottles would brew a batch and then dump them all at
## once; carrying three forces trips between the rooms, which is what gives
## the shift its rhythm.

const SLOT_W := 108
## Tall enough for the bottle plus three lines naming what it does.
const SLOT_H := 128
const GAP := 6

var brews: Array[Brew] = []
## The bottle currently held by the cursor — hidden from the shelf so it
## does not appear in two places at once.
var dragging: Brew = null


func slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (SLOT_W + GAP), 0), Vector2(SLOT_W, SLOT_H))


func brew_at(global_pos: Vector2) -> Brew:
	var local := to_local(global_pos)
	for i in range(brews.size()):
		if slot_rect(i).has_point(local):
			return brews[i]
	return null


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, -10), "DIBAWA (%d/%d)" % [
		brews.size(), GameState.CARRY_LIMIT],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c9b892"))

	# Empty slots are left blank rather than outlined — the count in the
	# header already says how many hands are free.
	for i in range(brews.size()):
		var r := slot_rect(i)
		var b := brews[i]
		if b == dragging:
			continue

		Potion.draw_bottle(self, r.position + Vector2(r.size.x * 0.5, r.size.y - 34),
			b, 0.85, false, false)

		# What this bottle does, spelled out. This is where it matters most:
		# three bottles of similar colour in hand, and the player has to
		# pick the right one for the person in front of them.
		var y := r.size.y - 26.0
		for line in _wrap(font, b.effect_summary(), r.size.x, 9):
			draw_string(font, r.position + Vector2(0, y), line,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color("c9b892"))
			y += 10

		for line in _wrap(font, b.ingredient_summary(), r.size.x, 8):
			draw_string(font, r.position + Vector2(0, y), line,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, Color("7a6f60"))
			y += 9

		# Whose complaint this was mixed for — the reminder that makes a
		# misdelivery the player's slip rather than the game's trap.
		if b.intended_for:
			draw_string(font, r.position + Vector2(0, y),
				"→ %s" % b.intended_for.display_name, HORIZONTAL_ALIGNMENT_CENTER,
				r.size.x, 9, Color("9a8f80"))


func _wrap(font: Font, text: String, width: float, size: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in text.split(" "):
		var probe := word if line.is_empty() else line + " " + word
		if font.get_string_size(probe, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			if not line.is_empty():
				out.append(line)
			line = word
		else:
			line = probe
	if not line.is_empty():
		out.append(line)
	return out
