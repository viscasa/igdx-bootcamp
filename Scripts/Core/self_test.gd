extends SceneTree

## Headless sanity checks for the pure-logic layer.
## Run: godot --headless --script res://Scripts/Core/self_test.gd

var failures := 0


func _init() -> void:
	print("=== ACARAKI self-test ===")
	_test_grid_logic()
	_test_rotation()
	_test_evaluator()
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

	# Perfect match
	var r1 := RecipeEvaluator.evaluate([brotowali], [S.DEMAM])
	check("full accuracy on exact match", is_equal_approx(r1.accuracy, 1.0))
	check("grade reads correct", r1.grade() == "Racikan Tepat")

	# Partial
	var r2 := RecipeEvaluator.evaluate([brotowali], [S.DEMAM, S.BATUK])
	check("half accuracy on partial", is_equal_approx(r2.accuracy, 0.5))
	check("missed symptom reported", r2.missed.has(S.BATUK))

	# Complete miss
	var r3 := RecipeEvaluator.evaluate([kencur], [S.DEMAM])
	check("zero accuracy on miss", is_equal_approx(r3.accuracy, 0.0))
	check("covered empty", r3.covered.is_empty())

	# Two ingredients cover two symptoms
	var r4 := RecipeEvaluator.evaluate([brotowali, kencur], [S.DEMAM, S.BATUK])
	check("compound symptoms covered", is_equal_approx(r4.accuracy, 1.0))

	# Sweetening raises palatability
	var bitter := RecipeEvaluator.palatability([brotowali])
	var sweetened := RecipeEvaluator.palatability([brotowali, gula])
	check("gula jawa improves palatability", sweetened > bitter)


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

	var perfect := RecipeEvaluator.evaluate([good], [S.DEMAM])
	var wrong := RecipeEvaluator.evaluate([good], [S.BATUK])

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
