@tool
class_name RequestVariant extends Resource

## One complaint a customer can voice. The dialogue describes symptoms
## indirectly; `symptoms` is the answer key the player must deduce.
##
## `severity` gives each symptom a potency requirement — how much of the
## right ingredient is needed, measured in grid cells. A severity of 3 on
## PENCERNAAN means the player must place at least 3 cells' worth of
## digestion-treating ingredients.
##
## This is what makes ingredient SIZE meaningful: one kunyit (2x2 = 4 cells)
## satisfies a severity-4 request on its own, while beras (1x1) needs four
## placements. Crucially it does not revive recipe memorisation — the player
## still has to know WHICH ingredient treats the symptom; severity only says
## how much, and the UI shows that as a live bar.

@export_multiline var dialogue: String = ""
@export var symptoms: Array[Symptom.Code] = []
@export var min_day: int = 1

## Symptom code -> required potency (cells). Missing entry means 1.
@export var severity: Dictionary = {}


static func create(text: String, syms: Array[Symptom.Code], from_day: int = 1,
		sev: Dictionary = {}) -> RequestVariant:
	var v := RequestVariant.new()
	v.dialogue = text
	v.symptoms = syms
	v.min_day = from_day
	v.severity = sev
	return v


func severity_of(code: Symptom.Code) -> int:
	return maxi(int(severity.get(code, 1)), 1)


## Total cells this request demands. Used to keep the pot solvable.
func total_potency() -> int:
	var t := 0
	for s in symptoms:
		t += severity_of(s)
	return t
