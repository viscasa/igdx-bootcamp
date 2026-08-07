extends Node2D

## The counter. Where the player reads complaints, chooses who to brew for,
## and hands over finished jamu.
##
## Time does not stop here. Standing at the counter reading is a real cost,
## which is what stops this room from becoming a safe place to hide.

@onready var queue_view: CustomerQueue = $CustomerQueue
@onready var shelf: CarryShelf = $CarryShelf
@onready var hud: HUD = $UILayer/HUD
@onready var diagnosis_board: DiagnosisBoard = $UILayer/DiagnosisBoard
@onready var serat: SeratBook = $UILayer/SeratBook

var _dragging: Brew = null
var _drag_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not GameState.running and not GameState.game_over:
		GameState.start_run()

	queue_view.orders = GameState.queue
	queue_view.taken = GameState.taken_orders()
	queue_view.order_selected.connect(_on_order_selected)
	diagnosis_board.take_requested.connect(_on_take_requested)

	shelf.brews = GameState.carried
	shelf.show_hint = true

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
	if serat.visible:
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
			var b := shelf.brew_at(get_global_mouse_position())
			if b:
				_dragging = b
				_drag_pos = get_global_mouse_position()
				shelf.dragging = b
				# Every customer advertises that they take the bottle, so the
				# player never has to guess where it can go.
				queue_view.carrying = true
				queue_view.refresh()
				get_viewport().set_input_as_handled()
		elif _dragging:
			_release()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragging:
		_drag_pos = get_global_mouse_position()
		queue_view.set_hover(queue_view.slot_at(_drag_pos))
		queue_redraw()


func _release() -> void:
	var slot := queue_view.slot_at(_drag_pos)
	var b := _dragging
	_dragging = null
	shelf.dragging = null
	queue_view.carrying = false
	queue_view.clear_hover()

	if slot >= 0:
		GameState.deliver(b, slot)
	else:
		# Dropped on nothing. Say so, rather than letting the bottle
		# silently snap back as if the click had not registered.
		GameState.post("Lepas botol tepat di atas pelanggan.",
			Color("9a8f80"))

	shelf.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if _dragging:
		Potion.draw_bottle(self, _drag_pos, _dragging, 1.1)
