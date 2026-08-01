extends Node2D

## The kitchen. Mix in the kuali, hit BREW, simmer in the panci.
##
## The pot no longer has to be full. Hitting "Jadikan Ramuan" bottles
## whatever is in there and the jamu is judged on what it actually treats —
## so the player fails on knowledge, not on a stubborn last empty cell.

const CELL := IngredientPiece.CELL

@onready var kuali: KualiGrid = $Kuali
@onready var tray: IngredientTray = $Tray
@onready var drag: DragManager = $DragLayer
@onready var panci: Panci = $Panci
@onready var pipisan: ToolStation = $Pipisan
@onready var shelf: CarryShelf = $CarryShelf
@onready var order_card: OrderCard = $OrderCard
@onready var hud: HUD = $UILayer/HUD
@onready var heat_slider: HeatSlider = $UILayer/HeatSlider

var _last_order: Order = null


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

	hud.room_hint = "TAB — ke Kasir"
	hud.help_lines = PackedStringArray([
		"Seret bahan ke KUALI untuk meracik  ·  seret ke PIPISAN untuk membelah — geser kiri/kanan untuk pilih letak potongan",
		"SPASI: jadikan ramuan (tak perlu penuh)  ·  W/S: atur api  ·  R: putar  ·  Q/E: ganti pesanan  ·  C: kosongkan",
	])

	shelf.brews = GameState.carried

	panci.set_slot_count(1 if GameState.day <= 2 else mini(1 + GameState.day / 2, 4))
	tray.set_available(IngredientDB.available_on_day(GameState.day))

	panci.brew_ready.connect(_on_brew_ready)
	panci.brew_burnt.connect(_on_brew_burnt)
	kuali.changed.connect(_refresh_preview)
	drag.potion_dropped_outside.connect(_on_potion_parked)
	drag.piece_dropped_on_station.connect(_on_piece_dropped_on_station)

	GameState.queue_changed.connect(_on_queue_changed)
	GameState.carried_changed.connect(_on_carried_changed)

	_restore_simmering()
	_new_session()


func _exit_tree() -> void:
	# Anything still in the pot keeps cooking while the player is away.
	_stash_simmering()
	if GameState.queue_changed.is_connected(_on_queue_changed):
		GameState.queue_changed.disconnect(_on_queue_changed)
	if GameState.carried_changed.is_connected(_on_carried_changed):
		GameState.carried_changed.disconnect(_on_carried_changed)


func _process(_delta: float) -> void:
	hud.queue_redraw()


func _on_carried_changed() -> void:
	shelf.brews = GameState.carried
	shelf.queue_redraw()


func _on_queue_changed() -> void:
	var o := GameState.active_order()
	if o != _last_order:
		_new_session()
	else:
		_refresh_preview()


# ═══════════════ SESSION ═══════════════

func _new_session() -> void:
	kuali.clear_pieces()
	tray.reset_loose()
	# Halves left on the pipisan belong to the order that made them; a new
	# session must not inherit someone else's offcuts.
	pipisan.clear()

	var order := GameState.active_order()
	_last_order = order

	# No order taken means no pot. An empty bench is what teaches the
	# player that taking an order at the counter is a step they have to
	# perform — a pot that works regardless would hide it entirely.
	if order == null:
		kuali.build([], [])
		_refresh_preview()
		return

	var needed := _shapes_needed_for(order)
	var required_area := 0
	for s in needed:
		required_area += (s as Array).size()

	# The pot is chosen to fit the order, not at random — a severe complaint
	# must never land in a pot too small to hold its dose.
	var shape := KualiShape.shape_for(required_area, GameState.rng)
	var budget := KualiShape.residue_budget(shape.size(), GameState.day, required_area)
	var residue := KualiShape.generate_residue(shape, budget, needed, GameState.rng)

	kuali.build(shape, residue)
	_refresh_preview()


## One concrete way to satisfy the order, used ONLY to prove the board can
## be solved — never to constrain what the player may actually place.
##
## With potency in play this has to cover the full dose, not just tick each
## symptom once: a severity-5 complaint may need two ingredients stacked.
func _shapes_needed_for(order: Order) -> Array:
	var out: Array = []
	if order == null:
		return out

	var pool := IngredientDB.available_on_day(GameState.day)

	for s in order.symptoms():
		var need := order.required_potency(s)

		# Largest-first: fewer, bigger pieces are the harder packing case,
		# so proving THAT fits leaves margin for the player's own choices.
		var options: Array[IngredientData] = []
		for ing in pool:
			if ing.treats_symptom(s):
				options.append(ing)
		if options.is_empty():
			continue
		options.sort_custom(func(a: IngredientData, b: IngredientData) -> bool:
			return a.shape_cells.size() > b.shape_cells.size())

		var guard := 0
		while need > 0 and guard < 8:
			guard += 1
			var pick: IngredientData = options[0]
			for ing in options:
				if ing.shape_cells.size() <= need:
					pick = ing
					break
			out.append(pick.shape_cells.duplicate())
			need -= pick.shape_cells.size()

	return out


## Feeds the live dose meters on the order card.
func _refresh_preview() -> void:
	var order := GameState.active_order()
	if order == null:
		order_card.order = null
		order_card.queue_redraw()
		return

	order_card.order = order
	order_card.supplied = RecipeEvaluator.potency(
		kuali.placed_ingredients(), kuali.placed_cell_counts())
	order_card.queue_redraw()


# ═══════════════ BOTTLING ═══════════════

## The pot does not need to be full. What matters is what is in it.
func _bottle_kuali() -> void:
	if not GameState.has_active_order():
		GameState.post("Ambil pesanan dulu di Kasir (TAB).", Color("e05a4f"))
		return

	var ings := kuali.placed_ingredients()
	if ings.is_empty():
		GameState.post("Kuali masih kosong.", Color("e05a4f"))
		return

	if not GameState.can_carry() and not panci.has_space():
		GameState.post("Tangan dan panci penuh — antar dulu.", Color("e05a4f"))
		return

	var order := GameState.active_order()
	var brew := Brew.create(
		ings, order.customer if order else null,
		order.symptoms() if order else [],
		kuali.placed_cell_counts())

	var potion := Potion.new()
	potion.setup(brew)

	if panci.has_space():
		add_child(potion)
		panci.put_anywhere(potion)
		GameState.post("Jamu masuk panci — atur apinya.", Color("6fd48f"))
	else:
		add_child(potion)
		_park(potion)
		GameState.post("Jamu jadi. Seret ke panci untuk direbus.", Color("6fd48f"))

	if not brew.heat_window.x <= brew.heat_window.y:
		GameState.post("Suhu bahan-bahannya bentrok — sulit dimatangkan!",
			Color("d89b3c"))

	_new_session()


func _on_potion_parked(potion: Potion) -> void:
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
	# A finished jamu goes straight into the player's hands so it can be
	# carried to the counter; if their hands are full it waits in the pot.
	if GameState.can_carry():
		GameState.carry(p.brew)
		panci.take(slot)
		p.queue_free()
		GameState.post("Jamu siap — bawa ke kasir (TAB).", Color("6fd48f"))
	else:
		GameState.post("Jamu siap, tapi tanganmu penuh.", Color("d89b3c"))


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
		var p := Potion.new()
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
		tray.return_piece(piece)
		return

	GameState.post("Dibelah — ambil potongannya dari pipisan.", Color("6fd48f"))


# ═══════════════ INPUT ═══════════════

func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_over:
		if event is InputEventKey and event.pressed:
			GameState.start_run()
			Rooms.go(Rooms.Room.KASIR)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_TAB:
				# Handled first: change_scene_to_file frees this node, and
				# get_viewport() returns null once it is gone.
				get_viewport().set_input_as_handled()
				Rooms.go(Rooms.Room.KASIR)
			KEY_SPACE:
				_bottle_kuali()
				get_viewport().set_input_as_handled()
			KEY_Q:
				GameState.cycle_active(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				GameState.cycle_active(1)
				get_viewport().set_input_as_handled()
			KEY_C:
				kuali.clear_pieces()
				GameState.post("Kuali dikosongkan.", Color("9a8f80"))
				get_viewport().set_input_as_handled()
