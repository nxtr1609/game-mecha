shader_type spatial;
render_mode cull_disabled;
// Mặt bia tròn: các vòng đỏ / trắng xen kẽ, hồng tâm đỏ, ngoài vòng tròn thì bỏ (trong suốt).

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	if (r > 1.0) {
		discard;
	}
	float vong = floor(r * 5.0);
	vec3 mau = mod(vong, 2.0) < 0.5 ? vec3(0.85, 0.08, 0.05) : vec3(0.95, 0.93, 0.88);
	if (r > 0.94) {
		mau = vec3(0.12);
	}
	ALBEDO = mau;
	EMISSION = mau * 0.25;
	ROUGHNESS = 0.6;
}
