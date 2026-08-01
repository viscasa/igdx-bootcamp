extends Node

## Autoload: everything that must survive a scene change.
##
## The kitchen and the counter are two scenes, but one shift. Time, queue,
## money and the tool allowance live here so that switching rooms is a
## camera move, not a reset — and, crucially, so patience keeps draining
## while the player is elbow-deep in the pot. That pressure is the whole
## reason for having two rooms instead of one crowded screen.

signal queue_changed
signal day_started(day: int)
signal day_ended(day: int, earnings: int)
signal game_over_triggered
signal feedback_posted(text: String, color: Color)
signal carried_changed

const BASE_PAY := 40
const MAX_QUEUE := 4
const START_REPUTATION := 5
const DAY_LENGTH := 300.0
## How many finished jamu the player can hold at once. Small on purpose:
## it forces trips between rooms and keeps the queue readable.
##
## Mirrors CarryShelf.CAPACITY. The dependency points THIS way on purpose:
## the shelf must not name GameState, or merely referencing CarryShelf from
## a --script run drags this autoload into the compile unit before the
## autoloads exist. self_test guards that the two stay equal.
const CARRY_LIMIT := 3

var rng := RandomNumberGenerator.new()

# ── Shift ──
var day: int = 1
var time_left: float = DAY_LENGTH
var money: int = 0
var day_earnings: int = 0
var reputation: int = START_REPUTATION
var game_over: bool = false
var running: bool = false

# ── Orders ──
var queue: Array[Order] = []
var spawn_timer: float = 0.0

## Orders the player has taken and not yet served. Empty until they press
## AMBIL on somebody. Several may be held at once — the kitchen serves all
## of them from one pot.
var _taken: Array[Order] = []

# ── Tools ──
var tools := ToolKit.new()

## Finished jamu the player is carrying between rooms.
var carried: Array[Brew] = []

var _feedback: String = ""
var _feedback_color: Color = Color.WHITE
var _feedback_timer: float = 0.0


func _ready() -> void:
	rng.randomize()
	set_process(true)


func start_run() -> void:
	day = 0
	money = 0
	reputation = START_REPUTATION
	game_over = false
	carried.clear()
	_next_day()


func _next_day() -> void:
	day += 1
	time_left = DAY_LENGTH
	day_earnings = 0
	queue.clear()
	_taken.clear()
	spawn_timer = 0.0
	tools.refill()
	running = true

	_spawn_customer()
	queue_changed.emit()
	day_started.emit(day)
	post("Hari %d dimulai." % day, Color("e8dcc0"))


func end_day() -> void:
	money += day_earnings
	day_ended.emit(day, day_earnings)
	_next_day()


# ═══════════════ TICK ═══════════════

## Runs regardless of which room is on screen — that is the point.
func _process(delta: float) -> void:
	if game_over or not running:
		return

	time_left -= delta
	if time_left <= 0.0:
		end_day()
		return

	for o in queue:
		o.patience_left -= delta

	for i in range(queue.size() - 1, -1, -1):
		if queue[i].is_expired():
			var lost := queue[i]
			_drop_order(i)
			reputation -= 1
			post("%s pergi kecewa." % lost.customer.display_name, Color("e05a4f"))
			if reputation <= 0:
				_trigger_game_over()
				return

	spawn_timer -= delta
	if spawn_timer <= 0.0 and queue.size() < MAX_QUEUE:
		_spawn_customer()

	if _feedback_timer > 0.0:
		_feedback_timer -= delta


func _trigger_game_over() -> void:
	game_over = true
	running = false
	post("Kedai tutup. Reputasi habis di hari %d." % day, Color("e05a4f"))
	game_over_triggered.emit()


# ═══════════════ ORDERS ═══════════════

func _spawn_customer() -> void:
	if queue.size() >= MAX_QUEUE:
		return

	var c := CustomerDB.pick_random(day, rng)
	var v := c.pick_variant(day, rng)
	if v == null:
		return

	var patience_scale := clampf(1.0 - (day - 1) * 0.04, 0.6, 1.0)
	queue.append(Order.create(c, v, patience_scale, day))
	spawn_timer = rng.randf_range(14.0, 22.0)
	queue_changed.emit()


func _drop_order(i: int) -> void:
	var gone := queue[i]
	queue.remove_at(i)
	_taken.erase(gone)
	queue_changed.emit()


## Every order the player has taken and not yet served.
##
## A LIST, not one order. The pot does not belong to a customer: the
## player mixes a jamu, then decides who it suits — sometimes it suits
## two people, sometimes it accidentally suits someone they were not
## even brewing for. Locking the kitchen to a single customer would
## erase that whole layer, and it is the most interesting thing the
## hand-carried bottles make possible.
func taken_orders() -> Array[Order]:
	var out: Array[Order] = []
	for o in _taken:
		if o in queue:
			out.append(o)
	# Drop anything whose customer has already left.
	if out.size() != _taken.size():
		_taken = out.duplicate()
	return out


func has_taken_orders() -> bool:
	return not taken_orders().is_empty()


func has_taken(o: Order) -> bool:
	return o in _taken


## Take an order at the counter. Taking more just adds to the pile.
func take_order(i: int) -> bool:
	if i < 0 or i >= queue.size():
		return false
	var o := queue[i]
	if o in _taken:
		return false
	_taken.append(o)
	queue_changed.emit()
	return true


## The heaviest dose among taken orders, used to size the pot so that
## every order the player has accepted stays brewable.
func heaviest_demand() -> Dictionary:
	var out := {}
	for o in taken_orders():
		for s in o.demand:
			out[s] = maxi(int(out.get(s, 0)), int(o.demand[s]))
	return out


# ═══════════════ CARRYING ═══════════════

func can_carry() -> bool:
	return carried.size() < CARRY_LIMIT


func carry(b: Brew) -> bool:
	if not can_carry():
		post("Tanganmu penuh — antar dulu ke pelanggan.", Color("e05a4f"))
		return false
	carried.append(b)
	carried_changed.emit()
	return true


func drop_carried(b: Brew) -> void:
	carried.erase(b)
	carried_changed.emit()


# ═══════════════ DELIVERY ═══════════════

## Scored against whoever RECEIVES it, never who ordered it. Handing the
## right jamu to the wrong person is a real mistake the player can make,
## and keeping it possible is what makes the second room matter.
func deliver(b: Brew, slot: int) -> void:
	if slot < 0 or slot >= queue.size():
		return

	var order := queue[slot]

	if not b.is_ready_to_serve():
		post("Belum matang — rebus dulu di dapur.", Color("e05a4f"))
		return

	var result := b.evaluate_for(order.demand)
	var pay := RecipeEvaluator.payment(
		BASE_PAY, result, order.patience_ratio(),
		order.customer.pay_multiplier, b.doneness_bonus())

	day_earnings += pay

	if result.accuracy >= 0.999 and not b.is_burnt:
		reputation = mini(reputation + 1, 10)
	elif result.accuracy <= 0.0:
		reputation = maxi(reputation - 1, 0)

	var mismatch := not b.is_intended_for(order.customer)
	_drop_order(slot)
	drop_carried(b)

	_report(order, result, pay, mismatch, b.is_burnt)

	if reputation <= 0:
		_trigger_game_over()


func _report(order: Order, result: BrewResult, pay: int,
		mismatch: bool, burnt: bool) -> void:
	var parts: Array[String] = []

	if mismatch:
		parts.append("(diracik untuk orang lain)")
	if burnt:
		parts.append("gosong")

	# Under-dosing gets its own wording. "Kurang takaran" tells the player
	# they picked the right plant but not enough of it — a different lesson
	# from picking the wrong plant entirely.
	var weak: Array[String] = []
	var absent: Array[String] = []
	for s in result.missed:
		var label := Symptom.display_name(s)
		if result.partial.has(s) and int(result.partial[s][0]) > 0:
			weak.append("%s %d/%d" % [label, result.partial[s][0], result.partial[s][1]])
		else:
			absent.append(label)

	if not weak.is_empty():
		parts.append("kurang takaran: %s" % ", ".join(weak))
	if not absent.is_empty():
		parts.append("terlewat: %s" % ", ".join(absent))

	var suffix := "  " + " · ".join(parts) if not parts.is_empty() else ""
	var col := Color("ffd36f") if result.accuracy >= 0.999 and not burnt \
		else (Color("e05a4f") if result.accuracy <= 0.0 else Color("e8dcc0"))

	post("%s: %s — bayar %d.%s" % [
		order.customer.display_name, result.grade(), pay, suffix], col)


# ═══════════════ FEEDBACK ═══════════════

func post(msg: String, col: Color) -> void:
	_feedback = msg
	_feedback_color = col
	_feedback_timer = 5.0
	feedback_posted.emit(msg, col)


func feedback_text() -> String:
	return _feedback if _feedback_timer > 0.0 else ""


func feedback_color() -> Color:
	return _feedback_color
