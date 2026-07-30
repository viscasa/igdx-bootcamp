class_name Panci extends Node2D

## The simmering pot. One heat lever, several brews, each wanting a
## different temperature — the compromise is the whole mechanic.

signal brew_ready(slot: int)
signal brew_burnt(slot: int)
signal slot_clicked(slot: int)

const SLOT_W := 148
const SLOT_H := 100
const BURN_RATE := 0.55
const OFF_IDEAL_RATE := 0.35     ## progress still creeps along outside the window

@export var slot_count: int = 2

var heat: float = 0.5
var slots: Array = []            ## Brew or null


func _ready() -> void:
	_resize_slots()
	set_process(true)


func _resize_slots() -> void:
	slots.resize(slot_count)
	for i in range(slot_count):
		if i >= slots.size() or slots[i] == null:
			slots[i] = null


func set_slot_count(n: int) -> void:
	slot_count = n
	_resize_slots()
	queue_redraw()


func free_slot() -> int:
	for i in range(slot_count):
		if slots[i] == null:
			return i
	return -1


func has_space() -> bool:
	return free_slot() >= 0


func add_brew(brew: Brew) -> int:
	var i := free_slot()
	if i < 0:
		return -1
	slots[i] = brew
	queue_redraw()
	return i


func take_brew(slot: int) -> Brew:
	if slot < 0 or slot >= slots.size():
		return null
	var b: Brew = slots[slot]
	slots[slot] = null
	queue_redraw()
	return b


func active_count() -> int:
	var n := 0
	for b in slots:
		if b != null:
			n += 1
	return n


func _process(delta: float) -> void:
	var dirty := false

	for i in range(slots.size()):
		var b: Brew = slots[i]
		if b == null or b.is_burnt:
			continue

		var rate := b.cook_rate if b.is_heat_ideal(heat) else b.cook_rate * OFF_IDEAL_RATE
		b.doneness += rate * delta
		dirty = true

		var w := b.heat_window()
		if heat > w.y:
			b.burn += (heat - w.y) * BURN_RATE * delta

		if b.burn >= 1.0:
			b.is_burnt = true
			brew_burnt.emit(i)
		elif not b.is_done and b.doneness >= 1.0:
			b.is_done = true
			brew_ready.emit(i)

	if dirty:
		queue_redraw()


func slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (SLOT_W + 10), 0), Vector2(SLOT_W, SLOT_H))


func slot_at(local_pos: Vector2) -> int:
	for i in range(slot_count):
		if slot_rect(i).has_point(local_pos):
			return i
	return -1


func _gui_click(local_pos: Vector2) -> void:
	var i := slot_at(local_pos)
	if i >= 0:
		slot_clicked.emit(i)


func _draw() -> void:
	var font := ThemeDB.fallback_font

	for i in range(slot_count):
		var r := slot_rect(i)
		draw_rect(r, Color("241f1a"))
		draw_rect(r, Color("4a4038"), false, 2.0)

		var b: Brew = slots[i] if i < slots.size() else null
		if b == null:
			draw_string(font, r.position + Vector2(10, 30), "kosong",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5a5048"))
			continue

		draw_string(font, r.position + Vector2(8, 18), b.customer.display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8dcc0"))

		# Ideal-heat band drawn on the same scale as the doneness bar, so
		# the player can see at a glance whether the lever is in range.
		var bar := Rect2(r.position + Vector2(8, 30), Vector2(SLOT_W - 16, 12))
		draw_rect(bar, Color("15120f"))

		var w := b.heat_window()
		if w.x <= w.y:
			var band := Rect2(
				bar.position + Vector2(bar.size.x * w.x, 0),
				Vector2(bar.size.x * (w.y - w.x), bar.size.y))
			draw_rect(band, Color(0.35, 0.8, 0.45, 0.5))
		else:
			draw_string(font, bar.position + Vector2(2, 10), "suhu bentrok!",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e05a4f"))

		# Current heat marker
		var hx := bar.position.x + bar.size.x * heat
		draw_line(Vector2(hx, bar.position.y - 2), Vector2(hx, bar.end.y + 2),
			Color("ffd36f"), 2.0)

		# Doneness
		var dbar := Rect2(r.position + Vector2(8, 50), Vector2(SLOT_W - 16, 14))
		draw_rect(dbar, Color("15120f"))
		var fill := clampf(b.doneness, 0.0, 1.2) / 1.2
		var dcol := Color("6fa84f")
		if b.is_burnt:
			dcol = Color("4a3a30")
		elif b.doneness > 1.15:
			dcol = Color("c4903c")
		draw_rect(Rect2(dbar.position, Vector2(dbar.size.x * fill, dbar.size.y)), dcol)
		# Mark where "done" sits on the 0..1.2 scale.
		var ready_x := dbar.position.x + dbar.size.x * (1.0 / 1.2)
		draw_line(Vector2(ready_x, dbar.position.y), Vector2(ready_x, dbar.end.y),
			Color("e8dcc0"), 2.0)

		# Burn
		if b.burn > 0.0:
			var bbar := Rect2(r.position + Vector2(8, 68), Vector2(SLOT_W - 16, 7))
			draw_rect(bbar, Color("15120f"))
			draw_rect(Rect2(bbar.position, Vector2(bbar.size.x * clampf(b.burn, 0, 1), bbar.size.y)),
				Color("e05a4f"))

		var status := ""
		if b.is_burnt:
			status = "GOSONG"
		elif b.is_done:
			status = "SIAP — klik untuk sajikan"
		elif b.doneness < 0.7:
			status = "mentah"
		else:
			status = "hampir..."
		draw_string(font, r.position + Vector2(8, SLOT_H - 8), status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color("6fd48f") if b.is_done and not b.is_burnt else Color("9a8f80"))
