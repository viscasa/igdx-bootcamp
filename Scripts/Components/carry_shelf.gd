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

@export_group("Bottle Hover")
@export_range(0.0, 30.0, 1.0) var hover_lift: float = 12.0
@export_range(1.0, 1.25, 0.01) var hover_scale: float = 1.08
@export_range(0.05, 0.4, 0.01) var hover_duration: float = 0.16

var brews: Array[Brew] = []:
	set(value):
		brews = value
		_sync_artwork()
		queue_redraw()
var dragging: Brew = null:
	set(value):
		var previous := dragging
		if value != null:
			set_hovered_slot(-1)
		dragging = value
		if previous != null and value == null:
			_suppress_pop_once = previous
		_sync_artwork()
		queue_redraw()
var show_hint: bool = false

var _art_slots: Array[Node2D] = []
var _slot_base_positions: Array[Vector2] = []
var _shown_brews: Array[Brew] = []
var _hovered_slot: int = -1
var _suppress_pop_once: Brew = null


func _ready() -> void:
	_collect_art_slots()
	if artwork_layout:
		_play_entrance()
	_sync_artwork()


func slot_rect(i: int) -> Rect2:
	if artwork_layout and i >= 0 and i < _art_slots.size():
		return Rect2(_slot_base_positions[i] - Vector2(82.0, 104.0),
			Vector2(164.0, 208.0))
	return Rect2(Vector2(i * (SLOT_W + GAP), HEADER_H), Vector2(SLOT_W, SLOT_H))


func slot_index_at(global_pos: Vector2) -> int:
	var local := to_local(global_pos)
	for i in range(brews.size()):
		if brews[i] != dragging and slot_rect(i).has_point(local):
			return i
	return -1


func brew_at(global_pos: Vector2) -> Brew:
	var index := slot_index_at(global_pos)
	return brews[index] if index >= 0 else null


func slot_anchor_global(index: int) -> Vector2:
	if artwork_layout and index >= 0 and index < _slot_base_positions.size():
		return to_global(_slot_base_positions[index])
	return to_global(slot_rect(index).get_center())


func set_hovered_slot(index: int) -> void:
	if not artwork_layout:
		return
	if index < 0 or index >= brews.size() or brews[index] == dragging:
		index = -1
	if _hovered_slot == index:
		return
	var previous := _hovered_slot
	_hovered_slot = index
	_animate_slot_hover(previous, false)
	_animate_slot_hover(_hovered_slot, true)


## Gives any bottle.tscn instance the same brew presentation as the shelf.
## Kasir uses this for its authored DragBottle preview.
func configure_bottle(bottle: Node2D, brew: Brew,
		show_labels: bool = false) -> void:
	if bottle == null or brew == null:
		return
	var visual := bottle.get_node("BottleVisual") as Node2D
	var back_swatch := bottle.get_node("BottleVisual/BrewSwatchBack") as Polygon2D
	var swatch := bottle.get_node("BottleVisual/BrewSwatch") as Polygon2D
	var name_label := bottle.get_node("NameLabel") as Label
	var effect_label := bottle.get_node("EffectLabel") as Label
	visual.modulate = Color.WHITE
	back_swatch.visible = true
	swatch.visible = true
	back_swatch.color = brew.color()
	swatch.color = brew.color()
	name_label.visible = show_labels
	effect_label.visible = show_labels
	name_label.text = brew.display_name()
	effect_label.text = brew.effect_summary()


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
	_slot_base_positions.clear()
	if not artwork_layout:
		return
	for i in range(CAPACITY):
		var slot := get_node_or_null("Slots/Slot%d" % i) as Node2D
		if slot != null:
			_art_slots.append(slot)
			_slot_base_positions.append(slot.position)


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
			configure_bottle(slot, brew, true)
		elif i < brews.size() and brews[i] == dragging:
			visual.modulate = Color(1, 1, 1, 0.16)

		var was_filled := i < _shown_brews.size() and _shown_brews[i] != null
		if filled and not was_filled and brews[i] != _suppress_pop_once:
			slot.scale = Vector2.ONE * 0.72
			var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(slot, "scale", Vector2.ONE, 0.34)

	_shown_brews.clear()
	for i in range(_art_slots.size()):
		_shown_brews.append(brews[i] if i < brews.size() and brews[i] != dragging else null)
	_suppress_pop_once = null

	var header := get_node_or_null("ShelfHeader") as Label
	if header != null:
		header.text = "JAMU SIAP  %d/%d" % [brews.size(), CAPACITY]


func _animate_slot_hover(index: int, hovered: bool) -> void:
	if index < 0 or index >= _art_slots.size():
		return
	var slot := _art_slots[index]
	var old_tween: Tween = slot.get_meta("hover_tween") as Tween \
		if slot.has_meta("hover_tween") else null
	if old_tween != null and old_tween.is_valid():
		old_tween.kill()
	var target_position := _slot_base_positions[index] \
		+ (Vector2.UP * hover_lift if hovered else Vector2.ZERO)
	var target_scale := Vector2.ONE * (hover_scale if hovered else 1.0)
	var tween := slot.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT if hovered else Tween.EASE_IN_OUT)
	tween.tween_property(slot, "position", target_position, hover_duration)
	tween.tween_property(slot, "scale", target_scale, hover_duration)
	slot.set_meta("hover_tween", tween)


func _play_entrance() -> void:
	var final_position := position
	position += Vector2(0.0, 150.0)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", final_position, 0.52).set_delay(0.12)
	tween.tween_property(self, "modulate:a", 1.0, 0.28).set_delay(0.12)
