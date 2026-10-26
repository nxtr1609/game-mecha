shader_type spatial;
// (Mọi màu trong file viết theo thang sRGB như bảng màu thường thấy; cuối cùng mới đổi sang tuyến tính.)
// Mặt đất đồng quê: ruộng chia ô xoay nghiêng (cỡ 150 m, giống DungDongQue.o_ruong): lúa mì vàng, ruộng xanh
// luống thẳng, đất cày nâu, bãi cỏ bỏ hoang; bờ ruộng cỏ. Đường đất có vệt bánh xe nối căn cứ – cứ điểm,
// sân lát đá quanh cứ điểm, bờ sông bùn ướt, sườn dốc nhiều cỏ hơn, hố bom.

uniform sampler2D tex_bt : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 duong[12];
uniform vec4 vung[8];
uniform vec4 ho[16];
uniform float muc_nuoc = -1.8;
uniform float o_ruong = 150.0;
uniform float goc_ruong = 0.35;
uniform float rong_duong = 18.0;

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

float kc_doan(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.001), 0.0, 1.0);
	return distance(p, a + ab * t);
}

void fragment() {
	vec2 p = vi_tri.xz;
	float n_lon = nhieu(p * 0.004) * 0.6 + nhieu(p * 0.03) * 0.4;
	float n_nho = nhieu(p * 1.1);
	// ô ruộng (lưới xoay goc_ruong)
	float c = cos(-goc_ruong);
	float s = sin(-goc_ruong);
	vec2 q = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
	vec2 id = floor(q / o_ruong);
	vec2 f = fract(q / o_ruong) * o_ruong;
	// cùng công thức DungDongQue.loai_ruong (số nguyên nhỏ, không lệch giữa GPU và CPU)
	float h = fract(id.x * 0.7548777 + id.y * 0.5698403 + fract(id.x * id.y * 0.1234567));
	float doc_luong = fract(id.x * 0.3141593 + id.y * 0.2718282 + fract(id.x * id.y * 0.0577216)) < 0.5 ? q.x : q.y;
	float xa = smoothstep(60.0, 260.0, length(VERTEX));      // ở xa: luống mờ dần (tránh sọc nhòe)
	float luong = mix(0.5 + 0.5 * sin(doc_luong * 2.1), 0.5, xa);          // luống cách nhau ~3 m
	vec3 co = mix(vec3(0.13, 0.21, 0.07), vec3(0.24, 0.31, 0.1), n_lon) * (0.9 + 0.12 * n_nho);
	vec3 ruong;
	if (h < 0.3) {
		ruong = mix(vec3(0.44, 0.36, 0.16), vec3(0.54, 0.45, 0.21), n_lon) * (0.92 + 0.08 * luong);   // lúa mì vàng
	} else if (h < 0.55) {
		ruong = mix(vec3(0.17, 0.17, 0.09), vec3(0.12, 0.26, 0.07), smoothstep(0.35, 0.65, luong));  // ruộng xanh có luống
	} else if (h < 0.75) {
		ruong = mix(vec3(0.24, 0.17, 0.11), vec3(0.31, 0.23, 0.15), luong) * (0.88 + 0.15 * n_lon);       // đất cày
	} else {
		ruong = co * vec3(1.1, 1.05, 0.85);                                                            // cỏ bỏ hoang
	}
	// bờ ruộng: dải cỏ 3 m quanh ô
	float bo = 1.0 - smoothstep(2.0, 3.5, min(min(f.x, o_ruong - f.x), min(f.y, o_ruong - f.y)));
	vec3 mau = mix(ruong, co * 0.85, bo);
	// sườn dốc: cỏ (không cày được)
	float doc = 1.0 - clamp(phap_tg.y, 0.0, 1.0);
	mau = mix(mau, co * 0.85, smoothstep(0.08, 0.2, doc));
	// bờ sông bùn ướt
	mau = mix(mau, vec3(0.2, 0.17, 0.13), 1.0 - smoothstep(muc_nuoc + 0.4, muc_nuoc + 2.2, vi_tri.y));
	// sân lát đá quanh cứ điểm / căn cứ
	vec3 bt = pow(texture(tex_bt, p / 7.0).rgb, vec3(1.0 / 2.2));
	float qt = 0.0;
	for (int i = 0; i < 8; i++) {
		if (vung[i].z > 0.0) {
			qt = max(qt, 1.0 - smoothstep(vung[i].z - 1.0, vung[i].z + 1.0, distance(p, vung[i].xy) + (nhieu(p * 0.05) - 0.5) * 10.0));
		}
	}
	vec2 o = fract(p / 3.0);
	float mach = smoothstep(0.0, 0.06, o.x) * smoothstep(0.0, 0.06, 1.0 - o.x) * smoothstep(0.0, 0.06, o.y) * smoothstep(0.0, 0.06, 1.0 - o.y);
	mau = mix(mau, bt * vec3(0.66, 0.62, 0.55) * (0.78 + 0.22 * mach), qt);
	// đường đất: hai vệt bánh xe, cỏ mọc giữa
	float d_dl = 1e9;
	for (int i = 0; i < 12; i++) {
		if (duong[i] != vec4(0.0)) {
			d_dl = min(d_dl, kc_doan(p, duong[i].xy, duong[i].zw));
		}
	}
	float dat = 1.0 - smoothstep(rong_duong * 0.5 - 1.5, rong_duong * 0.5 + 1.0, d_dl + (n_nho - 0.5) * 2.0);
	vec3 mau_dat = mix(vec3(0.34, 0.27, 0.19), vec3(0.41, 0.33, 0.24), n_lon) * (0.9 + 0.12 * n_nho);
	float vet = 1.0 - smoothstep(1.0, 2.2, abs(abs(d_dl) - rong_duong * 0.22));
	mau_dat *= 1.0 - vet * 0.18;
	mau_dat = mix(mau_dat, co, (1.0 - smoothstep(0.8, 1.6, d_dl)) * 0.5);
	mau = mix(mau, mau_dat, dat * (1.0 - qt * 0.5));
	// hố bom
	for (int i = 0; i < 16; i++) {
		if (ho[i].z > 0.0) {
			float d = distance(p, ho[i].xy) / ho[i].z + (nhieu(p * 0.4) - 0.5) * 0.25;
			if (d < 2.2) {
				mau = mix(mau, vec3(0.07, 0.05, 0.04), (1.0 - smoothstep(0.2, 1.0, d)) * 0.88);
				mau = mix(mau, vec3(0.32, 0.25, 0.17), smoothstep(0.85, 1.05, d) * (1.0 - smoothstep(1.05, 1.4, d)) * 0.6);
			}
		}
	}
	ALBEDO = pow(max(mau, vec3(0.0)), vec3(2.2));          // màu ở trên viết theo thang sRGB
	NORMAL = normalize((VIEW_MATRIX * vec4(phap_tg, 0.0)).xyz);
	ROUGHNESS = 0.95;
	SPECULAR = 0.25;
}
