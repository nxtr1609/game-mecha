class_name DungNgoaiO
extends DungBanDo
## Vùng ngoại ô (3,2 × 3,2 km) trên đồi thoải (DiaHinh kiểu "ngoai_o").
## - Phố cong đông–tây cách nhau 230 m (z_pho), phố nối bắc–nam cách nhau 400 m (x_noi), rộng 16 m.
##   Đường chính rộng 24 m nối căn cứ – cứ điểm (theo đúng đường bot đi).
## - Hai bên phố cong: nhà vườn của bạn (nha_vuon, nha_hien_dai) cách tim phố 21 m, mỗi lô 34–46 m,
##   có hàng rào / bờ cây phía trước, nhà kính và cây sau vườn. Giữa hai dãy nhà là vườn sau rộng ~160 m.
## - Cạnh mỗi cứ điểm: một khu thấp (khu_thap) làm mốc. Tháp ăng-ten trên các đỉnh đồi.
## - Chiến tranh mới lan tới: vài nhà trúng đạn đổ nát (nhiều hơn ở giữa bản đồ), ít hố bom, vài cột khói.

const D_PHO := 230.0
const D_NOI := 400.0
const RONG_PHO := 16.0
const RONG_DUONG := 24.0
const SO_HO_BOM := 16
const NHA := ["nha_vuon", "nha_hien_dai"]

var ho_bom: Array[Vector4] = []
var cay: TrongCay
var _rao: Array = []             # [Transform3D, Color] tấm rào (hộp đơn vị đã phóng)
var _bo_cay: Array = []          # bờ cây xanh (hộp đơn vị)
var _vat_can: Array = []
var _toa_do: Array = []


## Tim phố cong đông–tây thứ k tại x.
static func z_pho(x: float, k: float) -> float:
	return k * D_PHO + 30.0 * sin(x / 260.0 + k * 1.7)


static func x_noi(z: float, j: float) -> float:
	return j * D_NOI + 24.0 * sin(z / 210.0 + j * 2.3)


## Khoảng cách tới phố gần nhất (phố cong hoặc phố nối), giống mat_ngoai_o.gdshader.
static func kc_pho(p: Vector2) -> float:
	var tot := INF
	var k0 := roundf(p.y / D_PHO)
	for k in [k0 - 1.0, k0, k0 + 1.0]:
		var doc := 30.0 / 260.0 * cos(p.x / 260.0 + k * 1.7)
		tot = minf(tot, absf(p.y - z_pho(p.x, k)) / sqrt(1.0 + doc * doc))
	var j0 := roundf(p.x / D_NOI)
	for j in [j0 - 1.0, j0, j0 + 1.0]:
		var doc := 24.0 / 210.0 * cos(p.y / 210.0 + j * 2.3)
		tot = minf(tot, absf(p.x - x_noi(p.y, j)) / sqrt(1.0 + doc * doc))
	return tot


func tinh_duong(bd: Node3D) -> void:
	super(bd)
	rong_duong = RONG_DUONG
	_rng.seed = 20261022
	ho_bom.clear()
	var thu := 0
	while ho_bom.size() < SO_HO_BOM and thu < 2000:
		thu += 1
		var p := Vector2(_rng.randf_range(-1300, 1300), _rng.randf_range(-700, 700))
		if _gan_can_cu(p, 300.0):
			continue
		ho_bom.append(Vector4(p.x, p.y, _rng.randf_range(5.0, 11.0), 0.0))


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
		vung.append(Vector4(ban_do.VI_TRI_CU_DIEM[ten].x, ban_do.VI_TRI_CU_DIEM[ten].z, 95.0, 0.0))
	while vung.size() < 8:
		vung.append(Vector4.ZERO)
	mat.set_shader_parameter("vung", vung)
	mat.set_shader_parameter("d_pho", D_PHO)
	mat.set_shader_parameter("d_noi", D_NOI)
	mat.set_shader_parameter("rong_pho", RONG_PHO)
	mat.set_shader_parameter("rong_duong", RONG_DUONG)


func dung(bd: Node3D, dh: DiaHinh) -> void:
	ban_do = bd
	dia_hinh = dh
	_rng.seed = 20261023
	_tao_vat_lieu()
	cay = TrongCay.new(self, _rng, [Color(0.08, 0.2, 0.05), Color(0.26, 0.42, 0.1)])
	_can_cu(0)
	_can_cu(1)
	_khu_thap()
	_cho_nap()
	_day_nha()
	_thap_ang_ten()
	_cay_pho()
	_ria()
	_khoi_chay()
	_xong_xe()
	_xong_rao()
	cay.xong()
	_tuong_vo_hinh()
	so_phe_tich = so_nha


func _tao_vat_lieu() -> void:
	super()
	var mau := [Color(0.66, 0.64, 0.6), Color(0.58, 0.56, 0.52), Color(0.52, 0.5, 0.47), Color(0.7, 0.66, 0.6)]
	for i in _sa_thach.size():
		(_sa_thach[i] as StandardMaterial3D).albedo_color = mau[i % mau.size()]


func ds_ban_do() -> Array:
	return _vat_can


## Chỗ đặt nhà / vật còn trống: trong bản đồ, xa căn cứ, cứ điểm, đường chính, phố, nhà khác.
func _cho_trong(p: Vector2, r: float, cach_pho := 4.0) -> bool:
	if absf(p.x) > 1470.0 - r or absf(p.y) > 1470.0 - r:
		return false
	if _gan_can_cu(p, 285.0 + r) or _gan_cu_diem(p, 122.0 + r):
		return false
	if _gan_duong(p, r + 6.0) or kc_pho(p) < RONG_PHO * 0.5 + r + cach_pho:
		return false
	for x in _da_dat:
		if p.distance_to(x[0]) < r + float(x[1]) + 3.0:
			return false
	return true


# ---------------------------------------------------------------- dãy nhà hai bên phố cong

func _day_nha() -> void:
	for ki in range(-6, 7):
		var k := float(ki)
		var x := -1460.0
		while x < 1460.0:
			var w := _rng.randf_range(34.0, 46.0)
			x += w
			var doc := 30.0 / 260.0 * cos(x / 260.0 + k * 1.7)
			var a := atan(doc)
			var huong := Vector2(cos(a), sin(a))
			var phap := Vector2(-huong.y, huong.x)
			var tim := Vector2(x, z_pho(x, k))
			for ben in [-1.0, 1.0]:
				_lo_nha(tim, huong, phap * ben, a, w)


## Một lô nhà: nhà cách tim phố 21 m, rào phía trước, sau vườn có thể có nhà kính, cây.
func _lo_nha(tim: Vector2, huong: Vector2, ra: Vector2, a: float, w: float) -> void:
	var p := tim + ra * 21.0
	if _rng.randf() < 0.18 or not _cho_trong(p, 9.0, -2.0):
		return
	var tien_tuyen := 1.0 - smoothstep(250.0, 1150.0, absf(p.y))
	var ten: String = _chon(NHA)
	var ban := "nguyen"
	if _rng.randf() < 0.1 + 0.28 * tien_tuyen:
		ban = "do_1" if _rng.randf() < 0.5 else "do_2"
	var goc := -a + (PI if ra.dot(Vector2(-huong.y, huong.x)) > 0.0 else 0.0)       # mặt nhà (+z của mẫu) quay ra phố
	var y := _dat_nha(ten, ban, p, goc)
	_da_dat.append([p, 9.5])
	if ban != "nguyen":
		_toa_do.append(Vector3(p.x, y + MauNha.cao(ten, ban) - 2.0, p.y))
	# rào / bờ cây phía trước (sát vỉa hè) và hai bên lô
	var mat_truoc := tim + ra * (RONG_PHO * 0.5 + 3.6)
	var bo := _rng.randf() < 0.45
	_tam_rao(mat_truoc, huong, w * 0.92, bo)
	if _rng.randf() < 0.7:
		_tam_rao(tim + ra * 30.0 + huong * w * 0.5, ra, 24.0, _rng.randf() < 0.5)
	# vườn sau: nhà kính, cây, đôi khi xe cháy trước nhà
	var sau := tim + ra * _rng.randf_range(46.0, 58.0) + huong * _rng.randf_range(-8.0, 8.0)
	if _rng.randf() < 0.3 and _cho_trong(sau, 9.0):
		var tk := "nha_kinh" if _rng.randf() < 0.75 else "nha_kinh_lon"
		_dat_nha(tk, "nguyen" if _rng.randf() < 0.8 else "do_1", sau, goc)
		_da_dat.append([sau, 9.0])
	for i in _rng.randi_range(0, 2):
		var q := tim + ra * _rng.randf_range(36.0, 75.0) + huong * _rng.randf_range(-16.0, 16.0)
		if _cho_trong(q, 4.0):
			_trong_cay(q, _rng.randf_range(12.0, 20.0))
	if _rng.randf() < 0.08:
		_them_xe(tim + ra * _rng.randf_range(3.0, 6.0), -a + _rng.randf_range(-0.3, 0.3))


## Một tấm rào gỗ (thấp, 1,1 m) hoặc bờ cây xanh (1,8 m) dài "dai" theo hướng "huong" — chỉ để nhìn.
func _tam_rao(tam: Vector2, huong: Vector2, dai: float, bo_cay: bool) -> void:
	var y := dia_hinh.chieu_cao(tam.x, tam.y)
	var goc := atan2(huong.y, huong.x)
	var cao := 1.8 if bo_cay else 1.1
	var day := 1.3 if bo_cay else 0.25
	var b := Basis(Vector3.UP, -goc) * Basis.from_scale(Vector3(dai, cao, day))
	var t := Transform3D(b, Vector3(tam.x, y + cao * 0.5 - 0.1, tam.y))
	if bo_cay:
		_bo_cay.append([t, Color(0.16 + _rng.randf() * 0.05, 0.3 + _rng.randf() * 0.08, 0.1)])
	else:
		_rao.append([t, Color(0.4, 0.33, 0.25) if _rng.randf() < 0.6 else Color(0.58, 0.57, 0.54)])


func _xong_rao() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_hop(st, Transform3D(), Vector3.ONE)
	var hop := st.commit()
	var vl := StandardMaterial3D.new()
	vl.vertex_color_use_as_albedo = true
	vl.roughness = 0.95
	_gom(hop, _rao, vl, false)
	_gom(hop, _bo_cay, vl, false)


func _trong_cay(p: Vector2, cao_m: float) -> void:
	var ds := cay.cac_bien_the("cay")
	var r := cay.cay(_chon(ds), Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) - 0.3, p.y), _rng.randf() * TAU, cao_m)
	_da_dat.append([p, r + 2.0])


## Cây dọc phố (giữa vỉa hè và rào), bụi rải rác ở vườn sau.
func _cay_pho() -> void:
	for ki in range(-6, 7):
		var k := float(ki)
		var x := -1460.0
		while x < 1460.0:
			x += _rng.randf_range(22.0, 40.0)
			if _rng.randf() > 0.35:
				continue
			for ben in [-1.0, 1.0]:
				var q := Vector2(x, z_pho(x, k) + ben * (RONG_PHO * 0.5 + 6.5))
				if _cho_trong(q, 2.5, -RONG_PHO):
					_trong_cay(q, _rng.randf_range(11.0, 16.0))
	var bui := cay.cac_bien_the("bui")
	for thu in 2500:
		var q := Vector2(_rng.randf_range(-1460, 1460), _rng.randf_range(-1460, 1460))
		if _cho_trong(q, 3.0):
			cay.bui(_chon(bui), Vector3(q.x, dia_hinh.chieu_cao(q.x, q.y) - 0.3, q.y), _rng.randf() * TAU, _rng.randf_range(0.9, 1.4))


# ---------------------------------------------------------------- khu thấp cạnh cứ điểm, chỗ nấp, tháp ăng-ten

func _khu_thap() -> void:
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		for thu in 24:
			var g := _rng.randf() * TAU
			var p := c + Vector2(cos(g), sin(g)) * _rng.randf_range(165.0, 200.0)
			if _gan_duong(p, 40.0) or _gan_can_cu(p, 330.0) or kc_pho(p) < RONG_PHO * 0.5 + 32.0:
				continue
			_dat_nha("khu_thap", "nguyen" if _rng.randf() < 0.6 else "do_2", p, _rng.randi_range(0, 3) * PI * 0.5)
			_da_dat.append([p, 38.0])
			break


func _cho_nap() -> void:
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		for k in 8:
			var goc := TAU * k / 8.0 + _rng.randf_range(-0.15, 0.15)
			var p := c + Vector2(cos(goc), sin(goc)) * _rng.randf_range(70.0, 108.0)
			if _gan_duong(p, 8.0):
				continue
			var dai := _rng.randf_range(10.0, 18.0)
			_tuong(p, goc + PI * 0.5, dai, _rng.randf_range(5.0, 8.0), 2.6)
			_vat_can.append([p, dai * 0.5])
			_da_dat.append([p, dai * 0.6])


## Tháp ăng-ten trên đỉnh đồi (chọn chỗ cao nhất trong từng vùng, cách xa nhau).
func _thap_ang_ten() -> void:
	var vung := [Vector2(-1100, 0), Vector2(1100, 0), Vector2(-350, 450), Vector2(350, -450), Vector2(-1150, -1150), Vector2(1150, 1150)]
	for v in vung:
		var tot := Vector2.ZERO
		var cao := -INF
		for thu in 60:
			var q: Vector2 = v + Vector2(_rng.randf_range(-260, 260), _rng.randf_range(-260, 260))
			if not _cho_trong(q, 12.0):
				continue
			var h := dia_hinh.chieu_cao(q.x, q.y)
			if h > cao:
				cao = h
				tot = q
		if cao > -INF:
			_dat_nha("thap_ang_ten", "nguyen" if _rng.randf() < 0.7 else "do_2", tot, _rng.randf() * TAU)
			_da_dat.append([tot, 12.0])


## Rìa bản đồ: đồi cao dần + rừng cây dày (không va chạm, tường vô hình giữ mecha).
func _ria() -> void:
	var ds := cay.cac_bien_the("cay")
	for thu in 1600:
		var p := Vector2(_rng.randf_range(-1800, 1800), _rng.randf_range(-1800, 1800))
		var ria := maxf(absf(p.x), absf(p.y))
		if ria < 1500.0 or ria > 1800.0:
			continue
		cay.cay(_chon(ds), Vector3(p.x, dia_hinh.chieu_cao(p.x, p.y) - 0.5, p.y), _rng.randf() * TAU, _rng.randf_range(16.0, 26.0), false)


func _khoi_chay() -> void:
	var da_chon: Array = []
	for p in _toa_do:
		var q := p as Vector3
		var xa := absf(q.z) < 900.0
		for d in da_chon:
			if Vector2(q.x - (d as Vector3).x, q.z - (d as Vector3).z).length() < 500.0:
				xa = false
		if xa:
			da_chon.append(q)
			_cot_khoi(q, 0.7)
		if da_chon.size() >= 4:
			break
