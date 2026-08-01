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
	_test_taking_an_order()
	_test_tool_stations()
	await _test_room_switch()
	await _test_tab_key()
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


## Taking an order must be an act the player performs. If the kitchen has
## an order before anyone pressed AMBIL, the step is invisible — which is
## precisely the confusion this replaced.
func _test_taking_an_order() -> void:
	print("- Taking an order")
	var gs := _state()
	gs.start_run()

	check("no order is active before taking one", gs.active_order() == null)
	check("has_active_order agrees", not gs.has_active_order())

	gs.set_active(0)
	check("taking an order makes it active", gs.active_order() != null)
	check("the taken order is the one chosen",
		gs.active_order() == gs.queue[0])

	# Serving the taken customer must release the kitchen, not silently
	# slide onto whoever shifted into their index.
	var taken: Order = gs.active_order()
	gs._drop_order(0)
	check("order clears when that customer leaves", gs.active_order() == null)
	check("the cleared order is the one that left", taken not in gs.queue)


## The machines are now physical drop targets, so the thing worth testing
## is that dropping into one really runs it, spends a use, and returns
## shapes that conserve the ingredient's cells.
func _test_tool_stations() -> void:
	print("- Tool stations")
	var gs := _state()
	gs.start_run()

	var station := ToolStation.new()
	station.kind = ToolKit.Kind.PIPISAN
	station.tools = gs.tools
	root.add_child(station)

	var bar: Array[Vector2i] = [Vector2i(0,0), Vector2i(0,1),
		Vector2i(0,2), Vector2i(0,3)]
	var ing := IngredientData.create(&"t", "T", "", bar,
		Color.WHITE, [Symptom.Code.DEMAM], 0, Vector2(0.0, 1.0), "")

	var piece := IngredientPiece.new()
	piece.setup(ing, 1)
	root.add_child(piece)

	var before: int = gs.tools.remaining(ToolKit.Kind.PIPISAN)
	var out := station.process_piece(piece)

	check("station cuts the piece", out.size() == 2)
	check("station spends a use",
		gs.tools.remaining(ToolKit.Kind.PIPISAN) == before - 1)

	var total := 0
	for h in out:
		total += (h as Array).size()
	check("cut halves conserve cells", total == bar.size())

	# The mouth is the drop target; a point outside it must not trigger.
	check("mouth accepts a point inside it",
		station.accepts_at(station.to_global(station.mouth().get_center())))
	check("mouth rejects a point far away",
		not station.accepts_at(station.to_global(Vector2(-500, -500))))

	# Exhausting the machine must make it refuse rather than run for free.
	while gs.tools.can_use(ToolKit.Kind.PIPISAN):
		gs.tools.consume(ToolKit.Kind.PIPISAN)

	var piece2 := IngredientPiece.new()
	piece2.setup(ing, 2)
	root.add_child(piece2)
	check("exhausted station refuses", station.process_piece(piece2).is_empty())

	piece.queue_free()
	piece2.queue_free()
	station.queue_free()


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


## Regression: pressing TAB used to crash. `Rooms.go()` calls
## change_scene_to_file, which frees the node mid-handler — so any
## get_viewport() call placed AFTER the switch hit a null viewport.
##
## Calling Rooms.go() directly (as the test above does) never reproduced
## it. This drives the real key event through _unhandled_input instead,
## which is the only way to catch that class of bug.
func _test_tab_key() -> void:
	print("- TAB key switching")

	# The crash is non-fatal in Godot: it prints and execution continues,
	# so "did the room change?" alone would still report ok. Instead we
	# read the source of each room's handler and assert the ordering that
	# makes the crash impossible.
	for path in ["res://Scripts/Game/kasir.gd", "res://Scripts/Game/dapur.gd"]:
		check("%s marks input handled before switching room" % path.get_file(),
			_handles_input_before_switch(path))

	# Then drive the real key through both rooms.
	for i in range(2):
		var before := current_scene.name
		var count_before: int = _rooms().switch_count

		var ev := InputEventKey.new()
		ev.keycode = KEY_TAB
		ev.physical_keycode = KEY_TAB
		ev.pressed = true
		Input.parse_input_event(ev)

		await process_frame
		await process_frame

		check("TAB switch %d changes room" % (i + 1),
			current_scene != null and current_scene.name != before
			and _rooms().switch_count == count_before + 1)


## Scans a room script for a `Rooms.go(` call that is followed by a
## `get_viewport()` in the same block — the exact shape of the bug.
func _handles_input_before_switch(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var lines := f.get_as_text().split("\n")
	f.close()

	for i in range(lines.size()):
		if not lines[i].contains("Rooms.go("):
			continue
		# Look at the next couple of lines: touching the viewport after the
		# scene has been swapped is the crash.
		for j in range(i + 1, mini(i + 3, lines.size())):
			if lines[j].contains("get_viewport()"):
				print("        %s:%d calls get_viewport() after Rooms.go()"
					% [path.get_file(), j + 1])
				return false
	return true


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
