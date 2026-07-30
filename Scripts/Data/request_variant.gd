@tool
class_name RequestVariant extends Resource

## One complaint a customer can voice. The dialogue describes symptoms
## indirectly; `symptoms` is the answer key the player must deduce.

@export_multiline var dialogue: String = ""
@export var symptoms: Array[Symptom.Code] = []
@export var min_day: int = 1


static func create(text: String, syms: Array[Symptom.Code], from_day: int = 1) -> RequestVariant:
	var v := RequestVariant.new()
	v.dialogue = text
	v.symptoms = syms
	v.min_day = from_day
	return v
