class_name PanciSlot extends Node2D

@onready var background: Panel = $Background
@onready var hover_frame: Panel = $HoverFrame
@onready var bottle_anchor: Node2D = $BottleAnchor
@onready var empty_bottle: Node2D = $BottleAnchor/EmptyBottle
@onready var empty_label: Label = $EmptyLabel
@onready var name_label: Label = $NameLabel
@onready var stage_marker: ColorRect = $StageTrack/Marker
@onready var speed_label: Label = $SpeedLabel
@onready var cook_fill: ColorRect = $CookTrack/Fill
@onready var burn_track: Control = $BurnTrack
@onready var burn_fill: ColorRect = $BurnTrack/Fill
@onready var status_label: Label = $StatusLabel
@onready var feedback_label: Label = $FeedbackLabel


func set_hovered(value: bool) -> void:
	hover_frame.visible = value


func show_empty() -> void:
	empty_bottle.visible = true
	empty_label.visible = true
	name_label.visible = false
	$StageTrack.visible = false
	speed_label.visible = false
	$CookTrack.visible = false
	burn_track.visible = false
	status_label.visible = false
	feedback_label.visible = false


func show_brew(brew: Brew, speed: float, overcook_limit: float) -> void:
	empty_bottle.visible = false
	empty_label.visible = false
	name_label.visible = true
	$StageTrack.visible = true
	speed_label.visible = true
	$CookTrack.visible = true
	status_label.visible = true
	name_label.text = brew.display_name()
	speed_label.text = "api x%.1f" % speed

	var marker_x := ($StageTrack as Control).size.x * clampf(brew.doneness / overcook_limit, 0.0, 1.0)
	stage_marker.position.x = marker_x - stage_marker.size.x * 0.5
	cook_fill.size.x = ($CookTrack as Control).size.x * clampf(brew.doneness, 0.0, 1.0)
	cook_fill.color = Color("6fd48f") if brew.is_done else Color("ffd36f")
	burn_track.visible = brew.burn > 0.0 and not brew.is_burnt
	burn_fill.size.x = burn_track.size.x * clampf(brew.burn, 0.0, 1.0)

	feedback_label.visible = false
	status_label.text = "MENTAH"
	status_label.modulate = Color("9a8f80")
	if brew.is_burnt:
		status_label.text = "OVER"
		status_label.modulate = Color("e05a4f")
		feedback_label.text = "GOSONG!"
		feedback_label.modulate = Color("ff786d")
		feedback_label.visible = true
	elif brew.is_done:
		status_label.text = "MATANG"
		status_label.modulate = Color("3f7435")
		feedback_label.text = "MATANG!"
		feedback_label.modulate = Color("3f7435")
		feedback_label.visible = true
	elif brew.doneness >= 0.7:
		status_label.text = "hampir"
	if brew.burn > 0.55 and not brew.is_burnt:
		feedback_label.text = "ANGKAT!"
		feedback_label.modulate = Color("ad332d")
		feedback_label.visible = true
