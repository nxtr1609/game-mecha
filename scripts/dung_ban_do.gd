class_name DungBanDo
extends Node3D
## Lớp gốc dựng cảnh bản đồ 3,2 × 3,2 km (DungThanhPho, DungNgoaiO, DungDongQue và bãi tập DungBaiTap kế thừa):
## - đại lộ nối căn cứ – cứ điểm (tinh_duong; địa hình san phẳng dọc theo chúng, bot đi theo chúng);
## - căn cứ hai phe hiện đại: hangar, chảo radar, bệ tên lửa, phi thuyền (Kenney Space Kit);
## - hàm dùng chung: đặt nhà của bạn (MauNha) kèm hộp va chạm, tường đổ / gạch vụn bê tông (PheTich), cột khói lửa,
##   gom vật nhỏ vào MultiMesh, xe cháy, tường vô hình giữ mecha trong bản đồ.
## Mọi thứ sinh theo hạt giống cố định nên bản đồ lần nào cũng giống nhau.
## Vật cản có khối va chạm ở lớp 1 (mặt đất / vật cản) + lớp 16 (vật cản để bot né).
## (3 bản đồ cũ sa mạc / băng giá / rừng rậm đã cất ở _ban_luu/2026-10-20_ban_do_cu.)

const NA := "res://assets_ngoai/kenney_nature/"
const SP := "res://assets_ngoai/kenney_space/"
const DAI_LO := 30.0                     # bề rộng đại lộ mặc định (m)
const LOP_VAT_CAN := 1 | 16

var ban_do: Node3D
var dia_hinh: DiaHinh
var duong: Array = []                    # [Vector2 a, Vector2 b] các đại lộ
var _da_dat: Array = []                  # [Vector2 tâm, bán kính]
var _rng := RandomNumberGenerator.new()
var _sa_thach: Array[Material] = []      # chất liệu bê tông của tường đổ / gạch vụn (mỗi bản đồ nhuộm màu riêng)
var so_phe_tich := 0
var so_da := 0
var rong_duong := DAI_LO                 # bề rộng đại lộ (thành phố: rộng hơn)
var ds_hop_nha: Array = []               # [Vector2 tâm, Vector2 cỡ (x, z) đã xoay, đổ nát?] — nhà của bạn, để vẽ bản đồ
var so_nha := 0
var so_nha_do := 0
var _xe: Array = []                      # xe cháy: [Transform3D, Color]
static var _vl_khoi: StandardMaterial3D
static var _vl_lua: StandardMaterial3D


# ---------------------------------------------------------------- bước 1: đại lộ (trước khi dựng địa hình)

## Tính các đại lộ nối căn cứ – cứ điểm (địa hình được san phẳng dọc theo chúng).
func tinh_duong(bd: Node3D) -> void:
	ban_do = bd
	var cc0 := _v2(ban_do.CAN_CU[0])
	var cc1 := _v2(ban_do.CAN_CU[1])
	var cd: Dictionary = {}
	for ten in ban_do.VI_TRI_CU_DIEM:
		cd[ten] = _v2(ban_do.VI_TRI_CU_DIEM[ten])
	var tho := [
		[cc0, cd["A"]], [cc0, cd["B"]], [cc0, cd["C"]],
		[cd["A"], cd["C"]], [cd["B"], cd["C"]], [cd["C"], cd["D"]], [cd["C"], cd["E"]],
		[cd["D"], cc1], [cd["E"], cc1], [cd["C"], cc1],
		[cd["A"], cd["D"]], [cd["B"], cd["E"]],
	]
	duong = []
	for d in tho:
		var a: Vector2 = d[0]
		var b: Vector2 = d[1]
		var v := (b - a).normalized()
		var cat_a := 175.0 if (a == cc0 or a == cc1) else 62.0
		var cat_b := 175.0 if (b == cc0 or b == cc1) else 62.0
		duong.append([a + v * cat_a, b - v * cat_b])


# ---------------------------------------------------------------- bước 2: cảnh vật (lớp con viết lại)

func dung(bd: Node3D, dh: DiaHinh) -> void:
	ban_do = bd
	dia_hinh = dh
	_rng.seed = 20261017
	_tao_vat_lieu()
	_can_cu(0)
	_can_cu(1)
	_tuong_vo_hinh()


func _tao_vat_lieu() -> void:
	var tex := load("res://assets_ngoai/mat_dat/concrete_floor_worn_001_diff_2k.jpg") as Texture2D
	var nor := load("res://assets_ngoai/mat_dat/concrete_floor_worn_001_nor_gl_2k.jpg") as Texture2D
	for mau in [Color(0.62, 0.61, 0.6), Color(0.54, 0.53, 0.52), Color(0.47, 0.46, 0.45), Color(0.66, 0.63, 0.6)]:
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = mau
		m.normal_enabled = nor != null
		m.normal_texture = nor
		m.normal_scale = 1.4
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.11, 0.11, 0.11)
		m.roughness = 0.93
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_sa_thach.append(m)


# ---------------------------------------------------------------- tiện ích

func _chon(ds: Array) -> Variant:
	return ds[_rng.randi() % ds.size()]


func _v2(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func _kc_toi_doan(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _gan_duong(p: Vector2, them: float) -> bool:
	for d in duong:
		if _kc_toi_doan(p, d[0], d[1]) < rong_duong * 0.5 + them:
			return true
	return false


## Độ cao đặt vật: thấp nhất trong vòng bán kính (để không lơ lửng), lún xuống thêm "lun" mét như bị cát vùi.
func _nen(p: Vector2, r: float, lun := 0.8) -> float:
	var h := dia_hinh.chieu_cao(p.x, p.y)
	for k in 6:
		var a := TAU * k / 6.0
		h = minf(h, dia_hinh.chieu_cao(p.x + cos(a) * r, p.y + sin(a) * r))
	return h - lun


func _dat_luoi(luoi: Mesh, p: Vector3, goc: float, mat: Material, xa := 4200.0, nghieng := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = luoi
	mi.material_override = mat
	mi.visibility_range_end = xa
	add_child(mi)
	mi.position = p
	mi.rotation = Vector3(nghieng.x, -goc, nghieng.z)       # goc: góc hướng trên mặt phẳng (x, z) = (cos, sin)
	return mi


func _than(p: Vector3, goc: float) -> StaticBody3D:
	var than := StaticBody3D.new()
	than.collision_layer = LOP_VAT_CAN
	than.collision_mask = 0
	add_child(than)
	than.position = p
	than.rotation.y = -goc
	return than


func _hop_va_cham(than: StaticBody3D, tam: Vector3, kich: Vector3, xoay := Basis()) -> void:
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = kich
	hinh.shape = hop
	hinh.transform = Transform3D(xoay, tam)
	than.add_child(hinh)


# ---------------------------------------------------------------- tường đổ, gạch vụn (bê tông)

## Tường xếp khối đổ nát. goc: hướng chạy của tường.
func _tuong(p: Vector2, goc: float, dai: float, cao: float, day: float) -> void:
	var y := _nen(p, dai * 0.4, _rng.randf_range(0.5, 2.5))
	var kq: Array = PheTich.tuong(dai, cao, day, _rng)
	_dat_luoi(kq[0], Vector3(p.x, y, p.y), goc, _chon(_sa_thach))
	var than := _than(Vector3(p.x, y, p.y), goc)
	for c in kq[1]:
		_hop_va_cham(than, Vector3(float(c[0]), float(c[1]) * 0.5, 0), Vector3(4.0, float(c[1]), day))


## Khối đá rơi rải quanh một điểm (vật nhỏ, không va chạm từng khối).
func _khoi_roi(p: Vector2, so: int, ban_kinh: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y0 := dia_hinh.chieu_cao(p.x, p.y)
	for k in so:
		var q := Vector2(_rng.randf_range(-ban_kinh, ban_kinh), _rng.randf_range(-ban_kinh, ban_kinh))
		var y := dia_hinh.chieu_cao(p.x + q.x, p.y + q.y) - y0
		var kich := Vector3(_rng.randf_range(2.5, 5.0), _rng.randf_range(1.6, 3.0), _rng.randf_range(2.5, 5.0))
		var b := Basis.from_euler(Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, _rng.randf_range(-0.3, 0.3)))
		PheTich.them_hop(st, Transform3D(b, Vector3(q.x, y + kich.y * 0.3, q.y)), kich)
	_dat_luoi(st.commit(), Vector3(p.x, y0, p.y), 0.0, _chon(_sa_thach), 2200.0)


# ---------------------------------------------------------------- căn cứ hiện đại

func _can_cu(phe: int) -> void:
	var c: Vector3 = ban_do.CAN_CU[phe]
	var huong := -1.0 if phe == 0 else 1.0              # phía địch
	var mau := Color(0.85, 0.86, 0.88) if phe == 0 else Color(0.5, 0.48, 0.47)
	var ds := [
		["hangar_largeA", Vector3(-130, 0, 40), PI * 0.5, 16.0],
		["hangar_largeB", Vector3(130, 0, 40), -PI * 0.5, 16.0],
		["hangar_roundA", Vector3(-150, 0, -70), 0.4, 11.0],
		["hangar_roundB", Vector3(150, 0, -70), -0.4, 11.0],
		["satelliteDish_large", Vector3(-80, 0, 140), 0.6, 14.0],
		["structure_detailed", Vector3(80, 0, 140), 0.0, 13.0],
		["rocket_baseA", Vector3(-185, 0, 130), 0.0, 7.0],
		["rocket_baseB", Vector3(185, 0, 130), 0.0, 7.0],
		["machine_generatorLarge", Vector3(-60, 0, -150), 0.3, 7.0],
		["machine_wireless", Vector3(60, 0, -150), -0.3, 8.0],
		["structure_diagonal", Vector3(-205, 0, 0), PI * 0.5, 12.0],
		["structure_diagonal", Vector3(205, 0, 0), PI * 0.5, 12.0],
		["hangar_roundGlass", Vector3(0, 0, 175), 0.0, 10.0],
		["craft_cargoA", Vector3(-70, 0, 100), 0.5, 11.0],
		["craft_cargoB", Vector3(70, 0, 100), -0.5, 11.0],
		["craft_miner", Vector3(-150, 0, 190), 0.9, 10.0],
	]
	for d in ds:
		var lech: Vector3 = d[1]
		lech.z *= -huong                                   # mặt trước căn cứ quay về phía địch
		_dat_mau(SP + d[0] + ".glb", c + lech, float(d[3]), float(d[2]) + (PI if phe == 1 else 0.0), mau)


## Đặt một mẫu Kenney (đã căn tâm), có khối va chạm theo khung bao nếu va_cham.
## vat_lieu: nếu có thì phủ lên mọi mảnh của mẫu (đá phủ tuyết / rêu).
func _dat_mau(duong_mau: String, p: Vector3, ti_le: float, goc: float, mau: Color, va_cham := true, vat_lieu: Material = null) -> void:
	if not ResourceLoader.exists(duong_mau):
		return
	var n := TaiNguyen.tao(duong_mau, ti_le, mau)
	if vat_lieu:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = vat_lieu
	add_child(n)
	n.position = p
	n.rotation.y = goc
	if va_cham:
		var k := TaiNguyen.khung(duong_mau)
		var than := _than(p, -goc)                       # mẫu Kenney xoay thẳng theo rotation.y
		_hop_va_cham(than, Vector3(0, k.size.y * ti_le * 0.5, 0), k.size * ti_le * Vector3(0.9, 1.0, 0.9))


# ---------------------------------------------------------------- vẽ bản đồ

## Vật cản tròn để vẽ lên bản đồ chiến trường: [Vector2 tâm, bán kính] (nhà vẽ riêng theo ds_hop_nha).
func ds_ban_do() -> Array:
	return _da_dat


# ---------------------------------------------------------------- nhà của bạn (MauNha), khói lửa

## Đặt một mẫu nhà (MauNha): lưới + hộp va chạm theo json (lớp vật cản). goc: góc xoay quanh trục đứng.
## va_cham = false: chỉ để nhìn (dãy nhà ngoài tường vô hình). Trả về độ cao chân nhà.
func _dat_nha(ten: String, ban: String, p: Vector2, goc: float, va_cham := true, xa := 0.0) -> float:
	var h: Array = MauNha.hop(ten, ban)
	var kich: Vector3 = h[1]
	var c := absf(cos(goc))
	var sn := absf(sin(goc))
	var co := Vector2(kich.x * c + kich.z * sn, kich.x * sn + kich.z * c)
	var y := _nen(p, minf(co.x, co.y) * 0.45, 0.3)
	var mi := MeshInstance3D.new()
	mi.mesh = MauNha.luoi(ten, ban)
	mi.visibility_range_end = xa if xa > 0.0 else (2600.0 if kich.y > 30.0 else 1500.0)
	add_child(mi)
	mi.position = Vector3(p.x, y, p.y)
	mi.rotation.y = goc
	if va_cham:
		var than := StaticBody3D.new()
		than.collision_layer = LOP_VAT_CAN
		than.collision_mask = 0
		add_child(than)
		than.position = mi.position
		than.rotation.y = goc
		_hop_va_cham(than, h[0], kich)
		var lech: Vector3 = Basis(Vector3.UP, goc) * (h[0] as Vector3)
		ds_hop_nha.append([p + Vector2(lech.x, lech.z), co, ban != "nguyen"])
		so_nha += 1
		if ban != "nguyen":
			so_nha_do += 1
	return y


static func _vat_lieu_khoi(lua: bool) -> StandardMaterial3D:
	if (_vl_lua if lua else _vl_khoi) == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0.0)
		gt.width = 64
		gt.height = 64
		var m := StandardMaterial3D.new()
		m.albedo_texture = gt
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.disable_receive_shadows = true
		if lua:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_vl_lua = m
		else:
			_vl_khoi = m
	return _vl_lua if lua else _vl_khoi


## Cột khói đen bốc lên (gió đẩy nghiêng) + lửa và ánh lửa ở chân. p: chỗ cháy (đỉnh tòa nhà đổ).
func _cot_khoi(p: Vector3, to := 1.0) -> void:
	var h := GPUParticles3D.new()
	h.amount = 34
	h.lifetime = 16.0
	h.preprocess = 16.0
	h.local_coords = false
	h.visibility_aabb = AABB(Vector3(-220, -20, -220), Vector3(440, 460, 440))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 6.0 * to
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 7.0
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(2.4, 0.5, 1.1)
	pm.damping_min = 0.25
	pm.damping_max = 0.45
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	var cong := Curve.new()
	cong.add_point(Vector2(0, 0.3))
	cong.add_point(Vector2(1, 1.0))
	var ct := CurveTexture.new()
	ct.curve = cong
	pm.scale_curve = ct
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.08, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0.05, 0.045, 0.04, 0.0), Color(0.06, 0.055, 0.05, 0.85), Color(0.15, 0.14, 0.135, 0.5), Color(0.24, 0.23, 0.22, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	h.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(38, 38) * to
	q.material = _vat_lieu_khoi(false)
	h.draw_pass_1 = q
	h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(h)
	h.position = p
	# lửa
	var l := GPUParticles3D.new()
	l.amount = 22
	l.lifetime = 1.3
	l.preprocess = 1.3
	l.local_coords = false
	var pl := ParticleProcessMaterial.new()
	pl.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pl.emission_sphere_radius = 5.0 * to
	pl.direction = Vector3(0, 1, 0)
	pl.spread = 20.0
	pl.initial_velocity_min = 3.0
	pl.initial_velocity_max = 6.0
	pl.gravity = Vector3(0, 2.0, 0)
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g2.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 0.0), Color(1.0, 0.5, 0.15, 0.9), Color(0.6, 0.15, 0.05, 0.0)])
	var gt2 := GradientTexture1D.new()
	gt2.gradient = g2
	pl.color_ramp = gt2
	l.process_material = pl
	var q2 := QuadMesh.new()
	q2.size = Vector2(7, 7) * to
	q2.material = _vat_lieu_khoi(true)
	l.draw_pass_1 = q2
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(l)
	l.position = p
	var den := OmniLight3D.new()
	den.light_color = Color(1.0, 0.55, 0.25)
	den.light_energy = 3.5
	den.omni_range = 45.0 * to
	add_child(den)
	den.position = p + Vector3(0, 3, 0)


## Gom nhiều vật nhỏ giống nhau (xe cháy, rào bê tông...) vào một MultiMesh. ds: [Transform3D, Color].
func _gom(luoi: Mesh, ds: Array, vat_lieu: Material, bong := true) -> void:
	if ds.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = luoi
	mm.instance_count = ds.size()
	for i in ds.size():
		mm.set_instance_transform(i, ds[i][0])
		mm.set_instance_color(i, ds[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = vat_lieu
	if not bong:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Xe cháy (chỉ để nhìn): ghi vị trí bằng _them_xe, cuối cùng _xong_xe() gom vào một MultiMesh.
func _them_xe(p: Vector2, goc: float) -> void:
	var lat := _rng.randf() < 0.12
	var b := Basis(Vector3.UP, goc)
	if lat:
		b = b * Basis(Vector3.FORWARD, PI * _rng.randf_range(0.45, 1.0))
	var y := 1.1 if lat else 0.0
	var mau: Color = [Color(0.16, 0.13, 0.11), Color(0.3, 0.17, 0.1), Color(0.11, 0.11, 0.12), Color(0.36, 0.33, 0.3)][_rng.randi() % 4]
	_xe.append([Transform3D(b, Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) + y, p.y)), mau])


## Xe con cháy trơ khung: thân + ca-bin + bánh (chỉ để nhìn).
func _luoi_xe() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(4.5, 0.8, 1.85))
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(-0.25, 1.45, 0)), Vector3(2.3, 0.65, 1.7))
	for x in [-1.45, 1.45]:
		for z in [-0.85, 0.85]:
			PheTich.them_hop(st, Transform3D(Basis(), Vector3(x, 0.38, z)), Vector3(0.75, 0.75, 0.3))
	return st.commit()


func _xong_xe() -> void:
	var vl_xe := StandardMaterial3D.new()
	vl_xe.vertex_color_use_as_albedo = true
	vl_xe.roughness = 0.95
	vl_xe.metallic = 0.3
	_gom(_luoi_xe(), _xe, vl_xe)


## Tường vô hình giữ mecha trong bản đồ.
func _tuong_vo_hinh() -> void:
	for d in [[Vector3(0, 200, -1600), Vector3(3400, 600, 20)], [Vector3(0, 200, 1600), Vector3(3400, 600, 20)],
			[Vector3(-1600, 200, 0), Vector3(20, 600, 3400)], [Vector3(1600, 200, 0), Vector3(20, 600, 3400)]]:
		var than := StaticBody3D.new()
		than.collision_layer = LOP_VAT_CAN
		var hinh := CollisionShape3D.new()
		var hop := BoxShape3D.new()
		hop.size = d[1]
		hinh.shape = hop
		than.add_child(hinh)
		than.position = d[0]
		add_child(than)
