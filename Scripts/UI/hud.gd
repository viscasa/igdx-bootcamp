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
@onready var feedback_toast: PanelContainer = %FeedbackToast
@onready var feedback_label: Label = %FeedbackLabel

var _switching: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_label.visible = false
	room_button.pressed.connect(_switch_room)
	kamus_button.pressed.connect(_open_kamus)
	_refresh()


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
	day_label.text = "HARI %d" % GameState.day
	event_label.text = GameState.day_event_name()
	time_label.text = "%02d:%02d.%d" % [mins, secs, tenths] if in_kitchen \
		else "%02d:%02d" % [mins, secs]
	time_label.visible = false
	time_label.modulate = Color("e05a4f") if GameState.time_left < 45.0 else Color.WHITE
	room_label.text = Rooms.NAMES[Rooms.current].to_upper()
	room_button.text = "DAPUR" if Rooms.current == Rooms.Room.KASIR else "KASIR"
	money_label.text = "DUIT %d  +%d" % [GameState.money, GameState.day_earnings]
	rep_label.text = "NAMA %d/10" % GameState.reputation
	rep_label.modulate = Color("e05a4f") if GameState.reputation <= 2 else Color.WHITE
	queue_label.text = "ANTRE %d" % GameState.queue.size()

	putar_button.visible = in_kitchen
	racik_button.visible = in_kitchen
	api_button.visible = in_kitchen

	var feedback := GameState.feedback_text()
	feedback_toast.visible = feedback != ""
	feedback_label.text = feedback
	feedback_label.modulate = GameState.feedback_color()


func _open_kamus() -> void:
	var serat := get_parent().get_node_or_null("SeratBook")
	if serat and serat.has_method("toggle"):
		serat.toggle()


func _switch_room() -> void:
	if _switching:
		return
	_switching = true
	Rooms.toggle()
