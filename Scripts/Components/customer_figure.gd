class_name CustomerFigure extends Control

## A scene-authored customer figure. The modular CustomerAppearance scene owns
## the character artwork; this script binds order data and queue interaction.

@export_group("Speech Layout")
@export_range(0.5, 2.0, 0.05) var speech_screen_scale: float = 1.25
@export_range(80.0, 500.0, 5.0) var speech_offset_pixels: float = 400.0
## Tucks the tail underneath the panel border, avoiding a filtered seam where
## two separately rendered edges otherwise meet exactly.
@export_range(0.0, 20.0, 1.0) var speech_tail_overlap_pixels: float = 8.0

@export_group("Speech Animation")
@export_range(0.1, 0.6, 0.01) var speech_reveal_duration: float = 0.24
@export_range(0.5, 1.0, 0.01) var speech_reveal_scale: float = 0.84
@export_range(-8.0, 8.0, 0.25) var speech_reveal_tilt_degrees: float = -2.5
@export_range(0.0, 0.3, 0.01) var speech_tail_delay: float = 0.07

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
@onready var bubble_visual: Control = %BubbleVisual
@onready var speech_tail: Polygon2D = $SpeechTail
@onready var dialogue_label: Label = %DialogueLabel
@onready var patience: ProgressBar = %Patience
@onready var interaction_area: Control = %InteractionArea

var order: Order = null
var diagnosis_enabled: bool = false
var settled_at_slot: bool = false
var _patience_ratio: float = 1.0
var _patience_color: Color = Color("6fa84f")
var _patience_fill: StyleBoxFlat = null
var _appearance_customer_id: StringName = &""
var _bubble_tween: Tween = null


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
	name_label.visible = focused and settled_at_slot
	role_label.visible = focused and settled_at_slot
	var show_bubble := focused and settled_at_slot and not carrying
	var bubble_was_visible := bubble.visible
	bubble.visible = show_bubble
	speech_tail.visible = bubble.visible
	if show_bubble and not bubble_was_visible:
		_play_bubble_reveal()
	elif not show_bubble and bubble_was_visible:
		_reset_bubble_reveal()
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

	# CustomerQueue owns input so diagnosis and bottle drops use the same
	# scene-authored area and the same window clipping boundary.
	diagnosis_enabled = focused and settled_at_slot and not carrying
	queue_redraw()


func set_settled_at_slot(settled: bool) -> void:
	settled_at_slot = settled


func _play_bubble_reveal() -> void:
	_kill_bubble_tween()
	bubble_visual.offset_transform_enabled = true
	bubble_visual.offset_transform_pivot_ratio = Vector2(0.5, 0.78)
	bubble_visual.offset_transform_scale = Vector2.ONE * speech_reveal_scale
	bubble_visual.offset_transform_rotation = deg_to_rad(speech_reveal_tilt_degrees)
	bubble_visual.modulate.a = 0.0
	speech_tail.modulate.a = 0.0

	_bubble_tween = create_tween().set_parallel(true)
	_bubble_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble_tween.tween_property(
		bubble_visual, "offset_transform_scale", Vector2.ONE,
		speech_reveal_duration)
	_bubble_tween.tween_property(
		bubble_visual, "offset_transform_rotation", 0.0,
		speech_reveal_duration * 0.8)
	_bubble_tween.tween_property(
		bubble_visual, "modulate:a", 1.0,
		speech_reveal_duration * 0.55
	).set_trans(Tween.TRANS_QUAD)
	_bubble_tween.tween_property(
		speech_tail, "modulate:a", 1.0,
		speech_reveal_duration * 0.45
	).set_delay(speech_tail_delay).set_trans(Tween.TRANS_QUAD)


func _reset_bubble_reveal() -> void:
	_kill_bubble_tween()
	if bubble_visual != null:
		bubble_visual.offset_transform_scale = Vector2.ONE
		bubble_visual.offset_transform_rotation = 0.0
		bubble_visual.modulate.a = 1.0
	if speech_tail != null:
		speech_tail.modulate.a = 1.0


func _kill_bubble_tween() -> void:
	if _bubble_tween != null and _bubble_tween.is_valid():
		_bubble_tween.kill()
	_bubble_tween = null


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
		bubble_center.y + pivot.y * local_scale \
			- speech_tail_overlap_pixels / global_scale
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
