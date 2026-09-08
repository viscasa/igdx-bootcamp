extends Node2D

## The kitchen. Mix in the kuali, hit BREW, simmer in the panci.
##
## The pot no longer has to be full. Hitting "Jadikan Ramuan" bottles
## whatever is in there and the jamu is judged on what it actually treats —
## so the player fails on knowledge, not on a stubborn last empty cell.

const CELL := IngredientPiece.CELL
const POTION_SCENE := preload("res://Scenes/Item/potion.tscn")

@onready var kuali: KualiGrid = $Kuali
@onready var tray: IngredientTray = $Tray
@onready var drag: DragManager = $DragLayer
@onready var panci: Panci = $Panci
@onready var pipisan: ToolStation = $Pipisan
@onready var shelf: CarryShelf = $CarryShelf
@onready var order_card: OrderCard = $OrderCard
@onready var hud: HUD = $UILayer/HUD
@onready var heat_slider: HeatSlider = $PanciArea/HeatSlider
@onready var serat: SeratBook = $UILayer/SeratBook

## Whether the bench had any order last time we looked. Used to tell
## "the player just took their first order" apart from "they took another
## one" — only the former should build a fresh pot.
var _had_orders: bool = false
var _bottling_count: int = 0


func _ready() -> void:
	if not GameState.running and not GameState.game_over:
		GameState.start_run()

	drag.tray = tray
	drag.kuali = kuali
	drag.panci = panci
	drag.stations = [pipisan]
	tray.kuali = kuali
	heat_slider.panci = panci

	for s in drag.stations:
		s.tools = GameState.tools

	shelf.brews = GameState.carried

	panci.set_slot_count(1 if GameState.day <= 2 else mini(1 + GameState.day / 2, 4))
	tray.set_available(IngredientDB.available_on_day(GameState.day))

	panci.brew_ready.connect(_on_brew_ready)
	panci.brew_burnt.connect(_on_brew_burnt)
	panci.bottle_requested.connect(_on_panci_bottle_requested)
	panci.interaction_blocked.connect(_on_panci_interaction_blocked)
	kuali.brew_requested.connect(_bottle_kuali)
	kuali.changed.connect(_refresh_preview)
	drag.potion_dropped_outside.connect(_on_potion_parked)
	drag.piece_dropped_on_station.connect(_on_piece_dropped_on_station)

	GameState.queue_changed.connect(_on_queue_changed)
	GameState.carried_changed.connect(_on_carried_changed)

	_restore_simmering()
	_new_session()
	if GameState.day == 1 and GameState.total_served == 0 \
			and not GameState.kitchen_tip_seen:
		GameState.kitchen_tip_seen = true
		GameState.post("Target awal butuh beberapa takaran. Pipisan membantu pas-kan bentuk dan dosis.",
			Color("ffd36f"))
	call_deferred("_play_station_entrance")


func _play_station_entrance() -> void:
	var delay := 0.03
	for station in get_tree().get_nodes_in_group("kitchen_station"):
		if not is_ancestor_of(station) or not station is Control:
			continue
		var panel := station as Control
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2.ONE * 0.96
		panel.modulate.a = 0.0
		var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.34).set_delay(delay)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_delay(delay)
		delay += 0.045


func _exit_tree() -> void:
	# Anything still in the pot keeps cooking while the player is away.
	_stash_simmering()
	if GameState.queue_changed.is_connected(_on_queue_changed):
		GameState.queue_changed.disconnect(_on_queue_changed)
	if GameState.carried_changed.is_connected(_on_carried_changed):
		GameState.carried_changed.disconnect(_on_carried_changed)


func _process(_delta: float) -> void:
	hud.queue_redraw()

	# Clicking a cooked pan frees its slot after the pour animation, so the
	# kuali action has to re-check capacity continuously.
	var room := panci.has_space()
	if room != kuali.panci_has_room:
		kuali.panci_has_room = room
		kuali.queue_redraw()


func _on_carried_changed() -> void:
	shelf.brews = GameState.carried
	shelf.queue_redraw()


## Taking a new order must NOT wipe a pot the player is halfway through.
## It only matters when the bench was idle for want of any order at all.
func _on_queue_changed() -> void:
	var have := GameState.has_taken_orders()
	if have and not _had_orders:
		_new_session()
	elif not have:
		_new_session()
	else:
		_refresh_preview()


# ═══════════════ SESSION ═══════════════

func _new_session() -> void:
	kuali.clear_pieces()
	tray.reset_loose()
	# A leftover half stays for the next mix. Because cut pieces pay only for
	# the cells used, this turns the pipisan into planning rather than waste.

	var orders := GameState.taken_orders()
	_had_orders = not orders.is_empty()

	# No order taken means no pot. An empty bench is what teaches the
	# player that taking an order at the counter is a step they have to
	# perform — a pot that works regardless would hide it entirely.
	if orders.is_empty():
		kuali.build([], [])
		_refresh_preview()
		return

	# Size the pot for the HEAVIEST order in hand, so every order the
	# player has accepted stays brewable in it. A pot picked for the
	# lightest one would strand the others.
	var needed := _shapes_needed_for_demand(GameState.heaviest_demand())
	var required_area := 0
	for s in needed:
		required_area += (s as Array).size()

	var shape := KualiShape.shape_for(required_area, GameState.rng)
	var budget := maxi(KualiShape.residue_budget(
		shape.size(), GameState.day, required_area) - GameState.residue_reduction, 0)
	var residue := KualiShape.generate_residue(shape, budget, needed, GameState.rng)

	kuali.build(shape, residue)
	_refresh_preview()


## One concrete way to satisfy a dose, used ONLY to prove the board can be
## solved — never to constrain what the player may actually place.
func _shapes_needed_for_demand(demand: Dictionary) -> Array:
	return KualiShape.shapes_for_demand(
		demand, IngredientDB.available_on_day(GameState.day))


## Feeds the live dose meters: what the pot holds, matched against every
## order in hand at once.
func _refresh_preview() -> void:
	var ings := kuali.placed_ingredients()
	var counts := kuali.placed_cell_counts()
	order_card.orders = GameState.taken_orders()
	order_card.supplied = RecipeEvaluator.potency(ings, counts)
	order_card.mix_cost = 0
	for i in range(ings.size()):
		order_card.mix_cost += ings[i].cost_for_cells(counts[i])
	order_card.heritage_preview = RecipeEvaluator.heritage_recipe(ings)
	order_card.queue_redraw()
	# The button lives on the kuali but has to know whether the panci can
	# take another jamu, so it can say why it will not fire.
	kuali.panci_has_room = panci.has_space()
	kuali.queue_redraw()


# ═══════════════ BOTTLING ═══════════════

## The pot does not need to be full. What matters is what is in it.
##
## The jamu is NOT bound to a customer. It records what it treats and the
## player decides at the counter who should get it — which is what lets one
## brew serve whoever it happens to suit.
func _bottle_kuali() -> void:
	if not GameState.has_taken_orders():
		GameState.post("Ambil pesanan dulu di Kasir.", Color("e05a4f"))
		return

	var ings := kuali.placed_ingredients()
	if ings.is_empty():
		GameState.post("Kuali masih kosong.", Color("e05a4f"))
		return

	if not panci.has_space():
		GameState.post("Panci penuh — ambil jamu yang sudah matang dulu.",
			Color("e05a4f"))
		return

	# Labelled with whichever taken order it fits best, purely so the
	# bottle has a readable name. Scoring still happens on delivery,
	# against whoever actually receives it.
	var counts := kuali.placed_cell_counts()
	var best := _best_match(ings, counts)

	# The empty fallback has to be a TYPED array: a bare `[]` in a ternary
	# is untyped and Brew.create rejects it at runtime.
	var label_symptoms: Array[Symptom.Code] = []
	if best:
		label_symptoms = best.symptoms()

	var brew := Brew.create(
		ings,
		best.customer if best else null,
		label_symptoms,
		counts)
	brew.widen_heat_window(GameState.heat_tolerance_bonus)

	var potion := POTION_SCENE.instantiate() as Potion
	potion.setup(brew)
	add_child(potion)
	panci.put_anywhere(potion)

	if not brew.heat_window.x <= brew.heat_window.y:
		GameState.post("Suhu bahan-bahannya bentrok — sulit dimatangkan!",
			Color("d89b3c"))
	elif best:
		GameState.post("Jamu masuk panci (cocok untuk %s) — atur apinya."
			% best.customer.display_name, Color("6fd48f"))
	else:
		GameState.post("Jamu masuk panci — atur apinya.", Color("6fd48f"))

	# Fresh pot for the next brew: new shape, new residue.
	_new_session()


## Which order in hand this mix serves best, or null if it helps nobody.
func _best_match(ings: Array[IngredientData], counts: Array[int]) -> Order:
	var best: Order = null
	var best_score := 0.0

	for o in GameState.taken_orders():
		# Labels and live guidance follow the player's diagnosis. The answer
		# key stays sealed until delivery, where the real complaint is scored.
		var r := RecipeEvaluator.evaluate(ings, o.working_demand(), counts)
		if r.accuracy > best_score:
			best_score = r.accuracy
			best = o

	return best


func _on_potion_parked(potion: Potion) -> void:
	if potion.brew != null and potion.brew.is_ready_to_serve():
		if GameState.carry(potion.brew):
			potion.queue_free()
			GameState.post("Jamu diangkat dari api — bawa ke kasir.", Color("6fd48f"))
			return
	_park(potion)


func _park(potion: Potion) -> void:
	if potion.get_parent() != self:
		if potion.get_parent():
			potion.get_parent().remove_child(potion)
		add_child(potion)

	var others := 0
	for c in get_children():
		if c is Potion and c != potion and panci.slot_of(c) < 0:
			others += 1

	potion.global_position = $CounterSpot.global_position \
		+ Vector2((others % 3) * 46, 0)
	potion.z_index = 1


func _on_brew_ready(slot: int) -> void:
	var p: Potion = panci.potions[slot]
	if p == null:
		return
	# The timing decision remains because a ready brew keeps cooking until
	# the player clicks its physical pan.
	GameState.post("JAMU SIAP — klik pancinya untuk botolkan!", Color("6fd48f"))


func _on_panci_bottle_requested(slot: int) -> void:
	if GameState.carried.size() + _bottling_count >= GameState.CARRY_LIMIT:
		var station := panci.get_node("Slots").get_child(slot) as PanciSlot
		station.reject_click("RAK BOTOL PENUH")
		GameState.post("Rak botol penuh — antar jamu dulu.", Color("e05a4f"))
		return
	_bottling_count += 1
	var potion: Potion = await panci.bottle_slot(slot)
	_bottling_count -= 1
	if potion == null or potion.brew == null:
		return
	var brew := potion.brew
	if GameState.carry(brew):
		potion.queue_free()
		GameState.post("Jamu selesai dibotolkan — bawa ke kasir.", Color("6fd48f"))
	else:
		_park(potion)


func _on_panci_interaction_blocked(_slot: int, reason: String) -> void:
	if reason == "belum matang":
		GameState.post("Belum matang — biarkan ramuan tetap merebus.", Color("d89b3c"))


func _on_brew_burnt(_slot: int) -> void:
	GameState.post("Jamu gosong!", Color("e05a4f"))


## Potions left in the pot must survive the room switch, so their brews are
## parked in GameState and rebuilt on the way back in.
func _stash_simmering() -> void:
	var out: Array = []
	for i in range(panci.potions.size()):
		var p: Potion = panci.potions[i]
		if p != null and p.brew != null:
			out.append([i, p.brew])
	GameState.set_meta("simmering", out)
	GameState.set_meta("heat", panci.heat)


func _restore_simmering() -> void:
	if not GameState.has_meta("simmering"):
		return
	var stash: Array = GameState.get_meta("simmering")
	for entry in stash:
		var slot: int = entry[0]
		var b: Brew = entry[1]
		if slot >= panci.slot_count:
			slot = panci.free_slot()
		if slot < 0:
			continue
		var p := POTION_SCENE.instantiate() as Potion
		p.setup(b)
		add_child(p)
		panci.put(p, slot)
	panci.heat = GameState.get_meta("heat", 0.5)
	GameState.set_meta("simmering", [])


# ═══════════════ TOOLS ═══════════════

## A piece was dragged onto the pipisan. The machine keeps the halves on
## its own bed until the player lifts them off, so nothing lands in the pot
## by itself — the tool stays a step in the puzzle, not an autocorrect.
func _on_piece_dropped_on_station(piece: IngredientPiece, station: ToolStation) -> void:
	var ok := await station.receive(piece)

	if not ok:
		# Refused (out of uses, busy, or the shape cannot be split there).
		# The machine draws its own reason; just put the ingredient back.
		GameState.post("Bahan terlalu kecil/pipisan belum siap - kembali ke rak.",
			Color("e05a4f"))
		tray.return_piece(piece)
		return

	GameState.post("Dibelah — ambil potongannya dari pipisan.", Color("6fd48f"))


# ═══════════════ INPUT ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if serat.visible:
		return
	if GameState.game_over:
		if event is InputEventKey and event.pressed:
			GameState.start_run()
			Rooms.go(Rooms.Room.KASIR)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				# Kept as a shortcut for the SELESAI button, not as the
				# only way in — the button is what teaches the step.
				_bottle_kuali()
				get_viewport().set_input_as_handled()
			KEY_C:
				kuali.clear_pieces()
				GameState.post("Kuali dikosongkan.", Color("9a8f80"))
				get_viewport().set_input_as_handled()
