class_name CustomerFigure extends Control

## A scene-authored customer figure. The modular CustomerAppearance scene owns
## the character artwork; this script binds order data and queue interaction.

signal chosen(order: Order)

@onready var customer_visual: CustomerAppearance = $Customer
@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var state_label: Label = %StateLabel
@onready var bubble: PanelContainer = %Bubble
@onready var dialogue_label: Label = %DialogueLabel
@onready var patience: ProgressBar = %Patience
@onready var hit_button: Button = %HitButton

var order: Order = null
var _patience_ratio: float = 1.0
var _patience_color: Color = Color("6fa84f")
var _patience_fill: StyleBoxFlat = null
var _appearance_customer_id: StringName = &""


func _ready() -> void:
	set_process(true)
	_sync_customer_appearance()
	patience.visible = true
	patience.min_value = 0.0
	patience.max_value = 100.0
	var fill_style := patience.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style != null:
		_patience_fill = fill_style.duplicate() as StyleBoxFlat
		patience.add_theme_stylebox_override("fill", _patience_fill)
	hit_button.pressed.connect(func() -> void:
		if order != null:
			chosen.emit(order))


func bind(next: Order, focused: bool, is_taken: bool,
		carrying: bool, hovered: bool) -> void:
	order = next
	if order == null:
		visible = false
		return

	visible = true
	_sync_customer_appearance()
	# Modular character art keeps its authored colors. Queue state is conveyed
	# by scale, z-order, labels, and the speech bubble—not a full-body tint.
	customer_visual.modulate = Color.WHITE
	name_label.text = order.customer.display_name
	role_label.text = order.customer.role
	name_label.visible = focused
	role_label.visible = focused
	bubble.visible = focused and not carrying
	dialogue_label.text = order.current_dialogue()
	_update_patience()

	if hovered:
		state_label.text = "LEPAS JAMU"
		state_label.modulate = Color("6fd48f")
	elif is_taken and focused:
		state_label.text = "✓ DIPESAN"
		state_label.modulate = Color("ffd36f")
	else:
		state_label.text = ""

	# While carrying, the world-space queue handles the release. Letting this
	# GUI button consume the mouse-up would make bottle drops unreliable.
	hit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if carrying \
		else Control.MOUSE_FILTER_STOP
	hit_button.disabled = carrying
	queue_redraw()


func _sync_customer_appearance() -> void:
	if order == null or customer_visual == null:
		return
	var customer_id := order.customer.customer_id
	if customer_id == _appearance_customer_id:
		return
	_appearance_customer_id = customer_id
	var stable_seed := hash(String(customer_id))
	customer_visual.appearance_seed = stable_seed if stable_seed != 0 else 1
	customer_visual.randomize_appearance()


func _process(_delta: float) -> void:
	if order != null and visible:
		_update_patience()


func _update_patience() -> void:
	if order == null:
		return
	_patience_ratio = order.patience_ratio()
	_patience_color = Color("e05a4f") if _patience_ratio < 0.25 \
		else (Color("d89b3c") if _patience_ratio < 0.5 else Color("6fa84f"))
	patience.value = _patience_ratio * 100.0
	if _patience_fill != null:
		_patience_fill.bg_color = _patience_color
