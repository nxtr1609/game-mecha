class_name DungDongQue
extends DungBanDo
## Vùng đồng quê (3,2 × 3,2 km): đồi lượn cao tới ~38 m, hai con sông uốn lượn (DiaHinh kiểu "dong_que",
## cùng dòng chảy với DiaHinh.z_suoi), cầu bê tông nơi đường đất qua sông.
## - Ruộng chia ô 150 m xoay nghiêng (vẽ trong mat_dong_que.gdshader); bờ cây (bụi + cây) chạy dọc một số bờ ruộng.
## - Trang trại: nhà vườn của bạn + nhà kính, cây quanh nhà, cuộn rơm trên ruộng lúa mì.
## - Làng nhỏ quanh cứ điểm A, B, D, E; khu thấp cạnh C. Tháp ăng-ten trên đồi cao, mỏm đá trên sườn đồi.
## - Tầm nhìn xa, ít chỗ nấp: hợp súng bắn tỉa / tên lửa. Chiến tranh mới lan tới: ít hố bom, vài nhà cháy.

const O_RUONG := 150.0
const GOC_RUONG := 0.35
const RONG_DUONG := 18.0
const SO_HO_BOM := 16

var ho_bom: Array[Vector4] = []
var cay: TrongCay
var _vat_can: Array = []
var _toa_do: Array = []
var _rom: Array = []             # cuộn rơm [Transform3D, Color]
var _cau: Array = []             # [Vector2 giữa cầu, góc] — vẽ bản đồ


## Toạ độ trong lưới ruộng (xoay -GOC_RUONG), giống shader.
static func q_ruong(p: Vector2) -> Vector2:
	return p.rotated(-GOC_RUONG)


static func p_tu_q(q: Vector2) -> Vector2:
	return q.rotated(GOC_RUONG)


## Loại ruộng của ô chứa p: 0 lúa mì, 1 ruộng xanh, 2 đất cày, 3 cỏ (giống hàm hash của shader).
static func loai_ruong(p: Vector2) -> int:
	var id := (q_ruong(p) / O_RUONG).floor()
	var h := fposmod(id.x * 0.7548777 + id.y * 0.5698403 + fposmod(id.x * id.y * 0.1234567, 1.0), 1.0)
	return 0 if h < 0.3 else (1 if h < 0.55 else (2 if h < 0.75 else 3))


func tinh_duong(bd: Node3D) -> void:
	super(bd)
	rong_duong = RONG_DUONG
	_rng.seed = 20261024
	ho_bom.clear()
	var thu := 0
	while ho_bom.size() < SO_HO_BOM and thu < 2000:
		thu += 1
		var p := Vector2(_rng.randf_range(-1300, 1300), _rng.randf_range(-750, 750))
		if _gan_can_cu(p, 300.0):
			continue
		ho_bom.append(Vector4(p.x, p.y, _rng.randf_range(5.0, 12.0), 0.0))


func _gan_can_cu(p: Vector2, r: float) -> bool:
	for cc in ban_do.CAN_CU:
		if p.distance_to(_v2(cc)) < r:
			return true
	return false


func _gan_cu_diem(p: Vector2, r: float) -> bool:
	for ten in ban_do.VI_TRI_CU_DIEM:
		if p.distance_to(_v2(ban_do.VI_TRI_CU_DIEM[ten])) < r:
			return true
	return false


func cai_mat_dat(mat: ShaderMaterial) -> void:
	var ds := ho_bom.duplicate()
	while ds.size() < SO_HO_BOM:
		ds.append(Vector4.ZERO)
	mat.set_shader_parameter("ho", ds)
	var vung: Array[Vector4] = []
	for cc in ban_do.CAN_CU:
		vung.append(Vector4(cc.x, cc.z, 230.0, 0.0))
	for ten in ban_do.VI_TRI_CU_DIEM:
		vung.append(Vector4(ban_do.VI_TRI_CU_DIEM[ten].x, ban_do.VI_TRI_CU_DIEM[ten].z, 85.0, 0.0))
	while vung.size() < 8:
		vung.append(Vector4.ZERO)
	mat.set_shader_parameter("vung", vung)
	mat.set_shader_parameter("muc_nuoc", DiaHinh.MUC_NUOC)
	mat.set_shader_parameter("o_ruong", O_RUONG)
	mat.set_shader_parameter("goc_ruong", GOC_RUONG)
	mat.set_shader_parameter("rong_duong", RONG_DUONG)


func dung(bd: Node3D, dh: DiaHinh) -> void:
	ban_do = bd
	dia_hinh = dh
	_rng.seed = 20261025
	_tao_vat_lieu()
	cay = TrongCay.new(self, _rng, [Color(0.07, 0.18, 0.05), Color(0.24, 0.38, 0.09)])
	_can_cu(0)
	_can_cu(1)
	_nuoc()
	_cau_qua_song()
	_lang()
	_cho_nap()
	_trang_trai()
	_thap_ang_ten()
	_mom_da()
	_bo_cay()
	_ria()
	_khoi_chay()
	_xong_rom()
	_xong_xe()
	cay.xong()
	_tuong_vo_hinh()
	so_phe_tich = so_nha


func _tao_vat_lieu() -> void:
	super()
	var mau := [Color(0.66, 0.63, 0.58), Color(0.58, 0.55, 0.5), Color(0.52, 0.5, 0.46), Color(0.7, 0.65, 0.58)]
	for i in _sa_thach.size():
		(_sa_thach[i] as StandardMaterial3D).albedo_color = mau[i % mau.size()]


func ds_ban_do() -> Array:
	return _vat_can


func _cho_trong(p: Vector2, r: float, cach_duong := 6.0) -> bool:
	if absf(p.x) > 1470.0 - r or absf(p.y) > 1470.0 - r:
		return false
	if _gan_can_cu(p, 285.0 + r) or _gan_cu_diem(p, 118.0 + r):
		return false
	if _gan_duong(p, r + cach_duong) or dia_hinh.la_nuoc(p.x, p.y, r + 4.0):
		return false
	for x in _da_dat:
		if p.distance_to(x[0]) < r + float(x[1]) + 3.0:
			return false
	return true


# ---------------------------------------------------------------- sông, cầu

func _nuoc() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3300, 1500)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/nuoc.gdshader")
	mat.set_shader_parameter("mau", Color(0.08, 0.13, 0.12))
	pm.material = mat
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, DiaHinh.MUC_NUOC, 0)
	add_child(mi)


## Cầu bê tông nơi đường đất cắt qua sông: mặt cầu ngang mặt đường (mecha đi thẳng qua), lan can, trụ cầu.
func _cau_qua_song() -> void:
	var vl := StandardMaterial3D.new()
	vl.albedo_texture = load("res://assets_ngoai/mat_dat/concrete_floor_worn_001_diff_2k.jpg")
	vl.albedo_color = Color(0.7, 0.68, 0.64)
	vl.uv1_triplanar = true
	vl.uv1_world_triplanar = true
	vl.uv1_scale = Vector3(0.12, 0.12, 0.12)
	vl.roughness = 0.92
	for d in duong:
		var a: Vector2 = d[0]
		var b: Vector2 = d[1]
		var truoc := 0.0
		for i in 241:
			var p := a.lerp(b, i / 240.0)
			var ks := dia_hinh.kc_suoi(p.x, p.y)
			if i > 0 and ks < 6.0 and truoc >= 6.0:
				_mot_cau(p, (b - a).normalized(), vl)
			truoc = ks


func _mot_cau(p: Vector2, huong: Vector2, vl: Material) -> void:
	var goc := atan2(huong.y, huong.x)
	var dai := 130.0
	var rong := RONG_DUONG + 4.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, -0.6, 0)), Vector3(dai, 1.2, rong))
	for s in [-1.0, 1.0]:
		PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 0.55, s * (rong * 0.5 - 0.4))), Vector3(dai, 1.1, 0.6))
	for x in [-30.0, 0.0, 30.0]:
		PheTich.them_hop(st, Transform3D(Basis(), Vector3(x, -4.0, 0)), Vector3(3.0, 7.0, rong * 0.8))
	var y := 0.05
	_dat_luoi(st.commit(), Vector3(p.x, y, p.y), goc, vl, 3000.0)
	var than := _than(Vector3(p.x, y, p.y), goc)
	_hop_va_cham(than, Vector3(0, -0.6, 0), Vector3(dai, 1.2, rong))
	_da_dat.append([p, 30.0])
	_cau.append([p, goc])


# ---------------------------------------------------------------- làng quanh cứ điểm, trang trại

func _lang() -> void:
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		if ten == "C":
			for thu in 30:
				var g := _rng.randf() * TAU
				var p := c + Vector2(cos(g), sin(g)) * _rng.randf_range(170.0, 210.0)
				if _cho_trong(p, 36.0, 10.0):
					_dat_nha("khu_thap", "nguyen", p, _rng.randi_range(0, 3) * PI * 0.5)
					_da_dat.append([p, 38.0])
					break
		var so := 0
		for thu in 80:
			if so >= 8:
				break
			var g := _rng.randf() * TAU
			var p := c + Vector2(cos(g), sin(g)) * _rng.randf_range(135.0, 235.0)
			if not _cho_trong(p, 9.0):
				continue
			var ban := "nguyen" if _rng.randf() < 0.75 else ("do_1" if _rng.randf() < 0.5 else "do_2")
			var tn: String = _chon(["nha_vuon", "nha_hien_dai", "nha_vuon", "nha_kinh_lon"])
			var y := _dat_nha(tn, ban, p, -g + PI * 0.5 + _rng.randf_range(-0.3, 0.3))
			_da_dat.append([p, 10.0])
			if ban != "nguyen":
				_toa_do.append(Vector3(p.x, y + MauNha.cao(tn, ban) - 2.0, p.y))
			so += 1


func _trang_trai() -> void:
	var so := 0
	for thu in 900:
		if so >= 28:
			break
		var p := Vector2(_rng.randf_range(-1420, 1420), _rng.randf_range(-1420, 1420))
		if not _cho_trong(p, 40.0, 10.0):
			continue
		if dia_hinh.phap_tuyen(p.x, p.y).y < 0.97:
			continue                                     # trang trại ở chỗ đất bằng
		var goc := -GOC_RUONG + _rng.randi_range(0, 3) * PI * 0.5      # cạnh nhà song song bờ ruộng
		var huong := Vector2(cos(-goc), sin(-goc))
		var ngang := Vector2(-huong.y, huong.x)
		var ban := "nguyen" if _rng.randf() < 0.85 else "do_1"
		var y := _dat_nha(_chon(["nha_vuon", "nha_hien_dai"]), ban, p, goc)
		if ban != "nguyen":
			_toa_do.append(Vector3(p.x, y + 8.0, p.y))
		for i in _rng.randi_range(1, 3):
			var q := p + huong * _rng.randf_range(-30.0, 30.0) + ngang * (_rng.randf_range(24.0, 36.0) * (1.0 if i % 2 == 0 else -1.0))
			if _cho_trong(q, 9.0):
				_dat_nha("nha_kinh" if _rng.randf() < 0.55 else "nha_kinh_lon", "nguyen", q, goc)
				_da_dat.append([q, 10.0])
		_da_dat.append([p, 30.0])
		for i in _rng.randi_range(3, 6):
			var g := _rng.randf() * TAU
			var q := p + Vector2(cos(g), sin(g)) * _rng.randf_range(32.0, 55.0)
			if _cho_trong(q, 4.0):
				_trong_cay(q, _rng.randf_range(13.0, 21.0))
		# cuộn rơm trên ruộng lúa mì gần trang trại
		for i in 14:
			var q := p + Vector2(_rng.randf_range(-140, 140), _rng.randf_range(-140, 140))
			if loai_ruong(q) == 0 and _cho_trong(q, 2.0):
				var b := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.FORWARD, PI * 0.5)
				_rom.append([Transform3D(b, Vector3(q.x, dia_hinh.chieu_cao(q.x, q.y) + 0.9, q.y)), Color(0.78, 0.66, 0.38)])
		so += 1


func _trong_cay(p: Vector2, cao_m: float, va_cham := true) -> void:
	var r := cay.cay(_chon(cay.cac_bien_the("cay")), Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) - 0.3, p.y), _rng.randf() * TAU, cao_m, va_cham)
	_da_dat.append([p, r + 2.0])


## Bờ cây chạy dọc một số bờ ruộng: bụi sát nhau, cây lớn xen kẽ.
func _bo_cay() -> void:
	var bui := cay.cac_bien_the("bui")
	for i in range(-14, 15):
		for j in range(-14, 15):
			for canh in 2:
				if _rng.randf() > 0.28:
					continue
				var a := Vector2(i, j) * O_RUONG
				var b := a + (Vector2(O_RUONG, 0) if canh == 0 else Vector2(0, O_RUONG))
				var t := 0.0
				while t < O_RUONG:
					t += _rng.randf_range(6.0, 9.0)
					var p := p_tu_q(a.lerp(b, t / O_RUONG)) + Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-1.5, 1.5))
					if not _cho_trong(p, 3.0, 4.0):
						continue
					if _rng.randf() < 0.14:
						_trong_cay(p, _rng.randf_range(14.0, 22.0))
					else:
						cay.bui(_chon(bui), Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) - 0.4, p.y), _rng.randf() * TAU, _rng.randf_range(0.8, 1.3))


func _cho_nap() -> void:
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		for k in 7:
			var goc := TAU * k / 7.0 + _rng.randf_range(-0.2, 0.2)
			var p := c + Vector2(cos(goc), sin(goc)) * _rng.randf_range(70.0, 105.0)
			if _gan_duong(p, 8.0):
				continue
			var dai := _rng.randf_range(10.0, 18.0)
			_tuong(p, goc + PI * 0.5, dai, _rng.randf_range(4.5, 7.5), 2.6)
			_vat_can.append([p, dai * 0.5])
			_da_dat.append([p, dai * 0.6])


## Tháp ăng-ten trên đồi cao nhất từng vùng.
func _thap_ang_ten() -> void:
	for v in [Vector2(-1050, 150), Vector2(1050, -150), Vector2(-450, -1100), Vector2(450, 1100)]:
		var tot := Vector2.ZERO
		var cao := -INF
		for thu in 80:
			var q: Vector2 = v + Vector2(_rng.randf_range(-300, 300), _rng.randf_range(-300, 300))
			if not _cho_trong(q, 12.0):
				continue
			var h := dia_hinh.chieu_cao(q.x, q.y)
			if h > cao:
				cao = h
				tot = q
		if cao > -INF:
			_dat_nha("thap_ang_ten", "nguyen", tot, _rng.randf() * TAU)
			_da_dat.append([tot, 12.0])


## Mỏm đá trên sườn đồi (đá Kenney Nature Kit nhuộm xám, có va chạm): chỗ nấp hiếm hoi giữa đồng trống.
func _mom_da() -> void:
	var da := []
	for c in "ABCDEF":
		da.append(NA + "stone_large%s.glb" % c)
	for k in 260:
		if so_da >= 45:
			break
		var p := Vector2(_rng.randf_range(-1430, 1430), _rng.randf_range(-1430, 1430))
		if dia_hinh.phap_tuyen(p.x, p.y).y > 0.985:
			continue                                     # chỉ trên sườn dốc
		var duong_mau: String = _chon(da)
		var ti_le := _rng.randf_range(8.0, 16.0)
		var kk := TaiNguyen.khung(duong_mau)
		var ban_kinh := maxf(kk.size.x, kk.size.z) * ti_le * 0.55
		if not _cho_trong(p, ban_kinh):
			continue
		var y := _nen(p, ban_kinh * 0.6, 1.5)
		_dat_mau(duong_mau, Vector3(p.x, y, p.y), ti_le, _rng.randf() * TAU, Color(0.72, 0.7, 0.66))
		_da_dat.append([p, ban_kinh])
		_vat_can.append([p, ban_kinh * 0.8])
		so_da += 1


func _ria() -> void:
	var ds := cay.cac_bien_the("cay")
	for thu in 1400:
		var p := Vector2(_rng.randf_range(-1800, 1800), _rng.randf_range(-1800, 1800))
		var ria := maxf(absf(p.x), absf(p.y))
		if ria < 1500.0 or ria > 1800.0:
			continue
		cay.cay(_chon(ds), Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) - 0.5, p.y), _rng.randf() * TAU, _rng.randf_range(16.0, 26.0), false)


func _xong_rom() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_tru(st, Transform3D(Basis(), Vector3(0, -0.8, 0)), 0.9, 0.9, 1.6, 12, 0, 0.0, _rng)
	var vl := StandardMaterial3D.new()
	vl.vertex_color_use_as_albedo = true
	vl.roughness = 1.0
	_gom(st.commit(), _rom, vl)


func _khoi_chay() -> void:
	var da_chon: Array = []
	for p in _toa_do:
		var q := p as Vector3
		var xa := true
		for d in da_chon:
			if Vector2(q.x - (d as Vector3).x, q.z - (d as Vector3).z).length() < 600.0:
				xa = false
		if xa:
			da_chon.append(q)
			_cot_khoi(q, 0.6)
		if da_chon.size() >= 3:
			break
