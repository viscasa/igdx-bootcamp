class_name PanciSlot extends Node2D

signal clicked

const LIQUID_SURFACE_VERTICES := 17

@export_group("Liquid")
@export_range(0.0, 12.0, 0.1) var idle_wave_strength := 3.0
@export_range(0.0, 18.0, 0.1) var hot_wave_strength := 10.0
@export_range(0.0, 4.0, 0.05) var wave_speed := 1.15
@export_group("Motion")
@export_range(1.0, 1.12, 0.01) var hover_scale := 1.04
@export_range(0.1, 1.0, 0.05) var pour_duration := 0.38

var brew: Brew
var heat := 0.5
var bottling := false
var _time := 0.0
var _hover_tween: Tween
var _hovered := false
var _base_visual_position := Vector2.ZERO
var _base_visual_scale := Vector2.ONE
var _base_fire_scale := Vector2.ONE
var _base_liquid_position := Vector2.ZERO
var _base_liquid_scale := Vector2.ONE
var _base_liquid_polygon := PackedVector2Array()
var _bottle_base_position := Vector2.ZERO
var _bottle_base_scale := Vector2.ONE

@onready var hit_button: Button = $HitButton
@onready var visual_root: Node2D = $VisualRoot
@onready var fire_glow: Polygon2D = $VisualRoot/FireGlow
@onready var fire: AnimatedSprite2D = $VisualRoot/Fire
@onready var liquid_root: Node2D = $VisualRoot/LiquidRoot
@onready var liquid: Polygon2D = $VisualRoot/LiquidRoot/Liquid
@onready var bubbles: CPUParticles2D = $VisualRoot/LiquidRoot/Bubbles
@onready var steam: CPUParticles2D = $VisualRoot/Steam
@onready var bottle_anchor: Node2D = $BottleAnchor
@onready var bottle_preview: Node2D = $BottleAnchor/BottlePreview
@onready var status_label: Label = $StatusLabel
@onready var progress_fill: ColorRect = $Progress/Fill


func _ready() -> void:
	_base_visual_position = visual_root.position
	_base_visual_scale = visual_root.scale
	_base_fire_scale = fire.scale
	_base_liquid_position = liquid_root.position
	_base_liquid_scale = liquid_root.scale
	_base_liquid_polygon = liquid.polygon.duplicate()
	_bottle_base_position = bottle_preview.position
	_bottle_base_scale = bottle_preview.scale
	hit_button.pressed.connect(func(): clicked.emit())
	hit_button.mouse_entered.connect(func(): set_hovered(true))
	hit_button.mouse_exited.connect(func(): set_hovered(false))
	bottle_preview.visible = false
	_sync_visuals()


func _process(delta: float) -> void:
	_time += delta
	if liquid.material is ShaderMaterial:
		var material := liquid.material as ShaderMaterial
		material.set_shader_parameter("heat", heat)
	_animate_liquid()
	_sync_motion()


func bind(next_brew: Brew, next_heat: float, speed: float, overcook_limit: float) -> void:
	brew = next_brew
	heat = next_heat
	_sync_visuals()
	if brew == null:
		return
	progress_fill.size.x = ($Progress as Control).size.x * clampf(brew.doneness / overcook_limit, 0.0, 1.0)
	if brew.is_burnt:
		status_label.text = "GOSONG - KLIK"
		status_label.modulate = Color("a52f25")
	elif brew.is_done:
		status_label.text = "SIAP - KLIK PANCI"
		status_label.modulate = Color("3f7435")
	elif brew.doneness >= 0.72:
		status_label.text = "HAMPIR MATANG"
		status_label.modulate = Color("9b4a18")
	else:
		status_label.text = "MEREBUS - API x%.1f" % speed
		status_label.modulate = Color("654431")


func set_hovered(value: bool) -> void:
	if bottling:
		return
	var next_hovered := value and brew != null
	if _hovered == next_hovered:
		return
	_hovered = next_hovered
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(visual_root, "scale",
		_base_visual_scale * (hover_scale if _hovered else 1.0), 0.14)


func reject_click(message: String) -> void:
	status_label.text = message
	status_label.modulate = Color("ad332d")
	var tween := create_tween()
	tween.tween_property(visual_root, "position:x", _base_visual_position.x - 4.0, 0.045)
	tween.tween_property(visual_root, "position:x", _base_visual_position.x + 4.0, 0.07)
	tween.tween_property(visual_root, "position:x", _base_visual_position.x, 0.045)


func play_bottling() -> void:
	if brew == null or bottling:
		return
	bottling = true
	_hovered = false
	hit_button.disabled = true
	_configure_bottle(brew)
	bottle_preview.visible = true
	bottle_preview.modulate.a = 0.0
	bottle_preview.position = _bottle_base_position
	bottle_preview.scale = _bottle_base_scale * 0.72
	status_label.text = "MENUANG..."
	status_label.modulate = Color("654431")

	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(liquid_root, "scale:y", _base_liquid_scale.y * 0.04, pour_duration)
	tween.tween_property(liquid_root, "position:y", _base_liquid_position.y + 68.0, pour_duration)
	tween.tween_property(liquid_root, "modulate:a", 0.0, pour_duration * 0.9)
	tween.tween_property(bottle_preview, "modulate:a", 1.0, pour_duration * 0.42).set_delay(pour_duration * 0.2)
	tween.tween_property(bottle_preview, "scale", _bottle_base_scale, pour_duration * 0.55).set_delay(pour_duration * 0.2)
	await tween.finished

	var pop := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop.tween_property(bottle_preview, "position", _bottle_base_position + Vector2.UP * 8.0, 0.16)
	await pop.finished


func finish_bottling() -> void:
	bottling = false
	brew = null
	hit_button.disabled = false
	bottle_preview.visible = false
	bottle_preview.position = _bottle_base_position
	bottle_preview.scale = _bottle_base_scale
	liquid_root.scale = _base_liquid_scale
	liquid_root.position = _base_liquid_position
	liquid_root.modulate = Color.WHITE
	visual_root.position = _base_visual_position
	visual_root.scale = _base_visual_scale
	visual_root.rotation = 0.0
	_sync_visuals()


func _sync_visuals() -> void:
	if not is_node_ready():
		return
	var filled := brew != null
	if not filled:
		_hovered = false
	liquid_root.visible = filled
	fire.visible = filled
	fire_glow.visible = filled
	steam.emitting = filled and (heat > 0.18 or (brew != null and brew.is_done))
	bubbles.emitting = filled
	$Progress.visible = filled
	status_label.text = "KOSONG" if not filled else status_label.text
	status_label.modulate = Color("654431") if not filled else status_label.modulate
	if not filled:
		progress_fill.size.x = 0.0
		return
	var liquid_color := Color("3a2e24") if brew.is_burnt else brew.color()
	liquid.color = liquid_color
	bubbles.color = liquid_color.lightened(0.42)
	steam.amount = clampi(roundi(lerpf(3.0, 10.0, heat)), 3, 10)
	fire.speed_scale = lerpf(0.7, 1.7, heat)
	var fire_scale := lerpf(0.72, 1.08, heat)
	fire.scale = _base_fire_scale * fire_scale
	fire_glow.modulate.a = lerpf(0.12, 0.34, heat)


func _sync_motion() -> void:
	if brew == null or bottling:
		return
	visual_root.rotation = sin(_time * 18.0) * 0.004 * clampf(brew.burn * 1.5, 0.0, 1.0)


func _animate_liquid() -> void:
	if brew == null or bottling or _base_liquid_polygon.size() < LIQUID_SURFACE_VERTICES:
		return
	var points := _base_liquid_polygon.duplicate()
	var phase := _time * wave_speed * lerpf(0.65, 2.0, heat)
	var strength := lerpf(idle_wave_strength, hot_wave_strength, heat)
	for i in range(LIQUID_SURFACE_VERTICES):
		var horizontal := float(i) / float(LIQUID_SURFACE_VERTICES - 1)
		var wave := sin(horizontal * TAU * 1.15 + phase) * 0.75
		wave += sin(horizontal * TAU * 2.1 - phase * 0.83) * 0.25
		points[i].y = _base_liquid_polygon[i].y + wave * strength
	liquid.polygon = points


func _configure_bottle(value: Brew) -> void:
	var back := bottle_preview.get_node("BottleVisual/BrewSwatchBack") as Polygon2D
	var front := bottle_preview.get_node("BottleVisual/BrewSwatch") as Polygon2D
	var liquid_color := Color("3a2e24") if value.is_burnt else value.color()
	back.visible = true
	front.visible = true
	back.color = liquid_color
	front.color = liquid_color
	(bottle_preview.get_node("NameLabel") as Label).visible = false
	(bottle_preview.get_node("EffectLabel") as Label).visible = false
