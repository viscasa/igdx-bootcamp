class_name DiagnosisBoard extends Control

## Counter-side notebook. The scene owns all visual nodes; this script only
## binds an Order to them and relays the player's choices.

signal take_requested(order: Order)

const MAX_DIAGNOSIS := 3
const CLUE_PATIENCE_COST := 0.0

@onready var customer_name: Label = %CustomerName
@onready var role_label: Label = %RoleLabel
@onready var clue_panel: PanelContainer = %CluePanel
@onready var clue_label: Label = %ClueLabel
@onready var diagnosis_grid: GridContainer = %DiagnosisGrid
@onready var status_label: Label = %StatusLabel
@onready var clue_button: Button = %ClueButton
@onready var take_button: Button = %TakeButton

var order: Order = null
var _last_clue: String = ""


func _ready() -> void:
	for i in range(diagnosis_grid.get_child_count()):
		var button := diagnosis_grid.get_child(i) as Button
		if button:
			button.pressed.connect(_toggle.bind(i))
	clue_button.pressed.connect(_ask_clue)
	take_button.pressed.connect(_take)
	_show_empty()


func set_order(next: Order) -> void:
	order = next
	_last_clue = ""
	visible = order != null
	_refresh()


func _show_empty() -> void:
	visible = false
	clue_panel.visible = false
	status_label.text = ""
	clue_button.disabled = true
	take_button.disabled = true
	for child in diagnosis_grid.get_children():
		(child as Button).disabled = true


func _refresh() -> void:
	if order == null:
		_show_empty()
		return

	customer_name.text = order.customer.display_name
	role_label.text = order.customer.role
	clue_panel.visible = false
	clue_label.text = ""
	clue_button.disabled = false
	clue_button.text = "TANYA LAGI" if order.clue_uses >= 1 else "TANYA"
	take_button.disabled = order.diagnosis.is_empty()
	take_button.text = "SIMPAN" if GameState.has_taken(order) else "AMBIL"

	for i in range(diagnosis_grid.get_child_count()):
		var button := diagnosis_grid.get_child(i) as Button
		if button == null:
			continue
		button.disabled = false
		button.text = Symptom.display_name(i as Symptom.Code)
		button.button_pressed = (i as Symptom.Code) in order.diagnosis
		button.modulate = Symptom.color(i as Symptom.Code) if button.button_pressed \
			else Color.WHITE

	if order.diagnosis.is_empty():
		status_label.text = "0/3 dipilih"
	else:
		status_label.text = "%d/3 dipilih" % order.diagnosis.size()


func _toggle(code: int) -> void:
	if order == null:
		return
	if not order.toggle_diagnosis(code as Symptom.Code, MAX_DIAGNOSIS):
		status_label.text = "Maksimal 3"
		return
	_refresh()


func _ask_clue() -> void:
	if order == null:
		return
	order.patience_left = maxf(order.patience_left - CLUE_PATIENCE_COST, 1.0)
	_last_clue = order.next_clue()
	GameState.post("Petunjuk didapat.", Color("ffd36f"))
	GameState.queue_changed.emit()
	_refresh()


func _take() -> void:
	if order == null or order.diagnosis.is_empty():
		return
	take_requested.emit(order)
	_refresh()
