class_name RecipeEvaluator

## Pure scoring. No nodes, so it can be tuned and tested in isolation —
## this is the system that will need the most balancing.

## Combined heat window is the INTERSECTION of every ingredient's window.
## Mixing turmeric (needs gentle heat) with ginger (needs a hard boil)
## narrows the window painfully — a consequence that emerges from the data
## rather than from a special-case rule.
##
## Flexible ingredients (rice, palm sugar) are skipped: they show up in
## most brews as filler, and letting them constrain temperature would make
## nearly every window impossible.
static func heat_window(ingredients: Array[IngredientData]) -> Vector2:
	var lo := 0.0
	var hi := 1.0
	var counted := 0
	for ing in ingredients:
		if ing.heat_flexible:
			continue
		lo = maxf(lo, ing.heat_min)
		hi = minf(hi, ing.heat_max)
		counted += 1

	if counted == 0:
		return Vector2(0.0, 1.0)
	return Vector2(lo, hi)


## Bitter jamu pays less unless sweetened. Teaches why gula jawa exists.
static func palatability(ingredients: Array[IngredientData]) -> float:
	var bitter := 0
	var sweet := 0
	for ing in ingredients:
		bitter += ing.bitterness
		sweet += ing.sweetness
		if ing.ingredient_id == &"gula_jawa":
			sweet += 4
		elif ing.ingredient_id == &"asam_jawa":
			sweet += 1

	var net := maxi(bitter - sweet, 0)
	return clampf(1.2 - net * 0.06, 0.5, 1.2)


static func evaluate(ingredients: Array[IngredientData],
		wanted: Array[Symptom.Code]) -> BrewResult:
	var r := BrewResult.new()
	r.status = BrewResult.Status.BREWED
	r.ingredients = ingredients
	r.heat_window = heat_window(ingredients)
	r.palatability = palatability(ingredients)

	var treated := {}
	for ing in ingredients:
		for s in ing.treats:
			treated[s] = true

	for s in wanted:
		if treated.has(s):
			r.covered.append(s)
		else:
			r.missed.append(s)

	r.accuracy = float(r.covered.size()) / maxf(wanted.size(), 1.0)
	return r


## Payment never reaches zero — a player who guessed wrong still gets
## something plus feedback, so mistakes read as lessons.
static func payment(base: int, result: BrewResult, patience_left: float,
		pay_multiplier: float, doneness_bonus: float = 1.0) -> int:
	var accuracy_factor := lerpf(0.3, 1.0, result.accuracy)
	var patience_factor := 1.0 + clampf(patience_left, 0.0, 1.0)
	var total := base * accuracy_factor * patience_factor \
		* result.palatability * pay_multiplier * doneness_bonus
	return maxi(int(round(total)), 1)
