extends Node2D

## The counter. Where the player reads complaints, chooses who to brew for,
## and hands over finished jamu.
##
## Time does not stop here. Standing at the counter reading is a real cost,
## which is what stops this room from becoming a safe place to hide.

@onready var queue_view: CustomerQueue = $CustomerQueue
@onready var shelf: CarryShelf = $CarryShelf
@onready var hud: HUD = $UILayer/HUD

var _dragging: Brew = null
var _drag_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not GameState.running and not GameState.game_over:
		GameState.start_run()

	queue_view.orders = GameState.queue
	queue_view.taken = GameState.taken_orders()
	queue_view.order_selected.connect(_on_order_selected)

	shelf.brews = GameState.carried
	hud.room_hint = "TAB — ke Dapur"
	hud.help_lines = PackedStringArray([
		"Klik pelanggan: pilih siapa yang mau diracik  ·  Seret botol dari DIBAWA ke pelanggan: serahkan",
		"Jamu dinilai dari siapa yang MENERIMA, bukan siapa yang memesan — periksa nama di botol.",
	])

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


func _process(_delta: float) -> void:
	queue_view.refresh()
	hud.queue_redraw()


## Taking an order adds it to the pile. The player can hold several and
## brew for all of them from one pot.
func _on_order_selected(slot: int) -> void:
	if _dragging:
		return
	if not GameState.take_order(slot):
		return

	var o := GameState.queue[slot]
	var n := GameState.taken_orders().size()
	GameState.post("Pesanan %s diambil (%d sedang dikerjakan)."
		% [o.customer.display_name, n], Color("ffd36f"))


# ═══════════════ HANDING OVER ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_over:
		if event is InputEventKey and event.pressed:
			GameState.start_run()
			Rooms.go(Rooms.Room.KASIR)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_TAB:
			# Mark the event handled BEFORE switching: change_scene_to_file
			# frees this node, after which get_viewport() returns null.
			get_viewport().set_input_as_handled()
			Rooms.go(Rooms.Room.DAPUR)
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
	queue_view.clear_hover()

	if slot >= 0:
		GameState.deliver(b, slot)

	shelf.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if _dragging:
		Potion.draw_bottle(self, _drag_pos, _dragging, 1.1)
