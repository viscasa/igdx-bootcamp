class_name IntroPanel extends Control

@onready var start_button: Button = %StartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_start)
	var scripted := "--script" in OS.get_cmdline_args()
	visible = not scripted and GameState.day == 1 and not GameState.intro_seen
	if visible:
		get_tree().paused = true


func _start() -> void:
	GameState.intro_seen = true
	visible = false
	get_tree().paused = false
	GameState.post("Klik pelanggan untuk mulai.  F membuka Serat.",
		Color("ffd36f"))
