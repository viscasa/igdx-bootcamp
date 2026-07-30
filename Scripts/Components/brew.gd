class_name Brew extends RefCounted

## One jamu simmering in the panci.

var result: BrewResult
var customer: CustomerData
var order_symptoms: Array[Symptom.Code] = []
var patience_at_brew: float = 1.0

var doneness: float = 0.0
var burn: float = 0.0
var cook_rate: float = 0.22        ## fraction per second at ideal heat

var is_done: bool = false
var is_burnt: bool = false


func heat_window() -> Vector2:
	return result.heat_window


func is_heat_ideal(heat: float) -> bool:
	var w := heat_window()
	return heat >= w.x and heat <= w.y


## Doneness scores best when served right at 1.0 — over-simmering past
## that starts costing money even before it burns.
func doneness_bonus() -> float:
	if is_burnt:
		return 0.4
	if doneness < 0.7:
		return 0.6                      # raw
	if doneness <= 1.15:
		return 1.2                      # just right
	return 0.85                         # oversteeped
