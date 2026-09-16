shader_type canvas_item;

uniform float valid : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 edge_uv = abs(UV - vec2(0.5));
	float edge = smoothstep(0.32, 0.49, max(edge_uv.x, edge_uv.y));
	float sweep = 0.5 + 0.5 * sin((UV.x + UV.y) * 19.0 - TIME * 7.5);
	float pulse = 0.72 + 0.28 * sin(TIME * 8.0);
	vec3 good = vec3(0.30, 1.0, 0.38);
	vec3 bad = vec3(1.0, 0.12, 0.055);
	vec3 color = mix(bad, good, valid);
	float alpha = mix(0.32, 0.60, edge) * mix(0.72, 1.0, sweep) * pulse;
	COLOR = vec4(color, alpha);
}
