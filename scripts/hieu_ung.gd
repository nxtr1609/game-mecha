class_name HieuUng
## Hiệu ứng hình ảnh: vệt đạn, tia lửa, vệt chém, vụ nổ (chớp sáng + quả cầu lửa + khói cuộn + mảnh vụn), bụi,
## vệt khói tên lửa. Hạt dùng chung một ảnh tròn mềm và một tấm vật liệu tô màu theo hạt (đỡ tạo vật liệu mới mỗi lần).

static var _tron: GradientTexture2D


## Ảnh tròn mềm (hạt bụi / khói không lộ ô vuông).
static func tron_mem() -> GradientTexture2D:
	if _tron == null:
		_tron = GradientTexture2D.new()
		_tron.fill = GradientTexture2D.FILL_RADIAL
		_tron.fill_from = Vector2(0.5, 0.5)
		_tron.fill_to = Vector2(1.0, 0.5)
		var gr := Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		_tron.gradient = gr
	return _tron


## Bụi tung dưới chân mecha khi lướt (gắn vào mecha, bật / tắt theo tốc độ).
static func hat_bui() -> CPUParticles3D:
	var b := CPUParticles3D.new()
	b.amount = 60
	b.lifetime = 0.9
	b.emitting = false
	b.direction = Vector3(0, 1, 0)
	b.spread = 60.0
	b.initial_velocity_min = 3.0
	b.initial_velocity_max = 8.0
	b.gravity = Vector3(0, -4, 0)
	b.scale_amount_min = 1.2
	b.scale_amount_max = 2.6
	var qm := QuadMesh.new()
	var mb := StandardMaterial3D.new()
	mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mb.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mb.albedo_color = Color(0.62, 0.58, 0.48, 0.3)
	mb.albedo_texture = tron_mem()
	qm.material = mb
	b.mesh = qm
	return b


static func _vat_lieu(mau: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = mau
	return mat


static func vet_dan(cha: Node, a: Vector3, b: Vector3, mau: Color, rong := 1.0) -> void:
	var dai := a.distance_to(b)
	if dai < 0.5 or cha == null:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22 * rong, 0.22 * rong, dai)
	var mat := _vat_lieu(mau)
	bm.material = mat
	mi.mesh = bm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cha.add_child(mi)
	mi.global_position = (a + b) * 0.5
	var huong := (b - a) / dai
	var tren: Vector3 = Vector3.UP if absf(huong.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	mi.look_at(b, tren)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.12 * (1.0 + (rong - 1.0) * 0.6))
	tw.tween_callback(mi.queue_free)


## Tia lửa tóe ra khi đạn trúng (bắn ngược về phía người bắn).
static func tia_lua(cha: Node, p: Vector3, huong: Vector3, mau: Color, so: int, toc := 30.0) -> void:
	if cha == null:
		return
	var pt := CPUParticles3D.new()
	pt.one_shot = true
	pt.explosiveness = 0.95
	pt.amount = so
	pt.lifetime = 0.4
	pt.local_coords = false
	pt.direction = huong
	pt.spread = 55.0
	pt.initial_velocity_min = toc * 0.33
	pt.initial_velocity_max = toc
	pt.gravity = Vector3(0, -30, 0)
	pt.particle_flag_align_y = true
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 0.6)
	var mat := _vat_lieu(mau)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.material = mat
	pt.mesh = bm
	pt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cha.add_child(pt)
	pt.global_position = p
	pt.emitting = true
	pt.get_tree().create_timer(0.8).timeout.connect(pt.queue_free)


## Vệt chém plasma hình lưỡi liềm, đặt trước mặt người chém rồi mờ dần.
static func vet_chem(cha: Node, tam: Vector3, co_so: Basis, mau: Color) -> void:
	if cha == null:
		return
	var mesh := ImmediateMesh.new()
	var ban_kinh := 6.5
	var day := 1.6
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var n := 24
	for k in n + 1:
		var t := float(k) / n
		var goc := deg_to_rad(lerpf(70.0, -120.0, t))
		var huong := Vector3(cos(goc), sin(goc), 0.0)
		var rong := day * sin(PI * t)
		mesh.surface_add_vertex(huong * (ban_kinh - rong * 0.5))
		mesh.surface_add_vertex(huong * (ban_kinh + rong * 0.5))
	mesh.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := _vat_lieu(Color(mau.r * 1.8, mau.g * 1.8, mau.b * 1.8, 0.9))
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cha.add_child(mi)
	# mặt phẳng lưỡi liềm vuông góc với hướng nhìn, nghiêng chéo như một nhát chém
	mi.global_transform = Transform3D(co_so * Basis(Vector3.BACK, deg_to_rad(-25.0)), tam)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.28)
	tw.tween_callback(mi.queue_free)


static var _tam_hat: QuadMesh


## Tấm hạt dùng chung: ảnh tròn mềm, luôn quay về camera, màu lấy từ màu từng hạt (color_ramp).
static func _tam() -> QuadMesh:
	if _tam_hat == null:
		_tam_hat = QuadMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tron_mem()
		_tam_hat.material = m
	return _tam_hat


## Một chùm hạt bung ra một lần rồi tự xóa. mau: [màu đầu, màu giữa, màu cuối] (alpha cuối nên = 0).
static func _chum(cha: Node, p: Vector3, so: int, song: float, toc: Vector2, co: Vector2, troi: float, mau: Array) -> void:
	var pt := CPUParticles3D.new()
	pt.one_shot = true
	pt.explosiveness = 0.9
	pt.amount = so
	pt.lifetime = song
	pt.local_coords = false
	pt.direction = Vector3.UP
	pt.spread = 180.0
	pt.initial_velocity_min = toc.x
	pt.initial_velocity_max = toc.y
	pt.damping_min = toc.y * 0.9
	pt.damping_max = toc.y * 1.3
	pt.gravity = Vector3(0, troi, 0)
	pt.scale_amount_min = co.x
	pt.scale_amount_max = co.y
	var cong := Curve.new()
	cong.add_point(Vector2(0, 0.35))
	cong.add_point(Vector2(0.25, 0.85))
	cong.add_point(Vector2(1, 1))
	pt.scale_amount_curve = cong
	var gr := Gradient.new()
	gr.set_color(0, mau[0])
	gr.set_color(1, mau[2])
	gr.add_point(0.3, mau[1])
	pt.color_ramp = gr
	pt.mesh = _tam()
	pt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cha.add_child(pt)
	pt.global_position = p
	pt.emitting = true
	pt.get_tree().create_timer(song + 0.3).timeout.connect(pt.queue_free)


## Vụ nổ: chớp sáng + quả cầu lửa cuộn + khói xám bốc lên + mảnh vụn tóe lửa (nổ lớn). Màu mau là màu lửa
## (vụ nổ EMP / plasma màu khác thì lửa và chớp theo màu đó). am = false: chỉ chớp sáng, không tiếng, không lửa khói.
static func vu_no(cha: Node, p: Vector3, ban_kinh: float, mau: Color, am := true) -> void:
	if am and ban_kinh >= 8.0:
		var cay := Engine.get_main_loop() as SceneTree
		var a: Node = cay.root.get_node_or_null("AmThanh") if cay else null
		if a:
			a.call("phat", "no_lon" if ban_kinh >= 20.0 else "no_nho", p)
	if cha == null:
		return
	var goc := Node3D.new()
	cha.add_child(goc)
	goc.global_position = p
	# chớp sáng ở tâm (quả cầu sáng nở nhanh rồi tắt) + đèn chiếu sáng cảnh xung quanh
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 8
	var mat := _vat_lieu(Color(minf(mau.r * 1.6 + 0.4, 3.0), minf(mau.g * 1.6 + 0.3, 3.0), minf(mau.b * 1.6 + 0.2, 3.0), 0.9))
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.material = mat
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	goc.add_child(mi)
	var den := OmniLight3D.new()
	den.light_color = mau
	den.light_energy = 8.0
	den.omni_range = ban_kinh * 3.5
	goc.add_child(den)
	mi.scale = Vector3.ONE * ban_kinh * 0.25
	var tw := goc.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * ban_kinh * 0.75, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.tween_property(den, "light_energy", 0.0, 0.5)
	tw.chain().tween_callback(goc.queue_free)
	if not am:
		return                                     # chỉ chớp sáng (thùng tiếp tế đáp / nhặt)
	# quả cầu lửa: các cụm lửa vàng → cam → đỏ thẫm rồi tối dần
	var r := ban_kinh
	var so_lua := clampi(int(r * 1.2), 6, 26)
	_chum(cha, p, so_lua, 0.55 + r * 0.012, Vector2(r * 0.8, r * 2.2), Vector2(r * 0.35, r * 0.6), r * 0.4,
		[Color(minf(mau.r * 1.5 + 0.5, 2.5), minf(mau.g * 1.5 + 0.35, 2.0), minf(mau.b * 1.2 + 0.2, 2.0), 1.0),
		Color(mau.r, mau.g * 0.6, mau.b * 0.5, 0.85), Color(0.12, 0.08, 0.06, 0.0)])
	# khói xám cuộn lên, tan chậm (vụ nổ nhỏ ít khói)
	if r >= 5.0:
		var so_khoi := clampi(int(r * 0.9), 5, 20)
		_chum(cha, p + Vector3.UP * r * 0.2, so_khoi, 1.6 + r * 0.04, Vector2(r * 0.4, r * 1.2), Vector2(r * 0.5, r * 0.95), r * 0.35,
			[Color(0.35, 0.32, 0.3, 0.0), Color(0.3, 0.28, 0.26, 0.55), Color(0.42, 0.4, 0.38, 0.0)])
	# mảnh vụn tóe lửa (nổ lớn)
	if r >= 8.0:
		tia_lua(cha, p, Vector3.UP, Color(2.0, 1.2, 0.5), clampi(int(r * 1.5), 12, 40), r * 2.5)


## Bụi tung thành vòng khi mecha đáp đất mạnh / rơi từ tàu xuống.
static func bui_dap(cha: Node, p: Vector3, r: float) -> void:
	_chum(cha, p + Vector3.UP * 0.8, clampi(int(r * 2.0), 8, 24), 1.4, Vector2(r * 0.8, r * 2.0), Vector2(r * 0.25, r * 0.5), -1.5,
		[Color(0.6, 0.56, 0.48, 0.0), Color(0.58, 0.54, 0.46, 0.45), Color(0.6, 0.57, 0.5, 0.0)])


## Vệt khói theo sau tên lửa (gắn làm con của tên lửa; hạt bay theo thế giới nên kéo thành vệt).
static func vet_khoi(mau := Color(0.85, 0.85, 0.85)) -> CPUParticles3D:
	var vet := CPUParticles3D.new()
	vet.amount = 48
	vet.lifetime = 1.3
	vet.local_coords = false
	vet.direction = Vector3(0, 0, 1)
	vet.spread = 8.0
	vet.initial_velocity_min = 2.0
	vet.initial_velocity_max = 4.0
	vet.gravity = Vector3(0, 1.2, 0)
	vet.scale_amount_min = 0.8
	vet.scale_amount_max = 1.6
	var cong := Curve.new()
	cong.add_point(Vector2(0, 0.4))
	cong.add_point(Vector2(1, 2.2))
	vet.scale_amount_curve = cong
	var gr := Gradient.new()
	gr.set_color(0, Color(1.6, 1.0, 0.5, 0.7))
	gr.set_color(1, Color(mau.r, mau.g, mau.b, 0.0))
	gr.add_point(0.12, Color(mau.r, mau.g, mau.b, 0.4))
	vet.color_ramp = gr
	vet.mesh = _tam()
	vet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return vet
