class_name HUD extends Control

## Compact scene-authored HUD. It keeps only state needed for the next
## decision; explanations live in the intro and Serat.

@onready var day_label: Label = %DayLabel
@onready var event_label: Label = %EventLabel
@onready var time_label: Label = %TimeLabel
@onready var room_label: Label = %RoomLabel
@onready var room_button: Button = %RoomButton
@onready var money_label: Label = %MoneyLabel
@onready var rep_label: Label = %RepLabel
@onready var queue_label: Label = %QueueLabel
@onready var putar_button: Button = %PutarButton
@onready var racik_button: Button = %RacikButton
@onready var api_button: Button = %ApiButton
@onready var kamus_button: Button = %KamusButton
@onready var feedback_toast: Control = %FeedbackToast
@onready var feedback_label: Label = %FeedbackLabel

var _switching: bool = false
var _feedback_text: String = ""
var _motion_tweens: Dictionary = {}
var _value_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_label.visible = false
	WorldAudioManager.set_button_cue(room_button, WorldAudioManager.MENU_CLOSE)
	WorldAudioManager.set_button_cue(kamus_button, &"")
	room_button.pressed.connect(_switch_room)
	kamus_button.pressed.connect(_open_kamus)
	_bind_button_motion(room_button, -0.025)
	_bind_button_motion(kamus_button, 0.025)
	_refresh()
	call_deferred("_play_entrance")


func _process(_delta: float) -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	if not is_node_ready() or GameState.phase != GameState.Phase.SHIFT:
		return
	if GameState.study_open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed \
				and room_button.get_global_rect().has_point(mb.position):
			get_viewport().set_input_as_handled()
			_switch_room()


func _refresh() -> void:
	if not is_node_ready():
		return
	var shown_time := maxf(GameState.time_left, 0.0)
	var total_tenths := int(floor(shown_time * 10.0))
	var mins := total_tenths / 600
	var secs := (total_tenths / 10) % 60
	var tenths := total_tenths % 10
	var in_kitchen := Rooms.current == Rooms.Room.DAPUR
	var illustrated := get_node_or_null("%RoomCaption") != null
	_set_value(day_label, "%d" % GameState.day if illustrated \
		else "HARI %d" % GameState.day)
	event_label.text = GameState.day_event_name()
	time_label.text = "%02d:%02d.%d" % [mins, secs, tenths] if in_kitchen \
		else "%02d:%02d" % [mins, secs]
	time_label.visible = false
	time_label.modulate = Color("e05a4f") if GameState.time_left < 45.0 else Color.WHITE
	room_label.text = Rooms.NAMES[Rooms.current].to_upper()
	var destination := "DAPUR" if Rooms.current == Rooms.Room.KASIR else "KASIR"
	room_button.text = destination
	var room_caption := get_node_or_null("%RoomCaption") as Label
	if room_caption != null:
		room_button.add_theme_color_override("font_color", Color.TRANSPARENT)
		room_button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
		room_button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
		room_caption.text = destination
	_set_value(money_label, "%d" % GameState.money if illustrated \
		else "DUIT %d  +%d" % [GameState.money, GameState.day_earnings])
	_set_value(rep_label, "%d/10" % GameState.reputation if illustrated \
		else "NAMA %d/10" % GameState.reputation)
	rep_label.modulate = Color("e05a4f") if GameState.reputation <= 2 else Color.WHITE
	_set_value(queue_label, "%d" % GameState.queue.size() if illustrated \
		else "ANTRE %d" % GameState.queue.size())

	putar_button.visible = in_kitchen
	racik_button.visible = in_kitchen
	api_button.visible = in_kitchen

	var feedback := GameState.feedback_text()
	if feedback != _feedback_text:
		_feedback_text = feedback
		_show_feedback(feedback)
	if feedback != "":
		feedback_label.modulate = GameState.feedback_color()


func _set_value(label: Label, value: String) -> void:
	if label.text == value:
		return
	var animate := label.text != ""
	label.text = value
	if animate and label.visible:
		_pulse(label)


func _pulse(control: Control) -> void:
	var key := control.get_instance_id()
	var previous := _value_tweens.get(key) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 1.16
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_value_tweens[key] = tween
	tween.tween_property(control, "scale", Vector2.ONE, 0.24)


func _show_feedback(message: String) -> void:
	if message == "":
		feedback_toast.visible = false
		return
	feedback_label.text = message
	feedback_toast.visible = true
	feedback_toast.pivot_offset = feedback_toast.size * 0.5
	feedback_toast.modulate.a = 0.0
	feedback_toast.scale = Vector2(0.94, 0.94)
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(feedback_toast, "modulate:a", 1.0, 0.18)
	tween.tween_property(feedback_toast, "scale", Vector2.ONE, 0.24)


func _bind_button_motion(button: BaseButton, tilt: float) -> void:
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_animate_button.bind(button, Vector2.ONE * 1.06, tilt))
	button.mouse_exited.connect(_animate_button.bind(button, Vector2.ONE, 0.0))
	button.button_down.connect(_animate_button.bind(button, Vector2.ONE * 0.95, 0.0))
	button.button_up.connect(_animate_button.bind(button, Vector2.ONE * 1.06, tilt))


func _animate_button(button: BaseButton, target_scale: Vector2,
		target_rotation: float) -> void:
	var key := button.get_instance_id()
	var previous := _motion_tweens.get(key) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	_motion_tweens[key] = tween
	tween.tween_property(button, "scale", target_scale, 0.16)
	tween.tween_property(button, "rotation", target_rotation, 0.16)


func _play_entrance() -> void:
	var directions := {
		"hud_entrance_left": Vector2(-90.0, 0.0),
		"hud_entrance_right": Vector2(90.0, 0.0),
		"hud_entrance_bottom": Vector2(0.0, 90.0),
	}
	var stagger := 0
	for group_name in directions:
		for item in get_tree().get_nodes_in_group(group_name):
			if not is_ancestor_of(item) or not item is CanvasItem:
				continue
			var canvas_item := item as CanvasItem
			var final_position: Vector2 = item.position
			item.position = final_position + directions[group_name]
			canvas_item.modulate.a = 0.0
			var delay := float(stagger) * 0.055
			var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_BACK)
			tween.tween_property(item, "position", final_position, 0.42).set_delay(delay)
			tween.tween_property(canvas_item, "modulate:a", 1.0, 0.22).set_delay(delay)
			stagger += 1


func _open_kamus() -> void:
	var serat := get_parent().get_node_or_null("SeratBook")
	if serat and serat.has_method("toggle"):
		serat.toggle()


func _switch_room() -> void:
	if _switching:
		return
	_switching = true
	Rooms.toggle()
