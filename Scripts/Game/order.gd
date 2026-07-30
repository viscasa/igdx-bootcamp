class_name Order extends RefCounted

## One customer waiting to be served.

var customer: CustomerData
var variant: RequestVariant
var patience_max: float = 60.0
var patience_left: float = 60.0
var is_brewing: bool = false     ## already handed to the panci


func symptoms() -> Array[Symptom.Code]:
	return variant.symptoms


func dialogue() -> String:
	return variant.dialogue


func patience_ratio() -> float:
	return clampf(patience_left / maxf(patience_max, 0.001), 0.0, 1.0)


func is_expired() -> bool:
	return patience_left <= 0.0


static func create(c: CustomerData, v: RequestVariant, patience_scale: float) -> Order:
	var o := Order.new()
	o.customer = c
	o.variant = v
	o.patience_max = c.base_patience * patience_scale
	o.patience_left = o.patience_max
	return o
