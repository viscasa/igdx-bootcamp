extends Node2D

## The counter. Where the player reads complaints, chooses who to brew for,
## and hands over finished jamu.
##
## Time does not stop here. Standing at the counter reading is a real cost,
## which is what stops this room from becoming a safe place to hide.

@onready var queue_view: CustomerQueue = $CustomerQueue
@onready var shelf: CarryShelf = $CarryShelf
@onready var drag_bottle: Node2D = $DragBottle
@onready var drag_bottle_visual: Node2D = $DragBottle/BottleVisual
@onready var hud: HUD = $UILayer/HUD
@onready var diagnosis_board: DiagnosisBoard = $UILayer/DiagnosisBoard
@onready var serat: SeratBook = $UILayer/SeratBook

var _dragging: Brew = null
var _drag_pos: Vector2 = Vector2.ZERO
var _drag_origin: Vector2 = Vector2.ZERO
var _drag_slot: int = -1
var _drag_target_slot: int = -1
var _drag_tween: Tween = null
var _drop_animating: bool = false

const DRAG_UPRIGHT_ROTATION := -12.0
const DRAG_SCALE := 1.08
const TARGET_SCALE := 1.14


func _ready() -> void:
	if not GameState.running and not GameState.game_over:
		GameState.start_run()

	# Returning from the kitchen rebuilds this scene, but the customers never
	# left the queue. Restore them directly at their current ranks instead of
	# replaying the arrival walk from the left.
	queue_view.restore_existing_without_arrival = Rooms.previous == Rooms.Room.DAPUR
	queue_view.orders = GameState.queue
	queue_view.taken = GameState.taken_orders()
	queue_view.order_selected.connect(_on_order_selected)
	diagnosis_board.take_requested.connect(_on_take_requested)

	shelf.brews = GameState.carried
	shelf.show_hint = true
	drag_bottle.visible = false

	GameState.queue_changed.connect(_sync)
	GameState.carried_changed.connect(_sync)
	_sync()


func _exit_tree() -> void:
	if GameState.queue_changed.is_connected(_sync):
		GameState.queue_changed.disconnect(_sync)
	if GameState.carried_changed.is_connected(_sync):
		GameState.carried_changed.disconnect(_sync)


func _sync() -> void:
	queue_view.orders = GameState.queue
	queue_view.taken = GameState.taken_orders()
	shelf.brews = GameState.carried
	queue_view.refresh()
	shelf.queue_redraw()
	if diagnosis_board.order != null and not diagnosis_board.order in GameState.queue:
		diagnosis_board.set_order(null)


func _process(_delta: float) -> void:
	queue_view.refresh()
	hud.queue_redraw()
	if _dragging == null and not _drop_animating and not serat.visible:
		shelf.set_hovered_slot(shelf.slot_index_at(get_global_mouse_position()))
	else:
		shelf.set_hovered_slot(-1)


## Open the notebook for this customer. Taking only happens from the notebook
## after the player has committed at least one diagnosis.
func _on_order_selected(slot: int) -> void:
	if _dragging:
		return
	if slot < 0 or slot >= GameState.queue.size():
		return
	queue_view.focus(slot)
	diagnosis_board.set_order(GameState.queue[slot])


func _on_take_requested(order: Order) -> void:
	var slot := GameState.queue.find(order)
	if slot < 0:
		return
	if GameState.has_taken(order):
		GameState.post("Catatan diagnosis %s diperbarui." % order.customer.display_name,
			Color("ffd36f"))
		_sync()
		return
	if not GameState.take_order(slot):
		return

	var n := GameState.taken_orders().size()
	GameState.post("Pesanan %s diambil (%d sedang dikerjakan)."
		% [order.customer.display_name, n], Color("ffd36f"))
	_sync()


# ═══════════════ HANDING OVER ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if serat.visible or _drop_animating:
		return
	if GameState.game_over:
		if event is InputEventKey and event.pressed:
			GameState.start_run()
			Rooms.go(Rooms.Room.KASIR)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var index := shelf.slot_index_at(get_global_mouse_position())
			if index >= 0:
				_begin_drag(index, get_global_mouse_position())
				get_viewport().set_input_as_handled()
		elif _dragging:
			_release()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragging:
		_drag_pos = get_global_mouse_position()
		drag_bottle.global_position = _drag_pos
		_update_drag_target(queue_view.slot_at(_drag_pos))


func _begin_drag(index: int, mouse_position: Vector2) -> void:
	_drag_slot = index
	_dragging = shelf.brews[index]
	_drag_pos = mouse_position
	_drag_origin = shelf.slot_anchor_global(index)
	shelf.set_hovered_slot(-1)
	shelf.dragging = _dragging
	shelf.configure_bottle(drag_bottle, _dragging)
	drag_bottle.global_position = mouse_position
	drag_bottle.scale = Vector2.ONE * 0.94
	drag_bottle.modulate = Color.WHITE
	drag_bottle_visual.rotation = 0.0
	drag_bottle.visible = true
	_drag_target_slot = -1
	queue_view.carrying = true
	queue_view.refresh()

	_kill_drag_tween()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drag_tween.tween_property(
		drag_bottle, "scale", Vector2.ONE * DRAG_SCALE, 0.16)


func _release() -> void:
	var slot := queue_view.slot_at(_drag_pos)
	var b := _dragging
	_dragging = null
	_drop_animating = true
	queue_view.carrying = false
	queue_view.clear_hover()

	if slot >= 0:
		await _animate_delivery(slot)
		# Keep the source slot hidden until carried_changed removes the brew.
		GameState.deliver(b, slot)
		shelf.dragging = null
	else:
		await _animate_return()
		shelf.dragging = null
		GameState.post("Lepas botol tepat di atas pelanggan.",
			Color("9a8f80"))

	_reset_drag_preview()
	_drop_animating = false
	shelf.queue_redraw()


func _update_drag_target(slot: int) -> void:
	if _drag_target_slot == slot:
		return
	_drag_target_slot = slot
	queue_view.set_hover(slot)
	_kill_drag_tween()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target_rotation := deg_to_rad(DRAG_UPRIGHT_ROTATION) if slot >= 0 else 0.0
	var target_scale := TARGET_SCALE if slot >= 0 else DRAG_SCALE
	_drag_tween.tween_property(
		drag_bottle_visual, "rotation", target_rotation, 0.18)
	_drag_tween.tween_property(
		drag_bottle, "scale", Vector2.ONE * target_scale, 0.18)


func _animate_delivery(slot: int) -> void:
	_update_drag_target(slot)
	_kill_drag_tween()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_drag_tween.tween_property(
		drag_bottle, "global_position", queue_view.drop_target_global(slot), 0.24)
	_drag_tween.tween_property(drag_bottle, "scale", Vector2.ONE * 0.72, 0.24)
	_drag_tween.tween_property(drag_bottle, "modulate:a", 0.0, 0.18).set_delay(0.06)
	await _drag_tween.finished


func _animate_return() -> void:
	_kill_drag_tween()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drag_tween.tween_property(drag_bottle, "global_position", _drag_origin, 0.32)
	_drag_tween.tween_property(drag_bottle, "scale", Vector2.ONE, 0.32)
	_drag_tween.tween_property(drag_bottle_visual, "rotation", 0.0, 0.24)
	await _drag_tween.finished


func _reset_drag_preview() -> void:
	_kill_drag_tween()
	drag_bottle.visible = false
	drag_bottle.modulate = Color.WHITE
	drag_bottle.scale = Vector2.ONE
	drag_bottle_visual.rotation = 0.0
	_drag_slot = -1
	_drag_target_slot = -1


func _kill_drag_tween() -> void:
	if _drag_tween != null and _drag_tween.is_valid():
		_drag_tween.kill()
	_drag_tween = null
