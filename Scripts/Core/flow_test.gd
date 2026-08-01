extends SceneTree

## Drives the two-room flow with real nodes: start a shift, brew in the
## kitchen, walk to the counter, hand a jamu over.
##
## The unit tests prove the maths; this proves the wiring. Most of what can
## break in a scene split — state that resets on a room change, a pot that
## stops cooking while you are away, a queue that forgets who you selected —
## is invisible to pure-logic tests.

var failures := 0


func _init() -> void:
	print("=== ACARAKI flow test ===")
	_run.call_deferred()


func check(label: String, cond: bool) -> void:
	if cond:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		failures += 1


func _run() -> void:
	await process_frame

	_test_shift_state()
	await _test_room_switch()
	_test_carry_limit()
	_test_delivery()

	print("=== %s ===" % ("FLOW OK" if failures == 0 else "%d FAILURE(S)" % failures))
	quit(1 if failures > 0 else 0)


func _state() -> Node:
	return root.get_node("GameState")


func _rooms() -> Node:
	return root.get_node("Rooms")


func _test_shift_state() -> void:
	print("- Shift state")
	var gs := _state()

	gs.start_run()
	check("run starts on day 1", gs.day == 1)
	check("shift is running", gs.running)
	check("a customer is waiting", gs.queue.size() >= 1)
	check("tools start stocked",
		gs.tools.remaining(ToolKit.Kind.PIPISAN) > 0)
	check("reputation starts full", gs.reputation == gs.START_REPUTATION)

	# Day 1 must stay gentle: every dose pinned to 1.
	var gentle := true
	for o in gs.queue:
		for s in o.symptoms():
			if o.required_potency(s) != 1:
				gentle = false
	check("day 1 doses are all 1", gentle)


## The whole point of the split: the shift must not reset when the player
## walks between rooms, and patience must keep draining while they are away.
func _test_room_switch() -> void:
	print("- Room switching")
	var gs := _state()
	var rooms := _rooms()

	var day_before: int = gs.day
	var queue_before: int = gs.queue.size()
	var patience_before: float = gs.queue[0].patience_left

	rooms.go(rooms.Room.DAPUR)
	await process_frame
	await process_frame

	check("scene actually changed to dapur",
		current_scene != null and current_scene.name == "Dapur")
	check("day survives the switch", gs.day == day_before)
	check("queue survives the switch", gs.queue.size() == queue_before)

	# Let time pass inside the kitchen.
	for i in range(20):
		await process_frame

	check("patience drains while in the kitchen",
		gs.queue[0].patience_left < patience_before)

	rooms.go(rooms.Room.KASIR)
	await process_frame
	await process_frame

	check("scene changed back to kasir",
		current_scene != null and current_scene.name == "Kasir")
	check("state still intact after returning", gs.day == day_before)


func _test_carry_limit() -> void:
	print("- Carrying")
	var gs := _state()
	gs.carried.clear()

	var ing := IngredientData.create(&"t", "T", "", [Vector2i(0, 0)],
		Color.WHITE, [Symptom.Code.DEMAM], 0, Vector2(0.0, 1.0), "")
	var ings: Array[IngredientData] = [ing]

	for i in range(gs.CARRY_LIMIT):
		check("can carry jamu %d" % (i + 1),
			gs.carry(Brew.create(ings, null, [])))

	check("carrying is capped", not gs.can_carry())
	check("overflow is refused", not gs.carry(Brew.create(ings, null, [])))

	var held: Brew = gs.carried[0]
	gs.drop_carried(held)
	check("dropping frees a hand", gs.can_carry())

	gs.carried.clear()


## Delivery is judged against the RECIPIENT, so handing a jamu to the wrong
## person has to be possible and has to score differently.
func _test_delivery() -> void:
	print("- Delivery")
	var gs := _state()
	gs.carried.clear()

	if gs.queue.is_empty():
		check("a customer is present to serve", false)
		return

	var order: Order = gs.queue[0]
	var target_symptom = order.symptoms()[0]
	var dose := order.required_potency(target_symptom)

	# Build a jamu that treats exactly what this customer asked for, with
	# enough potency to satisfy the dose.
	var cells: Array[Vector2i] = []
	for i in range(dose):
		cells.append(Vector2i(i, 0))

	var cure := IngredientData.create(&"cure", "Cure", "", cells,
		Color.WHITE, [target_symptom], 0, Vector2(0.0, 1.0), "")
	var ings: Array[IngredientData] = [cure]

	var brew := Brew.create(ings, order.customer, order.symptoms(), [dose])
	brew.is_done = true
	brew.doneness = 1.0
	gs.carry(brew)

	var money_before: int = gs.day_earnings
	var queue_before: int = gs.queue.size()

	gs.deliver(brew, 0)

	check("customer leaves the queue", gs.queue.size() == queue_before - 1)
	check("delivery pays", gs.day_earnings > money_before)
	check("delivered jamu leaves the hands", not gs.carried.has(brew))

	# An unfinished jamu must be refused rather than silently served.
	# Spawn a customer if the queue happens to be empty, so this check
	# always runs instead of quietly disappearing.
	if gs.queue.is_empty():
		gs._spawn_customer()
	check("someone is queued to test refusal against", not gs.queue.is_empty())

	if not gs.queue.is_empty():
		var raw := Brew.create(ings, null, [])
		raw.is_done = false
		gs.carry(raw)
		var before: int = gs.queue.size()
		gs.deliver(raw, 0)
		check("raw jamu cannot be served", gs.queue.size() == before)
		check("refused jamu stays in hand", gs.carried.has(raw))
		gs.carried.clear()
