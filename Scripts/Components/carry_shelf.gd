class_name CarryShelf extends Node2D

## The jamu currently in the player's hands, shown in both rooms.
##
## Capacity is deliberately small (GameState.CARRY_LIMIT). A player who
## could carry ten bottles would brew a batch and then dump them all at
## once; carrying three forces trips between the rooms, which is what gives
## the shift its rhythm.

const SLOT_W := 74
const SLOT_H := 96
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

	for i in range(GameState.CARRY_LIMIT):
		var r := slot_rect(i)
		draw_rect(r, Color("1d1a16"))
		draw_rect(r, Color("3a332c"), false, 1.0)

		if i >= brews.size():
			continue

		var b := brews[i]
		if b == dragging:
			continue

		Potion.draw_bottle(self, r.position + Vector2(r.size.x * 0.5, r.size.y - 14),
			b, 0.85, false, false)

		# Whose complaint this was mixed for — the reminder that makes a
		# misdelivery the player's slip rather than the game's trap.
		if b.intended_for:
			draw_string(font, r.position + Vector2(2, r.size.y - 2),
				b.intended_for.display_name, HORIZONTAL_ALIGNMENT_CENTER,
				r.size.x - 4, 9, Color("9a8f80"))
