class_name CustomerQueue extends Node2D

## Spatial customer line: one person is large at the counter while the rest
## recede diagonally into the room. Every visual is authored in
## customer_figure.tscn; this node only orders and binds those figures.

signal order_selected(slot: int)

const FIGURE_SCENE := preload("res://Scenes/Components/customer_figure.tscn")
const DISPLAY_FONT := preload("res://Assets/Fonts/kelmscott/KELMSCOT.TTF")
const BODY_FONT := preload("res://Assets/Fonts/kelmscottroman/KelmscottRomanNF.ttf")
const FIGURE_SIZE := Vector2(220, 290)
const FRONT_POS := Vector2(420, 208)
const BACK_POSITIONS: Array[Vector2] = [
	Vector2(280, 222),
	Vector2(155, 206),
	Vector2(55, 187),
]
const BACK_SCALES: Array[float] = [0.76, 0.63, 0.52]

var orders: Array[Order] = []
var taken: Array[Order] = []
var preview: Dictionary = {}
var preview_slot: int = -1
var carrying: bool = false
var focused_slot: int = 0

var _hover_slot: int = -1
var _figures: Array[CustomerFigure] = []


func card_rect(i: int) -> Rect2:
	var rank := _rank_for_slot(i)
	var scale_value: float = 1.0 if rank == 0 else BACK_SCALES[mini(rank - 1, BACK_SCALES.size() - 1)]
	var at: Vector2 = FRONT_POS if rank == 0 else BACK_POSITIONS[mini(rank - 1, BACK_POSITIONS.size() - 1)]
	return Rect2(at, FIGURE_SIZE * scale_value)


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
			var slot := slot_at(mb.position)
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

	var panel := Rect2(FRONT_POS + Vector2(250, 18), Vector2(240, 92))
	draw_rect(panel, Color(0.08, 0.055, 0.03, 0.95))
	draw_rect(panel, Color("ffd36f"), false, 2.0)

	var head := panel.position + Vector2(18, 16)
	draw_circle(head + Vector2(14, 12), 12, game_state.last_reaction_color)
	draw_rect(Rect2(head + Vector2(4, 25), Vector2(20, 28)), game_state.last_reaction_color)

	draw_string(DISPLAY_FONT, panel.position + Vector2(52, 22), game_state.last_reaction_name,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 64, 14, Color("ffd36f"))
	draw_string(BODY_FONT, panel.position + Vector2(52, 39), game_state.last_reaction_role,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 64, 10, Color("9a8f80"))
	draw_string(DISPLAY_FONT, panel.position + Vector2(16, 68), "+%d duit" % game_state.last_reaction_pay,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32, 15, Color("6fd48f"))
	draw_string(BODY_FONT, panel.position + Vector2(88, 68), game_state.last_reaction_text,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 100, 11, Color("e8dcc0"))


func _sync_figures() -> void:
	var rebuild := _figures.size() != orders.size()
	if not rebuild:
		for i in range(orders.size()):
			if _figures[i].order != orders[i]:
				rebuild = true
				break
	if not rebuild:
		return

	for figure in _figures:
		if is_instance_valid(figure):
			figure.queue_free()
	_figures.clear()

	for order in orders:
		var figure := FIGURE_SCENE.instantiate() as CustomerFigure
		add_child(figure)
		figure.order = order
		figure.chosen.connect(_choose.bind(order))
		_figures.append(figure)


func _refresh_figures() -> void:
	for i in range(_figures.size()):
		var figure := _figures[i]
		var rank := _rank_for_slot(i)
		var visual_scale: float = 1.0 if rank == 0 \
			else BACK_SCALES[mini(rank - 1, BACK_SCALES.size() - 1)]
		figure.position = FRONT_POS if rank == 0 \
			else BACK_POSITIONS[mini(rank - 1, BACK_POSITIONS.size() - 1)]
		figure.scale = Vector2.ONE * visual_scale
		figure.z_index = 20 - rank
		figure.bind(orders[i], rank == 0, orders[i] in taken,
			carrying, i == _hover_slot)


func _choose(_ignored: Order, order: Order) -> void:
	var slot := orders.find(order)
	if slot < 0:
		return
	focus(slot)
	order_selected.emit(slot)


func _rank_for_slot(slot: int) -> int:
	if slot == focused_slot:
		return 0
	var rank := 1
	for i in range(orders.size()):
		if i == focused_slot:
			continue
		if i == slot:
			return rank
		rank += 1
	return rank


func _slot_for_rank(target_rank: int) -> int:
	for i in range(orders.size()):
		if _rank_for_slot(i) == target_rank:
			return i
	return -1
