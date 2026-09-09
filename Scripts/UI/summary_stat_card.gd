@tool
class_name SummaryStatCard
extends Control

@export var card_icon: Texture2D:
	set(value):
		card_icon = value
		_sync_preview()
@export var caption := "TERLAYANI":
	set(value):
		caption = value
		_sync_preview()
@export var preview_value := "4":
	set(value):
		preview_value = value
		_sync_preview()
@export var value_color := Color("4f240e"):
	set(value):
		value_color = value
		_sync_preview()


func _ready() -> void:
	_sync_preview()


func set_value(value: String) -> void:
	$Margin/Row/Copy/Value.text = value


func _sync_preview() -> void:
	if not is_node_ready():
		return
	$Margin/Row/Icon.texture = card_icon
	$Margin/Row/Copy/Value.text = preview_value
	$Margin/Row/Copy/Value.add_theme_color_override("font_color", value_color)
	$Margin/Row/Copy/Caption.text = caption
