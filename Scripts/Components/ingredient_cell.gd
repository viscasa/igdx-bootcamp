@tool
class_name IngredientCell extends Node2D

@export var cell_color: Color = Color("c4553c"):
	set(value):
		cell_color = value
		_sync_visual()

@export var shadow_offset: Vector2 = Vector2(3, 5):
	set(value):
		shadow_offset = value
		_sync_visual()

var _lifted := false


func _ready() -> void:
	_sync_visual()


func set_cell_color(value: Color) -> void:
	cell_color = value


func set_lifted(value: bool) -> void:
	_lifted = value
	_sync_visual()


func _sync_visual() -> void:
	if not is_inside_tree():
		return
	var shadow := get_node_or_null("Shadow") as ColorRect
	var body := get_node_or_null("Body") as ColorRect
	var top := get_node_or_null("TopHighlight") as ColorRect
	var bottom := get_node_or_null("BottomShade") as ColorRect
	var border := get_node_or_null("Border") as Panel
	if shadow:
		shadow.position = shadow_offset
		shadow.visible = _lifted
	if body:
		body.color = cell_color
	if top:
		top.color = cell_color.lightened(0.35)
	if bottom:
		bottom.color = cell_color.darkened(0.3)
	if border:
		var style := border.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = cell_color.darkened(0.45)
