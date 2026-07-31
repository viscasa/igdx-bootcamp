extends Node2D

## Orchestrator: day timer, customer queue, kuali session, panci.
##
## Flow: mix in the kuali -> SPACE bottles it -> drag the bottle into the
## panci -> simmer -> drag it onto a customer. Delivery is by hand, so the
## player can hand a jamu to the wrong person.

const CELL := IngredientPiece.CELL
const BASE_PAY := 40
const MAX_QUEUE := 3
const START_REPUTATION := 5

@onready var kuali: KualiGrid = $Kuali
@onready var tray: IngredientTray = $Tray
@onready var drag: DragManager = $DragLayer
@onready var panci: Panci = $Panci
@onready var queue_view: CustomerQueue = $CustomerQueue
@onready var hud: HUD = $UILayer/HUD
@onready var heat_slider: HeatSlider = $UILayer/HeatSlider

## Where a freshly bottled jamu waits before the player moves it.
@onready var counter: Node2D = $CounterSpot
@onready var counter_pos: Vector2 = $CounterSpot.global_position

var rng := RandomNumberGenerator.new()

# ── Day ──
var day: int = 1
var day_duration: float = 300.0
var time_left: float = 300.0
var money: int = 0
var day_earnings: int = 0
var reputation: int = START_REPUTATION
var game_over: bool = false

# ── Orders ──
var queue: Array[Order] = []
var active_index: int = 0
var spawn_timer: float = 0.0

# Timer slows while reading — we punish slow hands, not slow thinking.
const READING_TIME_SCALE := 0.2
var is_reading: bool = false

var _last_feedback: String = ""
var _feedback_timer: float = 0.0
var _feedback_color: Color = Color.WHITE


func _ready() -> void:
	rng.randomize()

	drag.tray = tray
	drag.kuali = kuali
	drag.panci = panci
	drag.queue_view = queue_view
	tray.kuali = kuali
	heat_slider.panci = panci
	hud.game = self
	queue_view.orders = queue

	panci.brew_ready.connect(_on_brew_ready)
	panci.brew_burnt.connect(_on_brew_burnt)
	drag.potion_dropped_on_customer.connect(_on_potion_delivered)
	drag.potion_dropped_outside.connect(_on_potion_parked)

	_start_day(1)


# ═══════════════ DAY ═══════════════

func _start_day(n: int) -> void:
	day = n
	day_duration = 300.0
	time_left = day_duration
	day_earnings = 0
	queue.clear()
	active_index = 0
	spawn_timer = 0.0

	panci.set_slot_count(1 if day <= 2 else mini(1 + day / 2, 4))
	tray.set_available(IngredientDB.available_on_day(day))

	_new_kuali_session()
	_spawn_customer()
	queue_view.refresh()
	_feedback("Hari %d dimulai." % day, Color("e8dcc0"))


func _end_day() -> void:
	money += day_earnings
	_start_day(day + 1)


func _process(delta: float) -> void:
	if game_over:
		return

	is_reading = Input.is_key_pressed(KEY_TAB)
	var scale := READING_TIME_SCALE if is_reading else 1.0

	time_left -= delta * scale
	if time_left <= 0.0:
		_end_day()
		return

	for o in queue:
		o.patience_left -= delta * scale

	for i in range(queue.size() - 1, -1, -1):
		if queue[i].is_expired():
			var lost := queue[i]
			queue.remove_at(i)
			if active_index >= i:
				active_index = maxi(active_index - 1, 0)
			reputation -= 1
			_feedback("%s pergi kecewa." % lost.customer.display_name, Color("e05a4f"))
			_sync_queue_view()
			_new_kuali_session()
			if reputation <= 0:
				_game_over()
				return

	spawn_timer -= delta * scale
	if spawn_timer <= 0.0 and queue.size() < MAX_QUEUE:
		_spawn_customer()

	if _feedback_timer > 0.0:
		_feedback_timer -= delta

	queue_view.refresh()
	hud.queue_redraw()


func _game_over() -> void:
	game_over = true
	drag.set_enabled(false)
	_feedback("Kedai tutup. Reputasi habis di hari %d." % day, Color("e05a4f"))


# ═══════════════ CUSTOMERS ═══════════════

func _spawn_customer() -> void:
	if queue.size() >= MAX_QUEUE:
		return

	var c := CustomerDB.pick_random(day, rng)
	var v := c.pick_variant(day, rng)
	if v == null:
		return

	var patience_scale := clampf(1.0 - (day - 1) * 0.04, 0.6, 1.0)
	queue.append(Order.create(c, v, patience_scale))
	spawn_timer = rng.randf_range(14.0, 22.0)

	_sync_queue_view()
	if queue.size() == 1:
		active_index = 0
		_new_kuali_session()


func _sync_queue_view() -> void:
	queue_view.orders = queue
	queue_view.active_index = active_index
	queue_view.refresh()


func active_order() -> Order:
	if queue.is_empty():
		return null
	active_index = clampi(active_index, 0, queue.size() - 1)
	return queue[active_index]


func _cycle_active(dir: int) -> void:
	if queue.size() <= 1:
		return
	active_index = wrapi(active_index + dir, 0, queue.size())
	_sync_queue_view()
	_new_kuali_session()


# ═══════════════ KUALI ═══════════════

func _new_kuali_session() -> void:
	kuali.clear_pieces()
	tray.reset_loose()

	var order := active_order()
	var shape := KualiShape.random_shape(rng)

	var needed := _shapes_needed_for(order)
	var required_area := 0
	for s in needed:
		required_area += (s as Array).size()

	var budget := KualiShape.residue_budget(shape.size(), day, required_area)
	var residue := KualiShape.generate_residue(shape, budget, needed, rng)

	kuali.build(shape, residue)


## Rough guess at what the player needs, used only to guarantee the board
## is solvable — never to constrain their choices.
func _shapes_needed_for(order: Order) -> Array:
	var out: Array = []
	if order == null:
		return out

	var used := {}
	for s in order.symptoms():
		for ing in IngredientDB.available_on_day(day):
			if used.has(ing.ingredient_id):
				continue
			if ing.treats_symptom(s):
				out.append(ing.shape_cells.duplicate())
				used[ing.ingredient_id] = true
				break
	return out


# ═══════════════ BOTTLING ═══════════════

## SPACE: turn a full kuali into a bottle the player then carries.
func _bottle_kuali() -> void:
	if not kuali.is_full():
		_feedback("Kuali belum penuh — sisa %d petak." % kuali.empty_count(),
			Color("e05a4f"))
		return

	var order := active_order()
	var brew := Brew.create(
		kuali.placed_ingredients(),
		order.customer if order else null,
		order.symptoms() if order else [])

	var potion := Potion.new()
	potion.setup(brew)
	add_child(potion)
	_park_on_counter(potion)

	if not brew.heat_window.x <= brew.heat_window.y:
		_feedback("Jamu jadi, tapi suhunya bentrok — sulit dimatangkan!",
			Color("d89b3c"))
	else:
		_feedback("Jamu jadi! Seret ke panci untuk direbus.", Color("6fd48f"))

	_new_kuali_session()


## A potion dropped somewhere useless waits on the counter.
func _on_potion_parked(potion: Potion) -> void:
	_park_on_counter(potion)
	_feedback("Jamu ditaruh di meja.", Color("9a8f80"))


## Bottles fan out sideways so several can sit on the bench at once.
func _park_on_counter(potion: Potion) -> void:
	if potion.get_parent() != self:
		if potion.get_parent():
			potion.get_parent().remove_child(potion)
		add_child(potion)

	var others := 0
	for c in get_children():
		if c is Potion and c != potion:
			others += 1

	potion.global_position = counter_pos + Vector2((others % 3) * 30 - 30, 0)
	potion.z_index = 1


func _on_brew_ready(slot: int) -> void:
	var p: Potion = panci.potions[slot]
	if p:
		_feedback("Jamu siap — seret ke pelanggan!", Color("6fd48f"))


func _on_brew_burnt(slot: int) -> void:
	var p: Potion = panci.potions[slot]
	if p:
		_feedback("Jamu gosong!", Color("e05a4f"))


# ═══════════════ DELIVERY ═══════════════

## The heart of the change: the jamu is scored against whoever actually
## receives it, not whoever it was mixed for.
func _on_potion_delivered(potion: Potion, slot: int) -> void:
	if slot < 0 or slot >= queue.size():
		_on_potion_parked(potion)
		return

	var order := queue[slot]
	var brew := potion.brew

	if not brew.is_ready_to_serve():
		_feedback("Belum matang — rebus dulu di panci.", Color("e05a4f"))
		_on_potion_parked(potion)
		return

	var result := brew.evaluate_for(order.symptoms())
	var pay := RecipeEvaluator.payment(
		BASE_PAY, result, order.patience_ratio(),
		order.customer.pay_multiplier, brew.doneness_bonus())

	day_earnings += pay

	var mismatch := not brew.is_intended_for(order.customer)

	if result.accuracy >= 0.999 and not brew.is_burnt:
		reputation = mini(reputation + 1, 10)
	elif result.accuracy <= 0.0:
		reputation = maxi(reputation - 1, 0)

	queue.remove_at(slot)
	if active_index >= slot:
		active_index = maxi(active_index - 1, 0)
	_sync_queue_view()

	potion.queue_free()

	_report_delivery(order, result, pay, mismatch, brew.is_burnt)

	if reputation <= 0:
		_game_over()
		return

	if queue.is_empty():
		_new_kuali_session()


func _report_delivery(order: Order, result: BrewResult, pay: int,
		mismatch: bool, burnt: bool) -> void:
	var parts: Array[String] = []

	if mismatch:
		parts.append("(diracik untuk orang lain)")
	if burnt:
		parts.append("gosong")

	if not result.missed.is_empty():
		var names: Array[String] = []
		for s in result.missed:
			names.append(Symptom.display_name(s))
		parts.append("terlewat: %s" % ", ".join(names))

	var suffix := "  " + " · ".join(parts) if not parts.is_empty() else ""
	var col := Color("ffd36f") if result.accuracy >= 0.999 and not burnt \
		else (Color("e05a4f") if result.accuracy <= 0.0 else Color("e8dcc0"))

	_feedback("%s: %s — bayar %d.%s" % [
		order.customer.display_name, result.grade(), pay, suffix], col)


func _feedback(msg: String, col: Color) -> void:
	_last_feedback = msg
	_feedback_color = col
	_feedback_timer = 5.0


# ═══════════════ INPUT ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event is InputEventKey and event.pressed:
			get_tree().reload_current_scene()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				_bottle_kuali()
				get_viewport().set_input_as_handled()
			KEY_Q:
				_cycle_active(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				_cycle_active(1)
				get_viewport().set_input_as_handled()
