shader_type spatial;
// Viền sáng nhẹ màu phe phủ lên thân mecha (material_overlay): sáng ở mép, mạnh dần khi ở xa
// để mecha nổi lên khỏi nền nhà cửa / đồng ruộng.
render_mode blend_add, unshaded, depth_draw_never, cull_back, fog_disabled;

uniform vec3 mau : source_color = vec3(0.35, 0.7, 1.0);
uniform float manh = 0.55;

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float xa = smoothstep(60.0, 700.0, length(VERTEX));
	ALBEDO = mau * f * manh * mix(0.5, 1.8, xa);
}
