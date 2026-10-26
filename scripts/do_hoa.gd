class_name DoHoa
extends RefCounted
## Đồ họa dùng chung (26/10/2026): mức chất lượng ở Cài đặt → "Chất lượng đồ họa" (thap / vua / cao) và các bước
## làm đẹp cho mọi cảnh:
## - môi trường: tone map Filmic (AgX thử rồi, tối và nhạt quá), chỉnh màu riêng từng bản đồ, glow; bóng khe hở SSAO (vừa, cao) + SSIL (cao),
##   ánh sáng gián tiếp SDFGI và phản chiếu SSR (cao), sương thể tích có tia nắng (vừa, cao);
## - bóng mặt trời mềm hơn, bản đồ bóng lớn hơn ở mức cao; khử răng cưa theo mức;
## - vật liệu: mẫu Tripo chỉ có màu gốc (không kim loại, rất nhám) → chỉnh độ kim loại / độ nhám cho mecha, súng,
##   tàu sân bay; súng và tàu thêm vân bề mặt kim loại (ảnh pháp tuyến tạo từ nhiễu, chiếu ba mặt nên không cần UV).
## Hàm static không gọi được autoload, nên mức chất lượng truyền vào từ ngoài (TienTrinh.cai_dat["do_hoa"]).

const MUC := ["thap", "vua", "cao"]
const TEN_MUC := {"thap": "Thấp", "vua": "Vừa", "cao": "Cao"}

static var cu := false                # --do_hoa=cu: giữ đúng ánh sáng / vật liệu trước 26/10 (chỉ để chụp ảnh so sánh)
static var _vat_lieu := {}            # [id vật liệu gốc, thông số] -> vật liệu đã chỉnh (dùng chung giữa các bản sao mẫu)
static var _van: NoiseTexture2D
static var _trong: ImageTexture


## Áp mức chất lượng cho một môi trường + mặt trời. kieu: thông số riêng của cảnh
## {"sang", "tuong_phan", "bao_hoa", "phoi_sang", "suong": mật độ sương thể tích, "mau_suong": Color}.
## Ghi nhớ vào nhóm "moi_truong" để đổi mức trong Cài đặt thì áp lại ngay (ap_lai).
static func ap_moi_truong(we: WorldEnvironment, sun: DirectionalLight3D, kieu: Dictionary, muc: String) -> void:
	we.add_to_group("moi_truong")
	we.set_meta("kieu", kieu)
	if sun:
		we.set_meta("mat_troi", sun)
	var env := we.environment
	if cu:
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
		return
	var cao := muc == "cao"
	var thap := muc == "thap"
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = float(kieu.get("phoi_sang", 1.0))
	env.adjustment_enabled = true
	env.adjustment_brightness = float(kieu.get("sang", 1.0))
	env.adjustment_contrast = float(kieu.get("tuong_phan", 1.04))
	env.adjustment_saturation = float(kieu.get("bao_hoa", 1.02))
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	# bóng khe hở: thước mecha 10 m nên bán kính lớn hơn mặc định
	env.ssao_enabled = not thap
	env.ssao_radius = 3.0
	env.ssao_intensity = 1.8
	env.ssao_power = 1.6
	env.ssao_detail = 0.6
	env.ssil_enabled = cao
	env.ssil_radius = 8.0
	env.ssil_intensity = 0.8
	env.ssr_enabled = cao
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	# ánh sáng gián tiếp: bản đồ 3,2 km nên dùng 6 tầng, ô nhỏ nhất 0,8 m
	env.sdfgi_enabled = cao
	env.sdfgi_cascades = 6
	env.sdfgi_min_cell_size = 0.8
	env.sdfgi_use_occlusion = true
	env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
	env.sdfgi_energy = 0.9
	env.sdfgi_bounce_feedback = 0.4
	# sương thể tích quanh camera (khói bụi, tia nắng); sương xa vẫn là sương thường của cảnh
	var suong := float(kieu.get("suong", 0.0))
	env.volumetric_fog_enabled = not thap and suong > 0.0
	env.volumetric_fog_density = suong
	env.volumetric_fog_albedo = kieu.get("mau_suong", Color(0.8, 0.8, 0.85))
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 400.0 if cao else 220.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject = 0.6
	env.volumetric_fog_ambient_inject = 0.25
	env.volumetric_fog_sky_affect = 0.0
	if sun:
		sun.shadow_blur = 1.2
		sun.directional_shadow_blend_splits = not thap
		sun.light_volumetric_fog_energy = 1.2
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_HIGH if cao else (RenderingServer.SHADOW_QUALITY_HARD if thap else RenderingServer.SHADOW_QUALITY_SOFT_LOW))
	RenderingServer.directional_shadow_atlas_set_size(8192 if cao else 4096, true)
	RenderingServer.environment_set_volumetric_fog_volume_size(96 if cao else 64, 96 if cao else 64)
	_khu_rang_cua(we.get_viewport(), muc)


## Khử răng cưa: thấp FXAA (rẻ nhất), vừa MSAA 2x, cao MSAA 4x.
static func _khu_rang_cua(vp: Viewport, muc: String) -> void:
	if vp == null:
		return
	vp.msaa_3d = Viewport.MSAA_4X if muc == "cao" else (Viewport.MSAA_2X if muc == "vua" else Viewport.MSAA_DISABLED)
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if muc == "thap" else Viewport.SCREEN_SPACE_AA_DISABLED


## Đổi mức trong Cài đặt: áp lại cho mọi môi trường đang có trong cảnh.
static func ap_lai(cay: SceneTree, muc: String) -> void:
	if cay == null:
		return
	for n in cay.get_nodes_in_group("moi_truong"):
		var we := n as WorldEnvironment
		if we and we.environment:
			var sun: DirectionalLight3D = we.get_meta("mat_troi") if we.has_meta("mat_troi") else null
			ap_moi_truong(we, sun, we.get_meta("kieu", {}), muc)


## Chỉnh vật liệu mọi lưới trong `goc`: độ kim loại, độ nhám; van = thêm vân bề mặt kim loại (chỉ dùng cho vật
## cứng như súng, tàu — lưới có khung xương mà chiếu ba mặt thì vân bị trôi khi cử động).
static func chinh_vat_lieu(goc: Node, kim_loai: float, nham: float, van := false) -> void:
	if cu:
		return
	for n in goc.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var goc_vl := mi.get_active_material(i) as BaseMaterial3D
			if goc_vl == null:
				continue
			var khoa := [goc_vl.get_instance_id(), kim_loai, nham, van]
			if not _vat_lieu.has(khoa):
				var vl := goc_vl.duplicate() as BaseMaterial3D
				vl.metallic = kim_loai
				vl.roughness = nham
				vl.metallic_specular = 0.55
				if van:
					vl.normal_enabled = true
					vl.detail_enabled = true
					vl.detail_normal = _anh_van()
					vl.detail_albedo = _anh_trong()
					vl.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
					vl.uv2_triplanar = true
					vl.uv2_scale = Vector3.ONE * 0.4
				_vat_lieu[khoa] = vl
			mi.set_surface_override_material(i, _vat_lieu[khoa])


## Ảnh pháp tuyến vân kim loại (nhiễu mịn, lặp liền mạch).
static func _anh_van() -> NoiseTexture2D:
	if _van == null:
		var nhieu := FastNoiseLite.new()
		nhieu.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		nhieu.frequency = 0.03
		nhieu.fractal_octaves = 4
		_van = NoiseTexture2D.new()
		_van.width = 512
		_van.height = 512
		_van.seamless = true
		_van.as_normal_map = true
		_van.bump_strength = 3.0
		_van.noise = nhieu
	return _van


## Ảnh 1×1 trong suốt: lớp chi tiết chỉ thêm vân pháp tuyến, không đổi màu gốc.
static func _anh_trong() -> ImageTexture:
	if _trong == null:
		var anh := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		anh.fill(Color(1, 1, 1, 0))
		_trong = ImageTexture.create_from_image(anh)
	return _trong
