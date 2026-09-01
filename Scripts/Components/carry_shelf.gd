class_name CarryShelf extends Node2D

## The jamu currently in the player's hands, shown in both rooms.
## Capacity is deliberately small: carrying three keeps trips between rooms
## meaningful without turning bottle management into clutter.

const CAPACITY := 3
const SLOT_W := 104
const SLOT_H := 102
const GAP := 8
const HEADER_H := 18

@export var artwork_layout: bool = false

var brews: Array[Brew] = []:
	set(value):
		brews = value
		_sync_artwork()
		queue_redraw()
var dragging: Brew = null:
	set(value):
		dragging = value
		_sync_artwork()
		queue_redraw()
var show_hint: bool = false

var _art_slots: Array[Node2D] = []
var _shown_brews: Array[Brew] = []


func _ready() -> void:
	_collect_art_slots()
	if artwork_layout:
		_play_entrance()
	_sync_artwork()


func slot_rect(i: int) -> Rect2:
	if artwork_layout and i >= 0 and i < _art_slots.size():
		return Rect2(_art_slots[i].position - Vector2(82.0, 104.0),
			Vector2(164.0, 208.0))
	return Rect2(Vector2(i * (SLOT_W + GAP), HEADER_H), Vector2(SLOT_W, SLOT_H))


func brew_at(global_pos: Vector2) -> Brew:
	var local := to_local(global_pos)
	for i in range(brews.size()):
		if slot_rect(i).has_point(local):
			return brews[i]
	return null


func _draw() -> void:
	if artwork_layout:
		return
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


func _collect_art_slots() -> void:
	_art_slots.clear()
	if not artwork_layout:
		return
	for i in range(CAPACITY):
		var slot := get_node_or_null("Slots/Slot%d" % i) as Node2D
		if slot != null:
			_art_slots.append(slot)


func _sync_artwork() -> void:
	if not is_node_ready() or not artwork_layout:
		return
	for i in range(_art_slots.size()):
		var slot := _art_slots[i]
		var visual := slot.get_node("BottleVisual") as Node2D
		var back_swatch := slot.get_node("BottleVisual/BrewSwatchBack") as Polygon2D
		var swatch := slot.get_node("BottleVisual/BrewSwatch") as Polygon2D
		var name_label := slot.get_node("NameLabel") as Label
		var effect_label := slot.get_node("EffectLabel") as Label
		var filled := i < brews.size() and brews[i] != dragging
		visual.modulate = Color.WHITE if filled else Color(1, 1, 1, 0.68)
		back_swatch.visible = filled
		swatch.visible = filled
		name_label.visible = filled
		effect_label.visible = filled
		if filled:
			var brew := brews[i]
			back_swatch.color = brew.color()
			swatch.color = brew.color()
			name_label.text = brew.display_name()
			effect_label.text = brew.effect_summary()
		elif i < brews.size() and brews[i] == dragging:
			visual.modulate = Color(1, 1, 1, 0.16)

		var was_filled := i < _shown_brews.size() and _shown_brews[i] != null
		if filled and not was_filled:
			slot.scale = Vector2.ONE * 0.72
			var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(slot, "scale", Vector2.ONE, 0.34)

	_shown_brews.clear()
	for i in range(_art_slots.size()):
		_shown_brews.append(brews[i] if i < brews.size() and brews[i] != dragging else null)

	var header := get_node_or_null("ShelfHeader") as Label
	if header != null:
		header.text = "JAMU SIAP  %d/%d" % [brews.size(), CAPACITY]


func _play_entrance() -> void:
	var final_position := position
	position += Vector2(0.0, 150.0)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", final_position, 0.52).set_delay(0.12)
	tween.tween_property(self, "modulate:a", 1.0, 0.28).set_delay(0.12)
