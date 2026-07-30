extends SceneTree

## Simulates full order cycles without a renderer: build a kuali, greedily
## fill it with sensible ingredients, evaluate, then simmer in the panci.
## Catches integration bugs the unit tests cannot see.

var failures := 0
var rng := RandomNumberGenerator.new()


func _init() -> void:
	print("=== ACARAKI simulation ===")
	rng.seed = 4242

	var ing_db = load("res://Scripts/Data/ingredient_db.gd").new()
	ing_db._build()
	var cust_db = load("res://Scripts/Data/customer_db.gd").new()
	cust_db._build()

	var total := 0
	var filled_count := 0
	var accuracy_sum := 0.0
	var impossible_heat := 0

	for day in [1, 3, 6, 10]:
		var pool: Array = ing_db.available_on_day(day)
		for c in cust_db.all:
			var v = c.pick_variant(day, rng)
			if v == null:
				continue
			total += 1

			var outcome := _run_order(pool, v.symptoms, day)
			if outcome["filled"]:
				filled_count += 1
			accuracy_sum += outcome["accuracy"]
			if not outcome["heat_ok"]:
				impossible_heat += 1

			if not outcome["filled"]:
				print("  note: could not fill kuali for %s day %d (left %d)"
					% [c.display_name, day, outcome["empty"]])

	print("- Orders simulated: %d" % total)
	print("- Kuali filled:     %d (%.0f%%)" % [filled_count, 100.0 * filled_count / total])
	print("- Mean accuracy:    %.2f" % (accuracy_sum / total))
	print("- Impossible heat:  %d" % impossible_heat)

	_check("most orders can be filled", float(filled_count) / total >= 0.75)
	_check("greedy play scores well", accuracy_sum / total >= 0.7)
	# A brew that can never be simmered correctly is a dead end, so most
	# natural combinations must leave a workable window.
	_check("most brews have a workable heat window (%d/%d impossible)"
		% [impossible_heat, total], float(impossible_heat) / total <= 0.15)

	_report_conflicts(ing_db)

	_test_panci_cycle()
	_test_burn()

	print("=== %s ===" % ("SIMULATION OK" if failures == 0 else "%d FAILURE(S)" % failures))
	quit(1 if failures > 0 else 0)


## Lists ingredient pairs whose heat windows do not overlap. Some tension
## is good design; a pair that shares a symptom and cannot co-exist is not,
## because the player gets punished for a sensible choice.
func _report_conflicts(ing_db) -> void:
	var hard: Array[String] = []
	for i in range(ing_db.all.size()):
		for j in range(i + 1, ing_db.all.size()):
			var a: IngredientData = ing_db.all[i]
			var b: IngredientData = ing_db.all[j]
			if a.heat_flexible or b.heat_flexible:
				continue
			var w := RecipeEvaluator.heat_window([a, b])
			if w.x > w.y:
				var shares := false
				for s in a.treats:
					if b.treats_symptom(s):
						shares = true
						break
				hard.append("%s+%s%s" % [a.display_name, b.display_name,
					"  <-- shares a symptom!" if shares else ""])

	if hard.is_empty():
		print("  ok   no impossible ingredient pairs")
	else:
		print("  note: %d impossible pairs:" % hard.size())
		for h in hard:
			print("        %s" % h)


func _check(label: String, cond: bool) -> void:
	if cond:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		failures += 1


## Greedy player: pick ingredients that treat the wanted symptoms, then
## fill leftover space with rice (the 1x1 gap filler).
func _run_order(pool: Array, wanted: Array, day: int) -> Dictionary:
	var shape := KualiShape.random_shape(rng)

	var chosen: Array[IngredientData] = []
	var used := {}
	for s in wanted:
		for ing in pool:
			if used.has(ing.ingredient_id):
				continue
			if ing.treats_symptom(s):
				chosen.append(ing)
				used[ing.ingredient_id] = true
				break

	var needed: Array = []
	var required_area := 0
	for ing in chosen:
		needed.append(ing.shape_cells.duplicate())
		required_area += ing.shape_cells.size()

	var budget := KualiShape.residue_budget(shape.size(), day, required_area)
	var residue := KualiShape.generate_residue(shape, budget, needed, rng)

	# Build the grid the same way KualiGrid.build does.
	var grid := {}
	for c in shape:
		grid[c] = 0
	for c in residue:
		grid[c] = -1

	var placed: Array[IngredientData] = []
	var id := 1

	for ing in chosen:
		if _try_place(grid, ing.shape_cells, id):
			placed.append(ing)
			id += 1

	# Fill remaining space with rice.
	var rice: IngredientData = null
	for ing in pool:
		if ing.ingredient_id == &"beras":
			rice = ing
			break

	if rice:
		var guard := 0
		while GridLogic.count_empty(grid) > 0 and guard < 200:
			if not _try_place(grid, rice.shape_cells, id):
				break
			placed.append(rice)
			id += 1
			guard += 1

	var result := RecipeEvaluator.evaluate(placed, wanted)

	return {
		"filled": GridLogic.is_full(grid),
		"empty": GridLogic.count_empty(grid),
		"accuracy": result.accuracy,
		"heat_ok": result.has_valid_heat_window(),
	}


func _try_place(grid: Dictionary, cells: Array[Vector2i], id: int) -> bool:
	var variant := cells.duplicate()
	for r in range(4):
		for cell in grid.keys():
			var anchor := cell as Vector2i
			var origin: Vector2i = anchor - variant[0]
			if GridLogic.can_place(grid, variant, origin.x, origin.y):
				GridLogic.place(grid, variant, origin.x, origin.y, id)
				return true
		variant = GridLogic.rotate_cw(variant)
	return false


func _test_panci_cycle() -> void:
	print("- Panci simmering")
	var S := Symptom.Code
	var ing := IngredientData.create(&"x", "Test", "", [Vector2i(0, 0)],
		Color.WHITE, [S.DEMAM], 0, Vector2(0.4, 0.6), "")

	var brew := Brew.new()
	brew.result = RecipeEvaluator.evaluate([ing], [S.DEMAM])
	brew.customer = CustomerData.new()

	# Simmer at the ideal temperature.
	var t := 0.0
	var heat := 0.5
	while brew.doneness < 1.0 and t < 30.0:
		brew.doneness += brew.cook_rate * 0.1
		t += 0.1
	_check("brew reaches done at ideal heat", brew.doneness >= 1.0)
	_check("takes a sensible time (%.1fs)" % t, t > 2.0 and t < 12.0)
	_check("ideal heat detected", brew.is_heat_ideal(heat))
	_check("cold heat rejected", not brew.is_heat_ideal(0.1))

	brew.doneness = 1.0
	_check("done brew earns bonus", brew.doneness_bonus() > 1.0)

	var raw := Brew.new()
	raw.result = brew.result
	raw.doneness = 0.4
	_check("raw brew penalised", raw.doneness_bonus() < 1.0)


func _test_burn() -> void:
	print("- Burning")
	var S := Symptom.Code
	var cool := IngredientData.create(&"c", "Beras", "", [Vector2i(0, 0)],
		Color.WHITE, [S.LEMAH], 0, Vector2(0.0, 0.4), "")

	var brew := Brew.new()
	brew.result = RecipeEvaluator.evaluate([cool], [S.LEMAH])
	brew.customer = CustomerData.new()

	# Hold the heat well above the window.
	var heat := 1.0
	var t := 0.0
	while brew.burn < 1.0 and t < 60.0:
		brew.burn += (heat - brew.heat_window().y) * Panci.BURN_RATE * 0.1
		t += 0.1

	_check("overheating burns the brew", brew.burn >= 1.0)
	_check("burning is not instant (%.1fs)" % t, t > 1.5)

	brew.is_burnt = true
	_check("burnt brew heavily penalised", brew.doneness_bonus() < 0.5)
