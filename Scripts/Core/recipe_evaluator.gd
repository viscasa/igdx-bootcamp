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


## How much healing power the mix delivers per symptom.
##
## Potency is measured in GRID CELLS, which is the whole point of the
## system: placing a bigger ingredient — or more of a small one — is what
## makes a remedy stronger. That ties the spatial puzzle directly to the
## deduction puzzle instead of leaving them as two unrelated minigames.
## `cell_counts` optionally overrides each ingredient's size, entry by
## entry. Cutting a piece in half must halve what it heals, and the pot
## knows the real placed size while IngredientData only knows the pristine
## shape — so the caller passes the truth in.
static func potency(ingredients: Array[IngredientData],
		cell_counts: Array[int] = []) -> Dictionary:
	var out := {}
	for i in range(ingredients.size()):
		var ing := ingredients[i]
		var cells := ing.shape_cells.size()
		if i < cell_counts.size():
			cells = cell_counts[i]
		for s in ing.treats:
			out[s] = int(out.get(s, 0)) + cells
	return out


## Live progress for the HUD: symptom -> [supplied, required].
## Lets the player watch a bar fill as they place pieces, so "how much is
## enough" is read off the screen rather than memorised.
static func progress(ingredients: Array[IngredientData],
		demand: Dictionary, cell_counts: Array[int] = []) -> Dictionary:
	var have := potency(ingredients, cell_counts)
	var out := {}
	for s in demand:
		out[s] = [int(have.get(s, 0)), int(demand[s])]
	return out


static func evaluate(ingredients: Array[IngredientData],
		demand: Dictionary, cell_counts: Array[int] = []) -> BrewResult:
	var r := BrewResult.new()
	r.status = BrewResult.Status.BREWED
	r.ingredients = ingredients
	r.heat_window = heat_window(ingredients)
	r.palatability = palatability(ingredients)

	var have := potency(ingredients, cell_counts)

	# Accuracy is potency-weighted rather than a symptom headcount, so
	# under-dosing a severe complaint costs proportionally — half the
	# required kunyit reads as half a treatment, not as a clean miss.
	var supplied := 0.0
	var needed := 0.0

	for s in demand:
		var want := int(demand[s])
		var got := mini(int(have.get(s, 0)), want)
		supplied += got
		needed += want

		if got >= want:
			r.covered.append(s)
		else:
			r.missed.append(s)
			r.partial[s] = [got, want]

	r.accuracy = supplied / maxf(needed, 1.0)
	return r


## Payment never reaches zero — a player who guessed wrong still gets
## something plus feedback, so mistakes read as lessons.
##
## Note: empty space in the pot carries no penalty. Potency already
## rewards a fuller pot on its own (more cells = more healing power), so
## an extra efficiency multiplier would be punishing the same thing twice.
static func payment(base: int, result: BrewResult, patience_left: float,
		pay_multiplier: float, doneness_bonus: float = 1.0) -> int:
	var accuracy_factor := lerpf(0.3, 1.0, result.accuracy)
	var patience_factor := 1.0 + clampf(patience_left, 0.0, 1.0)
	var total := base * accuracy_factor * patience_factor \
		* result.palatability * pay_multiplier * doneness_bonus
	return maxi(int(round(total)), 1)
