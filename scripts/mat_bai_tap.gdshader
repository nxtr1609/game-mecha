shader_type spatial;
// (Mọi màu trong file viết theo thang sRGB; cuối cùng mới đổi sang tuyến tính.)
// Sân bãi tập bằng bê tông: tấm đổ 12 m có mạch ghép, vạch sơn: vạch xuất phát / vạch bắn (vàng, z = 300),
// các làn bắn (trắng đứt), bệ đáp tròn (0, -40), vòng sàn đấu (cam, tâm (0, 0)); ngoài sân là đất cỏ.

uniform sampler2D tex_bt : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float rong_san = 560.0;

varying vec3 vi_tri;
varying vec3 phap_tg;

void vertex() {
	vi_tri = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	phap_tg = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float nhieu(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float vach(float d, float rong) {
	return 1.0 - smoothstep(rong * 0.5 - 0.15, rong * 0.5 + 0.15, abs(d));
}

void fragment() {
	vec2 p = vi_tri.xz;
	float n_lon = nhieu(p * 0.01) * 0.6 + nhieu(p * 0.06) * 0.4;
	vec3 bt = pow(texture(tex_bt, p / 8.0).rgb, vec3(1.0 / 2.2));
	vec2 tam_o = floor(p / 12.0);
	vec3 mau = bt * vec3(0.66, 0.66, 0.65) * (0.86 + 0.14 * hash(tam_o)) * (0.88 + 0.16 * n_lon);
	vec2 o = fract(p / 12.0) * 12.0;
	float mach = min(min(o.x, 12.0 - o.x), min(o.y, 12.0 - o.y));
	mau *= 0.7 + 0.3 * smoothstep(0.05, 0.25, mach);
	// vết bánh xích / muội
	mau *= 1.0 - smoothstep(0.62, 0.8, nhieu(p * 0.03 + 7.0)) * 0.25;
	// vạch bắn
	float vang = vach(p.y - 300.0, 2.0) * step(abs(p.x), 220.0);
	// làn bắn
	float lan = 0.0;
	for (float x = -120.0; x <= 120.0; x += 60.0) {
		lan = max(lan, vach(p.x - x, 0.6) * step(-100.0, p.y) * step(p.y, 300.0) * step(0.5, fract(p.y / 10.0)));
	}
	// bệ đáp
	float d_be = distance(p, vec2(0.0, -40.0));
	float be = vach(d_be - 22.0, 1.6) + vach(d_be - 16.0, 0.8);
	vec2 hp = abs(p - vec2(0.0, -40.0));
	be = max(be, step(hp.x, 0.8) * step(hp.y, 8.0) + step(hp.y, 0.8) * step(hp.x, 8.0));
	// vòng sàn đấu
	float d_sd = length(p);
	float sd = vach(d_sd - 130.0, 2.0) * step(0.5, fract(atan(p.y, p.x) * 20.0 / 6.2832));
	mau = mix(mau, vec3(0.92, 0.88, 0.85), clamp(lan, 0.0, 1.0) * 0.8);
	mau = mix(mau, vec3(0.95, 0.78, 0.15), clamp(vang + be, 0.0, 1.0) * 0.85);
	mau = mix(mau, vec3(0.95, 0.45, 0.12), sd * 0.8);
	// ngoài sân: đất cỏ
	float ngoai = smoothstep(rong_san - 6.0, rong_san + 6.0, max(abs(p.x), abs(p.y)) + (nhieu(p * 0.05) - 0.5) * 12.0);
	vec3 co = mix(vec3(0.22, 0.27, 0.13), vec3(0.34, 0.36, 0.2), n_lon);
	mau = mix(mau, co, ngoai);
	ALBEDO = pow(max(mau, vec3(0.0)), vec3(2.2));
	NORMAL = normalize((VIEW_MATRIX * vec4(phap_tg, 0.0)).xyz);
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
}
