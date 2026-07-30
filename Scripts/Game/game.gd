extends Node2D

## Prototype orchestrator: day timer, customer queue, kuali session, panci.
## Everything is drawn with primitives — no art dependencies.

const CELL := IngredientPiece.CELL
const BASE_PAY := 40
const MAX_QUEUE := 3
const START_REPUTATION := 5

@onready var kuali: KualiGrid = $Kuali
@onready var tray: IngredientTray = $Tray
@onready var drag: DragManager = $DragLayer
@onready var panci: Panci = $Panci
@onready var hud: HUD = $UILayer/HUD
@onready var heat_slider: HeatSlider = $UILayer/HeatSlider

var rng := RandomNumberGenerator.new()

# ── Day state ──
var day: int = 1
var day_duration: float = 300.0
var time_left: float = 300.0
var money: int = 0
var day_earnings: int = 0
var reputation: int = START_REPUTATION
var game_over: bool = false

# ── Order state ──
var queue: Array[Order] = []
var active_index: int = 0        ## which order the kuali is currently mixing for
var spawn_timer: float = 0.0
var served_today: int = 0

# Timer slows while the player reads — we punish slow hands, not slow
# thinking. See Docs/01-GDD-Core.md §4.
const READING_TIME_SCALE := 0.2
var is_reading: bool = false

var _last_feedback: String = ""
var _feedback_timer: float = 0.0
var _feedback_color: Color = Color.WHITE


func _ready() -> void:
	rng.randomize()

	drag.tray = tray
	drag.kuali = kuali
	tray.kuali = kuali
	heat_slider.panci = panci
	hud.game = self

	panci.brew_ready.connect(_on_brew_ready)
	panci.brew_burnt.connect(_on_brew_burnt)

	_start_day(1)


# ═══════════════ DAY ═══════════════

func _start_day(n: int) -> void:
	day = n
	day_duration = 300.0
	time_left = day_duration
	day_earnings = 0
	served_today = 0
	queue.clear()
	active_index = 0
	spawn_timer = 0.0

	panci.set_slot_count(1 if day <= 2 else mini(1 + day / 2, 4))
	tray.set_available(IngredientDB.available_on_day(day))

	_new_kuali_session()
	_spawn_customer()
	_feedback("Hari %d dimulai." % day, Color("e8dcc0"))


func _end_day() -> void:
	money += day_earnings
	if day >= 10:
		_feedback("Hari %d selesai! Total: %d" % [day, money], Color("ffd36f"))
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

	# Customer patience
	for o in queue:
		if o.is_brewing:
			continue
		o.patience_left -= delta * scale

	for i in range(queue.size() - 1, -1, -1):
		if queue[i].is_expired() and not queue[i].is_brewing:
			var lost := queue[i]
			queue.remove_at(i)
			if active_index > i:
				active_index -= 1
			active_index = clampi(active_index, 0, maxi(queue.size() - 1, 0))
			reputation -= 1
			_feedback("%s pergi kecewa." % lost.customer.display_name, Color("e05a4f"))
			_new_kuali_session()
			if reputation <= 0:
				_game_over()
				return

	# Spawning
	spawn_timer -= delta * scale
	if spawn_timer <= 0.0 and queue.size() < MAX_QUEUE:
		_spawn_customer()

	if _feedback_timer > 0.0:
		_feedback_timer -= delta

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

	if queue.size() == 1:
		active_index = 0
		_new_kuali_session()


func active_order() -> Order:
	if queue.is_empty():
		return null
	active_index = clampi(active_index, 0, queue.size() - 1)
	return queue[active_index]


func _cycle_active(dir: int) -> void:
	if queue.size() <= 1:
		return
	active_index = wrapi(active_index + dir, 0, queue.size())
	_new_kuali_session()


# ═══════════════ KUALI SESSION ═══════════════

func _new_kuali_session() -> void:
	kuali.clear_pieces()
	tray.reset_loose()

	var order := active_order()
	var shape := KualiShape.random_shape(rng)

	# Residue must never make the order impossible, so we tell the
	# generator roughly what has to fit.
	var needed := _shapes_needed_for(order)
	var required_area := 0
	for s in needed:
		required_area += (s as Array).size()

	var budget := KualiShape.residue_budget(shape.size(), day, required_area)
	var residue := KualiShape.generate_residue(shape, budget, needed, rng)

	kuali.build(shape, residue)


## A cheap guess at what the player will need: one ingredient per symptom.
## Used only to guarantee solvability, not to constrain the player.
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


# ═══════════════ BREWING ═══════════════

func _try_send_to_panci() -> void:
	var order := active_order()
	if order == null:
		_feedback("Tidak ada pesanan.", Color("e05a4f"))
		return

	if not kuali.is_full():
		_feedback("Kuali belum penuh — sisa %d petak." % kuali.empty_count(), Color("e05a4f"))
		return

	if not panci.has_space():
		_feedback("Panci penuh!", Color("e05a4f"))
		return

	var result := RecipeEvaluator.evaluate(kuali.placed_ingredients(), order.symptoms())

	var brew := Brew.new()
	brew.result = result
	brew.customer = order.customer
	brew.order_symptoms = order.symptoms()
	brew.patience_at_brew = order.patience_ratio()

	panci.add_brew(brew)
	order.is_brewing = true

	# Move on to whoever still needs mixing.
	queue.erase(order)
	_brewing_orders.append(order)
	active_index = 0
	_new_kuali_session()

	_feedback("Masuk panci — %s (%d%% tepat)" % [
		result.grade(), int(result.accuracy * 100)], Color("6fd48f"))


var _brewing_orders: Array[Order] = []


func _on_brew_ready(_slot: int) -> void:
	_feedback("Ada jamu yang siap disajikan!", Color("6fd48f"))


func _on_brew_burnt(slot: int) -> void:
	var b: Brew = panci.slots[slot]
	if b:
		_feedback("Jamu %s gosong!" % b.customer.display_name, Color("e05a4f"))


func _serve(slot: int) -> void:
	var b: Brew = panci.slots[slot]
	if b == null:
		return
	if not b.is_done and not b.is_burnt:
		_feedback("Belum matang.", Color("e05a4f"))
		return

	panci.take_brew(slot)

	var pay := RecipeEvaluator.payment(
		BASE_PAY, b.result, b.patience_at_brew,
		b.customer.pay_multiplier, b.doneness_bonus())

	day_earnings += pay
	served_today += 1

	if b.result.accuracy >= 0.999 and not b.is_burnt:
		reputation = mini(reputation + 1, 10)

	# Remove the matching brewing order.
	for i in range(_brewing_orders.size()):
		if _brewing_orders[i].customer == b.customer:
			_brewing_orders.remove_at(i)
			break

	var missed_txt := ""
	if not b.result.missed.is_empty():
		var names: Array[String] = []
		for s in b.result.missed:
			names.append(Symptom.display_name(s))
		missed_txt = "  (terlewat: %s)" % ", ".join(names)

	_feedback("%s membayar %d.%s" % [b.customer.display_name, pay, missed_txt],
		Color("ffd36f") if b.result.accuracy >= 0.999 else Color("e8dcc0"))


func _feedback(msg: String, col: Color) -> void:
	_last_feedback = msg
	_feedback_color = col
	_feedback_timer = 4.0


# ═══════════════ INPUT ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event is InputEventKey and event.pressed:
			get_tree().reload_current_scene()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				_try_send_to_panci()
				get_viewport().set_input_as_handled()
			KEY_Q:
				_cycle_active(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				_cycle_active(1)
				get_viewport().set_input_as_handled()
			KEY_1, KEY_2, KEY_3, KEY_4:
				var slot := (event as InputEventKey).keycode - KEY_1
				if slot < panci.slot_count:
					_serve(slot)
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not drag.is_dragging():
			var local := panci.to_local(get_global_mouse_position())
			var slot := panci.slot_at(local)
			if slot >= 0:
				_serve(slot)
				get_viewport().set_input_as_handled()
