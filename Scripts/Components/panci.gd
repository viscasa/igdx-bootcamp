class_name Panci extends Node2D

## The simmering pot. One heat lever, several slots, each brew wanting a
## different temperature — the compromise is the whole mechanic.
##
## Potions are dropped in and picked back out by hand, so the pot is a
## place rather than an automatic conveyor.

signal brew_ready(slot: int)
signal brew_burnt(slot: int)

const SLOT_W := 100
const SLOT_H := 132
const GAP := 8
const BURN_RATE := 0.55
const OFF_IDEAL_RATE := 0.35     ## progress still creeps outside the window

@export var slot_count: int = 2

var heat: float = 0.5
var potions: Array = []          ## Potion or null, one per slot

var _hover_slot: int = -1


func _ready() -> void:
	_resize_slots()
	set_process(true)


func _resize_slots() -> void:
	var old := potions.duplicate()
	potions.clear()
	potions.resize(slot_count)
	for i in range(slot_count):
		potions[i] = old[i] if i < old.size() else null


func set_slot_count(n: int) -> void:
	slot_count = n
	_resize_slots()
	queue_redraw()


func slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (SLOT_W + GAP), 0), Vector2(SLOT_W, SLOT_H))


## Bottles hang below the heat bar and above the status line.
func slot_center(i: int) -> Vector2:
	var r := slot_rect(i)
	return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y - 26)


func slot_at(global_pos: Vector2) -> int:
	var local := to_local(global_pos)
	for i in range(slot_count):
		if slot_rect(i).has_point(local):
			return i
	return -1




func free_slot() -> int:
	for i in range(slot_count):
		if potions[i] == null:
			return i
	return -1


func has_space() -> bool:
	return free_slot() >= 0


func set_hover(slot: int) -> void:
	if _hover_slot != slot:
		_hover_slot = slot
		queue_redraw()


func clear_hover() -> void:
	set_hover(-1)


## Drop a potion into a specific slot. Returns false if taken/out of range.
func put(potion: Potion, slot: int) -> bool:
	if slot < 0 or slot >= slot_count or potions[slot] != null:
		return false

	potions[slot] = potion
	if potion.get_parent() != self:
		if potion.get_parent():
			potion.get_parent().remove_child(potion)
		add_child(potion)
	potion.position = slot_center(slot)
	potion.z_index = 0
	potion.compact = true       # the slot draws its own status text
	potion.queue_redraw()
	queue_redraw()
	return true


## Put into the first free slot.
func put_anywhere(potion: Potion) -> bool:
	return put(potion, free_slot())


func take(slot: int) -> Potion:
	if slot < 0 or slot >= potions.size():
		return null
	var p: Potion = potions[slot]
	potions[slot] = null
	if p:
		p.compact = false
		p.queue_redraw()
	queue_redraw()
	return p


func potion_at(global_pos: Vector2) -> Potion:
	for p in potions:
		if p != null and p.hits(global_pos):
			return p
	return null


func slot_of(potion: Potion) -> int:
	return potions.find(potion)


func active_count() -> int:
	var n := 0
	for p in potions:
		if p != null:
			n += 1
	return n


func _process(delta: float) -> void:
	var dirty := false

	for i in range(potions.size()):
		var p: Potion = potions[i]
		if p == null:
			continue
		var b: Brew = p.brew
		if b == null or b.is_burnt:
			continue

		var rate := b.cook_rate if b.is_heat_ideal(heat) else b.cook_rate * OFF_IDEAL_RATE
		b.doneness += rate * delta
		dirty = true

		if heat > b.heat_window.y:
			b.burn += (heat - b.heat_window.y) * BURN_RATE * delta

		if b.burn >= 1.0:
			b.is_burnt = true
			p.queue_redraw()
			brew_burnt.emit(i)
		elif not b.is_done and b.doneness >= 1.0:
			b.is_done = true
			p.queue_redraw()
			brew_ready.emit(i)
		else:
			p.queue_redraw()

	if dirty:
		queue_redraw()


## Effect and recipe, stacked above the slot. Wrapped by hand because the
## slot is narrow and an overflowing line would run into its neighbour.
func _draw_slot_label(font: Font, r: Rect2, b: Brew) -> void:
	var y := r.position.y - 30.0

	var effect := b.effect_summary()
	var ecol := Color("e05a4f") if b.treats().is_empty() else Color("c9b892")
	for line in _wrap(font, effect, r.size.x, 9):
		draw_string(font, Vector2(r.position.x, y), line,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, ecol)
		y += 10

	for line in _wrap(font, b.ingredient_summary(), r.size.x, 8):
		draw_string(font, Vector2(r.position.x, y), line,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, Color("7a6f60"))
		y += 9


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


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(0, -10), "PANCI", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("c9b892"))

	for i in range(slot_count):
		var r := slot_rect(i)
		var p: Potion = potions[i] if i < potions.size() else null

		# Drop target is shown with a thin underline instead of a framed
		# panel — enough to aim at, nothing to tear out later.
		if i == _hover_slot:
			draw_rect(Rect2(Vector2(r.position.x, r.end.y - 2),
				Vector2(r.size.x, 2)), Color("6fd48f"))

		if p == null:
			draw_string(font, r.position + Vector2(0, r.size.y * 0.55), "kosong",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("5a5048"))
			continue

		var b: Brew = p.brew

		# What this jamu is, written above the slot. The bottle hides its
		# own label here to avoid overlapping the heat bar, so the pot has
		# to say it — otherwise two similar-coloured brews are impossible
		# to tell apart while they simmer.
		_draw_slot_label(font, r, b)

		# Ideal-heat band, on the same scale as the heat marker. This is
		# functional readout, so it keeps its track.
		var bar := Rect2(r.position + Vector2(6, 8), Vector2(r.size.x - 12, 10))
		draw_rect(bar, Color("1d1a16"))

		if b.heat_window.x <= b.heat_window.y:
			draw_rect(Rect2(
				bar.position + Vector2(bar.size.x * b.heat_window.x, 0),
				Vector2(bar.size.x * (b.heat_window.y - b.heat_window.x), bar.size.y)),
				Color(0.35, 0.8, 0.45, 0.55))
		else:
			draw_string(font, bar.position + Vector2(1, 9), "bentrok!",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e05a4f"))

		var hx := bar.position.x + bar.size.x * heat
		draw_line(Vector2(hx, bar.position.y - 2), Vector2(hx, bar.end.y + 2),
			Color("ffd36f"), 2.0)

		# Status under the bottle
		var status := "mentah"
		var scol := Color("9a8f80")
		if b.is_burnt:
			status = "GOSONG"
			scol = Color("e05a4f")
		elif b.is_done:
			status = "SIAP"
			scol = Color("6fd48f")
		elif b.doneness >= 0.7:
			status = "hampir"
		draw_string(font, r.position + Vector2(6, r.size.y - 6), status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, scol)

		# Burn warning
		if b.burn > 0.0 and not b.is_burnt:
			var bb := Rect2(r.position + Vector2(6, r.size.y - 20), Vector2(r.size.x - 12, 5))
			draw_rect(bb, Color("15120f"))
			draw_rect(Rect2(bb.position, Vector2(bb.size.x * clampf(b.burn, 0, 1), bb.size.y)),
				Color("e05a4f"))
