shader_type spatial;
// (Mọi màu trong file viết theo thang sRGB như bảng màu thường thấy; cuối cùng mới đổi sang tuyến tính.)
// Mặt đất thành phố bị tàn phá: phố ô bàn cờ (nhựa đường, vạch kẻ mờ, vỉa hè bê tông), đại lộ chéo rộng,
// quảng trường lát đá quanh cứ điểm / căn cứ, lô đất bê tông bám bụi gạch, hố bom cháy đen.
// Màu trung tính, hơi tối để mecha xanh / đỏ nổi lên.

uniform sampler2D tex_bt : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 duong[12];            // đại lộ: a.xy, b.zw (0 = bỏ qua)
uniform vec4 vung[8];              // quảng trường: x, y tâm; z bán kính
uniform vec4 ho[48];               // hố bom: x, y tâm; z bán kính
uniform float o_pho = 150.0;       // khoảng cách giữa hai phố
uniform float rong_pho = 28.0;
uniform float rong_dai_lo = 56.0;

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
	float n_nho = nhieu(p * 0.9);
	vec3 bt = pow(texture(tex_bt, p / 7.0).rgb, vec3(1.0 / 2.2));
	// lô đất trong khu phố: bê tông bẩn, lấm bụi gạch
	vec3 mau = bt * vec3(0.5, 0.49, 0.47) * (0.8 + 0.35 * n_lon);
	mau = mix(mau, vec3(0.36, 0.32, 0.29), smoothstep(0.6, 0.9, nhieu(p * 0.05)) * 0.3);
	// phố ô bàn cờ
	vec2 g = abs(fract(p / o_pho + 0.5) - 0.5) * o_pho;      // khoảng cách tới tim phố gần nhất theo x và z
	float d_pho = min(g.x, g.y);
	float pho = 1.0 - smoothstep(rong_pho * 0.5 - 0.4, rong_pho * 0.5 + 0.4, d_pho);
	float he = (1.0 - smoothstep(rong_pho * 0.5 + 5.5, rong_pho * 0.5 + 6.5, d_pho)) * (1.0 - pho);
	// đại lộ chéo
	float d_dl = 1e9;
	vec2 huong_dl = vec2(1.0, 0.0);
	for (int i = 0; i < 12; i++) {
		if (duong[i] != vec4(0.0)) {
			float d = kc_doan(p, duong[i].xy, duong[i].zw);
			if (d < d_dl) {
				d_dl = d;
				huong_dl = normalize(duong[i].zw - duong[i].xy);
			}
		}
	}
	float dai_lo = 1.0 - smoothstep(rong_dai_lo * 0.5 - 0.5, rong_dai_lo * 0.5 + 0.5, d_dl);
	float he_dl = (1.0 - smoothstep(rong_dai_lo * 0.5 + 5.5, rong_dai_lo * 0.5 + 6.5, d_dl)) * (1.0 - dai_lo);
	vec3 via_he = bt * vec3(0.64, 0.63, 0.61) * (0.85 + 0.2 * n_lon);
	mau = mix(mau, via_he, max(he, he_dl));
	// nhựa đường: tối, nứt, vá
	vec3 nhua = vec3(0.16, 0.16, 0.17) * (0.8 + 0.4 * n_lon) * (0.92 + 0.16 * n_nho);
	nhua = mix(nhua, vec3(0.1, 0.1, 0.105), smoothstep(0.62, 0.66, nhieu(p * 0.07)) * 0.6);
	float nut = smoothstep(0.012, 0.0, abs(nhieu(p * 0.45) - 0.5)) * 0.35 * smoothstep(0.4, 0.7, nhieu(p * 0.02));
	nhua *= 1.0 - nut;
	float duong_nhua = max(pho, dai_lo);
	mau = mix(mau, nhua, duong_nhua);
	// vạch kẻ mờ: tim phố (vạch đứt), đại lộ (hai mép + tim đôi)
	float phai = 0.55 + 0.45 * nhieu(p * 0.02);
	float tim_x = step(g.y, g.x) * (1.0 - smoothstep(0.18, 0.35, g.y)) * step(0.5, fract(p.x / 12.0));
	float tim_z = step(g.x, g.y) * (1.0 - smoothstep(0.18, 0.35, g.x)) * step(0.5, fract(p.y / 12.0));
	float vach = max(tim_x, tim_z) * pho * (1.0 - dai_lo);
	float doc = dot(p, huong_dl);
	float vach_dl = (1.0 - smoothstep(0.2, 0.35, abs(d_dl - (rong_dai_lo * 0.5 - 2.5))))
		+ (1.0 - smoothstep(0.15, 0.3, abs(d_dl - 0.45))) + step(0.5, fract(doc / 14.0)) * (1.0 - smoothstep(0.15, 0.3, abs(d_dl - rong_dai_lo * 0.25)));
	vach = max(vach, clamp(vach_dl, 0.0, 1.0) * dai_lo);
	mau = mix(mau, vec3(0.72, 0.68, 0.55), vach * phai * 0.7);
	// quảng trường lát đá quanh cứ điểm / căn cứ
	float qt = 0.0;
	for (int i = 0; i < 8; i++) {
		if (vung[i].z > 0.0) {
			qt = max(qt, 1.0 - smoothstep(vung[i].z - 1.0, vung[i].z + 1.0, distance(p, vung[i].xy)));
		}
	}
	vec2 o = fract(p / 3.0);
	float mach = smoothstep(0.0, 0.06, o.x) * smoothstep(0.0, 0.06, 1.0 - o.x) * smoothstep(0.0, 0.06, o.y) * smoothstep(0.0, 0.06, 1.0 - o.y);
	vec3 da = bt * vec3(0.6, 0.58, 0.55) * (0.75 + 0.25 * mach) * (0.85 + 0.2 * n_lon);
	mau = mix(mau, da, qt);
	// hố bom: lòng cháy đen, viền đất / gạch vụn bật lên
	for (int i = 0; i < 48; i++) {
		if (ho[i].z > 0.0) {
			float d = distance(p, ho[i].xy) / ho[i].z + (nhieu(p * 0.4) - 0.5) * 0.25;
			if (d < 2.2) {
				mau = mix(mau, vec3(0.05, 0.045, 0.04), (1.0 - smoothstep(0.2, 1.0, d)) * 0.92);
				mau = mix(mau, vec3(0.28, 0.24, 0.2), smoothstep(0.85, 1.05, d) * (1.0 - smoothstep(1.05, 1.4, d)) * 0.55);
				mau = mix(mau, mau * 0.55, (1.0 - smoothstep(1.0, 2.2, d)) * 0.6);   // muội than quanh hố
			}
		}
	}
	ALBEDO = pow(max(mau, vec3(0.0)), vec3(2.2));          // màu ở trên viết theo thang sRGB
	NORMAL = normalize((VIEW_MATRIX * vec4(phap_tg, 0.0)).xyz);
	ROUGHNESS = mix(0.93, 0.82, duong_nhua);
	SPECULAR = 0.3;
}
