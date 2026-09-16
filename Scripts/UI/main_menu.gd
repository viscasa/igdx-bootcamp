class_name MainMenu extends Control

const BUTTON_REST_SCALE := Vector2.ONE
const BUTTON_HOVER_SCALE := Vector2(1.06, 1.06)

@export var pattern_scroll_speed := Vector2(0.018, 0.006)

@onready var menu_artwork: Control = %MenuArtwork
@onready var logo_pivot: Control = %LogoPivot
@onready var pattern: ColorRect = %Pattern
@onready var menu_buttons: VBoxContainer = %MenuButtons
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var exit_button: Button = %ExitButton
@onready var settings_layer: Control = %SettingsLayer
@onready var settings_panel: Control = %SettingsPanel
@onready var close_settings_button: TextureButton = %CloseSettingsButton
@onready var credits_layer: Control = %CreditsLayer
@onready var credits_panel: Control = %CreditsPanel
@onready var close_credits_button: TextureButton = %CloseCreditsButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fade: ColorRect = %Fade

var _transitioning := false
var _idle_tween: Tween
var _button_tweens: Dictionary = {}
var _pattern_offset := Vector2.ZERO


func _ready() -> void:
	WorldAudioManager.play_main_menu()
	WorldAudioManager.set_button_cue(start_button, WorldAudioManager.CONFIRM)
	WorldAudioManager.set_button_cue(settings_button, WorldAudioManager.MENU_OPEN)
	WorldAudioManager.set_button_cue(credits_button, WorldAudioManager.MENU_OPEN)
	WorldAudioManager.set_button_cue(exit_button, WorldAudioManager.CANCEL)
	WorldAudioManager.set_button_cue(close_settings_button, WorldAudioManager.MENU_CLOSE)
	WorldAudioManager.set_button_cue(close_credits_button, WorldAudioManager.MENU_CLOSE)
	start_button.pressed.connect(_start_game)
	settings_button.pressed.connect(_open_settings)
	credits_button.pressed.connect(_open_credits)
	exit_button.pressed.connect(get_tree().quit)
	close_settings_button.pressed.connect(_close_settings)
	close_credits_button.pressed.connect(_close_credits)
	music_slider.value_changed.connect(_set_bus_volume.bind(&"Music"))
	sfx_slider.value_changed.connect(_set_bus_volume.bind(&"SFX"))
	music_slider.drag_started.connect(_on_slider_drag_started)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_started.connect(_on_slider_drag_started)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	for button: BaseButton in [start_button, settings_button, credits_button, exit_button,
			close_settings_button, close_credits_button]:
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(_play_button_hover.bind(button))
		button.mouse_exited.connect(_play_button_rest.bind(button))
	settings_layer.visible = false
	credits_layer.visible = false
	_sync_volume_sliders()
	_animate_in.call_deferred()


func _process(delta: float) -> void:
	_pattern_offset += pattern_scroll_speed * delta
	_pattern_offset.x = wrapf(_pattern_offset.x, 0.0, 1.0)
	_pattern_offset.y = wrapf(_pattern_offset.y, 0.0, 1.0)
	var shader_material := pattern.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"scroll_offset", _pattern_offset)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and settings_layer.visible:
		_close_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and credits_layer.visible:
		_close_credits()
		get_viewport().set_input_as_handled()


func _start_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	start_button.disabled = true
	settings_button.disabled = true
	credits_button.disabled = true
	exit_button.disabled = true

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu_artwork, "modulate:a", 0.0, 0.32)
	tween.tween_property(logo_pivot, "scale", Vector2(0.96, 0.96), 0.32)
	tween.tween_property(logo_pivot, "modulate:a", 0.0, 0.32)
	tween.tween_property(menu_buttons, "modulate:a", 0.0, 0.22)
	tween.tween_property(menu_buttons, "position:x", menu_buttons.position.x - 24.0, 0.28)
	tween.tween_property(fade, "color:a", 1.0, 0.48)
	await tween.finished
	GameState.start_run()
	Rooms.enter_shop()


func _open_settings() -> void:
	if _transitioning or settings_layer.visible:
		return
	settings_layer.visible = true
	settings_panel.pivot_offset = settings_panel.size * 0.5
	settings_panel.scale = Vector2(0.94, 0.94)
	settings_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.24)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.16)


func _close_settings() -> void:
	if not settings_layer.visible:
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(settings_panel, "scale", Vector2(0.96, 0.96), 0.14)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.12)
	await tween.finished
	settings_layer.visible = false


func _open_credits() -> void:
	if _transitioning or credits_layer.visible:
		return
	credits_layer.visible = true
	credits_panel.pivot_offset = credits_panel.size * 0.5
	credits_panel.scale = Vector2(0.94, 0.94)
	credits_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_panel, "scale", Vector2.ONE, 0.24)
	tween.tween_property(credits_panel, "modulate:a", 1.0, 0.16)


func _close_credits() -> void:
	if not credits_layer.visible:
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(credits_panel, "scale", Vector2(0.96, 0.96), 0.14)
	tween.tween_property(credits_panel, "modulate:a", 0.0, 0.12)
	await tween.finished
	credits_layer.visible = false


func _sync_volume_sliders() -> void:
	music_slider.set_value_no_signal(_bus_percent(&"Music"))
	sfx_slider.set_value_no_signal(_bus_percent(&"SFX"))


func _bus_percent(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 100.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0,
		0.0, 100.0)


func _set_bus_volume(value: float, bus_name: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var linear := value / 100.0
	AudioServer.set_bus_volume_db(bus_index,
		linear_to_db(linear) if linear > 0.0001 else -80.0)


func _on_slider_drag_started() -> void:
	WorldAudioManager.play_ui(WorldAudioManager.CLICK_IN, Vector2.ONE, -4.0)


func _on_slider_drag_ended(_value_changed: bool) -> void:
	WorldAudioManager.play_ui(WorldAudioManager.CLICK_OUT, Vector2.ONE, -4.0)


func _animate_in() -> void:
	var buttons_start_x := menu_buttons.position.x - 64.0
	menu_artwork.modulate.a = 0.0
	logo_pivot.scale = Vector2(0.88, 0.88)
	logo_pivot.rotation_degrees = -2.2
	logo_pivot.modulate.a = 0.0
	menu_buttons.modulate.a = 0.0
	menu_buttons.position.x = buttons_start_x
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_artwork, "modulate:a", 1.0, 0.36)
	tween.tween_property(logo_pivot, "modulate:a", 1.0, 0.22)
	tween.tween_property(logo_pivot, "scale", Vector2.ONE, 0.48)
	tween.tween_property(logo_pivot, "rotation_degrees", 0.0, 0.42)
	tween.tween_property(menu_buttons, "modulate:a", 1.0, 0.28).set_delay(0.16)
	tween.tween_property(menu_buttons, "position:x", buttons_start_x + 64.0, 0.38).set_delay(0.12)
	await tween.finished
	_start_idle_motion()


func _start_idle_motion() -> void:
	if is_instance_valid(_idle_tween):
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops().set_parallel(true)
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(logo_pivot, "rotation_degrees", 0.65, 2.2)
	_idle_tween.tween_property(logo_pivot, "position:y", logo_pivot.position.y + 5.0, 2.2)
	_idle_tween.chain().tween_property(logo_pivot, "rotation_degrees", -0.45, 2.4)
	_idle_tween.tween_property(logo_pivot, "position:y", logo_pivot.position.y - 5.0, 2.4)


func _play_button_hover(button: BaseButton) -> void:
	_tween_button(button, BUTTON_HOVER_SCALE, 0.14)


func _play_button_rest(button: BaseButton) -> void:
	_tween_button(button, BUTTON_REST_SCALE, 0.18)


func _tween_button(button: BaseButton, target: Vector2, duration: float) -> void:
	var old := _button_tweens.get(button) as Tween
	if is_instance_valid(old):
		old.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	_button_tweens[button] = tween
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, duration)
