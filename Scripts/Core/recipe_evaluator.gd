class_name RecipeEvaluator

## Pure scoring. No nodes, so it can be tuned and tested in isolation —
## this is the system that will need the most balancing.

## A brew's target follows the weighted centre of its medicinal ingredients.
## This creates genuinely different bottles: ginger runs hot, turmeric gentle,
## and a mixed brew lands between them. The old intersection model accidentally
## gave all real content one universal safe setting.
static func heat_window(ingredients: Array[IngredientData]) -> Vector2:
	var weighted := 0.0
	var weight_total := 0.0
	for ing in ingredients:
		if ing.heat_flexible:
			continue
		var weight := maxf(ing.shape_cells.size(), 1.0)
		weighted += ing.heat_center() * weight
		weight_total += weight

	if weight_total <= 0.0:
		return Vector2(0.0, 1.0)
	var centre := weighted / weight_total
	var half_width := clampf(0.15 - (ingredients.size() - 1) * 0.012, 0.09, 0.15)
	return Vector2(maxf(centre - half_width, 0.0), minf(centre + half_width, 1.0))


## Bitter jamu pays a little less unless sweetened. It should read as
## customer satisfaction, not as the main answer; efficacy still dominates.
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
	return clampf(1.08 - net * 0.035, 0.72, 1.08)


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
	r.precision = dose_precision(have, demand)

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


## Exact dosing is a bonus, never a hard failure. This gives the pipisan a
## reason to exist while keeping a generous over-dose fully medicinal.
static func dose_precision(have: Dictionary, demand: Dictionary) -> float:
	var wanted_total := 0
	var excess_total := 0
	for s in demand:
		var want := int(demand[s])
		wanted_total += want
		excess_total += maxi(int(have.get(s, 0)) - want, 0)
	if wanted_total <= 0:
		return 1.0
	return clampf(1.0 - float(excess_total) / (wanted_total * 2.0), 0.35, 1.0)


## Classic combinations are discoveries and quality bonuses, not mandatory
## answers. Personalised jamu remains the main game.
static func heritage_recipe(ingredients: Array[IngredientData]) -> String:
	var ids := {}
	for ing in ingredients:
		ids[ing.ingredient_id] = true
	if ids.has(&"kunyit") and ids.has(&"asam_jawa") and ids.has(&"gula_jawa"):
		return "Kunyit Asam"
	if ids.has(&"beras") and ids.has(&"kencur") and ids.has(&"gula_jawa"):
		return "Beras Kencur"
	if ids.has(&"jahe_merah") and ids.has(&"gula_jawa"):
		return "Wedang Jahe"
	if ids.has(&"brotowali") and (ids.has(&"sambiloto") or ids.has(&"gula_jawa")):
		return "Pahitan"
	return ""


static func heritage_recipes() -> Array[Dictionary]:
	return [
		{
			"name": "Kunyit Asam",
			"ids": [&"kunyit", &"asam_jawa", &"gula_jawa"],
			"effect": "Ramuan segar untuk perut, pegal ringan, dan keseimbangan badan.",
			"lore": "Resep kunyit-asam adalah jamu klasik: kunyit memberi dasar hangat, asam jawa menyegarkan, gula jawa menenangkan pahitnya."
		},
		{
			"name": "Beras Kencur",
			"ids": [&"beras", &"kencur", &"gula_jawa"],
			"effect": "Ramuan tenaga ringan: cocok untuk badan lesu, batuk, dan nafsu makan turun.",
			"lore": "Beras kencur terasa lembut dan manis. Dalam fantasi kedai ini, ia adalah potion stamina untuk pekerja pasar dan anak kecil."
		},
		{
			"name": "Wedang Jahe",
			"ids": [&"jahe_merah", &"gula_jawa"],
			"effect": "Ramuan hangat untuk dingin, batuk, pegal, dan badan kurang tenaga.",
			"lore": "Jahe merah membawa rasa panas yang kuat. Di dunia Acaraki, prajurit menyebutnya ramuan penghangat penjaga malam."
		},
		{
			"name": "Pahitan",
			"ids": [&"brotowali", &"sambiloto"],
			"effect": "Ramuan pahit untuk panas, kulit bermasalah, dan ketahanan tubuh.",
			"lore": "Pahitan bukan dibuat untuk enak, tapi untuk kuat. Brotowali dan sambiloto memberi identitas jamu yang tegas dan berani."
		},
	]


static func heritage_recipe_entry(name_: String) -> Dictionary:
	for recipe in heritage_recipes():
		if String(recipe["name"]) == name_:
			return recipe
	return {}


static func brew_name(ingredients: Array[IngredientData],
		cell_counts: Array[int] = []) -> String:
	var heritage := heritage_recipe(ingredients)
	if heritage != "":
		return heritage
	if ingredients.is_empty():
		return "Ramuan Kosong"

	var have := potency(ingredients, cell_counts)
	var top_symptom = null
	var top_power := -1
	for s in have:
		if int(have[s]) > top_power:
			top_symptom = s
			top_power = int(have[s])

	var main := ingredients[0]
	var main_cells := 0
	for i in range(ingredients.size()):
		var cells := cell_counts[i] if i < cell_counts.size() else ingredients[i].cell_count()
		if cells > main_cells:
			main = ingredients[i]
			main_cells = cells

	var effect := _potion_effect_name(top_symptom)
	var root := _short_ingredient_name(main)
	if have.size() == 2:
		return "Jamu Campur %s" % root
	if have.size() >= 3:
		return "Jamu Komplit %s" % root
	return "%s %s" % [effect, root]


static func _potion_effect_name(symptom) -> String:
	return {
		Symptom.Code.DEMAM: "Jamu Panas",
		Symptom.Code.NYERI_SENDI: "Jamu Pegal",
		Symptom.Code.LEMAH: "Jamu Kuat",
		Symptom.Code.PENCERNAAN: "Jamu Perut",
		Symptom.Code.BATUK: "Jamu Batuk",
		Symptom.Code.NAFSU_MAKAN: "Jamu Nafsu Makan",
		Symptom.Code.DINGIN: "Jamu Hangat",
		Symptom.Code.LUKA_DALAM: "Jamu Memar",
		Symptom.Code.PIKIRAN: "Jamu Tidur",
		Symptom.Code.KULIT: "Jamu Kulit",
		Symptom.Code.HATI_LIVER: "Jamu Hati",
		Symptom.Code.WANITA: "Jamu Bulanan",
	}.get(symptom, "Jamu Racikan")


static func _short_ingredient_name(ing: IngredientData) -> String:
	if ing == null:
		return "Acaraki"
	return {
		&"jahe_merah": "Jahe",
		&"asam_jawa": "Asam",
		&"gula_jawa": "Gula",
		&"daun_sirih": "Sirih",
		&"kayu_manis": "Kayu Manis",
		&"temu_ireng": "Temu Ireng",
	}.get(ing.ingredient_id, ing.display_name)


## Payment never reaches zero — a player who guessed wrong still gets
## something plus feedback, so mistakes read as lessons.
##
## Note: empty space in the pot carries no penalty. Potency already
## rewards a fuller pot on its own (more cells = more healing power), so
## an extra efficiency multiplier would be punishing the same thing twice.
static func payment(base: int, result: BrewResult, patience_left: float,
		pay_multiplier: float, doneness_bonus: float = 1.0,
		heritage_bonus: float = 1.0) -> int:
	var accuracy_factor := lerpf(0.3, 1.0, result.accuracy)
	var patience_factor := 1.0 + clampf(patience_left, 0.0, 1.0)
	var precision_factor := lerpf(0.82, 1.12, result.precision)
	var total := base * accuracy_factor * patience_factor \
		* result.palatability * pay_multiplier * doneness_bonus \
		* precision_factor * heritage_bonus
	return maxi(int(round(total)), 1)
