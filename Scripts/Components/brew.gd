class_name Brew extends RefCounted

## A finished jamu, as an object in its own right.
##
## Deliberately does NOT belong to a customer. The player brews a jamu, then
## decides who to hand it to — so accuracy is judged at delivery, against
## whoever actually receives it. That is what makes misdelivery possible.

var ingredients: Array[IngredientData] = []
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
		for_symptoms: Array[Symptom.Code]) -> Brew:
	var b := Brew.new()
	b.ingredients = ings
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


## Scored only when handed over, against the recipient's actual complaint.
func evaluate_for(symptoms: Array[Symptom.Code]) -> BrewResult:
	return RecipeEvaluator.evaluate(ingredients, symptoms)


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
