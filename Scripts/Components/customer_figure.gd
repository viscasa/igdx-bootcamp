class_name CustomerFigure extends Control

## A scene-authored customer figure. The modular CustomerAppearance scene owns
## the character artwork; this script binds order data and queue interaction.

signal chosen(order: Order)

@export_group("Speech Layout")
@export_range(0.5, 2.0, 0.05) var speech_screen_scale: float = 1.25
@export_range(80.0, 500.0, 5.0) var speech_offset_pixels: float = 400.0

var depth_alpha: float = 1.0:
	set(value):
		depth_alpha = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_depth_alpha()

@onready var customer_visual: CustomerAppearance = $Customer
@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var state_label: Label = %StateLabel
@onready var bubble: Control = %Bubble
@onready var speech_tail: Polygon2D = $SpeechTail
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
	_apply_depth_alpha()
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
	_apply_depth_alpha()
	name_label.text = order.customer.display_name
	role_label.text = order.customer.role
	name_label.visible = focused
	role_label.visible = focused
	bubble.visible = focused and not carrying
	speech_tail.visible = bubble.visible
	_sync_speech_layout()
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
	var can_diagnose := focused and not carrying
	hit_button.mouse_filter = Control.MOUSE_FILTER_STOP if can_diagnose \
		else Control.MOUSE_FILTER_IGNORE
	hit_button.disabled = not can_diagnose
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


func _apply_depth_alpha() -> void:
	# Customer is a CanvasGroup, so its layered sprites are composited first.
	# Fading the group result prevents body/hair/clothes from showing through.
	if customer_visual != null:
		customer_visual.self_modulate = Color(1.0, 1.0, 1.0, depth_alpha)
	if patience != null:
		patience.self_modulate = Color(1.0, 1.0, 1.0, depth_alpha)


func _process(_delta: float) -> void:
	if order != null and visible:
		_update_patience()
		if bubble.visible:
			_sync_speech_layout()


func _sync_speech_layout() -> void:
	if bubble == null or speech_tail == null:
		return
	var figure_transform := get_global_transform()
	var global_scale := maxf(
		(figure_transform.x.length() + figure_transform.y.length()) * 0.5,
		0.001
	)
	var local_scale := speech_screen_scale / global_scale
	var pivot := bubble.size * 0.5
	var character_anchor := Vector2(110.0, 185.0)
	var bubble_center := character_anchor \
		+ Vector2(0.0, -speech_offset_pixels / global_scale)
	bubble.pivot_offset = pivot
	bubble.position = bubble_center - pivot
	bubble.scale = Vector2.ONE * local_scale
	speech_tail.position = Vector2(
		bubble_center.x,
		bubble_center.y + pivot.y * local_scale
	)
	speech_tail.scale = Vector2.ONE * local_scale


func _update_patience() -> void:
	if order == null:
		return
	_patience_ratio = order.patience_ratio()
	_patience_color = Color("e05a4f") if _patience_ratio < 0.25 \
		else (Color("d89b3c") if _patience_ratio < 0.5 else Color("6fa84f"))
	patience.value = _patience_ratio * 100.0
	if _patience_fill != null:
		_patience_fill.bg_color = _patience_color
