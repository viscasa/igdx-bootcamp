@tool
class_name CustomerData extends Resource

## A customer archetype plus their pool of complaints.
## Customers never name a jamu — they describe how they feel.

@export var customer_id: StringName = &""
@export var display_name: String = "Pelanggan"
@export var role: String = ""
@export var color: Color = Color.WHITE

@export_group("Behaviour")
@export var base_patience: float = 60.0
@export var pay_multiplier: float = 1.0

@export_group("Requests")
@export var variants: Array[RequestVariant] = []


func pick_variant(day: int, rng: RandomNumberGenerator) -> RequestVariant:
	var pool: Array[RequestVariant] = []
	for v in variants:
		if day >= v.min_day:
			pool.append(v)
	if pool.is_empty():
		return variants[0] if not variants.is_empty() else null
	return pool[rng.randi() % pool.size()]
