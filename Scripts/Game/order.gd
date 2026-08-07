class_name Order extends RefCounted

## One customer waiting to be served.

var customer: CustomerData
var variant: RequestVariant
var patience_max: float = 60.0
var patience_left: float = 60.0
var is_brewing: bool = false     ## already handed to the panci

## The player's hypothesis. The actual symptom list stays hidden until the
## jamu is delivered; the kitchen works from these notes instead of leaking
## the answer key through its dose meters.
var diagnosis: Array[Symptom.Code] = []
var clue_uses: int = 0
var displayed_dialogue: String = ""

## Symptom code -> potency required, resolved once at spawn so the demand
## the player sees never shifts underneath them.
var demand: Dictionary = {}


func symptoms() -> Array[Symptom.Code]:
	return variant.symptoms


func working_symptoms() -> Array[Symptom.Code]:
	return diagnosis if not diagnosis.is_empty() else symptoms()


func working_demand() -> Dictionary:
	var out := {}
	for s in working_symptoms():
		out[s] = required_potency(s)
	return out


func toggle_diagnosis(code: Symptom.Code, max_count: int = 3) -> bool:
	if code in diagnosis:
		diagnosis.erase(code)
		return true
	if diagnosis.size() >= max_count:
		return false
	diagnosis.append(code)
	return true


func diagnosis_accuracy() -> float:
	if diagnosis.is_empty():
		return 0.0
	var hits := 0
	for s in symptoms():
		if s in diagnosis:
			hits += 1
	var false_positive := 0
	for s in diagnosis:
		if not s in symptoms():
			false_positive += 1
	return clampf(float(hits) / maxf(symptoms().size(), 1.0)
		- false_positive * 0.2, 0.0, 1.0)


func next_clue() -> String:
	var syms := symptoms()
	if syms.is_empty():
		return "Coba dengarkan lagi keluhannya."
	var authored_count := variant.clues.size()
	var authored := variant.clue_at(clue_uses % authored_count) \
		if authored_count > 0 else ""
	if authored != "":
		clue_uses += 1
		displayed_dialogue = authored
		return authored
	var code: Symptom.Code = syms[clue_uses % syms.size()]
	clue_uses += 1
	displayed_dialogue = Symptom.clue(code)
	return displayed_dialogue


func max_clues() -> int:
	return 999999


func dialogue() -> String:
	return variant.dialogue


func current_dialogue() -> String:
	return displayed_dialogue if displayed_dialogue != "" else dialogue()


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
	o.displayed_dialogue = v.dialogue
	o.patience_max = maxf(c.base_patience * patience_scale, 120.0)
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
			want = maxi(want, 4)
		elif day <= 4:
			want = maxi(mini(want, 5), 4)
		else:
			want = maxi(want, 4)
		out[s] = want
	return out
