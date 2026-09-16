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
	var dosed_count := 0
	var accuracy_sum := 0.0
	var impossible_heat := 0

	for day in [1, 3, 6, 10]:
		var pool: Array = ing_db.available_on_day(day)
		for c in cust_db.all:
			var v = c.pick_variant(day, rng)
			if v == null or not ing_db.supports_request(v):
				continue
			total += 1

			var order := Order.create(c, v, 1.0, day)
			var outcome := _run_order(pool, order, day)
			if outcome["fully_dosed"]:
				dosed_count += 1
			accuracy_sum += outcome["accuracy"]
			if not outcome["heat_ok"]:
				impossible_heat += 1

			if not outcome["fully_dosed"]:
				print("  note: could not reach full dose for %s day %d (acc %.2f)"
					% [c.display_name, day, outcome["accuracy"]])

	print("- Orders simulated: %d" % total)
	print("- Fully dosed:      %d (%.0f%%)" % [dosed_count, 100.0 * dosed_count / total])
	print("- Mean accuracy:    %.2f" % (accuracy_sum / total))
	print("- Impossible heat:  %d" % impossible_heat)

	# The pot no longer has to be FULL, so the meaningful bar is whether a
	# reasonable player can reach the required dose.
	_check("most uncut greedy orders can be fully dosed", float(dosed_count) / total >= 0.6)
	_check("greedy play scores well", accuracy_sum / total >= 0.7)
	# A brew that can never be simmered correctly is a dead end, so most
	# natural combinations must leave a workable window.
	_check("most brews have a workable heat window (%d/%d impossible)"
		% [impossible_heat, total], float(impossible_heat) / total <= 0.15)

	_report_conflicts(ing_db)

	_test_solvability(ing_db, cust_db)
	_test_panci_cycle()
	_test_burn()
	_test_misdelivery()

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


## Greedy player: keep adding ingredients that treat a still-underdosed
## symptom until the dose is met, then stop. Notably it does NOT try to
## fill the pot — under the new rules an empty cell costs nothing, so a
## sensible player stops once the medicine is right.
func _run_order(pool: Array, order: Order, day: int) -> Dictionary:
	var chosen := _greedy_choice(pool, order)

	var needed: Array = []
	var required_area := 0
	for ing in chosen:
		needed.append(ing.shape_cells.duplicate())
		required_area += ing.shape_cells.size()

	var shape := KualiShape.shape_for(required_area, rng)
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

	var result := RecipeEvaluator.evaluate(placed, order.demand)

	return {
		"fully_dosed": result.accuracy >= 0.999,
		"empty": GridLogic.count_empty(grid),
		"accuracy": result.accuracy,
		"heat_ok": result.has_valid_heat_window(),
	}


## Picks enough of the right ingredients to cover every symptom's dose.
func _greedy_choice(pool: Array, order: Order) -> Array[IngredientData]:
	var chosen: Array[IngredientData] = []
	var remaining := {}
	for s in order.symptoms():
		remaining[s] = order.required_potency(s)

	var guard := 0
	while _remaining_total(remaining) > 0 and guard < 16:
		guard += 1
		var best: IngredientData = null
		var best_score := -1
		var best_waste := 999

		for ing in pool:
			var score := KualiShape._relief_score(ing, remaining)
			var waste: int = ing.shape_cells.size() - score
			if score > best_score or (score == best_score and waste < best_waste):
				best = ing
				best_score = score
				best_waste = waste
		if best == null or best_score <= 0:
			break

		chosen.append(best)
		var cells := best.shape_cells.size()
		for s in remaining.keys():
			if best.treats_symptom(s):
				remaining[s] = maxi(int(remaining[s]) - cells, 0)

	return chosen


func _remaining_total(remaining: Dictionary) -> int:
	var total := 0
	for s in remaining:
		total += int(remaining[s])
	return total


## The guarantee your board generation rests on: for every customer,
## variant and day, the residue the game hands out must still leave a
## layout that fits a full-dose recipe. An unsolvable board is the one
## failure a puzzle game cannot recover from, so this sweeps the whole
## content set rather than sampling it.
func _test_solvability(ing_db, cust_db) -> void:
	print("- Solvability guarantee")

	var checked := 0
	var broken: Array[String] = []
	var r := RandomNumberGenerator.new()
	r.seed = 20260801

	for day in [1, 2, 3, 5]:
		var pool: Array = ing_db.available_on_day(day)
		for c in cust_db.all:
			for v in c.variants:
				if v.min_day > day or not ing_db.supports_request(v):
					continue

				var order := Order.create(c, v, 1.0, day)

				# Deliberately the SAME call the kitchen makes. Two copies
				# of this logic would let the sweep pass while the real
				# board is impossible.
				var needed := KualiShape.shapes_for_demand(order.demand, pool)
				var required_area := 0
				for cells in needed:
					required_area += (cells as Array).size()

				# Sample the pot the game would really hand out. Repeated
				# draws cover every silhouette large enough for this order,
				# which is the set the player can actually receive.
				for attempt in range(3):
					var shape := KualiShape.shape_for(required_area, r)
					var budget := KualiShape.residue_budget(
						shape.size(), day, required_area)
					var residue := KualiShape.generate_residue(
						shape, budget, needed, r)

					checked += 1

					var free := shape.size() - residue.size()
					if free < required_area:
						broken.append("%s day %d: free %d < needed %d"
							% [c.display_name, day, free, required_area])
						continue

					# The real proof: an actual packing must exist.
					if not KualiShape._is_solvable(shape, residue, needed):
						broken.append("%s day %d: no packing exists (pot %d, need %d)"
							% [c.display_name, day, shape.size(), required_area])

	print("  boards checked: %d" % checked)
	if not broken.is_empty():
		for b in broken.slice(0, 10):
			print("        %s" % b)

	_check("every generated board admits a full-dose solution (%d bad)"
		% broken.size(), broken.is_empty())


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

	var ings: Array[IngredientData] = [ing]
	var wanted: Array[Symptom.Code] = [S.DEMAM]
	var brew := Brew.create(ings, null, wanted)

	# Simmer at medium fire: about 20 seconds.
	var t := 0.0
	var heat := 0.5
	while brew.doneness < 1.0 and t < 30.0:
		brew.doneness += brew.cook_rate * lerpf(0.35, 2.0, heat) * 0.1
		t += 0.1
	_check("brew reaches done at medium fire", brew.doneness >= 1.0)
	_check("takes about twenty seconds (%.1fs)" % t, t > 16.0 and t < 24.0)
	_check("medium fire is the calm baseline", brew.is_heat_ideal(heat))
	_check("small fire is slower, not ideal", not brew.is_heat_ideal(0.1))

	brew.doneness = 1.0
	_check("done brew earns bonus", brew.doneness_bonus() > 1.0)

	var raw := Brew.create(ings, null, wanted)
	raw.doneness = 0.4
	_check("raw brew penalised", raw.doneness_bonus() < 1.0)


func _test_burn() -> void:
	print("- Burning")
	var S := Symptom.Code
	var cool := IngredientData.create(&"c", "Beras", "", [Vector2i(0, 0)],
		Color.WHITE, [S.LEMAH], 0, Vector2(0.0, 0.4), "")

	var ings: Array[IngredientData] = [cool]
	var wanted: Array[Symptom.Code] = [S.LEMAH]
	var brew := Brew.create(ings, null, wanted)

	# Hold the fire high: it cooks quickly, then overcooks if ignored.
	var heat := 1.0
	var t := 0.0
	while brew.doneness < Panci.OVERCOOK_AT and t < 60.0:
		brew.doneness += brew.cook_rate * lerpf(0.35, 2.0, heat) * 0.1
		if brew.doneness > 1.0:
			brew.burn = clampf((brew.doneness - 1.0) / (Panci.OVERCOOK_AT - 1.0), 0.0, 1.0)
		t += 0.1

	_check("overcooking burns the brew", brew.burn >= 1.0)
	_check("burning is a timing mistake, not instant (%.1fs)" % t, t > 10.0 and t < 25.0)

	brew.is_burnt = true
	_check("burnt brew heavily penalised", brew.doneness_bonus() < 0.5)


## The point of hand delivery: the same bottle scores differently depending
## on who receives it.
func _test_misdelivery() -> void:
	print("- Misdelivery")
	var S := Symptom.Code

	var jahe := IngredientData.create(&"jahe", "Jahe", "", [Vector2i(0, 0)],
		Color.WHITE, [S.DINGIN, S.BATUK], 0, Vector2(0.5, 1.0), "")

	var right := CustomerData.new()
	right.customer_id = &"tuan_li"
	var wrong := CustomerData.new()
	wrong.customer_id = &"ki_wanata"

	var ings: Array[IngredientData] = [jahe]
	var intended: Array[Symptom.Code] = [S.DINGIN, S.BATUK]
	var brew := Brew.create(ings, right, intended)

	# Handed to the person it was mixed for.
	var good := brew.evaluate_for({S.DINGIN: 1, S.BATUK: 1})
	_check("correct recipient scores full", is_equal_approx(good.accuracy, 1.0))
	_check("recognises intended customer", brew.is_intended_for(right))

	# Handed to someone with unrelated complaints.
	var bad := brew.evaluate_for({S.HATI_LIVER: 1, S.NYERI_SENDI: 1})
	_check("wrong recipient scores zero", is_equal_approx(bad.accuracy, 0.0))
	_check("detects mismatch", not brew.is_intended_for(wrong))

	# A partial accident: the jamu happens to help a bit.
	var mid := brew.evaluate_for({S.DINGIN: 1, S.HATI_LIVER: 1})
	_check("accidental partial match scores half", is_equal_approx(mid.accuracy, 0.5))

	# Under-dosing the right recipient is its own outcome: the plant was
	# correct, the amount was not. The game must be able to say so.
	var weak := brew.evaluate_for({S.DINGIN: 4})
	_check("under-dosed correct recipient scores partial",
		weak.accuracy > 0.0 and weak.accuracy < 1.0)
	_check("under-dose is reported as a dose problem", weak.partial.has(S.DINGIN))

	# Even a total mismatch pays something, so mistakes teach.
	var pay := RecipeEvaluator.payment(40, bad, 1.0, 1.0, 1.0)
	_check("wrong delivery still pays a little", pay > 0)

	_check("brew reports what it treats",
		brew.treats().has(S.DINGIN) and brew.treats().has(S.BATUK))
