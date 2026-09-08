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
signal phase_changed
signal service_reported

const BASE_PAY := 40
const MAX_QUEUE := 4
const START_REPUTATION := 5
const DAY_LENGTH := 240.0
const RUN_DAYS := 5
const CUSTOMER_PATIENCE_SCALE := 1.35
const STUDY_TIME_SCALE := 0.0
const SPAWN_INTERVAL := Vector2(20.0, 30.0)
const DAY_EVENT_NAMES := {
	1: "Hari Pertama",
	2: "Angin Muson",
	3: "Pasar Besar",
	4: "Tamu dari Penjuru",
	5: "Penilaian Kedai",
}
const DAY_EVENT_DESCRIPTIONS := {
	1: "Pelajari dasar diagnosis dan layani Raka.",
	2: "Batuk, menggigil, dan masuk angin lebih sering muncul.",
	3: "Pesta pasar membawa keluhan perut dan hilang selera.",
	4: "Empat bahan lanjutan terbuka di Serat.",
	5: "Keluhan majemuk dan pelanggan tidak sabar menguji kedaimu.",
}
const DAY_EVENT_SYMPTOMS := {
	2: [Symptom.Code.DINGIN, Symptom.Code.BATUK],
	3: [Symptom.Code.PENCERNAAN, Symptom.Code.NAFSU_MAKAN],
	4: [Symptom.Code.PIKIRAN, Symptom.Code.LUKA_DALAM, Symptom.Code.WANITA],
}
const DAY_SCHEDULE := {
	1: [[&"raka", 2], [&"ki_wanata", 0], [&"nyai_sekar", 2], [&"jayeng", 2]],
	2: [[&"raka", 0], [&"nyai_sekar", 0], [&"tuan_li", 0], [&"mbok_darmi", 1]],
	3: [[&"ki_wanata", 2], [&"dyah_pramesti", 3], [&"mbok_darmi", 2], [&"tuan_li", 2]],
	4: [[&"jayeng", 3], [&"dyah_pramesti", 0], [&"empu_gandring", 1], [&"ki_wanata", 1]],
	5: [[&"empu_gandring", 0], [&"dyah_pramesti", 4], [&"nyai_sekar", 3], [&"mbok_darmi", 2], [&"jayeng", 0]],
}
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

enum Phase { SHIFT, DAY_END, VICTORY, GAME_OVER }
var phase: Phase = Phase.SHIFT

# ── Run progression ──
var patience_bonus: float = 0.0
var base_pay_bonus: int = 0
var heat_tolerance_bonus: float = 0.0
var residue_reduction: int = 0
var discovered_recipes: Array[String] = []
var day_served: int = 0
var day_perfect: int = 0
var day_goal_bonus: int = 0
var total_served: int = 0

## Opening the Serat is learning time, not a punishment. It pauses shift
## pressure completely so players can actually learn from the reference.
var study_open: bool = false
var intro_seen: bool = false
var kitchen_tip_seen: bool = false
var diagnosis_board_position: Vector2 = Vector2.ZERO
var diagnosis_board_position_set: bool = false

# ── Orders ──
var queue: Array[Order] = []
var spawn_timer: float = 0.0
var _schedule_index: int = 0

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
var service_report: Array[String] = []
var service_report_details: Dictionary = {}
var _service_report_timer: float = 0.0
var last_reaction_name: String = ""
var last_reaction_role: String = ""
var last_reaction_text: String = ""
var last_reaction_pay: int = 0
var last_reaction_color: Color = Color.WHITE
var _reaction_timer: float = 0.0


func _ready() -> void:
	rng.randomize()
	set_process(true)


func start_run() -> void:
	day = 0
	money = 0
	reputation = START_REPUTATION
	game_over = false
	phase = Phase.SHIFT
	patience_bonus = 0.0
	base_pay_bonus = 0
	heat_tolerance_bonus = 0.0
	residue_reduction = 0
	discovered_recipes.clear()
	total_served = 0
	intro_seen = false
	kitchen_tip_seen = false
	diagnosis_board_position_set = false
	tools.bonus.clear()
	carried.clear()
	_next_day()


func _next_day() -> void:
	day += 1
	time_left = DAY_LENGTH
	day_earnings = 0
	day_served = 0
	day_perfect = 0
	day_goal_bonus = 0
	queue.clear()
	_taken.clear()
	spawn_timer = 0.0
	_schedule_index = 0
	tools.refill()
	running = true
	phase = Phase.SHIFT
	study_open = false

	_spawn_customer()
	queue_changed.emit()
	day_started.emit(day)
	phase_changed.emit()
	var unlocks := IngredientDB.unlock_names_on_day(day)
	if day > 1 and not unlocks.is_empty():
		post("Hari %d dimulai. Bahan baru di Serat: %s." %
			[day, ", ".join(unlocks)], Color("ffd36f"))
	else:
		post("Hari %d dimulai." % day, Color("e8dcc0"))


func end_day() -> void:
	if not running:
		return
	running = false
	money += day_earnings
	day_ended.emit(day, day_earnings)
	if day >= RUN_DAYS:
		phase = Phase.VICTORY
		post("Lima hari terlewati — kedai Acaraki dikenal seluruh pelabuhan!",
			Color("ffd36f"))
	else:
		phase = Phase.DAY_END
		post("Hari %d selesai. Toko persiapan buka." % day,
			Color("ffd36f"))
	phase_changed.emit()


func continue_without_upgrade() -> void:
	if phase == Phase.DAY_END:
		_next_day()


func upgrade_cost(id: StringName) -> int:
	var base_costs := {
		&"pipisan": 75,
		&"heat": 90,
		&"clean": 85,
		&"patience": 95,
		&"pay": 125,
	}
	var bumps := {
		&"pipisan": 45,
		&"heat": 55,
		&"clean": 45,
		&"patience": 50,
		&"pay": 70,
	}
	return int(base_costs.get(id, 0)) + upgrade_level(id) * int(bumps.get(id, 0))


func upgrade_level(id: StringName) -> int:
	match id:
		&"pipisan":
			return int(tools.bonus.get(ToolKit.Kind.PIPISAN, 0))
		&"patience":
			return roundi(patience_bonus / 0.12)
		&"heat":
			return roundi(heat_tolerance_bonus / 0.20)
		&"pay":
			return int(base_pay_bonus / 8)
		&"clean":
			return int(residue_reduction / 2)
	return 0


func upgrade_name(id: StringName) -> String:
	return {
		&"pipisan": "Pipisan Tajam",
		&"heat": "Tungku Stabil",
		&"clean": "Lap Kuali",
		&"patience": "Bangku Tunggu",
		&"pay": "Papan Nama",
	}.get(id, "Persiapan")


func buy_upgrade(id: StringName) -> bool:
	if phase != Phase.DAY_END:
		return false
	var cost := upgrade_cost(id)
	if cost <= 0 or money < cost:
		post("Duit belum cukup untuk persiapan itu.", Color("e05a4f"))
		return false
	money -= cost
	match id:
		&"pipisan":
			tools.grant_bonus(ToolKit.Kind.PIPISAN, 1)
		&"patience":
			patience_bonus += 0.12
		&"heat":
			heat_tolerance_bonus += 0.20
		&"pay":
			base_pay_bonus += 8
		&"clean":
			residue_reduction += 2
	post("%s dibeli. Duit tersisa %d." % [upgrade_name(id), money],
		Color("6fd48f"))
	phase_changed.emit()
	return true


# ═══════════════ TICK ═══════════════

## Runs regardless of which room is on screen — that is the point.
func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
	if _service_report_timer > 0.0:
		_service_report_timer -= delta
	if _reaction_timer > 0.0:
		_reaction_timer -= delta

	if game_over or not running:
		return
	var tick := delta * (STUDY_TIME_SCALE if study_open else 1.0)

	time_left -= tick
	if time_left <= 0.0:
		end_day()
		return

	for o in queue:
		o.patience_left -= tick

	for i in range(queue.size() - 1, -1, -1):
		if queue[i].is_expired():
			var lost := queue[i]
			_drop_order(i)
			reputation -= 1
			post("%s pergi kecewa." % lost.customer.display_name, Color("e05a4f"))
			if reputation <= 0:
				_trigger_game_over()
				return

	spawn_timer -= tick
	if _schedule_exhausted() and queue.is_empty():
		end_day()
		return
	if spawn_timer <= 0.0 and queue.size() < MAX_QUEUE:
		_spawn_customer()

func _trigger_game_over() -> void:
	game_over = true
	running = false
	phase = Phase.GAME_OVER
	post("Kedai tutup. Reputasi habis di hari %d." % day, Color("e05a4f"))
	game_over_triggered.emit()
	phase_changed.emit()


# ═══════════════ ORDERS ═══════════════

func _spawn_customer() -> void:
	if queue.size() >= MAX_QUEUE:
		return

	var c: CustomerData
	var v: RequestVariant
	var pair := _next_scheduled_request()
	if pair.is_empty():
		if DAY_SCHEDULE.has(day):
			spawn_timer = 999999.0
			return
		pair = _pick_themed_request()
	c = pair[0]
	v = pair[1]
	if v == null:
		return

	var patience_scale := clampf(
		CUSTOMER_PATIENCE_SCALE - (day - 1) * 0.04 + patience_bonus,
		0.75, 1.65)
	queue.append(Order.create(c, v, patience_scale, day))
	spawn_timer = rng.randf_range(SPAWN_INTERVAL.x, SPAWN_INTERVAL.y)
	queue_changed.emit()


func _next_scheduled_request() -> Array:
	var schedule: Array = DAY_SCHEDULE.get(day, [])
	if schedule.is_empty() or _schedule_index >= schedule.size():
		return []
	var spec: Array = schedule[_schedule_index]
	_schedule_index += 1
	var c := CustomerDB.get_by_id(spec[0])
	if c == null:
		return []
	var idx := int(spec[1])
	if idx < 0 or idx >= c.variants.size():
		return []
	var v: RequestVariant = c.variants[idx]
	if v.min_day > day:
		return []
	return [c, v]


func _schedule_exhausted() -> bool:
	var schedule: Array = DAY_SCHEDULE.get(day, [])
	return not schedule.is_empty() and _schedule_index >= schedule.size()


func _pick_themed_request() -> Array:
	var pool: Array = []
	var themes: Array = DAY_EVENT_SYMPTOMS.get(day, [])
	for customer in CustomerDB.all:
		var already_waiting := false
		for waiting in queue:
			if waiting.customer.customer_id == customer.customer_id:
				already_waiting = true
				break
		if already_waiting:
			continue
		for variant in customer.variants:
			if variant.min_day > day:
				continue
			var weight := 1
			for s in variant.symptoms:
				if s in themes:
					weight += 3
			if day >= 5 and variant.symptoms.size() >= 2:
				weight += 2
			for n in range(weight):
				pool.append([customer, variant])
	if pool.is_empty():
		var fallback := CustomerDB.pick_random(day, rng)
		return [fallback, fallback.pick_variant(day, rng)]
	return pool[rng.randi() % pool.size()]


func day_event_name(for_day: int = day) -> String:
	return DAY_EVENT_NAMES.get(for_day, "Hari Ramai")


func day_event_description(for_day: int = day) -> String:
	return DAY_EVENT_DESCRIPTIONS.get(for_day, "Antrean terus berdatangan.")


func roster_text(for_day: int) -> String:
	var schedule: Array = DAY_SCHEDULE.get(for_day, [])
	if schedule.is_empty():
		return "Pelanggan: bebas"
	var names: Array[String] = []
	for spec in schedule:
		var c := CustomerDB.get_by_id(spec[0])
		if c != null:
			names.append(c.display_name)
	return "Pelanggan: %s" % ", ".join(names)


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
		post("Belum matang — masak dulu di panci.", Color("e05a4f"))
		return

	var result := b.evaluate_for(order.demand)
	var diagnosis_score := order.diagnosis_accuracy()
	var gross := RecipeEvaluator.payment(
		BASE_PAY + base_pay_bonus, result, order.patience_ratio(),
		order.customer.pay_multiplier, b.doneness_bonus(), b.heritage_bonus())
	gross = maxi(1, roundi(gross * lerpf(0.75, 1.05, diagnosis_score)))
	var pay := maxi(gross - b.ingredient_cost, 1)

	day_earnings += pay
	day_served += 1
	total_served += 1

	if result.accuracy >= 0.999 and diagnosis_score >= 0.999 and not b.is_burnt:
		reputation = mini(reputation + 1, 10)
		if result.precision >= 0.85:
			day_perfect += 1
	elif result.accuracy <= 0.0:
		reputation = maxi(reputation - 1, 0)

	var mismatch := not b.is_intended_for(order.customer)
	_drop_order(slot)
	drop_carried(b)

	_report(order, result, gross, pay, diagnosis_score, mismatch, b)

	if reputation <= 0:
		_trigger_game_over()


func _report(order: Order, result: BrewResult, gross: int, pay: int,
		diagnosis_score: float, mismatch: bool, brew: Brew) -> void:
	var parts: Array[String] = []
	var new_recipe := brew.heritage_name != "" \
		and not brew.heritage_name in discovered_recipes

	if mismatch:
		parts.append("(diracik untuk orang lain)")
	if brew.is_burnt:
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

	if new_recipe:
		discovered_recipes.append(brew.heritage_name)
		parts.append("RESEP BARU: %s" % brew.heritage_name)

	var suffix := "  " + " · ".join(parts) if not parts.is_empty() else ""
	var col := Color("ffd36f") if result.accuracy >= 0.999 and not brew.is_burnt \
		else (Color("e05a4f") if result.accuracy <= 0.0 else Color("e8dcc0"))

	var reaction := _reaction_text(order, result, brew, new_recipe)
	last_reaction_name = order.customer.display_name
	last_reaction_role = order.customer.role
	last_reaction_text = reaction
	last_reaction_pay = pay
	last_reaction_color = order.customer.color
	_reaction_timer = 4.0

	service_report = _build_service_report(
		order, result, gross, pay, diagnosis_score, brew)
	service_report_details = _build_service_report_details(
		order, result, gross, pay, diagnosis_score, brew)
	_service_report_timer = 10.0
	service_reported.emit()

	post("%s: %s — untung %d duit.%s" % [
		reaction, result.grade(), pay, suffix], col)


func _build_service_report(order: Order, result: BrewResult, gross: int, pay: int,
		diagnosis_score: float, brew: Brew) -> Array[String]:
	var out: Array[String] = []
	out.append("HASIL — %s" % order.customer.display_name)
	out.append("Diagnosis %d%%  ·  Khasiat %d%%" % [
		roundi(diagnosis_score * 100.0), roundi(result.accuracy * 100.0)])
	var taste := "seimbang" if result.palatability >= 1.0 else "terlalu pahit"
	var cooked := "gosong" if brew.is_burnt else (
		"pas" if brew.doneness <= 1.15 else "terlalu lama")
	out.append("Dosis %d%%  ·  Rebusan %s" % [
		roundi(result.precision * 100.0), cooked])
	var finish := "%s  ·  Rasa %s" % [brew.display_name(), taste]
	if brew.heritage_name != "":
		finish += "  ·  ★ %s" % brew.heritage_name
	out.append(finish)
	out.append("+%d duit  ·  bahan %d" % [pay, brew.ingredient_cost])
	return out


func _build_service_report_details(order: Order, result: BrewResult,
		gross: int, pay: int, diagnosis_score: float, brew: Brew) -> Dictionary:
	var guessed: Array[String] = []
	for code in order.diagnosis:
		guessed.append(Symptom.display_name(code))
	var actual: Array[String] = []
	for code in order.symptoms():
		actual.append(Symptom.display_name(code))
	return {
		"customer": order.customer.display_name,
		"grade": result.grade(),
		"diagnosis": diagnosis_score,
		"accuracy": result.accuracy,
		"precision": result.precision,
		"cooking": "GOSONG" if brew.is_burnt else (
			"PAS" if brew.doneness <= 1.15 else "TERLALU LAMA"),
		"taste": "SEIMBANG" if result.palatability >= 1.0 else "TERLALU PAHIT",
		"brew_name": brew.display_name(),
		"heritage": brew.heritage_name,
		"pay": pay,
		"gross": gross,
		"ingredient_cost": brew.ingredient_cost,
		"guessed": guessed,
		"actual": actual,
	}


# ═══════════════ FEEDBACK ═══════════════

func _reaction_text(order: Order, result: BrewResult, brew: Brew,
		new_recipe: bool) -> String:
	if new_recipe:
		return "%s berbinar menemukan rasa lama" % order.customer.display_name
	if brew.is_burnt:
		return "%s batuk mencium jamu gosong" % order.customer.display_name
	if result.accuracy >= 0.999 and result.precision >= 0.85:
		return "%s lega dan tersenyum" % order.customer.display_name
	if result.accuracy >= 0.5:
		return "%s merasa agak membaik" % order.customer.display_name
	if result.accuracy > 0.0:
		return "%s masih ragu" % order.customer.display_name
	return "%s menggeleng pelan" % order.customer.display_name


func post(msg: String, col: Color) -> void:
	_feedback = msg
	_feedback_color = col
	_feedback_timer = 5.0
	feedback_posted.emit(msg, col)


func feedback_text() -> String:
	return _feedback if _feedback_timer > 0.0 else ""


func feedback_color() -> Color:
	return _feedback_color


func service_report_visible() -> bool:
	return _service_report_timer > 0.0 and not service_report.is_empty()


func reaction_visible() -> bool:
	return _reaction_timer > 0.0 and last_reaction_text != ""
