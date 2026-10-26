shader_type spatial;
render_mode cull_disabled;
// Lá cây vẽ bằng code trên các tấm phẳng (không cần ảnh). kieu:
//  0 = chùm lá rộng (tán cây cổ thụ, bụi cây): 9 lá hình thoi bầu xếp quanh tâm tấm, mỗi lá một sắc xanh, có gân giữa.
//  1 = lá dương xỉ: cuống giữa, lá chét xếp hai bên, nhọn dần về ngọn.
//  2 = lá cọ: cuống giữa, lá chét dài mảnh rủ xuống.
// UV: u ngang tấm, v dọc theo lá (0 = gốc, 1 = ngọn). Lá đung đưa theo gió, ánh sáng xuyên qua lá (backlight).

uniform int kieu = 0;
uniform vec3 mau_a : source_color = vec3(0.1, 0.22, 0.05);
uniform vec3 mau_b : source_color = vec3(0.3, 0.45, 0.1);
uniform float gio = 0.35;          // biên độ đung đưa (m) trên mỗi 10 m chiều cao

varying float ngau;

void vertex() {
	vec3 goc = MODEL_MATRIX[3].xyz;
	ngau = fract(sin(dot(goc.xz, vec2(12.9898, 78.233))) * 43758.5453);
	float lac = sin(TIME * 1.1 + goc.x * 0.05 + goc.z * 0.04 + VERTEX.y * 0.08) + 0.4 * sin(TIME * 2.3 + VERTEX.x * 0.3);
	VERTEX.x += lac * gio * max(VERTEX.y, 0.0) * 0.1;
	VERTEX.z += lac * gio * 0.6 * max(VERTEX.y, 0.0) * 0.1;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float co = 0.0;
	float sac = 0.5;
	float gan = 0.0;
	if (kieu == 0) {
		// lưới 7×7 ô, mỗi ô một lá xoay ngẫu nhiên (lá được tràn sang ô bên); ô càng xa tâm tấm càng dễ trống
		// nên chùm lá có viền tròn tự nhiên, không lộ hình vuông của tấm.
		vec2 g = uv * 7.0;
		for (int dx = -1; dx <= 1; dx++) {
			for (int dy = -1; dy <= 1; dy++) {
				vec2 o = floor(g) + vec2(float(dx), float(dy));
				vec2 tam = (o + 0.5 + (vec2(hash(o + 3.7 + ngau), hash(o + 9.1 - ngau)) - 0.5) * 0.7) / 7.0;
				float xa = distance(tam, vec2(0.5)) * 2.0;
				if (xa > 0.95 || hash(o + ngau * 17.0) > 1.25 - xa * 1.15) {
					continue;
				}
				float a = hash(o + 5.3 + ngau) * 6.2832;
				vec2 huong = vec2(cos(a), sin(a));
				vec2 d = uv - tam;
				vec2 q = vec2(dot(d, huong), dot(d, vec2(-huong.y, huong.x)));
				float dai = 0.085 + 0.035 * hash(o + 1.1);
				float t = q.x / dai;
				float rong = 0.036 * (1.0 - t * t) * (1.0 + 0.3 * t);
				if (abs(t) < 1.0 && abs(q.y) < rong) {
					co = 1.0;
					sac = hash(o + 2.2 + ngau);
					gan = smoothstep(0.005, 0.0, abs(q.y)) * 0.5;
				}
			}
		}
	} else {
		float x = abs(uv.x - 0.5);
		float v = uv.y;
		float rong = (kieu == 1) ? 0.46 * pow(sin(3.1416 * clamp(v * 0.95 + 0.05, 0.0, 1.0)), 0.6) * (1.0 - 0.35 * v)
			: 0.48 * pow(sin(3.1416 * clamp(v, 0.0, 1.0)), 0.5);
		float so = (kieu == 1) ? 20.0 : 26.0;
		float lech = (kieu == 1) ? 1.4 : 2.6;
		float chet = fract(v * so - x * lech);
		float day = (kieu == 1) ? 0.72 : 0.5;
		if (x < 0.018) {
			co = step(v, 0.98);
			gan = 0.6;
		} else if (x < rong && chet < day) {
			co = 1.0;
			gan = smoothstep(0.08, 0.0, abs(chet - day * 0.5)) * 0.25;
		}
		sac = hash(floor(vec2(v * so - x * lech, step(0.5, uv.x)))) * 0.6 + v * 0.4;
	}
	vec3 c = mix(mau_a, mau_b, sac) * (0.85 + 0.3 * ngau);
	c = mix(c, c * 1.35 + vec3(0.03, 0.04, 0.0), gan);
	ALBEDO = c;
	ALPHA = co;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.65;
	SPECULAR = 0.35;
	BACKLIGHT = c * 0.6;
}
