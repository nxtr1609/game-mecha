shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// Nước suối rừng: màu xanh rêu đục, gợn sóng trôi theo dòng (pháp tuyến lệch theo hai lớp nhiễu trôi ngược nhau),
// mép lóe sáng theo góc nhìn (fresnel), hơi trong để thấy lờ mờ lòng suối.

uniform vec3 mau : source_color = vec3(0.07, 0.12, 0.07);

varying vec3 vi_tri;

void vertex() {
	vi_tri = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

float song(vec2 p) {
	return nhieu(p * 0.18 + vec2(TIME * 0.25, TIME * 0.06)) * 0.6 + nhieu(p * 0.45 - vec2(TIME * 0.18, -TIME * 0.12)) * 0.4;
}

void fragment() {
	vec2 p = vi_tri.xz;
	float e = 0.6;
	float h0 = song(p);
	vec3 nw = normalize(vec3(h0 - song(p + vec2(e, 0.0)), 0.9, h0 - song(p + vec2(0.0, e))));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mau * (0.9 + 0.2 * h0);
	ALPHA = clamp(0.78 + fres * 0.2, 0.0, 1.0);
	ROUGHNESS = 0.04;
	SPECULAR = 0.8;
	EMISSION = vec3(0.35, 0.42, 0.35) * fres * 0.15;
}
