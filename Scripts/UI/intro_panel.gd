class_name IntroPanel extends Control

@onready var start_button: Button = %StartButton
@onready var panel: Control = $Panel
@onready var steps: HBoxContainer = %Steps


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldAudioManager.set_button_cue(start_button, WorldAudioManager.CONFIRM)
	start_button.pressed.connect(_start)
	var scripted := "--script" in OS.get_cmdline_args()
	visible = not scripted and GameState.day == 1 and not GameState.intro_seen
	if visible:
		get_tree().paused = true
		_play_intro()


func _play_intro() -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0.0
	var panel_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_tween.set_parallel(true)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.22)

	for index in range(steps.get_child_count()):
		var card := steps.get_child(index) as Control
		if card == null:
			continue
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.92, 0.92)
		card.modulate.a = 0.0
		var card_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "scale", Vector2.ONE, 0.3) \
			.set_delay(0.08 + index * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(card, "modulate:a", 1.0, 0.22) \
			.set_delay(0.08 + index * 0.07)


func _start() -> void:
	GameState.intro_seen = true
	visible = false
	get_tree().paused = false
	WorldAudioManager.play_gameplay()
	GameState.post("Klik pelanggan untuk mulai.  F membuka Serat.",
		Color("ffd36f"))
