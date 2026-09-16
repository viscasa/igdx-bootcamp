class_name BrewResult extends RefCounted

## Graded outcome of a brew. Never a pass/fail boolean — a wrong mix still
## earns something, so failure teaches instead of punishing.

enum Status { INCOMPLETE, VIOLATED, BREWED }

var status: Status = Status.INCOMPLETE
var accuracy: float = 0.0          ## 0..1 — potency-weighted coverage
var covered: Array[Symptom.Code] = []
var missed: Array[Symptom.Code] = []
## Symptom code -> [supplied, required] for anything under-dosed. Lets the
## feedback line say "dosis kurang" instead of a flat "wrong", which is
## the difference between a lesson and a scolding.
var partial: Dictionary = {}
var palatability: float = 1.0      ## 0.5..1.2 — bitterness vs sweetness
var precision: float = 1.0         ## 0..1 — how close the dose is to demand
var heat_window: Vector2 = Vector2(0.0, 1.0)
var ingredients: Array[IngredientData] = []


func is_brewed() -> bool:
	return status == Status.BREWED


## Heat windows can conflict (ginger wants hot, rice wants cool).
func has_valid_heat_window() -> bool:
	return heat_window.x <= heat_window.y


func grade() -> String:
	if accuracy >= 0.999 and precision >= 0.85:
		return "Racikan Sempurna"
	if accuracy >= 0.999:
		return "Racikan Manjur"
	if accuracy >= 0.5:
		return "Cukup Membantu"
	if accuracy > 0.0:
		return "Kurang Tepat"
	return "Tidak Membantu"


static func incomplete() -> BrewResult:
	var r := BrewResult.new()
	r.status = Status.INCOMPLETE
	return r


static func violated() -> BrewResult:
	var r := BrewResult.new()
	r.status = Status.VIOLATED
	return r
