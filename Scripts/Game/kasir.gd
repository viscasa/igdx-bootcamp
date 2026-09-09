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
@onready var intro_panel: IntroPanel = $UILayer/IntroPanel

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

@export_group("Bottle Drag Juice")
@export_range(0.0, 15.0, 0.5) var bottle_maximum_tilt_degrees := 7.0
@export_range(100.0, 2500.0, 50.0) var bottle_full_tilt_speed := 950.0
@export_range(0.0, 24.0, 1.0) var bottle_maximum_visual_lag := 11.0
@export_range(1.0, 30.0, 0.5) var bottle_velocity_smoothing := 12.0
@export_range(0.5, 8.0, 0.1) var bottle_tilt_spring_frequency := 3.2
@export_range(0.1, 1.5, 0.05) var bottle_tilt_damping := 0.7
@export_range(0.0, 1.0, 0.05) var bottle_target_motion_factor := 0.38

var _bottle_visual_base_position := Vector2.ZERO
var _bottle_last_pointer_position := Vector2.ZERO
var _bottle_drag_velocity := Vector2.ZERO
var _bottle_visual_lag := Vector2.ZERO
var _bottle_drag_tilt := 0.0
var _bottle_drag_tilt_velocity := 0.0


func _ready() -> void:
	_bottle_visual_base_position = drag_bottle_visual.position
	if not GameState.running and not GameState.game_over:
		GameState.start_run()
	if not intro_panel.visible:
		WorldAudioManager.play_gameplay()

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
	CursorManager.set_pointing(self, false)
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


func _process(delta: float) -> void:
	_update_bottle_drag_juice(delta)
	queue_view.refresh()
	hud.queue_redraw()
	var mouse := get_global_mouse_position()
	var world_interactive := false
	if not serat.visible and not diagnosis_board.visible and not _drop_animating:
		world_interactive = _dragging != null \
			or shelf.slot_index_at(mouse) >= 0 \
			or queue_view.diagnosis_slot_at(mouse) >= 0
	CursorManager.set_pointing(self, world_interactive)
	if _dragging == null and not _drop_animating and not serat.visible:
		shelf.set_hovered_slot(shelf.slot_index_at(mouse))
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
	WorldAudioManager.play_ui(WorldAudioManager.DIALOGUE_EXPRESSION,
		Vector2(0.96, 1.04), -2.0, 100)


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
	_reset_bottle_drag_juice(mouse_position)
	drag_bottle.visible = true
	WorldAudioManager.play_ui(WorldAudioManager.CLICK_IN,
		Vector2(0.96, 1.04), -4.0, 45)
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
		WorldAudioManager.play_ui(WorldAudioManager.CANCEL, Vector2.ONE, -3.0)
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
	if slot >= 0:
		WorldAudioManager.play_ui(WorldAudioManager.HIGHLIGHT,
			Vector2(0.98, 1.02), -5.0, 80)
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
	WorldAudioManager.play_ui(WorldAudioManager.SELL, Vector2.ONE, -2.0, 150)
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
	_reset_bottle_drag_juice(_drag_pos)
	_drag_slot = -1
	_drag_target_slot = -1


func _update_bottle_drag_juice(delta: float) -> void:
	if not drag_bottle.visible:
		return
	var safe_delta := minf(maxf(delta, 0.0001), 0.05)
	var target_velocity := Vector2.ZERO
	if _dragging != null:
		target_velocity = (_drag_pos - _bottle_last_pointer_position) / safe_delta
	_bottle_last_pointer_position = _drag_pos

	var velocity_blend := 1.0 - exp(-bottle_velocity_smoothing * safe_delta)
	_bottle_drag_velocity = _bottle_drag_velocity.lerp(
		target_velocity, velocity_blend)
	var target_factor := bottle_target_motion_factor \
		if _drag_target_slot >= 0 else 1.0
	var speed_ratio := clampf(
		_bottle_drag_velocity.x / maxf(bottle_full_tilt_speed, 1.0),
		-1.0, 1.0)
	var target_tilt := deg_to_rad(bottle_maximum_tilt_degrees) \
		* speed_ratio * target_factor
	var omega := TAU * bottle_tilt_spring_frequency
	var acceleration := omega * omega * (target_tilt - _bottle_drag_tilt) \
		- 2.0 * bottle_tilt_damping * omega * _bottle_drag_tilt_velocity
	_bottle_drag_tilt_velocity += acceleration * safe_delta
	_bottle_drag_tilt += _bottle_drag_tilt_velocity * safe_delta
	_bottle_drag_tilt = clampf(
		_bottle_drag_tilt,
		-deg_to_rad(bottle_maximum_tilt_degrees * 1.35),
		deg_to_rad(bottle_maximum_tilt_degrees * 1.35))

	var lag_target := Vector2.ZERO
	if _dragging != null and _bottle_drag_velocity.length_squared() > 0.01:
		lag_target = -_bottle_drag_velocity.normalized() * minf(
			bottle_maximum_visual_lag,
			_bottle_drag_velocity.length() / maxf(bottle_full_tilt_speed, 1.0) \
				* bottle_maximum_visual_lag) * target_factor
	var lag_blend := 1.0 - exp(-bottle_velocity_smoothing * 0.8 * safe_delta)
	_bottle_visual_lag = _bottle_visual_lag.lerp(lag_target, lag_blend)

	# Root rotation is additive to BottleVisual's authored 0/-12 degree state.
	# The fluid reads the combined global rotation and gains matching slosh.
	drag_bottle.rotation = _bottle_drag_tilt
	drag_bottle_visual.position = _bottle_visual_base_position + _bottle_visual_lag


func _reset_bottle_drag_juice(pointer_position: Vector2) -> void:
	_bottle_last_pointer_position = pointer_position
	_bottle_drag_velocity = Vector2.ZERO
	_bottle_visual_lag = Vector2.ZERO
	_bottle_drag_tilt = 0.0
	_bottle_drag_tilt_velocity = 0.0
	drag_bottle.rotation = 0.0
	drag_bottle_visual.position = _bottle_visual_base_position


func _kill_drag_tween() -> void:
	if _drag_tween != null and _drag_tween.is_valid():
		_drag_tween.kill()
	_drag_tween = null
