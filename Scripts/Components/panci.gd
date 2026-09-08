class_name Panci extends Node2D

signal brew_ready(slot: int)
signal brew_burnt(slot: int)
signal bottle_requested(slot: int)
signal interaction_blocked(slot: int, reason: String)

const SLOT_W := 100
const SLOT_H := 132
const GAP := 8
const OVERCOOK_AT := 1.65

@export_range(1, 4, 1) var slot_count: int = 2

var heat: float = 0.5
var potions: Array = []
var _hover_slot: int = -1


func _ready() -> void:
	_resize_slots()
	for i in range(_slot_nodes().size()):
		var station := _slot_nodes()[i] as PanciSlot
		station.clicked.connect(_on_station_clicked.bind(i))
	_sync_slots()
	set_process(true)


func _slot_nodes() -> Array[Node]:
	var holder := get_node_or_null("Slots")
	return holder.get_children() if holder else []


func _resize_slots() -> void:
	var old := potions.duplicate()
	potions.clear()
	potions.resize(slot_count)
	for i in range(slot_count):
		potions[i] = old[i] if i < old.size() else null
	var slots := _slot_nodes()
	for i in range(slots.size()):
		slots[i].visible = i < slot_count


func set_slot_count(value: int) -> void:
	slot_count = clampi(value, 1, 4)
	_resize_slots()
	_sync_slots()


func slot_rect(i: int) -> Rect2:
	var slots := _slot_nodes()
	if i >= 0 and i < slots.size():
		var slot := slots[i] as PanciSlot
		return Rect2(slot.position + slot.hit_button.position, slot.hit_button.size)
	return Rect2(Vector2(i * (SLOT_W + GAP), 0), Vector2(SLOT_W, SLOT_H))


func slot_center(i: int) -> Vector2:
	var slots := _slot_nodes()
	if i >= 0 and i < slots.size():
		var slot := slots[i] as PanciSlot
		return slot.position + slot.bottle_anchor.position
	var rect := slot_rect(i)
	return Vector2(rect.get_center().x, rect.end.y - 26.0)


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
		var slots := _slot_nodes()
		if _hover_slot >= 0 and _hover_slot < slots.size():
			(slots[_hover_slot] as PanciSlot).set_hovered(false)
		_hover_slot = slot
		if _hover_slot >= 0 and _hover_slot < slots.size():
			(slots[_hover_slot] as PanciSlot).set_hovered(true)


func clear_hover() -> void:
	set_hover(-1)


func put(potion: Potion, slot: int) -> bool:
	if slot < 0 or slot >= slot_count or potions[slot] != null:
		return false
	potions[slot] = potion
	if potion.get_parent() != self:
		if potion.get_parent():
			potion.get_parent().remove_child(potion)
		add_child(potion)
	potion.position = slot_center(slot)
	potion.z_index = 1
	potion.compact = true
	potion.visible = false
	potion.queue_redraw()
	_sync_slots()
	return true


func put_anywhere(potion: Potion) -> bool:
	return put(potion, free_slot())


func take(slot: int) -> Potion:
	if slot < 0 or slot >= potions.size():
		return null
	var potion: Potion = potions[slot]
	potions[slot] = null
	if potion:
		potion.compact = false
		potion.visible = true
		potion.queue_redraw()
	_sync_slots()
	return potion


func potion_at(global_pos: Vector2) -> Potion:
	# Brews now simmer visibly as liquid in the pan. They are bottled by
	# clicking the station, never dragged out as an invisible Potion node.
	return null


func slot_of(potion: Potion) -> int:
	return potions.find(potion)


func active_count() -> int:
	var count := 0
	for potion in potions:
		if potion != null:
			count += 1
	return count


func _process(delta: float) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.get("study_open")):
		return
	var dirty := false
	for i in range(potions.size()):
		var potion: Potion = potions[i]
		if potion == null:
			continue
		var brew: Brew = potion.brew
		if brew == null or brew.is_burnt:
			continue
		brew.doneness += brew.cook_rate * cook_speed() * delta
		dirty = true
		var limit := overcook_at()
		if brew.doneness > 1.0:
			brew.burn = clampf((brew.doneness - 1.0) / (limit - 1.0), 0.0, 1.0)
		if brew.doneness >= limit:
			brew.is_burnt = true
			potion.queue_redraw()
			brew_burnt.emit(i)
		elif not brew.is_done and brew.doneness >= 1.0:
			brew.is_done = true
			potion.queue_redraw()
			brew_ready.emit(i)
		else:
			potion.queue_redraw()
	if dirty:
		_sync_slots()


func cook_speed() -> float:
	return lerpf(0.35, 2.0, heat)


func overcook_at() -> float:
	var game_state := get_node_or_null("/root/GameState")
	var bonus := 0.0
	if game_state != null:
		bonus = float(game_state.get("heat_tolerance_bonus"))
	return OVERCOOK_AT + bonus


func refresh_visuals() -> void:
	_sync_slots()


func bottle_slot(slot: int) -> Potion:
	if slot < 0 or slot >= potions.size():
		return null
	var potion: Potion = potions[slot]
	if potion == null or potion.brew == null or not potion.brew.is_ready_to_serve():
		return null
	var station := _slot_nodes()[slot] as PanciSlot
	if station.bottling:
		return null
	await station.play_bottling()
	potion = take(slot)
	station.finish_bottling()
	return potion


func _on_station_clicked(slot: int) -> void:
	if slot < 0 or slot >= potions.size() or potions[slot] == null:
		return
	var potion: Potion = potions[slot]
	if potion.brew == null or not potion.brew.is_ready_to_serve():
		(_slot_nodes()[slot] as PanciSlot).reject_click("BELUM MATANG")
		interaction_blocked.emit(slot, "belum matang")
		return
	bottle_requested.emit(slot)


func _sync_slots() -> void:
	if not is_inside_tree():
		return
	var slots := _slot_nodes()
	for i in range(slots.size()):
		var slot := slots[i] as PanciSlot
		slot.visible = i < slot_count
		if i >= slot_count:
			continue
		var potion: Potion = potions[i] if i < potions.size() else null
		if not slot.bottling:
			slot.bind(potion.brew if potion != null else null,
				heat, cook_speed(), overcook_at())
