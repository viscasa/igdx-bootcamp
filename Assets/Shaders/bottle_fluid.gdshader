shader_type canvas_item;
render_mode unshaded;

// The polygon supplies the bottle mask. Its surface is evaluated in world
// space, which keeps gravity horizontal regardless of the bottle transform.
uniform float surface_y = 0.0;
uniform float center_x = 0.0;
uniform float wave_amplitude = 1.0;
uniform float wave_frequency = 0.045;
uniform float wave_phase = 0.0;
uniform float secondary_wave_mix = 0.34;
uniform float secondary_wave_frequency_scale = 1.7;
uniform float secondary_wave_speed_ratio = -0.6;
uniform float wave_tilt = 0.0;
uniform float surface_bias = 0.0;
uniform float edge_softness = 0.9;
uniform float rim_strength : hint_range(0.0, 1.0, 0.05) = 0.28;
uniform vec4 layer_tint : source_color = vec4(1.0);

varying vec2 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	float primary_wave = sin(
		world_position.x * wave_frequency + wave_phase
	);
	float secondary_wave = sin(
		world_position.x * wave_frequency * secondary_wave_frequency_scale
		+ wave_phase * secondary_wave_speed_ratio + 1.7
	) * secondary_wave_mix;
	float wave = (primary_wave + secondary_wave) * wave_amplitude;
	float surface = surface_y + surface_bias + wave
		+ (world_position.x - center_x) * wave_tilt;
	float liquid_mask = smoothstep(
		surface - edge_softness,
		surface + edge_softness,
		world_position.y
	);
	float rim = 1.0 - smoothstep(
		edge_softness,
		edge_softness * 3.5,
		abs(world_position.y - surface)
	);
	vec4 liquid_color = COLOR * layer_tint;
	liquid_color.rgb = mix(
		liquid_color.rgb,
		min(liquid_color.rgb * 1.22, vec3(1.0)),
		rim * rim_strength
	);
	liquid_color.a *= liquid_mask;
	COLOR = liquid_color;
}
