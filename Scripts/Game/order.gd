class_name Order extends RefCounted

## One customer waiting to be served.

var customer: CustomerData
var variant: RequestVariant
var patience_max: float = 60.0
var patience_left: float = 60.0
var is_brewing: bool = false     ## already handed to the panci

## Symptom code -> potency required, resolved once at spawn so the demand
## the player sees never shifts underneath them.
var demand: Dictionary = {}


func symptoms() -> Array[Symptom.Code]:
	return variant.symptoms


func dialogue() -> String:
	return variant.dialogue


func required_potency(code: Symptom.Code) -> int:
	return maxi(int(demand.get(code, 1)), 1)


func total_potency() -> int:
	var t := 0
	for s in demand:
		t += int(demand[s])
	return t


func patience_ratio() -> float:
	return clampf(patience_left / maxf(patience_max, 0.001), 0.0, 1.0)


func is_expired() -> bool:
	return patience_left <= 0.0


static func create(c: CustomerData, v: RequestVariant, patience_scale: float,
		day: int = 1) -> Order:
	var o := Order.new()
	o.customer = c
	o.variant = v
	o.patience_max = c.base_patience * patience_scale
	o.patience_left = o.patience_max
	o.demand = _resolve_demand(v, day)
	return o


## Day 1-2 pins every severity to 1, so the opening days play exactly like
## the old one-ingredient-is-enough rule. Potency then ramps in gradually —
## the player learns the system by watching a bar need more, not by reading
## a tutorial.
static func _resolve_demand(v: RequestVariant, day: int) -> Dictionary:
	var out := {}
	for s in v.symptoms:
		var want: int = v.severity_of(s)
		if day <= 2:
			want = 1
		elif day <= 4:
			want = mini(want, 2)
		out[s] = want
	return out
