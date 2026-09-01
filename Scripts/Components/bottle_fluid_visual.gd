@tool
class_name BottleFluidVisual extends Node2D

## A signed spring-damper keeps the liquid's own momentum. Angular
## acceleration drives it toward the trailing side; stopping or reversing the
## bottle makes it overshoot before damping back to rest.

@export_range(0.05, 0.95, 0.01) var fill_ratio: float = 0.55

@export_group("Motion Sampling")
@export_range(1.0, 40.0, 0.5) var input_smoothing: float = 14.0
@export_range(0.0, 10.0, 0.1) var motion_deadzone: float = 1.2
@export_range(5.0, 120.0, 1.0) var maximum_angular_acceleration: float = 55.0

@export_group("Liquid Inertia")
@export_range(0.0, 0.5, 0.005) var inertia_gain: float = 0.16
@export_range(0.2, 4.0, 0.05) var spring_frequency: float = 1.25
@export_range(0.05, 1.0, 0.01) var damping_ratio: float = 0.22
@export_range(0.02, 0.4, 0.01) var maximum_slosh: float = 0.18

@export_group("Surface Wave")
@export_range(0.0, 4.0, 0.05) var idle_amplitude: float = 1.8
@export_range(0.005, 0.15, 0.001) var wave_frequency: float = 0.045
@export_range(0.0, 2.0, 0.05) var idle_wave_speed: float = 0.55
@export_range(0.0, 0.8, 0.01) var secondary_wave_mix: float = 0.34
@export_range(1.1, 3.0, 0.05) var secondary_wave_frequency_scale: float = 1.7
@export_range(-1.5, 1.5, 0.05) var secondary_wave_speed_ratio: float = -0.6
@export_range(0.0, 80.0, 1.0) var wave_energy_gain: float = 38.0
@export_range(1.0, 16.0, 0.5) var maximum_amplitude: float = 7.0
@export_range(0.0, 80.0, 1.0) var motion_wave_speed_gain: float = 34.0
@export_range(0.5, 12.0, 0.25) var phase_speed_smoothing: float = 3.0
@export_range(1.0, 20.0, 0.5) var maximum_motion_wave_speed: float = 8.0

@export_group("Depth")
@export_range(1.0, 20.0, 0.5) var back_layer_response: float = 5.0
@export_range(0.0, 8.0, 0.1) var back_surface_lift: float = 2.4
@export_range(0.1, 4.0, 0.1) var edge_softness: float = 0.9

@onready var back_fluid: Polygon2D = $BrewSwatchBack
@onready var front_fluid: Polygon2D = $BrewSwatch

var _last_rotation: float = 0.0
var _filtered_angular_velocity: float = 0.0
var _previous_angular_velocity: float = 0.0
var _slosh_position: float = 0.0
var _slosh_velocity: float = 0.0
var _back_position: float = 0.0
var _back_velocity: float = 0.0
var _wave_phase: float = 0.0
var _wave_phase_velocity: float = 0.0


func _ready() -> void:
	_last_rotation = global_rotation
	_wave_phase_velocity = idle_wave_speed
	set_process(true)
	_update_materials(idle_amplitude)


func _process(delta: float) -> void:
	if not is_instance_valid(front_fluid) or not is_instance_valid(back_fluid):
		return

	var safe_delta := maxf(delta, 0.0001)
	var angle_delta := wrapf(global_rotation - _last_rotation, -PI, PI)
	var raw_angular_velocity := angle_delta / safe_delta
	_last_rotation = global_rotation

	var smoothing := 1.0 - exp(-input_smoothing * safe_delta)
	_filtered_angular_velocity = lerpf(
		_filtered_angular_velocity, raw_angular_velocity, smoothing)
	var angular_acceleration := (
		_filtered_angular_velocity - _previous_angular_velocity) / safe_delta
	_previous_angular_velocity = _filtered_angular_velocity
	if absf(angular_acceleration) < motion_deadzone:
		angular_acceleration = 0.0
	angular_acceleration = clampf(
		angular_acceleration,
		-maximum_angular_acceleration,
		maximum_angular_acceleration
	)

	# The liquid centroid is below the visual pivot for every orientation.
	# Positive clockwise acceleration therefore pushes the mass toward the
	# opposite/trailing side through this signed lever.
	var drive := -angular_acceleration * _liquid_lever() * inertia_gain
	var omega := TAU * spring_frequency
	var spring_acceleration := drive \
		- 2.0 * damping_ratio * omega * _slosh_velocity \
		- omega * omega * _slosh_position
	_slosh_velocity += spring_acceleration * safe_delta
	_slosh_position += _slosh_velocity * safe_delta
	if absf(_slosh_position) > maximum_slosh:
		_slosh_position = clampf(
			_slosh_position, -maximum_slosh, maximum_slosh)
		_slosh_velocity *= 0.42

	# The rear surface follows the same physical side, only with a small lag.
	var back_response := 1.0 - exp(-back_layer_response * safe_delta)
	_back_position = lerpf(_back_position, _slosh_position, back_response)
	_back_velocity = lerpf(_back_velocity, _slosh_velocity, back_response)

	var energy := sqrt(
		_slosh_position * _slosh_position
		+ pow(_slosh_velocity / maxf(omega, 0.001), 2.0)
	)
	# Keep the wave moving forward on one continuous timeline. Energy only
	# changes its speed; it never chases a wrapped angle or abruptly reverses.
	var target_phase_velocity := minf(
		idle_wave_speed + energy * motion_wave_speed_gain,
		maximum_motion_wave_speed
	)
	var speed_blend := 1.0 - exp(-phase_speed_smoothing * safe_delta)
	_wave_phase_velocity = lerpf(
		_wave_phase_velocity,
		target_phase_velocity,
		speed_blend
	)
	_wave_phase = fposmod(
		_wave_phase + _wave_phase_velocity * safe_delta,
		TAU
	)

	var amplitude := clampf(
		idle_amplitude + energy * wave_energy_gain,
		idle_amplitude,
		maximum_amplitude
	)
	_update_materials(amplitude)


func _liquid_lever() -> float:
	var points := _world_polygon()
	if points.size() < 3:
		return 1.0
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	var surface := _surface_for_ratio(points, fill_ratio, 0.0, 0.0)
	var liquid_points := _clip_below(points, surface)
	var centroid := _polygon_centroid(liquid_points)
	var half_height := maxf((max_y - min_y) * 0.5, 1.0)
	return clampf((centroid.y - global_position.y) / half_height, 0.25, 1.25)


func _update_materials(amplitude: float) -> void:
	if not is_instance_valid(front_fluid) or not is_instance_valid(back_fluid):
		return
	var points := _world_polygon()
	if points.size() < 3:
		return

	var min_x := points[0].x
	var max_x := points[0].x
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
	var center := (min_x + max_x) * 0.5
	var scale_factor := maxf(
		(front_fluid.global_transform.x.length()
			+ front_fluid.global_transform.y.length()) * 0.5,
		0.001
	)

	var front_surface := _surface_for_ratio(
		points, fill_ratio, center, _slosh_position)
	var back_surface := _surface_for_ratio(
		points, fill_ratio, center, _back_position)
	_set_layer_parameters(
		front_fluid.material as ShaderMaterial,
		front_surface,
		center,
		amplitude * scale_factor,
		_slosh_position,
		_wave_phase,
		0.0,
		scale_factor
	)
	_set_layer_parameters(
		back_fluid.material as ShaderMaterial,
		back_surface,
		center,
		(amplitude * 0.72 + idle_amplitude * 0.28) * scale_factor,
		_back_position,
		_wave_phase + 2.25,
		-back_surface_lift * scale_factor,
		scale_factor
	)


func _set_layer_parameters(material: ShaderMaterial, surface: float,
		center: float, amplitude: float, tilt: float, phase: float,
		bias: float, scale_factor: float) -> void:
	if material == null:
		return
	material.set_shader_parameter("surface_y", surface)
	material.set_shader_parameter("center_x", center)
	material.set_shader_parameter("wave_amplitude", amplitude)
	material.set_shader_parameter("wave_frequency", wave_frequency / scale_factor)
	material.set_shader_parameter("wave_phase", phase)
	material.set_shader_parameter("secondary_wave_mix", secondary_wave_mix)
	material.set_shader_parameter(
		"secondary_wave_frequency_scale",
		secondary_wave_frequency_scale
	)
	material.set_shader_parameter(
		"secondary_wave_speed_ratio",
		secondary_wave_speed_ratio
	)
	material.set_shader_parameter("wave_tilt", tilt)
	material.set_shader_parameter("surface_bias", bias)
	material.set_shader_parameter("edge_softness", edge_softness * scale_factor)


func _world_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in front_fluid.polygon:
		points.append(front_fluid.to_global(point))
	return points


func _surface_for_ratio(points: PackedVector2Array, ratio: float,
		center_x: float, tilt: float) -> float:
	var gravity_points := PackedVector2Array()
	for point in points:
		gravity_points.append(Vector2(
			point.x,
			point.y - (point.x - center_x) * tilt
		))
	var low := gravity_points[0].y
	var high := gravity_points[0].y
	for point in gravity_points:
		low = minf(low, point.y)
		high = maxf(high, point.y)

	var target_area := _polygon_area(gravity_points) * clampf(ratio, 0.0, 1.0)
	for _step in range(22):
		var middle := (low + high) * 0.5
		if _area_below(gravity_points, middle) > target_area:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _area_below(points: PackedVector2Array, surface: float) -> float:
	return _polygon_area(_clip_below(points, surface))


func _clip_below(points: PackedVector2Array, surface: float) -> PackedVector2Array:
	var clipped := PackedVector2Array()
	for i in range(points.size()):
		var from := points[i]
		var to := points[(i + 1) % points.size()]
		var from_inside := from.y >= surface
		var to_inside := to.y >= surface
		if from_inside and to_inside:
			clipped.append(to)
		elif from_inside and not to_inside:
			clipped.append(_surface_intersection(from, to, surface))
		elif not from_inside and to_inside:
			clipped.append(_surface_intersection(from, to, surface))
			clipped.append(to)
	return clipped


func _surface_intersection(from: Vector2, to: Vector2, surface: float) -> Vector2:
	var height := to.y - from.y
	if is_zero_approx(height):
		return Vector2(to.x, surface)
	var weight := (surface - from.y) / height
	return from.lerp(to, weight)


func _polygon_centroid(points: PackedVector2Array) -> Vector2:
	if points.size() < 3:
		return global_position
	var cross_sum := 0.0
	var weighted := Vector2.ZERO
	for i in range(points.size()):
		var current := points[i]
		var next := points[(i + 1) % points.size()]
		var cross := current.x * next.y - next.x * current.y
		cross_sum += cross
		weighted += (current + next) * cross
	if is_zero_approx(cross_sum):
		return global_position
	return weighted / (3.0 * cross_sum)


func _polygon_area(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0
	var twice_area := 0.0
	for i in range(points.size()):
		var current := points[i]
		var next := points[(i + 1) % points.size()]
		twice_area += current.x * next.y - next.x * current.y
	return absf(twice_area) * 0.5
