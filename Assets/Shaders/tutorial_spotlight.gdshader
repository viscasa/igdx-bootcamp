shader_type canvas_item;
render_mode unshaded;
uniform vec4 target_a = vec4(0.0);
uniform vec4 target_b = vec4(0.0);
uniform vec4 target_c = vec4(0.0);
uniform vec4 target_d = vec4(0.0);
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform float pulse = 0.0;
float rounded_box(vec2 p, vec4 box) {
	vec2 half_size = box.zw * 0.5;
	vec2 q = abs(p - box.xy - half_size) - max(half_size - 16.0, vec2(0.0));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 16.0;
}
void fragment() {
	vec2 p = UV * viewport_size;
	float d = rounded_box(p, target_a);
	if (target_b.z > 0.0) { d = min(d, rounded_box(p, target_b)); }
	if (target_c.z > 0.0) { d = min(d, rounded_box(p, target_c)); }
	if (target_d.z > 0.0) { d = min(d, rounded_box(p, target_d)); }
	float shade = smoothstep(-3.0, 18.0, d) * 0.84;
	float rim = exp(-abs(d) * 0.20) * (0.68 + 0.18 * sin(pulse));
	float glow = exp(-max(d, 0.0) * 0.035) * step(0.0, d) * 0.22;
	vec3 gold = vec3(1.0, 0.67, 0.18);
	COLOR = vec4(mix(vec3(0.025, 0.015, 0.008), gold, rim + glow), max(shade, rim + glow));
}
