shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float direction : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float travel = mix(-0.35, 1.35, 1.0 - flash);
	float axis = UV.x + UV.y * 0.36;
	if (direction < 0.0) {
		axis = 1.36 - axis;
	}
	float streak = 1.0 - smoothstep(0.035, 0.13, abs(axis - travel));
	vec3 shine = vec3(1.0, 0.96, 0.62) * streak * flash * base.a;
	COLOR = vec4(base.rgb + shine * 0.85, base.a);
}
