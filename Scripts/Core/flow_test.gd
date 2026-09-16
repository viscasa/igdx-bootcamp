extends SceneTree


class ClickProbe extends Node:
	var reached_world := false

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			reached_world = true

## Drives the two-room flow with real nodes: start a shift, brew in the
## kitchen, walk to the counter, hand a jamu over.
##
## The unit tests prove the maths; this proves the wiring. Most of what can
## break in a scene split — state that resets on a room change, a pot that
## stops cooking while you are away, a queue that forgets who you selected —
## is invisible to pure-logic tests.

var failures := 0
var _checks := 0

## How many checks each section is expected to run.
##
## A GDScript runtime error aborts the current function but does NOT stop
## the suite — so a test that crashed halfway used to print its error and
## still let the run report FLOW OK. Pinning the count turns a section
## that died early into a real failure.
##
## A plain `var`, not `const`: a const dictionary at class scope is
## resolved while the script is being parsed, which happens before the
## autoloads exist and makes GameState fail to compile.
var EXPECTED := {
	"world audio": 7,
	"tutorial opening": 3,
	"shift state": 8,
	"taking orders": 15,
	"selesai button": 5,
	"handover": 15,
	"brew without match": 6,
	"tool stations": 18,
	"room switch": 8,
	"study pause": 3,
	"room button": 8,
	"carrying": 6,
	"delivery": 7,
	"diagnosis and progression": 20,
	"serat single selection": 8,
	"kitchen readability": 16,
	"multiple pans": 6,
}

var _section := ""
var _section_start := 0


func _init() -> void:
	print("=== ACARAKI flow test ===")
	_run.call_deferred()


func check(label: String, cond: bool) -> void:
	_checks += 1
	if cond:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		failures += 1


## Opens a section and closes the previous one, verifying it ran all of
## its checks rather than dying part-way through.
func section(name_: String) -> void:
	_close_section()
	_section = name_
	_section_start = _checks
	print("- %s" % name_)


func _close_section() -> void:
	if _section == "":
		return
	var ran := _checks - _section_start
	var want: int = EXPECTED.get(_section, -1)
	if want >= 0 and ran != want:
		print("  FAIL section '%s' ran %d/%d checks — it crashed part-way"
			% [_section, ran, want])
		failures += 1
	_section = ""


func _run() -> void:
	await process_frame

	_test_world_audio()
	_test_tutorial_opening()
	_test_shift_state()
	_test_taking_an_order()
	_test_brew_button()
	_test_handover_hit_tests()
	_test_brew_without_match()
	await _test_tool_stations()
	await _test_room_switch()
	await _test_study_pause()
	await _test_room_button()
	_test_carry_limit()
	_test_delivery()
	_test_diagnosis_and_progression()
	_test_serat_selection()
	await _test_kitchen_readability()
	await _test_multiple_pans()

	_close_section()

	print("  (%d checks)" % _checks)
	print("=== %s ===" % ("FLOW OK" if failures == 0 else "%d FAILURE(S)" % failures))
	quit(1 if failures > 0 else 0)


func _state() -> Node:
	return root.get_node("GameState")


func _rooms() -> Node:
	return root.get_node("Rooms")


func _test_world_audio() -> void:
	section("world audio")
	var audio := root.get_node_or_null("WorldAudioManager")
	var player := audio.get_node_or_null("BackgroundMusic") as AudioStreamPlayer \
		if audio != null else null
	check("world audio manager is autoloaded", audio != null)
	check("all supplied SFX cues are registered", audio != null and audio.SFX.size() == 27)
	check("background music starts automatically", player != null and player.playing)
	check("background music uses interactive crossfade",
		player != null and player.stream is AudioStreamInteractive)
	check("main menu music is the initial clip",
		audio != null and audio.current_bgm() == &"MainMenu")
	audio.play_gameplay()
	check("gameplay music can be selected", audio.current_bgm() == &"Gameplay")
	audio.play_main_menu()
	check("main menu music can be restored", audio.current_bgm() == &"MainMenu")


func _test_tutorial_opening() -> void:
	section("tutorial opening")
	var tutorial := root.get_node("Tutorial")
	check("tutorial uses an anywhere-click hint without a continue button",
		tutorial.has_node("Overlay/Card/ContinueHint")
		and not tutorial.has_node("Overlay/Card/Next")
		and not tutorial.has_node("Overlay/Card/Progress"))
	tutorial.step = 0
	tutorial.intro_page = 0
	tutorial._advance_explanation()
	check("first explanation advances to Raka", tutorial.intro_page == 1)
	tutorial.intro_page = 2
	tutorial._advance_explanation()
	check("reputation explanation advances to the clue lesson",
		tutorial.step == 1)
	tutorial.finish()
	tutorial.step = 0
	tutorial.intro_page = 0


func _test_shift_state() -> void:
	section("shift state")
	var gs := _state()

	gs.start_run()
	check("run starts on day 1", gs.day == 1)
	check("shift is running", gs.running)
	check("a customer is waiting", gs.queue.size() >= 1)
	check("tools start stocked",
		gs.tools.remaining(ToolKit.Kind.PIPISAN) > 0)
	check("reputation starts full", gs.reputation == gs.START_REPUTATION)
	check("new customers arrive without a long idle gap", gs.SPAWN_INTERVAL.y <= 12.0)
	var cashier_hud: Control = load("res://Scenes/UI/kasir_hud.tscn").instantiate()
	root.add_child(cashier_hud)
	check("cashier reputation joins the day widget entrance",
		cashier_hud.get_node("%RunStatus").get_parent().is_in_group("hud_entrance_left"))
	cashier_hud.queue_free()

	# Day 1 should already teach chunky potion dosing, not one-click cures.
	var gentle := true
	for o in gs.queue:
		for s in o.symptoms():
			if o.required_potency(s) < 4:
				gentle = false
	check("day 1 doses already need several cells", gentle)


## Taking an order must be an act the player performs, and several orders
## can be in hand at once — the kitchen is not tied to any one of them.
func _test_taking_an_order() -> void:
	section("taking orders")
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
	section("selesai button")

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
	k.build([], [])
	check("empty kuali still has a visible action area",
		Rect2(Vector2.ZERO, KualiGrid.EMPTY_SIZE).encloses(k.button_rect()))

	k.queue_free()


## Handing a jamu over is drag-from-shelf onto a customer figure. Both hit
## tests have to work, or the player ends up holding a bottle with no way
## to give it away.
func _test_handover_hit_tests() -> void:
	section("handover")
	var gs := _state()
	gs.start_run()

	var rack := CarryShelf.new()
	root.add_child(rack)
	rack.global_position = Vector2(880, 520)

	var ing := IngredientData.create(&"h", "H", "", [Vector2i(0, 0)],
		Color.WHITE, [Symptom.Code.DEMAM], 0, Vector2(0.0, 1.0), "")
	var ings: Array[IngredientData] = [ing]
	var none: Array[Symptom.Code] = []
	var b := Brew.create(ings, null, none, [1])
	var held: Array[Brew] = [b]
	rack.brews = held

	# Picking the bottle up: the slot must be grabbable where it is drawn.
	var centre := rack.to_global(rack.slot_rect(0).get_center())
	check("bottle can be grabbed from its slot", rack.brew_at(centre) == b)
	check("empty space grabs nothing",
		rack.brew_at(rack.to_global(Vector2(-400, -400))) == null)

	# Dropping it on a customer: the body must be a valid target.
	if gs.queue.size() < 2:
		gs._spawn_customer()
	var q := CustomerQueue.new()
	root.add_child(q)
	q.orders = gs.queue
	q.refresh()

	var body := q.to_global(q.card_rect(0).get_center())
	check("customer figure is a drop target", q.slot_at(body) == 0)
	check("off-card space is not a target",
		q.slot_at(q.to_global(Vector2(-400, -400))) < 0)
	var clicked := {"slot": -1}
	q.order_selected.connect(func(slot: int) -> void: clicked["slot"] = slot)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = body
	click.pressed = true
	q._unhandled_input(click)
	check("clicking a customer opens the order", int(clicked["slot"]) == 0)
	check("queue builds one figure per customer",
		q.get_child_count() == q.orders.size())
	var figure := q.get_child(0) as CustomerFigure
	check("customer figure uses modular customer artwork",
		figure != null and figure.customer_visual != null
		and figure.customer_visual.get_node("Body").texture.resource_path
			== "res://Assets/Characters/Body/body.png")
	gs.queue[0].patience_left = gs.queue[0].patience_max * 0.5
	q.refresh()
	check("customer patience progress bar follows live patience",
		figure.patience.visible and figure.patience.value < 75.0)
	check("back row is smaller than the person at the counter",
		q.orders.size() < 2 or q.card_rect(0).size.x > q.card_rect(1).size.x)
	var back_visible_point := q.to_global(q.card_rect(1).position + Vector2(5, 5))
	check("back customer remains a bottle drop target", q.slot_at(back_visible_point) == 1)
	check("back customer can open diagnosis", q.diagnosis_slot_at(back_visible_point) == 1)

	var arriving_q := preload("res://Scenes/Components/customer_queue.tscn").instantiate() \
		as CustomerQueue
	root.add_child(arriving_q)
	var arriving_orders: Array[Order] = [gs.queue[0]]
	arriving_q.orders = arriving_orders
	arriving_q.refresh()
	var arriving_figure: CustomerFigure = null
	for child in arriving_q.get_children():
		if child is CustomerFigure:
			arriving_figure = child as CustomerFigure
			break
	check("arriving customer keeps the complaint bubble hidden",
		arriving_figure != null and not arriving_figure.bubble.visible
		and not arriving_figure.diagnosis_enabled)
	if arriving_figure != null:
		arriving_figure.set_settled_at_slot(true)
		arriving_q.refresh()
	check("complaint appears only after the customer reaches the slot",
		arriving_figure != null and arriving_figure.bubble.visible
		and arriving_figure.diagnosis_enabled)

	var bounded_q := preload("res://Scenes/Components/customer_queue.tscn").instantiate() \
		as CustomerQueue
	bounded_q.restore_existing_without_arrival = true
	root.add_child(bounded_q)
	bounded_q.orders = gs.queue
	bounded_q.refresh()
	var opening_point := bounded_q.to_global(Vector2(0, 0))
	var behind_wall_point := bounded_q.to_global(Vector2(0, 100))
	check("window opening keeps customer interaction",
		bounded_q.slot_at(opening_point) == 0)
	check("window wall blocks customer interaction",
		bounded_q.slot_at(behind_wall_point) == -1
		and bounded_q.diagnosis_slot_at(behind_wall_point) == -1)

	rack.queue_free()
	q.queue_free()
	arriving_q.queue_free()
	bounded_q.queue_free()


## Regression: bottling a mix that helps NOBODY used to crash.
##
## `best.symptoms() if best else []` produces an untyped `[]` when there
## is no match, and Brew.create wants Array[Symptom.Code] — so the very
## first useless brew threw "the array of argument 3 does not have the
## same element type".
func _test_brew_without_match() -> void:
	section("brew without match")

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
	section("tool stations")
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
	section("room switch")
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
	var fire_loop := current_scene.get_node_or_null("Panci/FireLoop") as AudioStreamPlayer
	var boil_loop := current_scene.get_node_or_null("Panci/BoilLoop") as AudioStreamPlayer
	check("panci fire and boil loops are scene-authored and quiet",
		fire_loop != null and boil_loop != null
		and fire_loop.volume_db > -12.0 and fire_loop.volume_db < -8.0
		and boil_loop.volume_db < fire_loop.volume_db)

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
	var restored_queue := current_scene.get_node("CustomerQueue") as CustomerQueue
	var restored_front: CustomerFigure = null
	for child in restored_queue.get_children():
		if child is CustomerFigure and int(child.get_meta("queue_rank", -1)) == 0:
			restored_front = child as CustomerFigure
			break
	check("returning from kitchen does not replay customer arrival",
		restored_front != null and is_equal_approx(restored_front.depth_alpha, 1.0)
		and not restored_front.has_meta("queue_tween"))


func _test_study_pause() -> void:
	section("study pause")
	var gs := _state()
	gs.start_run()

	var time_before: float = gs.time_left
	var patience_before: float = gs.queue[0].patience_left
	var spawn_before: float = gs.spawn_timer
	gs.study_open = true

	for i in range(20):
		await process_frame

	check("Serat pauses the day clock", is_equal_approx(gs.time_left, time_before))
	check("Serat pauses customer patience",
		is_equal_approx(gs.queue[0].patience_left, patience_before))
	check("Serat pauses new arrivals", is_equal_approx(gs.spawn_timer, spawn_before))
	gs.study_open = false


## The room switch is now taught as a visible HUD button.
func _test_room_button() -> void:
	section("room button")

	var rooms := _rooms()
	rooms.go(rooms.Room.KASIR)
	await process_frame
	await process_frame

	var button := _room_button(current_scene.get_node("UILayer/HUD"))
	var hud := current_scene.get_node("UILayer/HUD")
	var sky := current_scene.get_node("Sky") as Control
	check("kasir background does not override world cursor",
		sky != null and sky.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	check("kasir HUD lets world clicks through",
		hud != null and hud.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	check("kasir offers a dapur button", button != null and button.text == "DAPUR")
	var dynamic_button := Button.new()
	root.add_child(dynamic_button)
	await process_frame
	check("runtime buttons receive pointing-hand cursor",
		dynamic_button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
	dynamic_button.queue_free()

	var count_before: int = rooms.switch_count
	_click_room_button(hud, button)
	await process_frame
	await process_frame

	check("dapur button changes room",
		current_scene != null and current_scene.name == "Dapur"
		and rooms.switch_count == count_before + 1)

	button = _room_button(current_scene.get_node("UILayer/HUD"))
	hud = current_scene.get_node("UILayer/HUD")
	check("dapur HUD lets world clicks through",
		hud != null and hud.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	check("dapur offers a kasir button", button != null and button.text == "KASIR")

	count_before = rooms.switch_count
	_click_room_button(hud, button)
	await process_frame
	await process_frame

	check("kasir button changes room",
		current_scene != null and current_scene.name == "Kasir"
		and rooms.switch_count == count_before + 1)


func _click_room_button(hud: Node, button: Button) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = button.get_global_rect().get_center()
	ev.pressed = true
	hud.call("_input", ev)


func _room_button(hud: Node) -> Button:
	var direct := hud.get_node_or_null("RoomButton") as Button
	if direct != null:
		return direct
	return hud.get_node_or_null("TopBar/Row/RoomButton") as Button


func _test_carry_limit() -> void:
	section("carrying")
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
	section("delivery")
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
	var purse_before: int = gs.money
	var queue_before: int = gs.queue.size()

	gs.deliver(brew, 0)

	check("customer leaves the queue", gs.queue.size() == queue_before - 1)
	check("delivery pays", gs.day_earnings > money_before)
	check("delivery immediately credits the purse", gs.money - purse_before == gs.day_earnings - money_before)
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


func _test_diagnosis_and_progression() -> void:
	section("diagnosis and progression")
	var gs := _state()
	gs.start_run()
	var order: Order = gs.queue[0]

	check("new order hides the answer behind an empty diagnosis",
		order.diagnosis.is_empty())
	var truth: Symptom.Code = order.symptoms()[0]
	check("player can pin a diagnosis", order.toggle_diagnosis(truth))
	check("working notes use the player's diagnosis",
		order.working_symptoms().has(truth))
	check("correct diagnosis scores full",
		is_equal_approx(order.diagnosis_accuracy(), 1.0))
	check("asking for a clue returns natural language",
		not order.next_clue().is_empty())
	# Runtime load is intentional: this SceneTree test installs its autoloads
	# before UI scripts that reference GameState are compiled.
	var board = load("res://Scenes/UI/diagnosis_board.tscn").instantiate()
	root.add_child(board)
	board.set_order(order)
	check("diagnosis board opens for the front customer", board.visible)
	order.diagnosis.clear()
	board.set_order(order)
	for i in range(4):
		var button: Button = board.diagnosis_grid.get_child(i)
		button.set_pressed_no_signal(true)
		button.pressed.emit()
	check("fourth diagnosis is refused by order state", order.diagnosis.size() == 3)
	check("refused fourth diagnosis is not visually pressed",
		not (board.diagnosis_grid.get_child(3) as Button).button_pressed)
	check("accepted diagnoses remain visually pressed",
		(board.diagnosis_grid.get_child(0) as Button).button_pressed)
	(board.diagnosis_grid.get_child(0) as Button).pressed.emit()
	(board.diagnosis_grid.get_child(3) as Button).pressed.emit()
	check("removing a diagnosis allows a replacement", order.diagnosis.has(3) and not order.diagnosis.has(0))
	order.diagnosis.assign([truth])
	board.set_order(order)
	board.close()
	check("diagnosis board can be closed without clearing the diagnosis",
		not board.visible and board.order == null and order.diagnosis.has(truth))
	board.queue_free()

	var ing_db := root.get_node("IngredientDB")
	var ing: IngredientData = ing_db.available_on_day(1)[0]
	var ings: Array[IngredientData] = [ing]
	var none: Array[Symptom.Code] = []
	var brew := Brew.create(ings, null, none, [1])
	check("used ingredients have a real cost", brew.ingredient_cost > 0)

	gs.day_earnings = 200
	gs.money = 200
	var day_before: int = gs.day
	gs.end_day()
	check("day end pauses on the preparation phase",
		gs.phase == gs.Phase.DAY_END)
	check("day end does not credit earnings twice", gs.money == 200)
	check("upgrade can be purchased", gs.buy_upgrade(&"pay"))
	check("shop purchase stays on day end and changes the run",
		gs.phase == gs.Phase.DAY_END and gs.day == day_before and gs.base_pay_bonus == 8)
	gs.money = 1000
	check("first pan upgrade adds a third pan", gs.buy_upgrade(&"pan") and gs.pan_slots == 3)
	check("second pan upgrade reaches four pans", gs.buy_upgrade(&"pan") and gs.pan_slots == 4)
	check("pan upgrades stop at four", not gs.buy_upgrade(&"pan") and gs.pan_slots == 4)
	gs.continue_without_upgrade()
	check("leaving the shop starts the next day",
		gs.day == day_before + 1 and gs.phase == gs.Phase.SHIFT)

	gs.start_run()


func _test_serat_selection() -> void:
	section("serat single selection")
	var book = load("res://Scenes/UI/serat_book.tscn").instantiate()
	root.add_child(book)
	book.open()
	var first: Button = book.symptom_grid.get_child(0)
	var second: Button = book.symptom_grid.get_child(1)
	first.set_pressed_no_signal(true)
	first.pressed.emit()
	second.set_pressed_no_signal(true)
	second.pressed.emit()
	check("selecting a symptom releases the previous button", not first.button_pressed and second.button_pressed)
	check("serat keeps only the focused symptom", book._selected_symptoms.size() == 1 and book._focused_symptom == 1)
	second.set_pressed_no_signal(false)
	second.pressed.emit()
	check("clicking the focused symptom preserves single selection", second.button_pressed and book._selected_symptoms.size() == 1)
	check("menstrual complaint uses a symptom name, not a gender",
		(book.symptom_grid.get_child(Symptom.Code.WANITA) as Button).text == "Nyeri Haid")
	check("serat symptom labels use readable font sizes", first.get_theme_font_size("font_size") >= 22)
	check("symptom explanation inherits the larger scene font",
		book.note_label.get_theme_font_size("normal_font_size") >= 26 and not "[font_size=" in book.note_label.text)
	book._change_page(book.Page.INGREDIENTS)
	book._select_ingredient(0)
	check("serat ingredient list uses readable font sizes",
		(book.ingredient_list.get_child(0).get_node("Margin/Row/Title") as Label).get_theme_font_size("font_size") >= 24)
	check("ingredient explanation does not override scene font size", not "[font_size=" in book.note_label.text)
	book.close()
	book.queue_free()


func _test_kitchen_readability() -> void:
	section("kitchen readability")
	var gs := _state()
	gs.start_run()
	var rooms := root.get_node("Rooms")
	rooms.go(rooms.Room.DAPUR)
	await scene_changed
	await create_timer(0.5).timeout
	var kitchen := current_scene
	var kitchen_hud = kitchen.hud
	var scroll: ScrollContainer = kitchen.get_node("IngredientScroll")
	var tray: IngredientTray = kitchen.get_node("IngredientScroll/Content/Tray")
	check("starting ingredients fit without scrolling",
		(scroll.get_node("Content") as Control).custom_minimum_size.y <= scroll.size.y)
	var sample: IngredientPiece = tray.get_node("Slots/Slot0/Piece")
	check("ingredient visuals fill the enlarged physical cells",
		(sample.get_node("VisualRoot/Cells/Cell0/Body") as Control).size.x == IngredientPiece.CELL)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	var pickup_position := sample.global_position + Vector2.ONE * IngredientPiece.CELL * 0.5
	click.position = root.get_final_transform() * pickup_position
	click.pressed = true
	var probe := ClickProbe.new()
	root.add_child(probe)
	root.push_input(click, true)
	await process_frame
	check("ingredient scroll lets real pickup clicks reach world input", probe.reached_world)
	probe.queue_free()
	# Headless Input has no OS mouse position; exercise the same pickup at
	# the simulated pointer explicitly after checking GUI propagation.
	if not kitchen.drag.is_dragging():
		kitchen.drag._pick(pickup_position)
	check("enlarged ingredient can be picked and leaves the clipped rack", kitchen.drag.is_dragging() and kitchen.drag._piece.get_parent() == kitchen.drag)
	kitchen.drag.set_enabled(false)
	kitchen.drag.set_enabled(true)
	tray.set_available(root.get_node("IngredientDB").available_on_day(7))
	await process_frame
	check("later days retain only the six illustrated ingredients",
		root.get_node("IngredientDB").available_on_day(7).size() == 6)
	scroll.scroll_vertical = 300
	await process_frame
	check("six ingredients still fit the rack on later days",
		(scroll.get_node("Content") as Control).custom_minimum_size.y <= scroll.size.y)
	check("two pans are available from day one", kitchen.panci.slot_count == 2)
	check("the two opening pans have separate click areas",
		not kitchen.panci.slot_rect(0).intersects(kitchen.panci.slot_rect(1)))
	var last_status: Control = kitchen.panci.get_node("Slots/Slot1/StatusLabel")
	var area: Control = kitchen.get_node("PanciArea")
	check("last pan status stays inside its station",
		last_status.get_global_rect().end.y <= area.get_global_rect().end.y)
	var cutter: ToolStation = kitchen.pipisan
	check("pipisan board and cut rail have clear physical sizes",
		cutter.zone().size.x >= 280.0 and (cutter.get_node("VerticalRail") as Control).size.x >= 4.0)
	var strip: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	check("visible blade still matches the actual cutting column",
		cutter.cut_col_for(strip, cutter.global_position - Vector2(IngredientPiece.CELL, 0)) == 1)
	check("pipisan shows its remaining uses as text",
		(cutter.get_node("Uses") as Label).text.begins_with("Jumlah pakai:"))
	check("heat control hides redundant size and keyboard labels",
		not kitchen.heat_slider.has_node("Fast")
		and not kitchen.heat_slider.has_node("Slow")
		and not kitchen.heat_slider.has_node("Keys"))
	check("unusable kuali action stays hidden",
		not kitchen.kuali.get_node("ActionButton").visible)
	gs.money = 40
	kitchen_hud._refresh()
	check("money count starts a tween instead of jumping",
		kitchen_hud._money_target == 40 and kitchen_hud._displayed_money < 40.0)
	await create_timer(0.8).timeout
	kitchen_hud._refresh()
	check("money count finishes at the real amount",
		roundi(kitchen_hud._displayed_money) == 40)


func _test_multiple_pans() -> void:
	section("multiple pans")
	var pan: Panci = current_scene.panci
	pan.set_process(false)
	var ingredient: IngredientData = root.get_node("IngredientDB").available_on_day(1)[0]
	var ingredients: Array[IngredientData] = [ingredient]
	var symptoms: Array[Symptom.Code] = []
	var first := Brew.create(ingredients, null, symptoms)
	var second := Brew.create(ingredients, null, symptoms)
	var potion_scene = load("res://Scenes/Item/potion.tscn")
	var a: Potion = potion_scene.instantiate()
	var b: Potion = potion_scene.instantiate()
	a.setup(first)
	b.setup(second)
	check("first brew enters the first pan", pan.put(a, 0))
	pan._process(5.0)
	check("second brew can enter while first is cooking", pan.put(b, 1))
	pan._process(5.0)
	check("both pans cook at the same time", first.doneness > 0.0 and second.doneness > 0.0)
	check("each pan retains its own cooking progress", first.doneness > second.doneness)
	var rooms := root.get_node("Rooms")
	rooms.go(rooms.Room.KASIR)
	await scene_changed
	await process_frame
	await process_frame
	rooms.go(rooms.Room.DAPUR)
	await scene_changed
	var restored: Panci = current_scene.panci
	check("room changes retain both active pans",
		restored.potions[0] != null and restored.potions[1] != null
		and restored.potions[0].brew == first and restored.potions[1].brew == second)
	check("room changes retain independent cooking progress", first.doneness > second.doneness)
