extends Node

const MAIN_MENU := &"MainMenu"
const GAMEPLAY := &"Gameplay"

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var _current_bgm_clip: StringName = MAIN_MENU


func _ready() -> void:
	background_music.play()


func play_main_menu() -> void:
	_switch_bgm(MAIN_MENU)


func play_gameplay() -> void:
	_switch_bgm(GAMEPLAY)


func current_bgm() -> StringName:
	return _current_bgm_clip


func _switch_bgm(clip: StringName) -> void:
	if _current_bgm_clip == clip:
		return
	if not background_music.playing:
		background_music.play()
	_current_bgm_clip = clip
	background_music["parameters/switch_to_clip"] = clip


func stop_bgm() -> void:
	background_music.stop()
	_current_bgm_clip = &""


func start_sfx(sfx_position: Node, sfx_path: String,
		pitch_randomizer: Array = [1.0, 1.0], volume: float = 0.0,
		start_at: float = 0.0) -> void:
	var audio_resource := load(sfx_path) as AudioStream
	if audio_resource == null:
		return
	var speaker := AudioStreamPlayer2D.new()
	sfx_position.add_child(speaker)
	speaker.stream = audio_resource
	speaker.bus = &"SFX"
	speaker.pitch_scale = randf_range(
		float(pitch_randomizer[0]), float(pitch_randomizer[1]))
	speaker.volume_db = volume
	speaker.play(start_at)
	await speaker.finished
	speaker.queue_free()


func start_ui_sfx(sfx_path: String, pitch_randomizer: Array = [1.0, 1.0],
		volume: float = 0.0, start_at: float = 0.0) -> void:
	var audio_resource := load(sfx_path) as AudioStream
	if audio_resource == null:
		return
	var speaker := AudioStreamPlayer.new()
	add_child(speaker)
	speaker.stream = audio_resource
	speaker.bus = &"SFX"
	speaker.pitch_scale = randf_range(
		float(pitch_randomizer[0]), float(pitch_randomizer[1]))
	speaker.volume_db = volume
	speaker.play(start_at)
	await speaker.finished
	speaker.queue_free()
