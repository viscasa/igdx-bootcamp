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
const OVERCOOK_AT := 1.65

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
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.get("study_open")):
		return

	var dirty := false

	for i in range(potions.size()):
		var p: Potion = potions[i]
		if p == null:
			continue
		var b: Brew = p.brew
		if b == null or b.is_burnt:
			continue

		var rate := b.cook_rate * cook_speed()
		b.doneness += rate * delta
		dirty = true

		var limit := overcook_at()
		if b.doneness > 1.0:
			b.burn = clampf((b.doneness - 1.0) / (limit - 1.0), 0.0, 1.0)

		if b.doneness >= limit:
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


func cook_speed() -> float:
	# 0.5 = medium fire = about 20 seconds. Full fire is tempting because
	# it is roughly twice as fast, but multitasking makes it risky.
	return lerpf(0.35, 2.0, heat)


func overcook_at() -> float:
	var game_state := get_node_or_null("/root/GameState")
	var bonus := 0.0
	if game_state != null:
		bonus = float(game_state.get("heat_tolerance_bonus"))
	return OVERCOOK_AT + bonus


func _draw_slot_label(font: Font, r: Rect2, b: Brew) -> void:
	var label := b.display_name()
	draw_string(font, Vector2(r.position.x, r.position.y - 9), label,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color("c9b892"))


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

		draw_rect(r, Color(0.055, 0.045, 0.035, 0.88))
		draw_rect(r, Color("3f3328"), false, 1.5)
		if i == _hover_slot:
			draw_rect(r, Color("6fd48f"), false, 3.0)

		if p == null:
			draw_string(font, r.position + Vector2(0, r.size.y * 0.55), "kosong",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("5a5048"))
			continue

		var b: Brew = p.brew
		_draw_cook_feedback(font, r, b)

		# What this jamu is, written above the slot. The bottle hides its
		# own label here to avoid overlapping the heat bar, so the pot has
		# to say it — otherwise two similar-coloured brews are impossible
		# to tell apart while they simmer.
		_draw_slot_label(font, r, b)

		# Three-stage cook track: raw, ready, then overcooked.
		var bar := Rect2(r.position + Vector2(6, 8), Vector2(r.size.x - 12, 10))
		var limit := overcook_at()
		draw_rect(bar, Color("1d1a16"))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * (1.0 / limit), bar.size.y)),
			Color("ffd36f"))
		draw_rect(Rect2(
			bar.position + Vector2(bar.size.x * (1.0 / limit), 0),
			Vector2(bar.size.x * (0.35 / limit), bar.size.y)),
			Color("6fd48f"))
		draw_rect(Rect2(
			bar.position + Vector2(bar.size.x * (1.35 / limit), 0),
			Vector2(bar.size.x * ((limit - 1.35) / limit), bar.size.y)),
			Color("e05a4f"))
		var px := bar.position.x + bar.size.x * clampf(b.doneness / limit, 0.0, 1.0)
		draw_line(Vector2(px, bar.position.y - 2), Vector2(px, bar.end.y + 2),
			Color("e8dcc0"), 2.0)

		draw_string(font, r.position + Vector2(6, 34), "api x%.1f" % cook_speed(),
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 10, Color("ffd36f"))

		var cook_bar := Rect2(r.position + Vector2(6, r.size.y - 33),
			Vector2(r.size.x - 12, 5))
		draw_rect(cook_bar, Color("15120f"))
		draw_rect(Rect2(cook_bar.position,
			Vector2(cook_bar.size.x * clampf(b.doneness, 0.0, 1.0), cook_bar.size.y)),
			Color("6fd48f") if b.is_done else Color("ffd36f"))

		# Status under the bottle.
		var status := "MENTAH"
		var scol := Color("9a8f80")
		if b.is_burnt:
			status = "OVER"
			scol = Color("e05a4f")
		elif b.is_done:
			status = "MATANG"
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


func _draw_cook_feedback(font: Font, r: Rect2, b: Brew) -> void:
	var pulse := 0.5 + sin(Time.get_ticks_msec() / 120.0) * 0.5
	if b.is_burnt:
		draw_rect(r.grow(4.0), Color(0.9, 0.1, 0.05, 0.18))
		draw_circle(r.position + Vector2(22, 54), 8.0, Color(0.05, 0.04, 0.035, 0.65))
		draw_circle(r.position + Vector2(34, 42), 5.0, Color(0.05, 0.04, 0.035, 0.55))
		draw_string(font, r.position + Vector2(0, 56), "GOSONG!",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color("e05a4f"))
	elif b.is_done:
		draw_rect(r.grow(3.0), Color(0.43, 0.83, 0.48, 0.14 + pulse * 0.16))
		draw_rect(r.grow(2.0), Color("6fd48f"), false, 2.0)
		draw_string(font, r.position + Vector2(0, 56), "MATANG!",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color("6fd48f"))
	elif b.burn > 0.55:
		draw_rect(r.grow(2.0), Color(0.9, 0.1, 0.05, 0.14 + pulse * 0.22))
		draw_string(font, r.position + Vector2(0, 56), "ANGKAT!",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("e05a4f"))
