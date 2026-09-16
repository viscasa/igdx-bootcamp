class_name ServiceReportPanel extends Control

@onready var title_label: Label = %TitleLabel
@onready var grade_label: Label = %GradeLabel
@onready var diagnosis_bar: ProgressBar = $Margin/Content/Scores/Diagnosis/Bar
@onready var diagnosis_value: Label = $Margin/Content/Scores/Diagnosis/Value
@onready var khasiat_bar: ProgressBar = $Margin/Content/Scores/Khasiat/Bar
@onready var khasiat_value: Label = $Margin/Content/Scores/Khasiat/Value
@onready var dosis_bar: ProgressBar = $Margin/Content/Scores/Dosis/Bar
@onready var dosis_value: Label = $Margin/Content/Scores/Dosis/Value
@onready var cooking_label: Label = $Margin/Content/States/CookingStatus/Label
@onready var taste_label: Label = $Margin/Content/States/TasteStatus/Label
@onready var guessed_label: Label = %GuessedLabel
@onready var actual_label: Label = %ActualLabel
@onready var brew_label: Label = %BrewLabel
@onready var pay_label: Label = %PayLabel

var _was_visible: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_delta: float) -> void:
	var show := GameState.service_report_visible()
	if not show:
		visible = false
		_was_visible = false
		return
	var details: Dictionary = GameState.service_report_details
	if details.is_empty():
		return
	visible = true
	_refresh(details)
	if not _was_visible:
		_play_reveal()
	_was_visible = true


func _refresh(details: Dictionary) -> void:
	title_label.text = "HASIL · %s" % String(details.get("customer", "Pelanggan"))
	grade_label.text = String(details.get("grade", "—")).to_upper()
	_set_score(diagnosis_bar, diagnosis_value, float(details.get("diagnosis", 0.0)))
	_set_score(khasiat_bar, khasiat_value, float(details.get("accuracy", 0.0)))
	_set_score(dosis_bar, dosis_value, float(details.get("precision", 0.0)))
	cooking_label.text = "KEMATANGAN · %s" % String(details.get("cooking", "—"))
	taste_label.text = "RASA · %s" % String(details.get("taste", "—"))
	guessed_label.text = "Dugaan: %s" % _join_names(details.get("guessed", []))
	actual_label.text = "Sebenarnya: %s" % _join_names(details.get("actual", []))
	var heritage := String(details.get("heritage", ""))
	brew_label.text = "★ %s" % heritage if heritage != "" \
		else String(details.get("brew_name", "Jamu Racikan")).to_upper()
	pay_label.text = "+%d UANG" % int(details.get("pay", 0))


func _set_score(bar: ProgressBar, label: Label, ratio: float) -> void:
	var percent := clampi(roundi(ratio * 100.0), 0, 100)
	bar.value = percent
	label.text = "%d%%" % percent


func _join_names(value: Variant) -> String:
	var names: Array = value as Array
	return ", ".join(names) if not names.is_empty() else "—"


func _play_reveal() -> void:
	pivot_offset = size * 0.5
	modulate.a = 0.0
	scale = Vector2.ONE * 0.92
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
