@tool
class_name SeratRowButton extends Button

@export var preview_title := "Nama catatan":
	set(value):
		preview_title = value
		_apply_preview()
@export var preview_marker := "◆":
	set(value):
		preview_marker = value
		_apply_preview()

var _muted := false

@onready var artwork: TextureRect = $Margin/Row/Artwork
@onready var marker: Label = $Margin/Row/Marker
@onready var title_label: Label = $Margin/Row/Title


func _ready() -> void:
	_apply_preview()


func setup(title: String, texture: Texture2D = null, marker_text := "",
		muted := false) -> void:
	_muted = muted
	title_label.text = title
	marker.text = marker_text
	artwork.texture = texture
	artwork.visible = texture != null
	_refresh_color()


func set_selected(value: bool) -> void:
	set_pressed_no_signal(value)
	_refresh_color()


func _refresh_color() -> void:
	if title_label == null:
		return
	title_label.modulate = Color("4b2414") if button_pressed \
		else (Color("79654c") if _muted else Color("4b2a18"))


func _apply_preview() -> void:
	if not is_inside_tree():
		return
	if title_label:
		title_label.text = preview_title
	if marker:
		marker.text = preview_marker
