shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// Hạt bay (bông tuyết / bụi phấn): luôn quay mặt về camera, hình tròn mềm, mờ dần khi quá sát camera
// (để không thành ô vuông to che màn hình).

uniform vec4 mau : source_color = vec4(1.0, 1.0, 1.0, 0.85);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float tron = smoothstep(1.0, 0.25, d);
	float gan = smoothstep(3.0, 9.0, length(VERTEX));
	ALBEDO = mau.rgb;
	ALPHA = mau.a * tron * gan;
}
