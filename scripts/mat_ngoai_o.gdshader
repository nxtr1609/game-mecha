shader_type spatial;
// (Mọi màu trong file viết theo thang sRGB như bảng màu thường thấy; cuối cùng mới đổi sang tuyến tính.)
// Mặt đất ngoại ô: bãi cỏ xanh (vệt cắt cỏ), vườn rau luống nâu, phố cong đông–tây và phố nối bắc–nam
// (công thức giống DungNgoaiO.z_pho / x_noi), đường chính nối căn cứ – cứ điểm, quảng trường lát đá, hố bom.

uniform sampler2D tex_bt : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 duong[12];
uniform vec4 vung[8];
uniform vec4 ho[16];
uniform float d_pho = 230.0;
uniform float d_noi = 400.0;
uniform float rong_pho = 16.0;
uniform float rong_duong = 24.0;

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

// khoảng cách tới phố cong đông–tây gần nhất (z = k·d_pho + 30·sin(x/260 + 1,7k))
float kc_pho(vec2 p) {
	float k0 = round(p.y / d_pho);
	float tot = 1e9;
	for (float k = k0 - 1.0; k <= k0 + 1.0; k += 1.0) {
		float z = k * d_pho + 30.0 * sin(p.x / 260.0 + k * 1.7);
		float doc = 30.0 / 260.0 * cos(p.x / 260.0 + k * 1.7);
		tot = min(tot, abs(p.y - z) / sqrt(1.0 + doc * doc));
	}
	return tot;
}

// phố nối bắc–nam (x = j·d_noi + 24·sin(z/210 + 2,3j))
float kc_noi(vec2 p) {
	float j0 = round(p.x / d_noi);
	float tot = 1e9;
	for (float j = j0 - 1.0; j <= j0 + 1.0; j += 1.0) {
		float x = j * d_noi + 24.0 * sin(p.y / 210.0 + j * 2.3);
		float doc = 24.0 / 210.0 * cos(p.y / 210.0 + j * 2.3);
		tot = min(tot, abs(p.x - x) / sqrt(1.0 + doc * doc));
	}
	return tot;
}

void fragment() {
	vec2 p = vi_tri.xz;
	float n_lon = nhieu(p * 0.004) * 0.6 + nhieu(p * 0.03) * 0.4;
	vec3 bt = pow(texture(tex_bt, p / 7.0).rgb, vec3(1.0 / 2.2));
	// cỏ
	vec3 co = mix(vec3(0.14, 0.22, 0.075), vec3(0.27, 0.34, 0.12), n_lon);
	co *= 0.92 + 0.08 * step(0.5, fract(p.x / 7.0 + nhieu(p * 0.01) * 3.0));        // vệt cắt cỏ
	co *= 0.9 + 0.1 * nhieu(p * 1.3);
	float doc = 1.0 - clamp(phap_tg.y, 0.0, 1.0);
	co *= mix(1.0, 0.8, smoothstep(0.05, 0.3, doc));
	vec3 mau = co;
	// vườn rau: luống nâu xen xanh, từng mảnh theo nhiễu
	float vuon = smoothstep(0.7, 0.74, nhieu(p * 0.012 + 3.1));
	vec3 luong = mix(vec3(0.3, 0.22, 0.14), vec3(0.24, 0.32, 0.12), step(0.55, fract(p.y / 3.2)));
	mau = mix(mau, luong, vuon * 0.9);
	// phố
	float d_p = kc_pho(p);
	float d_n = kc_noi(p);
	float d_s = min(d_p, d_n);
	float d_dl = 1e9;
	for (int i = 0; i < 12; i++) {
		if (duong[i] != vec4(0.0)) {
			d_dl = min(d_dl, kc_doan(p, duong[i].xy, duong[i].zw));
		}
	}
	float pho = 1.0 - smoothstep(rong_pho * 0.5 - 0.4, rong_pho * 0.5 + 0.4, d_s);
	float dl = 1.0 - smoothstep(rong_duong * 0.5 - 0.4, rong_duong * 0.5 + 0.4, d_dl);
	float he = max(1.0 - smoothstep(rong_pho * 0.5 + 2.6, rong_pho * 0.5 + 3.2, d_s), 1.0 - smoothstep(rong_duong * 0.5 + 2.6, rong_duong * 0.5 + 3.2, d_dl));
	mau = mix(mau, bt * vec3(0.66, 0.65, 0.62), he);
	vec3 nhua = vec3(0.19, 0.19, 0.2) * (0.85 + 0.3 * n_lon) * (0.92 + 0.16 * nhieu(p * 0.9));
	float duong_nhua = max(pho, dl);
	mau = mix(mau, nhua, duong_nhua);
	float vach = (1.0 - smoothstep(0.15, 0.3, d_s)) * step(0.5, fract((p.x + p.y) / 10.0)) * pho * (1.0 - dl);
	vach = max(vach, (1.0 - smoothstep(0.15, 0.3, d_dl)) * dl);
	mau = mix(mau, vec3(0.78, 0.74, 0.56), vach * 0.65);
	// quảng trường
	float qt = 0.0;
	for (int i = 0; i < 8; i++) {
		if (vung[i].z > 0.0) {
			qt = max(qt, 1.0 - smoothstep(vung[i].z - 1.0, vung[i].z + 1.0, distance(p, vung[i].xy)));
		}
	}
	vec2 o = fract(p / 3.0);
	float mach = smoothstep(0.0, 0.06, o.x) * smoothstep(0.0, 0.06, 1.0 - o.x) * smoothstep(0.0, 0.06, o.y) * smoothstep(0.0, 0.06, 1.0 - o.y);
	mau = mix(mau, bt * vec3(0.66, 0.63, 0.58) * (0.78 + 0.22 * mach), qt);
	// hố bom
	for (int i = 0; i < 16; i++) {
		if (ho[i].z > 0.0) {
			float d = distance(p, ho[i].xy) / ho[i].z + (nhieu(p * 0.4) - 0.5) * 0.25;
			if (d < 2.2) {
				mau = mix(mau, vec3(0.06, 0.05, 0.04), (1.0 - smoothstep(0.2, 1.0, d)) * 0.9);
				mau = mix(mau, vec3(0.3, 0.24, 0.17), smoothstep(0.85, 1.05, d) * (1.0 - smoothstep(1.05, 1.4, d)) * 0.6);
				mau = mix(mau, mau * 0.6, (1.0 - smoothstep(1.0, 2.2, d)) * 0.5);
			}
		}
	}
	ALBEDO = pow(max(mau, vec3(0.0)), vec3(2.2));          // màu ở trên viết theo thang sRGB
	NORMAL = normalize((VIEW_MATRIX * vec4(phap_tg, 0.0)).xyz);
	ROUGHNESS = mix(0.95, 0.85, duong_nhua);
	SPECULAR = 0.3;
}
