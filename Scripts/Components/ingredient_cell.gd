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

## A little overlap keeps painted outlines and antialiasing from being shaved
## off at cell boundaries once the physical ingredient has been cut.
@export_range(0.0, 8.0, 0.5) var artwork_bleed: float = 4.0

var _lifted := false
var _has_artwork := false


func _ready() -> void:
	_sync_visual()


func set_cell_color(value: Color) -> void:
	cell_color = value


func set_lifted(value: bool) -> void:
	_lifted = value
	_sync_visual()


## Shows one cell-sized crop of a larger ingredient illustration. Every cell
## receives a different crop, so together they reconstruct one continuous
## picture instead of repeating the ingredient in every square.
func set_artwork(texture: Texture2D, source_cell: Vector2i,
		source_grid_size: Vector2i, rotation_steps: int,
		show_slice: bool) -> void:
	var artwork := get_node_or_null("ArtworkSlice") as Sprite2D
	_has_artwork = texture != null and source_grid_size.x > 0 and source_grid_size.y > 0
	if artwork == null:
		_sync_visual()
		return
	if not _has_artwork:
		artwork.texture = null
		artwork.visible = false
		_sync_visual()
		return

	var slice_size := Vector2(
		float(texture.get_width()) / source_grid_size.x,
		float(texture.get_height()) / source_grid_size.y)
	var source_scale := Vector2(
		float(IngredientPiece.CELL) / slice_size.x,
		float(IngredientPiece.CELL) / slice_size.y)
	var base_start := Vector2(source_cell) * slice_size
	var source_bleed := Vector2(artwork_bleed, artwork_bleed) / source_scale
	var region_start := (base_start - source_bleed).max(Vector2.ZERO)
	var region_end := (base_start + slice_size + source_bleed).min(texture.get_size())
	var region_size := region_end - region_start
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region_start, region_size)
	artwork.texture = atlas
	var angle := deg_to_rad(float(posmod(rotation_steps, 4) * 90))
	var source_center_offset := (region_start + region_size * 0.5 \
		- (base_start + slice_size * 0.5)) * source_scale
	artwork.position = Vector2.ONE * IngredientPiece.CELL * 0.5 \
		+ source_center_offset.rotated(angle)
	artwork.scale = source_scale
	artwork.rotation = angle
	artwork.visible = show_slice
	_sync_visual()


func _sync_visual() -> void:
	if not is_inside_tree():
		return
	var shadow := get_node_or_null("Shadow") as ColorRect
	var body := get_node_or_null("Body") as ColorRect
	var artwork := get_node_or_null("ArtworkSlice") as Sprite2D
	var top := get_node_or_null("TopHighlight") as ColorRect
	var bottom := get_node_or_null("BottomShade") as ColorRect
	var border := get_node_or_null("Border") as Panel
	if shadow:
		shadow.position = shadow_offset
		shadow.visible = _lifted
	if body:
		body.color = Color(cell_color, 0.16) if _has_artwork else cell_color
	if artwork:
		artwork.modulate = Color(1.04, 1.04, 1.04, 1.0) if _lifted else Color.WHITE
	if top:
		top.color = Color(cell_color.lightened(0.35), 0.28 if _has_artwork else 1.0)
	if bottom:
		bottom.color = Color(cell_color.darkened(0.3), 0.22 if _has_artwork else 1.0)
	if border:
		var style := border.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = Color("6d351f", 0.72) if _has_artwork \
				else cell_color.darkened(0.45)
