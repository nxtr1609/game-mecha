class_name DungBaiTap
extends DungBanDo
## Bãi huấn luyện (sân bê tông ~1,1 × 1,1 km, đồi đất bao quanh; DiaHinh kiểu "bai_tap").
## Vạch sơn vẽ trong mat_bai_tap.gdshader. Rìa sân: vài tòa nhà nội thành của bạn, hàng rào bê tông, đèn pha;
## tường vô hình ở ±600 m giữ mecha trong sân. Bia, vòng bay, bệ phóng tên lửa do TranHuanLuyen đặt theo từng bài.

const RONG_SAN := 560.0


func tinh_duong(bd: Node3D) -> void:
	ban_do = bd
	duong = []                            # bãi tập không có đường (địa hình không cần san)


func dung(bd: Node3D, dh: DiaHinh) -> void:
	ban_do = bd
	dia_hinh = dh
	_rng.seed = 20261026
	_tao_vat_lieu()
	var mau := [Color(0.62, 0.61, 0.6), Color(0.54, 0.53, 0.52), Color(0.47, 0.46, 0.45), Color(0.66, 0.63, 0.6)]
	for i in _sa_thach.size():
		(_sa_thach[i] as StandardMaterial3D).albedo_color = mau[i % mau.size()]
	# nhà ở rìa sân (hai bên và phía bắc), có va chạm
	var ds := [Vector2(-470, 260), Vector2(-500, 60), Vector2(-470, -160), Vector2(-430, -400), Vector2(470, 240), Vector2(500, 20),
		Vector2(470, -200), Vector2(430, -420), Vector2(-200, -480), Vector2(30, -500), Vector2(240, -470)]
	for p in ds:
		_dat_nha(_chon(MauNha.NOI_THANH), "nguyen" if _rng.randf() < 0.6 else "do_2", p, _rng.randi_range(0, 3) * PI * 0.5)
	# hàng rào bê tông dọc vạch bắn hai bên (chỉ để nhìn) và vài đống gạch
	var rao: Array = []
	for s in [-1.0, 1.0]:
		for i in 10:
			var x: float = s * (240.0 + i * 4.6)
			rao.append([Transform3D(Basis(), Vector3(x, 0.0, 300.0)), Color(0.85, 0.8, 0.3) if i % 2 == 0 else Color(0.62, 0.6, 0.57)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 0.35, 0)), Vector3(4.2, 0.7, 1.0))
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(4.2, 0.7, 0.45))
	var vl := StandardMaterial3D.new()
	vl.vertex_color_use_as_albedo = true
	vl.roughness = 0.95
	_gom(st.commit(), rao, vl)
	for k in 8:
		var g := _rng.randf() * TAU
		_khoi_roi(Vector2(cos(g), sin(g)) * _rng.randf_range(380.0, 520.0), 10, 12.0)
	_tuong_bai_tap()


func cai_mat_dat(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("rong_san", RONG_SAN)


func ds_ban_do() -> Array:
	return []


func _tuong_bai_tap() -> void:
	var b := 600.0
	for d in [[Vector3(0, 200, -b), Vector3(2 * b + 40, 600, 20)], [Vector3(0, 200, b), Vector3(2 * b + 40, 600, 20)],
			[Vector3(-b, 200, 0), Vector3(20, 600, 2 * b + 40)], [Vector3(b, 200, 0), Vector3(20, 600, 2 * b + 40)]]:
		var than := StaticBody3D.new()
		than.collision_layer = LOP_VAT_CAN
		var hinh := CollisionShape3D.new()
		var hop := BoxShape3D.new()
		hop.size = d[1]
		hinh.shape = hop
		than.add_child(hinh)
		than.position = d[0]
		add_child(than)
