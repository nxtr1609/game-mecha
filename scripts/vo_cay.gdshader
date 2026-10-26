shader_type spatial;
// Vỏ cây rừng: thớ dọc sần sùi nâu xám (theo toạ độ của chính lưới cây nên mỗi cây trong MultiMesh giống nhau
// về vân nhưng khác màu nhờ vị trí), rêu xanh bám ở gốc và mặt hướng lên. Cây cọ dùng cùng shader (đốt ngang).

uniform vec3 mau_toi : source_color = vec3(0.14, 0.1, 0.07);
uniform vec3 mau_sang : source_color = vec3(0.38, 0.33, 0.26);
uniform vec3 mau_reu : source_color = vec3(0.16, 0.25, 0.07);
uniform float dot_ngang = 0.0;     // cây cọ: vân đốt ngang

varying vec3 lp;
varying vec3 phap_tg;
varying float ngau;

void vertex() {
	lp = VERTEX;
	phap_tg = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 goc = MODEL_MATRIX[3].xyz;
	ngau = fract(sin(dot(goc.xz, vec2(12.9898, 78.233))) * 43758.5453);
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

void fragment() {
	float g = atan(lp.z, lp.x);
	vec2 q = vec2(g * 6.0, lp.y * 0.18);
	float tho = nhieu(vec2(q.x * 1.5, q.y)) * 0.6 + nhieu(vec2(q.x * 4.0, q.y * 3.0)) * 0.4;
	float ranh = smoothstep(0.25, 0.0, abs(fract(q.x + nhieu(vec2(q.y * 2.0, 0.0)) * 0.6) - 0.5));
	vec3 c = mix(mau_toi, mau_sang, tho) * (1.0 - ranh * 0.35);
	c *= 0.85 + 0.3 * ngau;
	if (dot_ngang > 0.5) {
		float doan = smoothstep(0.12, 0.0, abs(fract(lp.y / 1.6) - 0.5) - 0.38);
		c = mix(c, mau_toi * 0.8, doan * 0.6);
	}
	float reu = max(smoothstep(7.0, 1.0, lp.y), smoothstep(0.35, 0.85, phap_tg.y)) * smoothstep(0.35, 0.65, nhieu(q * 2.0 + ngau * 9.0));
	c = mix(c, mau_reu * (0.8 + 0.4 * nhieu(q * 6.0)), reu * 0.85);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
