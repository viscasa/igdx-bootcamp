@tool
class_name IngredientPiece extends Node2D

const CELL := 46
const ARTWORKS := {
	&"jahe_merah": preload("res://Assets/Kitchen/Bahan/jahe_merah.png"),
	&"kunyit": preload("res://Assets/Kitchen/Bahan/kunyit.png"),
	&"kencur": preload("res://Assets/Kitchen/Bahan/kencur.png"),
	&"beras": preload("res://Assets/Kitchen/Bahan/beras.png"),
	&"asam_jawa": preload("res://Assets/Kitchen/Bahan/asam_jawa.png"),
	&"gula_jawa": preload("res://Assets/Kitchen/Bahan/gula_jawa.png"),
}


static func artwork_for(id: StringName) -> Texture2D:
	return ARTWORKS.get(id) as Texture2D

enum State { IN_TRAY, DRAGGING, IN_KUALI }

@export_group("Artwork")
## Shared fine tuning for the authored Sprite2D. The actual fit still follows
## the ingredient's grid bounds, while these values remain editable in scene.
@export var artwork_scale := Vector2.ONE:
	set(value):
		artwork_scale = value
		_sync_visual()
@export var artwork_offset := Vector2.ZERO:
	set(value):
		artwork_offset = value
		_sync_visual()

@export_group("Drag Juice")
@export_range(0.0, 15.0, 0.5) var maximum_drag_tilt_degrees := 7.0
@export_range(100.0, 2000.0, 50.0) var full_tilt_speed := 850.0
@export_range(0.0, 24.0, 1.0) var maximum_visual_lag := 10.0
@export_range(1.0, 30.0, 0.5) var velocity_smoothing := 12.0
@export_range(0.5, 8.0, 0.1) var tilt_spring_frequency := 3.4
@export_range(0.1, 1.5, 0.05) var tilt_damping := 0.72
@export_range(0.05, 0.3, 0.01) var lift_duration := 0.11
@export_range(1.0, 1.2, 0.01) var lifted_scale := 1.08

var data: IngredientData
var piece_id: int = -1
var cells: Array[Vector2i] = []:
	set(value):
		cells = value
		_sync_visual()
## Original atlas cell belonging to every entry in `cells`. This stays intact
## through rotations and cuts, so an offcut keeps the correct part of the art.
var artwork_cells: Array[Vector2i] = []
var artwork_grid_size := Vector2i.ZERO
var artwork_rotation_steps: int = 0
var state: State = State.IN_TRAY
var grid_pos: Vector2i = Vector2i(-1, -1)
## The full market price is paid once, when this piece first enters a
## workstation. Both halves inherit it so saved offcuts are never charged twice.
var paid: bool = false
var was_cut: bool = false:
	set(value):
		was_cut = value
		_sync_visual()
var _lifted := false
var _drag_velocity := Vector2.ZERO
var _smoothed_drag_velocity := Vector2.ZERO
var _visual_lag := Vector2.ZERO
var _drag_tilt := 0.0
var _drag_tilt_velocity := 0.0
var _scale_tween: Tween = null


func _ready() -> void:
	_sync_visual()
	set_process(true)


func _process(delta: float) -> void:
	_update_drag_juice(delta)


func setup(d: IngredientData, id: int) -> void:
	data = d
	piece_id = id
	paid = false
	was_cut = false
	cells = d.shape_cells.duplicate()
	artwork_cells = d.shape_cells.duplicate()
	artwork_grid_size = GridLogic.shape_size(d.shape_cells)
	artwork_rotation_steps = 0
	_sync_visual()


func setup_visual_mapping(source_cells: Array[Vector2i], source_size: Vector2i,
		rotation_steps: int) -> void:
	artwork_cells = source_cells.duplicate()
	artwork_grid_size = source_size
	artwork_rotation_steps = posmod(rotation_steps, 4)
	_sync_visual()


func set_editor_preview(id: StringName, shape: Array[Vector2i]) -> void:
	if not Engine.is_editor_hint():
		return
	cells = shape.duplicate()
	artwork_cells = shape.duplicate()
	artwork_grid_size = GridLogic.shape_size(shape)
	artwork_rotation_steps = 0
	_sync_visual()


func potency() -> int:
	return cells.size()


func size_cells() -> Vector2i:
	return GridLogic.shape_size(cells)


func pixel_size() -> Vector2:
	return Vector2(size_cells()) * CELL


func rotate_cw() -> void:
	cells = GridLogic.rotate_cw(cells)
	artwork_rotation_steps = posmod(artwork_rotation_steps + 1, 4)
	_sync_visual()


func set_lifted(value: bool) -> void:
	_lifted = value
	if not value:
		_drag_velocity = Vector2.ZERO
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root != null:
		_scale_tween = create_tween().set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_BACK)
		_scale_tween.tween_property(
			visual_root, "scale",
			Vector2.ONE * (lifted_scale if value else 1.0),
			lift_duration if value else lift_duration * 1.35)
	_sync_visual()


## Pointer velocity only drives the authored VisualRoot. The piece root stays
## axis-aligned, so hit testing and grid placement remain exact.
func set_drag_velocity(value: Vector2) -> void:
	_drag_velocity = value if _lifted else Vector2.ZERO


func play_placed() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	visual_root.scale = Vector2(1.13, 0.82)
	_scale_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_scale_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.24)


func _update_drag_juice(delta: float) -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	var safe_delta := minf(maxf(delta, 0.0001), 0.05)
	var velocity_blend := 1.0 - exp(-velocity_smoothing * safe_delta)
	_smoothed_drag_velocity = _smoothed_drag_velocity.lerp(
		_drag_velocity if _lifted else Vector2.ZERO, velocity_blend)

	var speed_ratio := clampf(
		_smoothed_drag_velocity.x / maxf(full_tilt_speed, 1.0), -1.0, 1.0)
	var target_tilt := deg_to_rad(maximum_drag_tilt_degrees) * speed_ratio
	var omega := TAU * tilt_spring_frequency
	var acceleration := omega * omega * (target_tilt - _drag_tilt) \
		- 2.0 * tilt_damping * omega * _drag_tilt_velocity
	_drag_tilt_velocity += acceleration * safe_delta
	_drag_tilt += _drag_tilt_velocity * safe_delta
	_drag_tilt = clampf(
		_drag_tilt,
		-deg_to_rad(maximum_drag_tilt_degrees * 1.35),
		deg_to_rad(maximum_drag_tilt_degrees * 1.35))

	var lag_target := Vector2.ZERO
	if _lifted and _smoothed_drag_velocity.length_squared() > 0.01:
		lag_target = -_smoothed_drag_velocity.normalized() * minf(
			maximum_visual_lag,
			_smoothed_drag_velocity.length() / maxf(full_tilt_speed, 1.0) \
				* maximum_visual_lag)
	var lag_blend := 1.0 - exp(-velocity_smoothing * 0.8 * safe_delta)
	_visual_lag = _visual_lag.lerp(lag_target, lag_blend)

	visual_root.position = pixel_size() * 0.5 + _visual_lag
	visual_root.rotation = _drag_tilt


func _sync_visual() -> void:
	if not is_inside_tree():
		return
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	var holder := get_node_or_null("VisualRoot/Cells")
	if holder == null:
		return
	var visual_center := pixel_size() * 0.5
	if visual_root != null and not _lifted:
		visual_root.position = visual_center + _visual_lag
	holder.position = -visual_center
	var base := data.color if data else Color("c4553c")
	var artwork := ARTWORKS.get(data.ingredient_id) as Texture2D if data else null
	_sync_full_artwork(artwork)
	var nodes := holder.get_children()
	for i in range(nodes.size()):
		var cell := nodes[i] as IngredientCell
		if cell == null:
			continue
		cell.visible = i < cells.size()
		if i < cells.size():
			cell.position = Vector2(cells[i]) * CELL
			cell.set_cell_color(base)
			if i < artwork_cells.size():
				cell.set_artwork(artwork, artwork_cells[i], artwork_grid_size,
					artwork_rotation_steps, was_cut)
			else:
				cell.set_artwork(null, Vector2i.ZERO, Vector2i.ZERO, 0, false)
			cell.set_lifted(_lifted)

	var pips := get_node_or_null("VisualRoot/BitternessPips") as Node2D
	if pips:
		var amount := mini(data.bitterness, 5) if data else 0
		pips.visible = amount > 0 and not cells.is_empty()
		if not cells.is_empty():
			pips.position = Vector2(cells[0]) * CELL + Vector2(6, 6) - visual_center
		for i in range(pips.get_child_count()):
			(pips.get_child(i) as CanvasItem).visible = i < amount


func _sync_full_artwork(texture: Texture2D) -> void:
	var full := get_node_or_null("VisualRoot/FullArtwork") as Sprite2D
	if full == null:
		return
	var usable := texture != null and artwork_grid_size.x > 0 \
		and artwork_grid_size.y > 0
	full.visible = usable and not was_cut
	if not usable:
		full.texture = null
		return

	var angle := deg_to_rad(float(posmod(artwork_rotation_steps, 4) * 90))
	full.texture = texture
	full.position = artwork_offset.rotated(angle)
	full.scale = Vector2(
		float(artwork_grid_size.x * CELL) / texture.get_width(),
		float(artwork_grid_size.y * CELL) / texture.get_height()) * artwork_scale
	full.rotation = angle
	full.modulate = Color(1.04, 1.04, 1.04, 1.0) if _lifted else Color.WHITE
