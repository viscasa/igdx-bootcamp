class_name CarryShelf extends Node2D

## The jamu currently in the player's hands, shown in both rooms.
## Capacity is deliberately small: carrying three keeps trips between rooms
## meaningful without turning bottle management into clutter.

const CAPACITY := 3
const SLOT_W := 104
const SLOT_H := 102
const GAP := 8
const HEADER_H := 18

var brews: Array[Brew] = []
var dragging: Brew = null
var show_hint: bool = false


func slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (SLOT_W + GAP), HEADER_H), Vector2(SLOT_W, SLOT_H))


func brew_at(global_pos: Vector2) -> Brew:
	var local := to_local(global_pos)
	for i in range(brews.size()):
		if slot_rect(i).has_point(local):
			return brews[i]
	return null


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, -10), "BOTOL JADI (%d/%d)" % [
		brews.size(), CAPACITY],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c9b892"))

	for i in range(CAPACITY):
		var slot := slot_rect(i)
		var filled := i < brews.size() and brews[i] != dragging
		draw_rect(slot, Color(0.05, 0.04, 0.03, 0.72))
		draw_rect(slot, Color("5a4030") if filled else Color("302820"),
			false, 2.0 if filled else 1.0)
		if not filled:
			draw_string(font, slot.position + Vector2(0, slot.size.y * 0.55),
				"kosong", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 10,
				Color("5a5048"))

	for i in range(brews.size()):
		var r := slot_rect(i)
		var b := brews[i]
		if b == dragging:
			continue

		Potion.draw_bottle(self, r.position + Vector2(r.size.x * 0.5, r.size.y - 30),
			b, 0.85, false, false)

		var y := r.size.y - 9.0
		draw_string(font, r.position + Vector2(0, y), b.display_name(),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9,
			Color("ffd36f") if b.heritage_name != "" else Color("c9b892"))
