class_name MainMenu extends Control

@onready var menu_panel: Control = %MenuPanel
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var settings_layer: Control = %SettingsLayer
@onready var settings_panel: Control = %SettingsPanel
@onready var close_settings_button: Button = %CloseSettingsButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fade: ColorRect = %Fade

var _transitioning := false


func _ready() -> void:
	WorldAudioManager.play_main_menu()
	WorldAudioManager.set_button_cue(start_button, WorldAudioManager.CONFIRM)
	WorldAudioManager.set_button_cue(settings_button, WorldAudioManager.MENU_OPEN)
	WorldAudioManager.set_button_cue(exit_button, WorldAudioManager.CANCEL)
	WorldAudioManager.set_button_cue(close_settings_button, WorldAudioManager.MENU_CLOSE)
	start_button.pressed.connect(_start_game)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(get_tree().quit)
	close_settings_button.pressed.connect(_close_settings)
	music_slider.value_changed.connect(_set_bus_volume.bind(&"Music"))
	sfx_slider.value_changed.connect(_set_bus_volume.bind(&"SFX"))
	music_slider.drag_started.connect(_on_slider_drag_started)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_started.connect(_on_slider_drag_started)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	settings_layer.visible = false
	_sync_volume_sliders()
	_animate_in.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and settings_layer.visible:
		_close_settings()
		get_viewport().set_input_as_handled()


func _start_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	start_button.disabled = true
	settings_button.disabled = true
	exit_button.disabled = true

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu_panel, "modulate:a", 0.0, 0.32)
	tween.tween_property(menu_panel, "scale", Vector2(0.97, 0.97), 0.32)
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
	menu_panel.pivot_offset = menu_panel.size * 0.5
	menu_panel.scale = Vector2(0.97, 0.97)
	menu_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_panel, "scale", Vector2.ONE, 0.42)
	tween.tween_property(menu_panel, "modulate:a", 1.0, 0.28)
