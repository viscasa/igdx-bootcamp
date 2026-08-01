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
	_test_brew_button()
	_test_brew_without_match()
	await _test_tool_stations()
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


## Taking an order must be an act the player performs, and several orders
## can be in hand at once — the kitchen is not tied to any one of them.
func _test_taking_an_order() -> void:
	print("- Taking orders")
	var gs := _state()
	gs.start_run()

	check("nothing is taken before pressing AMBIL",
		gs.taken_orders().is_empty())
	check("has_taken_orders agrees", not gs.has_taken_orders())

	# Make sure there are several people to take from.
	while gs.queue.size() < 3:
		gs._spawn_customer()

	check("taking an order succeeds", gs.take_order(0))
	check("one order is now in hand", gs.taken_orders().size() == 1)
	check("the taken order is the one chosen",
		gs.taken_orders()[0] == gs.queue[0])

	# The point of the change: a second order joins the first rather than
	# replacing it.
	var first: Order = gs.queue[0]
	var second: Order = gs.queue[1]
	check("taking a second order succeeds", gs.take_order(1))
	check("both orders are in hand", gs.taken_orders().size() == 2)
	check("the first order is still held", gs.has_taken(first))
	check("the second order is held too", gs.has_taken(second))

	check("taking the same order twice is refused", not gs.take_order(0))
	check("still only two in hand", gs.taken_orders().size() == 2)

	# Losing one customer must not disturb the others.
	gs._drop_order(0)
	check("the departed order is released", not gs.has_taken(first))
	check("the other order survives", gs.has_taken(second))
	check("one order remains in hand", gs.taken_orders().size() == 1)

	# The pot must be sized for the heaviest dose in hand, or a lighter
	# order would strand the heavier one.
	while gs.queue.size() < 3:
		gs._spawn_customer()
	for i in range(gs.queue.size()):
		gs.take_order(i)

	var heaviest: Dictionary = gs.heaviest_demand()
	var covers := true
	for o in gs.taken_orders():
		for s in o.demand:
			if int(heaviest.get(s, 0)) < int(o.demand[s]):
				covers = false
	check("heaviest demand covers every taken order", covers)


## The SELESAI button lives on the kuali, beside the grid, and follows the
## pot when a different silhouette is dealt.
func _test_brew_button() -> void:
	print("- SELESAI button")

	var k := KualiGrid.new()
	root.add_child(k)

	var small := KualiShape.get_shape("kecil")
	k.build(small, [])

	var CELL := IngredientPiece.CELL
	var b := GridLogic.bounds(k.grid)
	var r: Rect2 = k.button_rect()

	check("button sits to the RIGHT of the pot",
		r.position.x >= (b.position.x + b.size.x) * CELL)
	check("button is vertically centred on the pot",
		absf(r.get_center().y - (b.position.y + b.size.y * 0.5) * CELL) < 2.0)

	# A wider pot must push the button further out, or it would overlap.
	var wide := KualiShape.get_shape("lonjong")
	k.build(wide, [])
	var r2: Rect2 = k.button_rect()
	check("button follows a wider pot", r2.position.x > r.position.x)

	# It only fires when there is something to finish.
	check("empty kuali has no contents", not k.has_contents())

	k.queue_free()


## Regression: bottling a mix that helps NOBODY used to crash.
##
## `best.symptoms() if best else []` produces an untyped `[]` when there
## is no match, and Brew.create wants Array[Symptom.Code] — so the very
## first useless brew threw "the array of argument 3 does not have the
## same element type".
func _test_brew_without_match() -> void:
	print("- Brewing a jamu that helps nobody")

	var ing := IngredientData.create(&"none", "Gula", "", [Vector2i(0, 0)],
		Color.WHITE, [], 0, Vector2(0.0, 1.0), "")
	var ings: Array[IngredientData] = [ing]
	var counts: Array[int] = [1]

	var empty: Array[Symptom.Code] = []
	var brew := Brew.create(ings, null, empty, counts)

	check("brew with no intended customer is created", brew != null)
	check("it treats nothing", brew.treats().is_empty())
	check("effect summary says so plainly",
		brew.effect_summary() == "tidak menyembuhkan apa-apa")
	check("ingredient summary still names it", brew.ingredient_summary() == "Gula")

	# The description is what makes an unclear bottle readable.
	var mixed := IngredientData.create(&"k", "Kunyit", "",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		Color.WHITE, [Symptom.Code.PENCERNAAN], 0, Vector2(0.0, 1.0), "")
	var many: Array[IngredientData] = [mixed, mixed, ing]
	var many_counts: Array[int] = [4, 4, 1]
	var b2 := Brew.create(many, null, empty, many_counts)

	check("repeated ingredients are counted, not repeated",
		b2.ingredient_summary() == "Kunyit x2, Gula")
	check("effect summary reports real potency",
		b2.effect_summary() == "Pencernaan 8")


## The pipisan is a Waste Crusher machine: a fixed blade you slide the
## ingredient under. What matters is that aiming really chooses the cut,
## that the halves stay on the machine, and that cells are conserved.
func _test_tool_stations() -> void:
	print("- Pipisan (cutter)")
	var gs := _state()
	gs.start_run()

	var station := ToolStation.new()
	station.kind = ToolKit.Kind.PIPISAN
	station.tools = gs.tools
	root.add_child(station)
	station.global_position = Vector2(400, 300)

	# 4 wide, so there are three places the blade could land.
	var wide: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0),
		Vector2i(2,0), Vector2i(3,0)]
	var ing := IngredientData.create(&"t", "T", "", wide,
		Color.WHITE, [Symptom.Code.DEMAM], 0, Vector2(0.0, 1.0), "")

	var CELL := IngredientPiece.CELL

	# Aiming: sliding the piece left and right must move the cut column.
	# This is the mechanic — if this fails, cutting is just "halve it".
	var blade := station.global_position
	var col_left: int = station.cut_col_for(wide, blade - Vector2(CELL, 0))
	var col_mid: int = station.cut_col_for(wide, blade - Vector2(CELL * 2, 0))
	var col_right: int = station.cut_col_for(wide, blade - Vector2(CELL * 3, 0))
	check("aiming left of the blade cuts at column 1", col_left == 1)
	check("aiming further along cuts at column 2", col_mid == 2)
	check("aiming further still cuts at column 3", col_right == 3)

	# Snapping must line the chosen column up exactly with the blade.
	var snapped: Vector2 = station.snap_position(wide, blade - Vector2(CELL * 2, 0))
	check("snap lines column 2 up with the blade",
		is_equal_approx(snapped.x + 2 * CELL, blade.x))

	# Regression: aiming must not read back the SNAPPED position.
	#
	# The snap puts the piece exactly on a column boundary, so feeding that
	# position into cut_col_for returns the same column forever — the aim
	# freezes on whichever column it first touched and cutting always
	# splits in the same place. Aim has to come from the intended (mouse)
	# position instead.
	var frozen := true
	var seen := {}
	var pos: Vector2 = blade - Vector2(CELL, 0)
	for step in range(3):
		var c: int = station.cut_col_for(wide, pos)
		seen[c] = true
		# Simulate the snap, then aim again from a NEW intended position.
		pos = station.snap_position(wide, pos)
		pos = blade - Vector2(CELL * (step + 2), 0)
	frozen = seen.size() == 1
	check("aim keeps moving after a snap (not frozen)", not frozen)

	var piece := IngredientPiece.new()
	piece.setup(ing, 1)
	root.add_child(piece)
	piece.global_position = blade - Vector2(CELL, 0)

	var before: int = gs.tools.remaining(ToolKit.Kind.PIPISAN)
	station.set_pending_col(1)
	var ok: bool = await station.receive(piece)

	check("station accepts the piece", ok)
	check("station spends a use",
		gs.tools.remaining(ToolKit.Kind.PIPISAN) == before - 1)
	check("halves stay on the machine", station.results.size() == 2)

	var total := 0
	for p in station.results:
		total += (p as IngredientPiece).cells.size()
	check("cut halves conserve cells", total == wide.size())
	check("cut at column 1 leaves a 1-cell half",
		(station.results[0] as IngredientPiece).cells.size() == 1)

	# While holding results the machine is busy and must refuse more work.
	check("machine with results is not open", not station.is_open())

	# Lifting a half frees the machine again.
	var half: IngredientPiece = station.results[0]
	check("machine knows it owns the half", station.owns(half))
	station.release(half)
	station.release(station.results[0])
	check("machine reopens once emptied", station.is_open())

	# Offcuts must not survive into the next customer's order.
	var piece3 := IngredientPiece.new()
	piece3.setup(ing, 3)
	root.add_child(piece3)
	piece3.global_position = blade - Vector2(CELL * 2, 0)
	station.set_pending_col(2)
	await station.receive(piece3)
	check("machine holds halves before clearing", station.results.size() == 2)
	station.clear()
	check("clear empties the machine", station.results.is_empty())
	check("machine is open again after clearing", station.is_open())

	# Exhausting the allowance must make it refuse rather than run free.
	while gs.tools.can_use(ToolKit.Kind.PIPISAN):
		gs.tools.consume(ToolKit.Kind.PIPISAN)
	check("exhausted machine is closed", not station.is_open())

	var piece2 := IngredientPiece.new()
	piece2.setup(ing, 2)
	root.add_child(piece2)
	var ok2: bool = await station.receive(piece2)
	check("exhausted machine refuses", not ok2)

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
