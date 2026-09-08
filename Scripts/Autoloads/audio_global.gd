extends Node

const MAIN_MENU := &"MainMenu"
const GAMEPLAY := &"Gameplay"

const BUTTON := &"button"
const CANCEL := &"cancel"
const CLICK_IN := &"click_in"
const CLICK_OUT := &"click_out"
const CONFIRM := &"confirm"
const CURRENCY := &"currency"
const DIALOGUE_BLIP := &"dialogue_blip"
const DIALOGUE_EXPRESSION := &"dialogue_expression"
const BREW_BURNT := &"brew_burnt"
const BREW_READY := &"brew_ready"
const FAILURE := &"failure"
const HEAT_TICK := &"heat_tick"
const HIGHLIGHT := &"highlight"
const INGREDIENT_RUSTLE := &"ingredient_rustle"
const LOCK := &"lock"
const MENU_CLOSE := &"menu_close"
const MENU_OPEN := &"menu_open"
const PAUSE := &"pause"
const PAGE_FLIP := &"page_flip"
const PAPER_NOTE := &"paper_note"
const PIPISAN_HIT := &"pipisan_hit"
const PURCHASE := &"purchase"
const SELL := &"sell"
const SUCCESS := &"success"
const UNLOCK := &"unlock"
const UNPAUSE := &"unpause"
const WARNING := &"warning"

const SFX := {
	BUTTON: preload("res://Assets/SFX/Button_Pressed.wav"),
	CANCEL: preload("res://Assets/SFX/Cancel.wav"),
	CLICK_IN: preload("res://Assets/SFX/Clicked_In.wav"),
	CLICK_OUT: preload("res://Assets/SFX/Clicked_Out.wav"),
	CONFIRM: preload("res://Assets/SFX/Confirm.wav"),
	CURRENCY: preload("res://Assets/SFX/Currency.wav"),
	DIALOGUE_BLIP: preload("res://Assets/SFX/Dialogue_Blip.wav"),
	DIALOGUE_EXPRESSION: preload("res://Assets/SFX/Dialogue_Expression.wav"),
	BREW_BURNT: preload("res://Assets/SFX/brew_burnt.ogg"),
	BREW_READY: preload("res://Assets/SFX/brew_ready.ogg"),
	FAILURE: preload("res://Assets/SFX/Failure.wav"),
	HEAT_TICK: preload("res://Assets/SFX/heat_tick.ogg"),
	HIGHLIGHT: preload("res://Assets/SFX/Highlight.wav"),
	INGREDIENT_RUSTLE: preload("res://Assets/SFX/ingredient_rustle.mp3"),
	LOCK: preload("res://Assets/SFX/Lock.wav"),
	MENU_CLOSE: preload("res://Assets/SFX/Menu_Close.wav"),
	MENU_OPEN: preload("res://Assets/SFX/Menu_Open.wav"),
	PAUSE: preload("res://Assets/SFX/Pause.wav"),
	PAGE_FLIP: preload("res://Assets/SFX/page_flip.mp3"),
	PAPER_NOTE: preload("res://Assets/SFX/paper_note.mp3"),
	PIPISAN_HIT: preload("res://Assets/SFX/pipisan_hit.mp3"),
	PURCHASE: preload("res://Assets/SFX/Purchase.wav"),
	SELL: preload("res://Assets/SFX/Sell.wav"),
	SUCCESS: preload("res://Assets/SFX/Success.wav"),
	UNLOCK: preload("res://Assets/SFX/Unlock.wav"),
	UNPAUSE: preload("res://Assets/SFX/Unpause.wav"),
	WARNING: preload("res://Assets/SFX/Warning.wav"),
}

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var _current_bgm_clip: StringName = MAIN_MENU
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_configure_node)
	_configure_branch(get_tree().root)
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


## Every ordinary Godot button gets the same small hover/click feedback.
## A button may override its click with `sfx_pressed` metadata; an empty value
## silences the automatic click when its action plays a more specific cue.
func _configure_branch(node: Node) -> void:
	_configure_node(node)
	for child in node.get_children():
		_configure_branch(child)


func _configure_node(node: Node) -> void:
	if not node is BaseButton or node.has_meta("sfx_wired"):
		return
	var button := node as BaseButton
	button.set_meta("sfx_wired", true)
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_hovered(button: BaseButton) -> void:
	if button.disabled or not button.is_visible_in_tree():
		return
	play_ui(HIGHLIGHT, Vector2(0.98, 1.02), -7.0, 55)


func _on_button_pressed(button: BaseButton) -> void:
	if button.disabled:
		return
	var cue := StringName(button.get_meta("sfx_pressed", &"")) \
		if button.has_meta("sfx_pressed") else (
			CLICK_IN if button.toggle_mode and button.button_pressed else (
				CLICK_OUT if button.toggle_mode else BUTTON))
	if cue != &"":
		play_ui(cue, Vector2(0.98, 1.02), -3.0, 35)


func set_button_cue(button: BaseButton, cue: StringName) -> void:
	button.set_meta("sfx_pressed", cue)


func play_ui(cue: StringName, pitch_range := Vector2.ONE,
		volume_db: float = 0.0, min_gap_ms: int = 0) -> void:
	var stream := SFX.get(cue) as AudioStream
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if min_gap_ms > 0 and now - int(_last_played.get(cue, -1000000)) < min_gap_ms:
		return
	_last_played[cue] = now
	var speaker := AudioStreamPlayer.new()
	add_child(speaker)
	speaker.process_mode = Node.PROCESS_MODE_ALWAYS
	speaker.stream = stream
	speaker.bus = &"SFX"
	speaker.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	speaker.volume_db = volume_db
	speaker.play()
	await speaker.finished
	if is_instance_valid(speaker):
		speaker.queue_free()


func play_result(cue: StringName) -> void:
	play_ui(CURRENCY, Vector2(0.98, 1.02), -3.0, 250)
	await get_tree().create_timer(0.32, true).timeout
	play_ui(cue, Vector2.ONE, -3.0, 1000)


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
