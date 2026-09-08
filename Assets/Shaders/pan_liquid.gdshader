shader_type canvas_item;

uniform float heat : hint_range(0.0, 1.0) = 0.5;
uniform vec4 top_tint : source_color = vec4(1.0, 0.9, 0.65, 1.0);

void fragment() {
	float depth = smoothstep(0.0, 1.0, UV.y);
	vec3 shaded = mix(COLOR.rgb * top_tint.rgb, COLOR.rgb * 0.62, depth * 0.58);
	float rim = (1.0 - smoothstep(0.0, 0.13, UV.y)) * (0.18 + heat * 0.12);
	COLOR = vec4(shaded + rim, COLOR.a);
}
