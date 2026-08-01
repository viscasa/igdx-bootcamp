class_name Brew extends RefCounted

## A finished jamu, as an object in its own right.
##
## Deliberately does NOT belong to a customer. The player brews a jamu, then
## decides who to hand it to — so accuracy is judged at delivery, against
## whoever actually receives it. That is what makes misdelivery possible.

var ingredients: Array[IngredientData] = []
## Cells each ingredient actually occupied in the pot, parallel to
## `ingredients`. Cut pieces contribute less than their pristine shape, so
## the brew has to remember the real sizes rather than re-deriving them.
var cell_counts: Array[int] = []
var heat_window: Vector2 = Vector2(0.0, 1.0)
var palatability: float = 1.0

## Who it was mixed for. Used only for the label on the bottle, never for
## scoring — the player is free to give it to someone else.
var intended_for: CustomerData
var intended_symptoms: Array[Symptom.Code] = []

var doneness: float = 0.0
var burn: float = 0.0
var cook_rate: float = 0.22        ## fraction per second at ideal heat

var is_done: bool = false
var is_burnt: bool = false


static func create(ings: Array[IngredientData], for_customer: CustomerData,
		for_symptoms: Array[Symptom.Code], counts: Array[int] = []) -> Brew:
	var b := Brew.new()
	b.ingredients = ings
	b.cell_counts = counts
	b.heat_window = RecipeEvaluator.heat_window(ings)
	b.palatability = RecipeEvaluator.palatability(ings)
	b.intended_for = for_customer
	b.intended_symptoms = for_symptoms
	return b


func is_heat_ideal(heat: float) -> bool:
	return heat >= heat_window.x and heat <= heat_window.y


## Every symptom this jamu can treat, regardless of who ordered it.
func treats() -> Array[Symptom.Code]:
	var out: Array[Symptom.Code] = []
	for ing in ingredients:
		for s in ing.treats:
			if not out.has(s):
				out.append(s)
	return out


## What went in, counted. "Kunyit ×2, Beras" reads at a glance; a colour
## swatch does not. Without this, two bottles of similar colour are
## indistinguishable and the player has to remember what they mixed.
func ingredient_summary() -> String:
	if ingredients.is_empty():
		return "kosong"

	var counts := {}
	var order: Array[String] = []
	for ing in ingredients:
		var n := ing.display_name
		if not counts.has(n):
			counts[n] = 0
			order.append(n)
		counts[n] += 1

	var parts: Array[String] = []
	for n in order:
		parts.append(n if counts[n] == 1 else "%s x%d" % [n, counts[n]])
	return ", ".join(parts)


## Potency per symptom, as text: "Pencernaan 4 · Lemah 3".
##
## This is the honest answer to "what does this bottle actually do" — the
## same numbers the dose bars use, so a bottle can be matched to a
## complaint without guessing.
func effect_summary() -> String:
	var have := RecipeEvaluator.potency(ingredients, cell_counts)
	if have.is_empty():
		return "tidak menyembuhkan apa-apa"

	var parts: Array[String] = []
	for s in have:
		parts.append("%s %d" % [Symptom.display_name(s), int(have[s])])
	return " · ".join(parts)


## Scored only when handed over, against the recipient's actual complaint.
## `demand` maps symptom -> required potency (see Order.demand).
func evaluate_for(demand: Dictionary) -> BrewResult:
	return RecipeEvaluator.evaluate(ingredients, demand, cell_counts)


## True when this is the customer it was mixed for.
func is_intended_for(c: CustomerData) -> bool:
	return intended_for != null and c != null \
		and intended_for.customer_id == c.customer_id


func is_ready_to_serve() -> bool:
	return is_done or is_burnt


## Doneness scores best right at 1.0; over-simmering costs money before it burns.
func doneness_bonus() -> float:
	if is_burnt:
		return 0.4
	if doneness < 0.7:
		return 0.6                      # raw
	if doneness <= 1.15:
		return 1.2                      # just right
	return 0.85                         # oversteeped


## Bottle colour blends the ingredients, so the player can tell brews apart
## on sight while carrying them.
func color() -> Color:
	if ingredients.is_empty():
		return Color("8a7f6a")
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for ing in ingredients:
		r += ing.color.r
		g += ing.color.g
		b += ing.color.b
	var n := float(ingredients.size())
	return Color(r / n, g / n, b / n)
