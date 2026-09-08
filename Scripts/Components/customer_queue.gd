class_name CustomerQueue extends Node2D

## Spatial customer line: one person is large at the counter while the rest
## recede into the room. customer_queue.tscn owns the visible editor slots;
## this script only binds live orders to their authored transforms.

signal order_selected(slot: int)

const FIGURE_SCENE := preload("res://Scenes/Components/customer_figure.tscn")
const DISPLAY_FONT := preload("res://Assets/Fonts/kelmscott/KELMSCOT.TTF")
const BODY_FONT := preload("res://Assets/Fonts/kelmscottroman/KelmscottRomanNF.ttf")
const FALLBACK_INTERACTION_POSITION := Vector2(35, 74)
const FALLBACK_INTERACTION_SIZE := Vector2(150, 226)
const FIGURE_FOOT_OFFSET := Vector2(110, 262)
const FALLBACK_POSITIONS: Array[Vector2] = [
	Vector2(-110, -185),
	Vector2(-134.2, -118.2),
	Vector2(-161, -86),
	Vector2(-180, -57.5),
]
const FALLBACK_SCALES: Array[float] = [1.0, 0.72, 0.6, 0.5]
const FALLBACK_ALPHAS: Array[float] = [1.0, 0.72, 0.48, 0.28]

@export_group("Queue Motion")
@export_range(0.1, 2.0, 0.05) var advance_duration: float = 0.55
@export_range(0.1, 2.0, 0.05) var exit_duration: float = 0.7

var orders: Array[Order] = []
var taken: Array[Order] = []
var preview: Dictionary = {}
var preview_slot: int = -1
var carrying: bool = false
var focused_slot: int = 0
var restore_existing_without_arrival: bool = false

var _hover_slot: int = -1
var _figures: Array[CustomerFigure] = []
var _authored_slots: Array[Node2D] = []
var _did_initial_sync: bool = false


func _ready() -> void:
	_cache_authored_slots()
	var previews := get_node_or_null("QueueSlots") as Node2D
	if previews != null:
		# The authored customers are editor guides. Live figures use the same
		# transforms, but own the actual order and interaction state.
		previews.visible = false


func card_rect(i: int) -> Rect2:
	var rect: Rect2
	if i >= 0 and i < _figures.size() and is_instance_valid(_figures[i]):
		var figure := _figures[i]
		var area := figure.interaction_area
		rect = Rect2(
			figure.position + area.position * figure.scale,
			area.size * figure.scale.abs())
	else:
		var rank := _rank_for_slot(i)
		var slot_scale := _slot_scale(rank)
		rect = Rect2(
			_slot_position(rank) + FALLBACK_INTERACTION_POSITION * slot_scale,
			FALLBACK_INTERACTION_SIZE * slot_scale)
	var bounds := _interaction_bounds_rect()
	return rect.intersection(bounds) if bounds.has_area() else rect


## Kept as an interaction-geometry alias for tests and older callers.
func button_rect(i: int) -> Rect2:
	return card_rect(i)


func slot_at(global_pos: Vector2) -> int:
	var local := to_local(global_pos)
	# Front-most person wins when silhouettes overlap.
	var ordered: Array[int] = []
	for rank in range(orders.size()):
		ordered.append(_slot_for_rank(rank))
	for slot in ordered:
		if slot >= 0 and card_rect(slot).has_point(local):
			return slot
	return -1


func button_at(global_pos: Vector2) -> int:
	return slot_at(global_pos)


func drop_target_global(slot: int) -> Vector2:
	if slot < 0 or slot >= orders.size():
		return global_position
	var card := card_rect(slot)
	# Aim at the customer's hands/upper torso rather than covering their face.
	return to_global(card.get_center() + Vector2(0.0, card.size.y * 0.22))


## Conversation/diagnosis is deliberately restricted to the person who has
## reached the counter. Bottle drop hit-testing remains separate in slot_at().
func diagnosis_slot_at(global_pos: Vector2) -> int:
	if orders.is_empty():
		return -1
	var local := to_local(global_pos)
	return 0 if card_rect(0).has_point(local) else -1


func focus(slot: int) -> void:
	if slot < 0 or slot >= orders.size():
		return
	focused_slot = slot
	refresh()


func set_hover(slot: int) -> void:
	if _hover_slot == slot:
		return
	_hover_slot = slot
	_refresh_figures()


func clear_hover() -> void:
	set_hover(-1)


func _unhandled_input(event: InputEvent) -> void:
	if carrying:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var slot := diagnosis_slot_at(mb.position)
			if slot >= 0:
				focus(slot)
				order_selected.emit(slot)
				get_viewport().set_input_as_handled()


func refresh() -> void:
	if orders.is_empty():
		focused_slot = 0
	elif focused_slot >= orders.size():
		focused_slot = 0
	_sync_figures()
	_refresh_figures()
	queue_redraw()


func _draw() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.reaction_visible():
		return

	var panel := Rect2(_slot_position(0) + Vector2(250, 18), Vector2(240, 92))
	draw_rect(panel, Color(0.08, 0.055, 0.03, 0.95))
	draw_rect(panel, Color("ffd36f"), false, 2.0)

	var head := panel.position + Vector2(18, 16)
	draw_circle(head + Vector2(14, 12), 12, game_state.last_reaction_color)
	draw_rect(Rect2(head + Vector2(4, 25), Vector2(20, 28)), game_state.last_reaction_color)

	draw_string(DISPLAY_FONT, panel.position + Vector2(52, 22), game_state.last_reaction_name,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 64, 14, Color("ffd36f"))
	draw_string(BODY_FONT, panel.position + Vector2(52, 39), game_state.last_reaction_role,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 64, 12, Color("c8b892"))
	draw_string(DISPLAY_FONT, panel.position + Vector2(16, 68), "+%d duit" % game_state.last_reaction_pay,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32, 15, Color("6fd48f"))
	draw_string(BODY_FONT, panel.position + Vector2(88, 68), game_state.last_reaction_text,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 100, 13, Color("f0dfb8"))


func _sync_figures() -> void:
	var previous := _figures.duplicate()
	var next_figures: Array[CustomerFigure] = []
	var restoring_existing := restore_existing_without_arrival and not _did_initial_sync
	for order in orders:
		var figure := _figure_for_order(previous, order)
		if figure == null:
			figure = FIGURE_SCENE.instantiate() as CustomerFigure
			add_child(figure)
			if _did_initial_sync and not restoring_existing:
				var audio := get_node_or_null("/root/WorldAudioManager")
				if audio != null:
					audio.call("play_ui", &"dialogue_expression",
						Vector2(0.96, 1.04), -5.0, 180)
			figure.order = order
			figure.set_meta("queue_rank", -1)
			if not _authored_slots.is_empty():
				var arrival_rank := next_figures.size()
				if restoring_existing:
					figure.position = _slot_position(arrival_rank)
					figure.scale = Vector2.ONE * _slot_scale(arrival_rank)
					figure.depth_alpha = _slot_alpha(arrival_rank)
					figure.set_meta("queue_rank", arrival_rank)
				else:
					figure.scale = Vector2.ONE * _slot_scale(arrival_rank)
					figure.position = _entry_position(arrival_rank)
					figure.depth_alpha = 0.0
		next_figures.append(figure)

	for old_figure in previous:
		if is_instance_valid(old_figure) and not old_figure in next_figures:
			_animate_exit(old_figure)
	_figures = next_figures
	_did_initial_sync = true


func _refresh_figures() -> void:
	for i in range(_figures.size()):
		var figure := _figures[i]
		var rank := _rank_for_slot(i)
		figure.bind(orders[i], rank == 0, orders[i] in taken,
			carrying, i == _hover_slot)
		_move_figure_to_rank(figure, rank)


func _rank_for_slot(slot: int) -> int:
	# Selection opens that customer's notes, but never teleports people in
	# the physical line. Array order is the actual queue order.
	return slot


func _slot_for_rank(target_rank: int) -> int:
	return target_rank if target_rank >= 0 and target_rank < orders.size() else -1


func _figure_for_order(figures: Array[CustomerFigure], order: Order) -> CustomerFigure:
	for figure in figures:
		if is_instance_valid(figure) and figure.order == order:
			return figure
	return null


func _move_figure_to_rank(figure: CustomerFigure, rank: int) -> void:
	var target_position := _slot_position(rank)
	var target_scale := Vector2.ONE * _slot_scale(rank)
	var target_alpha := _slot_alpha(rank)
	figure.z_index = _slot_z_index(rank)
	if int(figure.get_meta("queue_rank", -1)) == rank:
		return
	figure.set_meta("queue_rank", rank)

	if _authored_slots.is_empty():
		figure.position = target_position
		figure.scale = target_scale
		figure.depth_alpha = target_alpha
		return

	_kill_figure_tween(figure)
	var tween := figure.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(figure, "position", target_position, advance_duration)
	tween.tween_property(figure, "scale", target_scale, advance_duration)
	tween.tween_property(figure, "depth_alpha", target_alpha, advance_duration)
	figure.set_meta("queue_tween", tween)


func _animate_exit(figure: CustomerFigure) -> void:
	_kill_figure_tween(figure)
	figure.set_process(false)
	figure.diagnosis_enabled = false
	var tween := figure.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(figure, "position", _exit_position(figure), exit_duration)
	tween.tween_property(
		figure,
		"depth_alpha",
		0.0,
		exit_duration * 0.85
	).set_delay(exit_duration * 0.15)
	tween.chain().tween_callback(figure.queue_free)
	figure.set_meta("queue_tween", tween)


func _kill_figure_tween(figure: CustomerFigure) -> void:
	if not figure.has_meta("queue_tween"):
		return
	var tween := figure.get_meta("queue_tween") as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	figure.remove_meta("queue_tween")


func _cache_authored_slots() -> void:
	_authored_slots.clear()
	var slots_root := get_node_or_null("QueueSlots")
	if slots_root == null:
		return
	for slot_name in [&"FrontSlot", &"BackSlot1", &"BackSlot2", &"BackSlot3"]:
		var slot := slots_root.get_node_or_null(NodePath(slot_name)) as Node2D
		if slot != null:
			_authored_slots.append(slot)
	if _authored_slots.size() != FALLBACK_POSITIONS.size():
		_authored_slots.clear()


func _slot_position(rank: int) -> Vector2:
	_ensure_slot_cache()
	var index := mini(maxi(rank, 0), FALLBACK_POSITIONS.size() - 1)
	if not _authored_slots.is_empty():
		return _authored_slots[index].position
	return FALLBACK_POSITIONS[index]


func _slot_scale(rank: int) -> float:
	_ensure_slot_cache()
	var index := mini(maxi(rank, 0), FALLBACK_SCALES.size() - 1)
	if not _authored_slots.is_empty():
		return _authored_slots[index].scale.x
	return FALLBACK_SCALES[index]


func _slot_alpha(rank: int) -> float:
	_ensure_slot_cache()
	var index := mini(maxi(rank, 0), FALLBACK_ALPHAS.size() - 1)
	if not _authored_slots.is_empty():
		var preview := _authored_slots[index].get_node_or_null("CustomerPreview") \
			as CanvasItem
		if preview != null:
			return preview.self_modulate.a
	return FALLBACK_ALPHAS[index]


func _slot_z_index(rank: int) -> int:
	_ensure_slot_cache()
	var index := mini(maxi(rank, 0), FALLBACK_POSITIONS.size() - 1)
	if not _authored_slots.is_empty():
		return _authored_slots[index].z_index
	return FALLBACK_POSITIONS.size() - index


func _entry_position(rank: int) -> Vector2:
	var marker := get_node_or_null("QueuePath/EntryPoint") as Marker2D
	var foot_position := marker.position if marker != null else Vector2(-250, 72)
	return foot_position - FIGURE_FOOT_OFFSET * _slot_scale(rank)


func _exit_position(figure: CustomerFigure) -> Vector2:
	var marker := get_node_or_null("QueuePath/ExitPoint") as Marker2D
	var foot_position := marker.position if marker != null else Vector2(330, 77)
	return foot_position - FIGURE_FOOT_OFFSET * figure.scale.x


func _ensure_slot_cache() -> void:
	if _authored_slots.is_empty() and has_node("QueueSlots"):
		_cache_authored_slots()


func _interaction_bounds_rect() -> Rect2:
	var bounds := get_node_or_null("InteractionBounds") as Control
	return Rect2(bounds.position, bounds.size) if bounds != null else Rect2()
