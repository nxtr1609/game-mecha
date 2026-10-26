class_name DungThanhPho
extends DungBanDo
## Thành phố bị chiến tranh tàn phá (3,2 × 3,2 km), mặt đất phẳng (DiaHinh kiểu "thanh_pho").
## - Phố ô bàn cờ cách nhau 150 m (phố rộng 28 m, vỉa hè 6 m); mỗi khu phố chia 4 lô.
## - Đại lộ chéo rộng 56 m nối căn cứ – cứ điểm (theo đúng đường bot đi), quảng trường lát đá quanh 5 cứ điểm.
## - Nhà nội thành của bạn (MauNha.NOI_THANH): càng gần giữa bản đồ (tiền tuyến) càng nhiều tòa đổ nát.
##   Lô trống: đống gạch vụn, bãi xe cháy. Giữa các tòa trong một khu phố có khe 15–20 m cho mecha lách qua.
## - Hố bom (vẽ trong mat_thanh_pho.gdshader), xe cháy, rào bê tông, chông sắt chống tăng, cột khói từ tòa đổ.
## - Quanh cứ điểm: tường bê tông đổ làm chỗ nấp. Rìa bản đồ: dãy nhà cao làm đường chân trời (ngoài tường vô hình).
## Mọi thứ sinh theo hạt giống cố định nên lần nào cũng giống nhau.

const O_PHO := 150.0
const RONG_PHO := 28.0
const RONG_DAI_LO := 56.0
const SO_HO_BOM := 48
const NHA_RIA := ["toa_phien", "toa_cao_2", "thap_cong_nghiep", "thap_tron", "toa_cao_1"]

var ho_bom: Array[Vector4] = []
var _toa_do: Array = []          # [Vector3 chỗ cháy] các tòa đổ nát (chọn vài tòa bốc khói)
var _rao: Array = []
var _chong: Array = []
var _vat_can: Array = []         # [Vector2, bán kính] tường đổ quanh cứ điểm (vẽ bản đồ)


func tinh_duong(bd: Node3D) -> void:
	super(bd)
	rong_duong = RONG_DAI_LO
	_rng.seed = 20261020
	ho_bom.clear()
	var thu := 0
	while ho_bom.size() < SO_HO_BOM and thu < 3000:
		thu += 1
		var p := Vector2(_rng.randf_range(-1450, 1450), _rng.randf_range(-1450, 1450))
		var tren_pho := kc_pho(p) < RONG_PHO * 0.5 or _gan_duong(p, -4.0)
		if not tren_pho and _rng.randf() < 0.75:
			continue
		if _gan_can_cu(p, 240.0):
			continue
		ho_bom.append(Vector4(p.x, p.y, _rng.randf_range(5.0, 13.0), 0.0))


## Khoảng cách tới tim phố gần nhất (phố chạy theo x hoặc z, cách nhau O_PHO).
static func kc_pho(p: Vector2) -> float:
	var gx := absf(fposmod(p.x / O_PHO + 0.5, 1.0) - 0.5) * O_PHO
	var gz := absf(fposmod(p.y / O_PHO + 0.5, 1.0) - 0.5) * O_PHO
	return minf(gx, gz)


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


## Thông số cho mặt đất (mat_thanh_pho.gdshader).
func cai_mat_dat(mat: ShaderMaterial) -> void:
	var ds := ho_bom.duplicate()
	while ds.size() < SO_HO_BOM:
		ds.append(Vector4.ZERO)
	mat.set_shader_parameter("ho", ds)
	var vung: Array[Vector4] = []
	for cc in ban_do.CAN_CU:
		vung.append(Vector4(cc.x, cc.z, 230.0, 0.0))
	for ten in ban_do.VI_TRI_CU_DIEM:
		vung.append(Vector4(ban_do.VI_TRI_CU_DIEM[ten].x, ban_do.VI_TRI_CU_DIEM[ten].z, 125.0, 0.0))
	while vung.size() < 8:
		vung.append(Vector4.ZERO)
	mat.set_shader_parameter("vung", vung)
	mat.set_shader_parameter("o_pho", O_PHO)
	mat.set_shader_parameter("rong_pho", RONG_PHO)
	mat.set_shader_parameter("rong_dai_lo", RONG_DAI_LO)


func dung(bd: Node3D, dh: DiaHinh) -> void:
	ban_do = bd
	dia_hinh = dh
	_rng.seed = 20261021
	_tao_vat_lieu()
	_can_cu(0)
	_can_cu(1)
	_cho_nap()
	_khu_pho()
	_ria()
	_vat_tren_pho()
	_khoi_chay()
	_tuong_vo_hinh()
	so_phe_tich = so_nha


## Đá phế tích của lớp cha đổi sang bê tông xám (tường đổ, gạch vụn).
func _tao_vat_lieu() -> void:
	super()
	var mau := [Color(0.62, 0.61, 0.6), Color(0.54, 0.53, 0.52), Color(0.47, 0.46, 0.45), Color(0.66, 0.63, 0.6)]
	for i in _sa_thach.size():
		(_sa_thach[i] as StandardMaterial3D).albedo_color = mau[i % mau.size()]


func ds_ban_do() -> Array:
	return _vat_can


# ---------------------------------------------------------------- khu phố

func _khu_pho() -> void:
	for ix in range(-10, 10):
		for iz in range(-10, 10):
			var tam := Vector2((ix + 0.5) * O_PHO, (iz + 0.5) * O_PHO)
			for lx in [-1.0, 1.0]:
				for lz in [-1.0, 1.0]:
					_lo_dat(tam + Vector2(lx, lz) * O_PHO * 0.25)


## Một lô đất 55 × 55 m: một tòa nhà (nguyên / đổ nát), hoặc để trống (đống gạch, bãi xe cháy).
func _lo_dat(p: Vector2) -> void:
	var r_lo := 30.0
	if absf(p.x) > 1470.0 or absf(p.y) > 1470.0:
		return
	if _gan_can_cu(p, 290.0 + r_lo) or _gan_cu_diem(p, 128.0 + r_lo):
		return
	if _gan_duong(p, r_lo + 3.0):
		if not _gan_duong(p, 6.0) and _rng.randf() < 0.3:
			_dong_gach(p, _rng.randf_range(8.0, 14.0))
		return
	var tien_tuyen := 1.0 - smoothstep(250.0, 1250.0, absf(p.y))     # 1 ở giữa bản đồ (giáp ranh hai phe)
	if _rng.randf() < 0.42 + 0.1 * tien_tuyen:
		if _rng.randf() < 0.55:
			_dong_gach(p, _rng.randf_range(10.0, 22.0))
		elif _rng.randf() < 0.5:
			for k in _rng.randi_range(3, 7):
				_them_xe(p + Vector2(_rng.randf_range(-22, 22), _rng.randf_range(-22, 22)), _rng.randf() * TAU)
		return
	var ban := "nguyen"
	if _rng.randf() < 0.35 + 0.45 * tien_tuyen:
		ban = "do_1" if _rng.randf() < 0.5 else "do_2"
	var ten: String = _chon(MauNha.NOI_THANH)
	var goc := _rng.randi_range(0, 3) * PI * 0.5
	var lech := Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0))
	var y := _dat_nha(ten, ban, p + lech, goc)
	if ban != "nguyen":
		_toa_do.append(Vector3(p.x + lech.x, y + MauNha.cao(ten, ban) - 4.0, p.y + lech.y))
		if _rng.randf() < 0.55:
			var g := _rng.randf() * TAU
			_dong_gach(p + Vector2(cos(g), sin(g)) * _rng.randf_range(22.0, 30.0), _rng.randf_range(6.0, 11.0))


## Đống gạch vụn bê tông (chỉ để nhìn, mecha đi xuyên được).
func _dong_gach(p: Vector2, r: float) -> void:
	_khoi_roi(p, int(r * 0.9) + 3, r)


# ---------------------------------------------------------------- chỗ nấp quanh cứ điểm

func _cho_nap() -> void:
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		for k in 10:
			var goc := TAU * k / 10.0 + _rng.randf_range(-0.15, 0.15)
			var r := _rng.randf_range(72.0, 112.0)
			var p := c + Vector2(cos(goc), sin(goc)) * r
			if _gan_duong(p, 8.0):
				continue
			if _rng.randf() < 0.55:
				var dai := _rng.randf_range(12.0, 20.0)
				_tuong(p, goc + PI * 0.5, dai, _rng.randf_range(6.0, 10.0), 3.0)
				_vat_can.append([p, dai * 0.5])
			else:
				# hàng rào bê tông
				var huong := Vector2(cos(goc + PI * 0.5), sin(goc + PI * 0.5))
				for i in _rng.randi_range(4, 7):
					var q := p + huong * (i - 3) * 4.4
					_rao.append([Transform3D(Basis(Vector3.UP, -(goc + PI * 0.5) + _rng.randf_range(-0.12, 0.12)), Vector3(q.x, 0.0, q.y)), Color(0.62, 0.6, 0.57)])
			_khoi_roi(p + Vector2(cos(goc), sin(goc)) * 8.0, 4, 6.0)


# ---------------------------------------------------------------- rìa bản đồ: dãy nhà cao làm đường chân trời

func _ria() -> void:
	for canh in 4:
		var k := -1700.0
		while k <= 1700.0:
			var d := _rng.randf_range(1560.0, 1640.0)
			var p: Vector2
			match canh:
				0:
					p = Vector2(k, -d)
				1:
					p = Vector2(k, d)
				2:
					p = Vector2(-d, k)
				_:
					p = Vector2(d, k)
			var ban := "nguyen" if _rng.randf() < 0.65 else "do_2"
			_dat_nha(_chon(NHA_RIA), ban, p, _rng.randi_range(0, 3) * PI * 0.5, false, 4200.0)
			k += _rng.randf_range(70.0, 110.0)


# ---------------------------------------------------------------- xe cháy, rào chắn, chông sắt trên phố

func _vat_tren_pho() -> void:
	# xe cháy dọc các phố
	for i in range(-9, 10):
		var c := i * O_PHO
		var t := -1470.0
		while t < 1470.0:
			t += _rng.randf_range(18.0, 45.0)
			if _rng.randf() > 0.16:
				continue
			for theo_x in [true, false]:
				var lech := _rng.randf_range(3.0, 10.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
				var p := Vector2(t, c + lech) if theo_x else Vector2(c + lech, t)
				if _gan_can_cu(p, 260.0) or _gan_cu_diem(p, 60.0) or _rng.randf() < 0.5:
					continue
				var huong := 0.0 if theo_x else PI * 0.5
				_them_xe(p, huong + _rng.randf_range(-0.35, 0.35) + (PI if _rng.randf() < 0.5 else 0.0))
	# trên đại lộ
	for d in duong:
		var a: Vector2 = d[0]
		var b: Vector2 = d[1]
		var dai := a.distance_to(b)
		var huong := atan2((b - a).y, (b - a).x)
		var ngang := Vector2(-(b - a).y, (b - a).x).normalized()
		var t := 0.0
		while t < dai:
			t += _rng.randf_range(25.0, 60.0)
			if _rng.randf() < 0.3:
				var p := a.lerp(b, t / dai) + ngang * _rng.randf_range(-22.0, 22.0)
				if not _gan_cu_diem(p, 70.0):
					_them_xe(p, -huong + _rng.randf_range(-0.4, 0.4))
	# chông sắt chống tăng ở các ngã tư gần cứ điểm
	for ten in ban_do.VI_TRI_CU_DIEM:
		var c := _v2(ban_do.VI_TRI_CU_DIEM[ten])
		for k in 26:
			var g := _rng.randf() * TAU
			var p := c + Vector2(cos(g), sin(g)) * _rng.randf_range(135.0, 260.0)
			if kc_pho(p) > RONG_PHO * 0.5 and not _gan_duong(p, -6.0):
				continue
			_chong.append([Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(p.x, 0.0, p.y)), Color(0.2, 0.19, 0.18)])
	_xong_xe()
	var vl_rao := StandardMaterial3D.new()
	vl_rao.vertex_color_use_as_albedo = true
	vl_rao.roughness = 0.95
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 0.35, 0)), Vector3(4.2, 0.7, 1.0))
	PheTich.them_hop(st, Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(4.2, 0.7, 0.45))
	_gom(st.commit(), _rao, vl_rao)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var b := Basis(Vector3.UP, k * PI / 3.0) * Basis(Vector3.RIGHT, deg_to_rad(54.7)) * Basis(Vector3.FORWARD, deg_to_rad(45.0))
		PheTich.them_hop(st2, Transform3D(b, Vector3(0, 1.6, 0)), Vector3(0.45, 4.2, 0.45))
	_gom(st2.commit(), _chong, vl_rao)


# ---------------------------------------------------------------- khói lửa

func _khoi_chay() -> void:
	var da_chon: Array = []
	for i in range(_toa_do.size() - 1, 0, -1):       # xáo theo hạt giống của bản đồ
		var j := _rng.randi_range(0, i)
		var tam: Variant = _toa_do[i]
		_toa_do[i] = _toa_do[j]
		_toa_do[j] = tam
	for p in _toa_do:
		var q := p as Vector3
		var xa := true
		for d in da_chon:
			if Vector2(q.x - (d as Vector3).x, q.z - (d as Vector3).z).length() < 380.0:
				xa = false
		if xa:
			da_chon.append(q)
			_cot_khoi(q, _rng.randf_range(0.85, 1.25))
		if da_chon.size() >= 9:
			break
