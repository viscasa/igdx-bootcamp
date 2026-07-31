class_name CounterSpot extends Node2D

## The bench where a freshly bottled jamu lands. Purely a visual anchor so
## the player knows where to look after pressing SPACE.

const W := 92
const H := 74


func _draw() -> void:
	var r := Rect2(Vector2(-W * 0.5, -H), Vector2(W, H))
	draw_rect(r, Color("1d1a16"))
	draw_rect(r, Color("3a332c"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-W * 0.5, -H - 8), "MEJA",
		HORIZONTAL_ALIGNMENT_CENTER, W, 12, Color("6a6155"))
