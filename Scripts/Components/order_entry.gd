class_name OrderEntry extends Control

@onready var name_label: Label = $Name
@onready var verdict_label: Label = $Verdict
@onready var patience_fill: ColorRect = $Patience/Fill
@onready var symptoms_label: Label = $Symptoms


func bind(order: Order, supplied: Dictionary) -> void:
	name_label.text = order.customer.display_name
	var ratio := order.patience_ratio()
	patience_fill.size.x = ($Patience as Control).size.x * ratio
	patience_fill.color = Color("e05a4f") if ratio < 0.25 else (Color("d89b3c") if ratio < 0.5 else Color("6fa84f"))
	var served := true
	var precise := true
	var lines: Array[String] = []
	for symptom in order.working_symptoms():
		var need := order.required_potency(symptom)
		var have := int(supplied.get(symptom, 0))
		served = served and have >= need
		precise = precise and have == need
		var pips := ""
		for i in range(need):
			pips += "◆" if i < have else "◇"
		lines.append("%s   %s  %d/%d" % [Symptom.display_name(symptom), pips, have, need])
	symptoms_label.text = "\n".join(lines)
	verdict_label.text = ("TEPAT" if precise else "CUKUP") if served else ""
	verdict_label.modulate = Color("9b4a18") if precise else Color("3f7435")
	name_label.modulate = Color("3f7435") if served else Color("542512")
