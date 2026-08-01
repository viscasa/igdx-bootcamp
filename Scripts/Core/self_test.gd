extends SceneTree

## Headless sanity checks for the pure-logic layer.
## Run: godot --headless --script res://Scripts/Core/self_test.gd

var failures := 0


func _init() -> void:
	print("=== ACARAKI self-test ===")
	_test_grid_logic()
	_test_rotation()
	_test_evaluator()
	_test_potency()
	_test_tools()
	_test_heat_window()
	_test_payment()
	_test_shapes_and_residue()
	_test_databases()

	print("=== %s ===" % ("ALL PASSED" if failures == 0 else "%d FAILURE(S)" % failures))
	quit(1 if failures > 0 else 0)


func check(label: String, cond: bool) -> void:
	if cond:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		failures += 1


func _test_grid_logic() -> void:
	print("- GridLogic")
	var grid := {}
	for x in range(3):
		for y in range(3):
			grid[Vector2i(x, y)] = 0

	var shape: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]

	check("place inside grid", GridLogic.can_place(grid, shape, 0, 0))
	check("reject out of bounds", not GridLogic.can_place(grid, shape, 2, 0))

	GridLogic.place(grid, shape, 0, 0, 7)
	check("cells marked", grid[Vector2i(0, 0)] == 7 and grid[Vector2i(1, 0)] == 7)
	check("reject overlap", not GridLogic.can_place(grid, shape, 0, 0))
	check("not full yet", not GridLogic.is_full(grid))
	check("empty count 7", GridLogic.count_empty(grid) == 7)

	GridLogic.remove(grid, 7)
	check("removal clears", grid[Vector2i(0, 0)] == 0)

	# Fill everything
	var one: Array[Vector2i] = [Vector2i(0, 0)]
	var id := 1
	for x in range(3):
		for y in range(3):
			GridLogic.place(grid, one, x, y, id)
			id += 1
	check("is_full detects full", GridLogic.is_full(grid))

	var b := GridLogic.bounds(grid)
	check("bounds 3x3", b.size == Vector2i(3, 3))


func _test_rotation() -> void:
	print("- Rotation")
	# L-piece
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
	check("shape is 2x3", GridLogic.shape_size(cells) == Vector2i(2, 3))

	var r1 := GridLogic.rotate_cw(cells)
	check("rotated is 3x2", GridLogic.shape_size(r1) == Vector2i(3, 2))
	check("cell count preserved", r1.size() == cells.size())

	var r4 := GridLogic.rotate_cw(GridLogic.rotate_cw(GridLogic.rotate_cw(r1)))
	var a := cells.duplicate()
	var b := r4.duplicate()
	a.sort()
	b.sort()
	check("4 rotations return to origin", a == b)

	# Normalization keeps things anchored at 0,0
	var off: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	var n := GridLogic.normalize(off)
	check("normalize anchors at origin", n.has(Vector2i(0, 0)) and n.has(Vector2i(1, 0)))


func _test_evaluator() -> void:
	print("- RecipeEvaluator")
	var S := Symptom.Code

	var brotowali := IngredientData.create(&"b", "Brotowali", "", [Vector2i(0,0)],
		Color.WHITE, [S.DEMAM, S.KULIT], 5, Vector2(0.6, 1.0), "")
	var kencur := IngredientData.create(&"k", "Kencur", "", [Vector2i(0,0)],
		Color.WHITE, [S.BATUK, S.NYERI_SENDI], 2, Vector2(0.2, 0.6), "")
	var gula := IngredientData.create(&"gula_jawa", "Gula", "", [Vector2i(0,0)],
		Color.WHITE, [], 0, Vector2(0.0, 0.5), "")

	# Perfect match. Demand is symptom -> required potency in cells; these
	# test ingredients are 1x1, so a dose of 1 is exactly enough.
	var r1 := RecipeEvaluator.evaluate([brotowali], {S.DEMAM: 1})
	check("full accuracy on exact match", is_equal_approx(r1.accuracy, 1.0))
	check("grade reads correct", r1.grade() == "Racikan Tepat")

	# Partial
	var r2 := RecipeEvaluator.evaluate([brotowali], {S.DEMAM: 1, S.BATUK: 1})
	check("half accuracy on partial", is_equal_approx(r2.accuracy, 0.5))
	check("missed symptom reported", r2.missed.has(S.BATUK))

	# Complete miss
	var r3 := RecipeEvaluator.evaluate([kencur], {S.DEMAM: 1})
	check("zero accuracy on miss", is_equal_approx(r3.accuracy, 0.0))
	check("covered empty", r3.covered.is_empty())

	# Two ingredients cover two symptoms
	var r4 := RecipeEvaluator.evaluate([brotowali, kencur], {S.DEMAM: 1, S.BATUK: 1})
	check("compound symptoms covered", is_equal_approx(r4.accuracy, 1.0))

	# Sweetening raises palatability
	var bitter := RecipeEvaluator.palatability([brotowali])
	var sweetened := RecipeEvaluator.palatability([brotowali, gula])
	check("gula jawa improves palatability", sweetened > bitter)


## Potency is the system that ties ingredient SIZE to healing power, so
## these checks guard the property the whole design rests on: a bigger
## piece must heal more, and a cut piece must heal less.
func _test_potency() -> void:
	print("- Potency")
	var S := Symptom.Code

	var big := IngredientData.create(&"big", "Kunyit", "",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		Color.WHITE, [S.PENCERNAAN], 0, Vector2(0.0, 1.0), "")
	var small := IngredientData.create(&"small", "Beras", "", [Vector2i(0,0)],
		Color.WHITE, [S.PENCERNAAN], 0, Vector2(0.0, 1.0), "")

	var p := RecipeEvaluator.potency([big])
	check("4-cell ingredient supplies 4 potency", int(p.get(S.PENCERNAAN, 0)) == 4)

	var p2 := RecipeEvaluator.potency([small, small, small])
	check("three 1-cell pieces supply 3", int(p2.get(S.PENCERNAAN, 0)) == 3)

	# Severity gating
	var enough := RecipeEvaluator.evaluate([big], {S.PENCERNAAN: 4})
	check("exact dose is full accuracy", is_equal_approx(enough.accuracy, 1.0))

	var under := RecipeEvaluator.evaluate([small], {S.PENCERNAAN: 4})
	check("under-dose scores proportionally", is_equal_approx(under.accuracy, 0.25))
	check("under-dose reported as partial", under.partial.has(S.PENCERNAAN))
	check("partial records supplied/required",
		under.partial[S.PENCERNAAN][0] == 1 and under.partial[S.PENCERNAAN][1] == 4)

	# Overdosing is allowed and simply wasted — never a penalty.
	var over := RecipeEvaluator.evaluate([big, big], {S.PENCERNAAN: 4})
	check("overdose is not punished", is_equal_approx(over.accuracy, 1.0))

	# A cut piece must count for less. This is the honesty check on the
	# cutter: halving a shape must halve what it heals.
	var halved := RecipeEvaluator.evaluate([big], {S.PENCERNAAN: 4}, [2])
	check("cut piece supplies fewer cells", is_equal_approx(halved.accuracy, 0.5))

	# Live progress feed for the HUD meters.
	var prog := RecipeEvaluator.progress([big], {S.PENCERNAAN: 5})
	check("progress reports supplied and required",
		prog[S.PENCERNAAN][0] == 4 and prog[S.PENCERNAAN][1] == 5)

	# Day ramp: the opening days must stay at dose 1 so potency introduces
	# itself gradually rather than all at once.
	var v := RequestVariant.create("x", [S.PENCERNAAN], 1, {S.PENCERNAAN: 5})
	var c := CustomerData.new()
	c.customer_id = &"t"
	c.display_name = "T"
	c.base_patience = 60.0
	check("day 1 pins dose to 1", Order.create(c, v, 1.0, 1).required_potency(S.PENCERNAAN) == 1)
	check("day 3 caps dose at 2", Order.create(c, v, 1.0, 3).required_potency(S.PENCERNAAN) == 2)
	check("day 6 uses full severity", Order.create(c, v, 1.0, 6).required_potency(S.PENCERNAAN) == 5)


func _test_tools() -> void:
	print("- Tools")

	var kit := ToolKit.new()
	var start := kit.remaining(ToolKit.Kind.PIPISAN)
	check("pipisan starts with a budget", start > 0)
	check("consume succeeds while stocked", kit.consume(ToolKit.Kind.PIPISAN))
	check("consume decrements", kit.remaining(ToolKit.Kind.PIPISAN) == start - 1)

	while kit.can_use(ToolKit.Kind.PIPISAN):
		kit.consume(ToolKit.Kind.PIPISAN)
	check("exhausted tool refuses use", not kit.consume(ToolKit.Kind.PIPISAN))
	check("exhausted tool reports zero", kit.remaining(ToolKit.Kind.PIPISAN) == 0)

	kit.refill()
	check("refill restores the daily budget",
		kit.remaining(ToolKit.Kind.PIPISAN) == start)

	check("pipisan is the only tool", ToolKit.BASE_USES.size() == 1)

	# The blade falls vertically, so only column width can be split. A tall
	# 1x4 bar has one column and must be rotated first — same rule as
	# Waste Crusher's cutter.
	var bar: Array[Vector2i] = [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)]
	check("1-wide column cannot be cut", not ToolKit.can_cut(bar))
	check("cutting a 1-wide column returns nothing", ToolKit.cut(bar).is_empty())

	var wide: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
	check("4-wide bar can be cut", ToolKit.can_cut(wide))
	check("cut width reads the x axis", ToolKit.cut_width(wide) == 4)

	# Cells must be conserved, or the cutter becomes a way to create or
	# destroy healing power out of nothing.
	var halves := ToolKit.cut(wide)
	check("cut returns two halves", halves.size() == 2)
	var total := (halves[0] as Array).size() + (halves[1] as Array).size()
	check("cut conserves cell count", total == wide.size())

	# The column chooses where the split lands — that is the whole mechanic.
	var at1 := ToolKit.cut_at(wide, 1)
	check("cut at column 1 yields 1 + 3",
		(at1[0] as Array).size() == 1 and (at1[1] as Array).size() == 3)

	var at3 := ToolKit.cut_at(wide, 3)
	check("cut at column 3 yields 3 + 1",
		(at3[0] as Array).size() == 3 and (at3[1] as Array).size() == 1)

	# Out-of-range columns clamp instead of producing an empty half.
	var clamped := ToolKit.cut_at(wide, 99)
	check("out-of-range column clamps to a real cut",
		clamped.size() == 2 and not (clamped[0] as Array).is_empty()
		and not (clamped[1] as Array).is_empty())

	var grain: Array[Vector2i] = [Vector2i(0,0)]
	check("1x1 cannot be cut", ToolKit.cut(grain).is_empty())

	# Halves come back normalised, ready to place in the pot.
	var origin_ok := true
	for h in halves:
		if not (h as Array).has(Vector2i(0, 0)):
			origin_ok = false
	check("halves are normalised to origin", origin_ok)


func _test_heat_window() -> void:
	print("- Heat windows")
	var hot := IngredientData.create(&"h", "Jahe", "", [Vector2i(0,0)],
		Color.WHITE, [], 0, Vector2(0.7, 1.0), "")
	var cool := IngredientData.create(&"c", "Beras", "", [Vector2i(0,0)],
		Color.WHITE, [], 0, Vector2(0.0, 0.4), "")
	var mid := IngredientData.create(&"m", "Kunyit", "", [Vector2i(0,0)],
		Color.WHITE, [], 0, Vector2(0.3, 0.6), "")

	var w1 := RecipeEvaluator.heat_window([hot])
	check("single ingredient keeps its window", w1 == Vector2(0.7, 1.0))

	var w2 := RecipeEvaluator.heat_window([hot, cool])
	check("hot + cool is impossible (lo > hi)", w2.x > w2.y)

	var w3 := RecipeEvaluator.heat_window([cool, mid])
	check("overlapping windows intersect", w3.x <= w3.y)
	check("intersection is 0.3..0.4", is_equal_approx(w3.x, 0.3) and is_equal_approx(w3.y, 0.4))


func _test_payment() -> void:
	print("- Payment")
	var S := Symptom.Code
	var good := IngredientData.create(&"g", "X", "", [Vector2i(0,0)],
		Color.WHITE, [S.DEMAM], 0, Vector2(0.0, 1.0), "")

	var perfect := RecipeEvaluator.evaluate([good], {S.DEMAM: 1})
	var wrong := RecipeEvaluator.evaluate([good], {S.BATUK: 1})

	var pay_perfect := RecipeEvaluator.payment(40, perfect, 1.0, 1.0, 1.0)
	var pay_wrong := RecipeEvaluator.payment(40, wrong, 1.0, 1.0, 1.0)

	check("correct brew pays more", pay_perfect > pay_wrong)
	check("wrong brew still pays (never zero)", pay_wrong > 0)

	var pay_slow := RecipeEvaluator.payment(40, perfect, 0.0, 1.0, 1.0)
	check("patience left increases pay", pay_perfect > pay_slow)

	var pay_burnt := RecipeEvaluator.payment(40, perfect, 1.0, 1.0, 0.4)
	check("burnt brew pays less", pay_burnt < pay_perfect)


func _test_shapes_and_residue() -> void:
	print("- Kuali shapes & residue")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	for name_ in KualiShape.SHAPES.keys():
		var shape := KualiShape.get_shape(name_)
		check("shape '%s' non-empty" % name_, shape.size() > 0)

	var shape := KualiShape.get_shape("bulat")

	# Residue must leave room for what has to fit.
	var needed: Array = [
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],   # 1x4
		[Vector2i(0,0), Vector2i(1,0)],                                  # 2x1
	]
	var required_area := 6

	for day in [1, 3, 5, 8, 12]:
		var budget := KualiShape.residue_budget(shape.size(), day, required_area)
		var residue := KualiShape.generate_residue(shape, budget, needed, rng)
		var free := shape.size() - residue.size()
		check("day %d leaves room (free %d >= needed %d)" % [day, free, required_area],
			free >= required_area)

	# The solver must reject a board that genuinely cannot fit the pieces.
	var tiny: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0)]
	var too_big: Array = [[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)]]
	var impossible := KualiShape.generate_residue(tiny, 1, too_big, rng)
	check("unsolvable board yields no residue", impossible.is_empty())


func _test_databases() -> void:
	print("- Databases")
	var ing_db = load("res://Scripts/Data/ingredient_db.gd").new()
	ing_db._build()
	check("12 ingredients defined", ing_db.all.size() == 12)

	var seen := {}
	var shapes_ok := true
	var treats_ok := true
	for ing in ing_db.all:
		if seen.has(ing.ingredient_id):
			check("duplicate id: %s" % ing.ingredient_id, false)
		seen[ing.ingredient_id] = true
		if ing.shape_cells.is_empty():
			shapes_ok = false
		if ing.heat_min > ing.heat_max:
			check("bad heat range on %s" % ing.ingredient_id, false)
		# Only gula jawa is allowed to treat nothing.
		if ing.treats.is_empty() and ing.ingredient_id != &"gula_jawa":
			treats_ok = false

	check("all ingredients have a shape", shapes_ok)
	check("all but gula jawa treat something", treats_ok)

	# Every symptom must be treatable by at least one ingredient, or a
	# customer could ask for something impossible.
	var coverage := {}
	for ing in ing_db.all:
		for s in ing.treats:
			coverage[s] = true
	var uncovered: Array[String] = []
	for s in Symptom.Code.values():
		if not coverage.has(s):
			uncovered.append(Symptom.display_name(s))
	check("every symptom is treatable%s" % ("" if uncovered.is_empty() else " (missing: %s)" % ", ".join(uncovered)),
		uncovered.is_empty())

	var cust_db = load("res://Scripts/Data/customer_db.gd").new()
	cust_db._build()
	check("8 customers defined", cust_db.all.size() == 8)

	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var variants_ok := true
	var dialogue_ok := true
	for c in cust_db.all:
		if c.variants.is_empty():
			variants_ok = false
		for v in c.variants:
			if v.symptoms.is_empty() or v.dialogue.strip_edges().is_empty():
				dialogue_ok = false
	check("all customers have variants", variants_ok)
	check("all variants have dialogue + symptoms", dialogue_ok)

	# Day-1 players must be able to solve day-1 orders with day-1 ingredients.
	var day1_ing: Array = ing_db.available_on_day(1)
	check("day 1 offers the core 8", day1_ing.size() == 8)
	check("day 4 offers all 12", ing_db.available_on_day(4).size() == 12)

	var day1_cover := {}
	for ing in day1_ing:
		for s in ing.treats:
			day1_cover[s] = true

	var unsolvable: Array[String] = []
	for c in cust_db.all:
		for v in c.variants:
			if v.min_day > 1:
				continue
			for s in v.symptoms:
				if not day1_cover.has(s):
					unsolvable.append("%s/%s" % [c.display_name, Symptom.display_name(s)])
	check("every day-1 request is solvable with day-1 ingredients%s"
		% ("" if unsolvable.is_empty() else " (gaps: %s)" % ", ".join(unsolvable)),
		unsolvable.is_empty())
