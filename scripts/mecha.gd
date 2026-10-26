class_name Mecha
extends CharacterBody3D
## Một con mecha. Người chơi (DieuKhienNguoiChoi) hay bot (DieuKhienBot) đều điều khiển giống nhau:
## bộ điều khiển ghi vào các biến dk_* mỗi khung hình.
## Cơ chế (ghép từ game thử "Thử Gameplay Mecha", học từ Iron Valiant, không chép nguyên):
## - THANH NHIỆT: bật lao, bay lên, giữ độ cao làm nóng động cơ; đầy = QUÁ NHIỆT: chỉ chạy bộ được,
##   không bay / bật lao / lướt, đang bay thì rơi; chờ nguội hết mới dùng lại.
## - Ctrl lúc đang bay: GIỮ ĐỘ CAO. Ctrl dưới đất: đổi lướt / chạy bộ. T: rơi nhanh.
## - Chuột trái / phải: vũ khí tay phải / trái. Q / E: tay phụ trái / phải. X: pháo nhiệt (tên lửa đang bám mình
##   mất khóa, lao theo pháo). Chỉ đạn súng máy bắn rơi được tên lửa.
## - Bấm Shift: bật lao (vọt nhanh). GIỮ Shift: lướt nhanh liên tục, nóng máy.
## - F: chém (lưỡi năng lượng cẳng tay trái); mecha địch đang khóa trong 120 m (chữ F hiện cạnh nó) thì F = lao chém,
##   tự lao cực nhanh tới chém (tốc độ lao nâng cấp được). Bị lao chém: Shift đúng lúc = né, F đúng lúc = đỡ.
## Hoạt ảnh: thư viện + bộ trộn của dự án Thử Hoạt Ảnh Mecha (TronHoatAnh).

signal bi_ha(mecha: Mecha)
signal ban_trung(muc_tieu: Node, sat_thuong: float)
signal su_kien(loai: String)
signal bi_trung(tu: Node, luong: float)       # vừa mất giáp (HUD vẽ mũi tên chỉ hướng bị bắn)

# ---- thiết lập (gán trước khi thêm vào cảnh)
var phe := 0                                  # 0: phe ta (Liên Hiệp, xanh), 1: địch (Đế Chế, đỏ)
var loai := "co_ban"
var ten := "Mecha"
var ten_mau_rieng := ""                       # để trống: mẫu theo loại + phe (CanBang.ten_mau)
var vk := {"phai": "sung_truong", "trai": "phao_plasma"}
var tay_phu := {"trai": "ten_lua", "phai": "ten_lua"}      # Q / E
var can_chien := "kiem"                       # kiểu cận chiến (ô F): kiem / thuong / dam_emp
var dieu_khien: Node = null                   # phải có hàm dieu_khien(mecha, dt)
var he_so_sat_thuong := 1.0                   # bot dùng hệ số nhỏ hơn để người chơi không bị bắn quá đau
var he_so_can_chien := 1.0
var he_so_mau := 1.0                          # nhân giáp (vd. mecha chỉ huy trong chiến dịch)
var lay_da_lao := 0.3                         # lao chém: lấy đà bao lâu (người chơi 0,08 s, máy 0,3 s để đối thủ kịp thấy báo động)
var toc_lao_chem_goc := 160.0                 # lao chém: tốc độ lao (m/s) trước nâng cấp (người chơi 220, máy 160)
var nut_nang_cap: Array = [0, 0, 0]           # số nút nâng cấp đã mở: [giáp, cơ động, hỏa lực]
var trung_bay := false                        # mecha đứng trưng bày ở menu: chỉ xoay, không tham gia trận
var mau_toi_thieu := 0.0                      # bãi tập: giáp không xuống dưới mức này (không thể bị hạ)

# ---- lệnh từ bộ điều khiển
var dk_di := Vector2.ZERO          # x: phải(+)/trái(-), y: tới(+)/lui(-), theo hướng dk_huong
var dk_huong := 0.0                # góc xoay thân mong muốn (rad)
var dk_ngam := Vector3.ZERO        # điểm đang ngắm (không khóa ai thì đạn bay tới đây)
var dk_bay := false                # giữ
var dk_lao := false                # bấm một lần (bật lao; lúc bị lao chém: né)
var dk_giu_lao := false            # giữ (Shift): lướt nhanh liên tục, tốn nhiệt
var dk_ctrl := false               # bấm một lần: dưới đất đổi lướt / chạy bộ, trên không bật / tắt giữ độ cao
var dk_ban := {"phai": false, "trai": false}
var dk_tay_phu := {"trai": false, "phai": false}   # bấm một lần
var dk_phao_nhiet := false         # bấm một lần
var dk_chem := false               # F, bấm một lần (lúc bị lao chém: đỡ)
var dk_lao_chem := false           # bấm một lần: lao chém mục tiêu đang khóa (người chơi: F khi địch trong tầm)
var dk_roi := false                # T, bấm một lần
var khoa: Node3D = null            # mục tiêu đang khóa: Mecha, máy bay, ụ súng
var muc_tieu_ban: Node3D = null    # bắn vật này thay mục tiêu khóa — vd. tên lửa đang lao tới (súng máy)

# ---- trạng thái
var cs: Dictionary
var mau := 4000.0
var nhiet := 0.0
var qua_nhiet := false
var giu_do_cao := false
var do_cao_giu := 0.0
var phao_nhiet := 2
var hoi_phao := 0.0
var hoi_tay_phu := {"trai": 0.0, "phai": 0.0}
var song := true
var di_bo := false
var dang_bay := false              # đang ở trên không (bay, giữ độ cao, rơi)
var dang_roi := false              # đang rơi từ tàu sân bay xuống (hồi sinh)
var luot_nhanh := false            # đang giữ Shift lướt nhanh
var da_bi_khoa := false            # người chơi đã từng khóa con này (từ đó mới được đánh dấu trên HUD / bản đồ)
var bat_tu_con := 0.0
var choang_con := 0.0
var sung_may_vai_con := 0.0
var khien_con := 0.0
var hoi_chem := 0.0
var hoi_lao_chem := 0.0
var laser_tay := ""                # tay đang chiếu laser báo trước (vũ khí "_dich"), "" = không
var laser_con := 0.0
var laser_dich := Vector3.ZERO
var ke_tan_cong: Node = null       # ai gây sát thương gần nhất (để tính ai hạ)
var u_minigun: Array[Node3D] = []
var kieu_di := "chay_may"
var trang_thai := ""
var ty_le := 1.0
# đếm để xem cơ chế chạy thế nào
var ban_roi_tl := 0
var tl_bi_lua := 0
var bi_trung_tl := 0
var ha_dich := 0

var truc: Node3D
var model: Node3D
var sk: Skeleton3D
var tron: TronHoatAnh
var cau_hinh := {}
var de_phu: Array = []

var _cho_nguoi := 0.0
var _hoi_ban := {"phai": 0.0, "trai": 0.0}
var _lao_con := 0.0
var _lao_huong := Vector3.ZERO
var _hoi_lao := 0.0
var _kep_con := 0.0                # Cơ động (lướt kép): còn bao lâu được bật lao lần hai không tốn nhiệt
var _tren_khong_truoc := false
var _vy_truoc := 0.0
var _mat_dat_y := 0.0              # độ cao mặt đất ngay dưới chân (để giới hạn độ cao bay)
var _hoi_do_dat := 0.0
var _diem_dap := Vector3.ZERO
var _cc := {}                      # đòn cận chiến đang ra: {"kieu": "chem"/"lao", "pha", "t", "muc", "phan_ung"}
var _t_do := 0.0                   # còn bao lâu giữ dáng đỡ đòn
var _roi_nhanh := false
var _hoi_smv := 0.0
var _mot_lan := {}
var _t := {}
var _w := {"dung": 1.0, "luot": 0.0, "di": 0.0, "bay": 0.0, "re": 0.0, "ngam_phai": 0.0, "ngam_trai": 0.0, "do": 0.0}
var _giu_ngam := {"phai": 0.0, "trai": 0.0}
var _w_huong := {"toi": 1.0, "lui": 0.0, "trai": 0.0, "phai": 0.0}
var _w_lao := {"toi": 1.0, "lui": 0.0, "trai": 0.0, "phai": 0.0}
var _pha_di := 0.0
var _yaw_truoc := 0.0
var _lx := {}
var _v_truoc := Vector3.ZERO
var _gia_toc := Vector3.ZERO
var _xuong := {}
var _rest_g := {}
var _sung := {}                    # tay -> Node3D súng
var _chop := {}                    # tay -> OmniLight3D chớp nòng
var _ong := {}                     # bên -> điểm phóng tên lửa (trục +Z hướng ra trước)
var _gan_tay := {}
var _lua: Array = []
var _bui: CPUParticles3D
var _khoi: CPUParticles3D          # khói xả lúc quá nhiệt
var _hinh: CollisionShape3D
var _luoi: MeshInstance3D          # lưỡi năng lượng cẳng tay trái
var _mat_luoi: StandardMaterial3D
var _khien_mesh: MeshInstance3D
var _tia_laser: MeshInstance3D
var _am_lop := {}                  # lớp động cơ: tên -> AudioStreamPlayer3D (vòng lặp)
var _am_muc := {}                  # lớp động cơ: tên -> mức đang phát 0..1 (hòa mượt)

## Các lớp tiếng động cơ, lặp liên tục và hòa âm lượng theo trạng thái (xem _am_dong_co).
const LOP_DONG_CO := ["dong_co_cho", "luot_lap", "luot_nhanh_lap", "bay_lap", "lo_lung_lap", "gio_roi"]

const HUONG := ["toi", "lui", "trai", "phai"]
const XUONG_TAY := {"phai": "RightHand", "trai": "LeftHand"}
## Vòi phụt mặc định (khi file .json của mẫu không ghi): 2 cửa xả động cơ vai, 2 ống sau bắp chân.
const VOI := [
	["UpperChest", Vector3(1.06, 7.05, -1.25), Vector3(0, -0.15, -1), "vai"],
	["UpperChest", Vector3(-1.06, 7.05, -1.25), Vector3(0, -0.15, -1), "vai"],
	["LeftLowerLeg", Vector3(1.85, 2.05, -0.95), Vector3(0, -0.3, -1), "chan"],
	["RightLowerLeg", Vector3(-1.85, 2.05, -0.95), Vector3(0, -0.3, -1), "chan"],
]


func _ready() -> void:
	if not trung_bay:
		add_to_group("mecha")
	cs = CanBang.chi_so_mecha(loai, nut_nang_cap)
	ty_le = float(cs["ty_le"])
	he_so_sat_thuong *= float(cs["he_so_hoa_luc"])
	mau = mau_toi_da()
	collision_layer = 2
	collision_mask = 1 | 2
	floor_snap_length = 1.5
	floor_max_angle = deg_to_rad(50.0)
	_hinh = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 2.6 * ty_le
	cap.height = 10.0 * ty_le
	_hinh.shape = cap
	_hinh.position.y = 5.0 * ty_le
	add_child(_hinh)
	truc = Node3D.new()
	truc.scale = Vector3.ONE * ty_le
	add_child(truc)
	var ten_m := ten_mau_rieng if ten_mau_rieng != "" else CanBang.ten_mau(loai, phe)
	var duong_mau := "res://models/mecha/%s.glb" % ten_m
	var duong_json := duong_mau.get_basename() + ".json"
	if FileAccess.file_exists(duong_json):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(duong_json))
		if d is Dictionary:
			cau_hinh = d
	de_phu = cau_hinh.get("de_phu", [])
	model = (load(duong_mau) as PackedScene).instantiate() as Node3D
	model.rotation.y = PI          # mẫu nhìn về +Z, thân mecha nhìn về -Z
	truc.add_child(model)
	DoHoa.chinh_vat_lieu(model, 0.4, 0.5)          # giáp kim loại sơn (mẫu gốc: không kim loại, rất nhám)
	if not trung_bay:
		_vien_phe()
	sk = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i)
		_xuong[n] = i
		_rest_g[n] = sk.get_bone_global_rest(i).basis.get_rotation_quaternion()
	var day := INF
	for n in ["LeftToes", "RightToes", "LeftFoot", "RightFoot"]:
		day = minf(day, sk.get_bone_global_rest(_xuong[n]).origin.y)
	model.position.y = -day + 0.3
	if cau_hinh.has("day"):
		model.position.y = -float(cau_hinh["day"])
	tron = TronHoatAnh.new(sk, load("res://hoat_anh/thu_vien_%s.res" % ten_m))
	_tao_vu_khi()
	_tao_lua()
	_tia_laser = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 1.0)
	var ml := StandardMaterial3D.new()
	ml.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ml.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ml.albedo_color = Color(2.0, 0.25, 0.2)
	bm.material = ml
	_tia_laser.mesh = bm
	_tia_laser.top_level = true
	_tia_laser.visible = false
	_tia_laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tia_laser)
	if not trung_bay:
		for ten in LOP_DONG_CO:
			var p := AmThanh.vong_lap(ten, self)
			p.set_meta("goc_db", p.volume_db)
			_am_lop[ten] = p
			_am_muc[ten] = 0.0


static var _vat_lieu_vien := {}


## Viền sáng nhẹ màu phe trên thân (xanh: Liên Hiệp, đỏ: Đế Chế) để mecha nổi lên khỏi nền, nhất là ở xa.
func _vien_phe() -> void:
	if not _vat_lieu_vien.has(phe):
		var vl := ShaderMaterial.new()
		vl.shader = load("res://scripts/vien_phe.gdshader")
		vl.set_shader_parameter("mau", Color(0.35, 0.7, 1.0) if phe == 0 else Color(1.0, 0.3, 0.22))
		_vat_lieu_vien[phe] = vl
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = _vat_lieu_vien[phe]


func mau_toi_da() -> float:
	return float(cs["mau"]) * he_so_mau


func nhiet_toi_da() -> float:
	return float(cs["nhiet_toi_da"])


func tam_than() -> Vector3:
	return global_position + Vector3.UP * 5.5 * ty_le


func diem_ngam_vao() -> Vector3:
	return tam_than()


func huong_toi() -> Vector3:
	return -global_basis.z


func dang_bi_choang() -> bool:
	return choang_con > 0.0


## Vũ khí tay phải (tầm khóa, tầm tối ưu lấy theo súng này).
func vk_chinh() -> Dictionary:
	return CanBang.VU_KHI[vk["phai"]]


## Súng tay còn phải chờ bao lâu mới bắn tiếp (giây). Súng bắn nhanh (nhịp < 0,5 s) coi như luôn sẵn sàng.
func hoi_ban_con(tay: String) -> float:
	var nhip := float(CanBang.VU_KHI[vk[tay]]["nhip"])
	if nhip < 0.5:
		return 0.0
	return clampf(float(_hoi_ban[tay]), 0.0, nhip)


## Thời gian hồi đầy đủ của món tay phụ một bên (giây).
func hoi_tay_phu_toi_da(ben: String) -> float:
	return float(CanBang.TAY_PHU.get(tay_phu[ben], {"hoi": 1.0})["hoi"]) * float(cs["he_so_hoi_tay_phu"])


## Mức "quá tầm" 0..1: 0 = trong tầm tối ưu, 1 = ở tầm tối đa.
static func muc_qua_tam(d: Dictionary, kc: float) -> float:
	var uu: float = d.get("tam_toi_uu", 1e9)
	var xa: float = d.get("tam", uu + 1.0)
	return clampf((kc - uu) / maxf(xa - uu, 1.0), 0.0, 1.0)


static func gio() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


## Lấy điểm ngắm của một mục tiêu bất kỳ (Mecha, ụ súng, máy bay...).
static func diem_cua(n: Node3D) -> Vector3:
	if n.has_method("tam_than"):
		return n.call("tam_than")
	if n.has_method("diem_ngam_vao"):
		return n.call("diem_ngam_vao")
	return n.global_position


## Làm nóng động cơ (súng tia năng lượng, EMP, đấm EMP của địch).
func them_nhiet(luong: float) -> void:
	if not song or luong <= 0.0:
		return
	nhiet += luong
	_cho_nguoi = CanBang.NHIET["cho_nguoi"]
	_kiem_qua_nhiet()


func _kiem_qua_nhiet() -> void:
	if nhiet >= nhiet_toi_da() and not qua_nhiet:
		nhiet = nhiet_toi_da()
		qua_nhiet = true
		giu_do_cao = false
		_lao_con = 0.0
		AmThanh.phat("qua_nhiet", tam_than())
		su_kien.emit("qua_nhiet")


# ================================================================ chuyển động + nhiệt

func _physics_process(dt: float) -> void:
	if trung_bay:
		rotation.y = rotate_toward(rotation.y, dk_huong, 2.0 * dt)
		velocity = Vector3(0.0, 0.0 if is_on_floor() else velocity.y - 30.0 * dt, 0.0)
		move_and_slide()
		return
	if not song:
		velocity = Vector3.ZERO
		_am_dong_co(dt)
		return
	if dang_roi:
		_roi_tu_tau(dt)
		_am_dong_co(dt)
		return
	if dieu_khien:
		dieu_khien.dieu_khien(self, dt)
	bat_tu_con = maxf(0.0, bat_tu_con - dt)
	var N: Dictionary = CanBang.NHIET
	var M := cs
	var hs: float = cs["he_so_toc"]
	if choang_con > 0.0:
		choang_con -= dt
		dk_di = Vector2.ZERO
		dk_lao = false
		dk_giu_lao = false
		dk_bay = false
		dk_chem = false
		dk_lao_chem = false
		dk_ban = {"phai": false, "trai": false}
		dk_tay_phu = {"trai": false, "phai": false}
	if dk_lao:
		_phan_ung("ne")
	if dk_chem or dk_lao_chem:
		if _phan_ung("do"):                            # đang bị lao chém: F là đỡ, không ra đòn
			dk_chem = false
			dk_lao_chem = false
	var toi := Vector3(-sin(dk_huong), 0.0, -cos(dk_huong))
	var phai := Vector3(cos(dk_huong), 0.0, -sin(dk_huong))
	var muon := phai * dk_di.x + toi * dk_di.y
	if muon.length() > 1.0:
		muon = muon.normalized()
	rotation.y = lerp_angle(rotation.y, dk_huong, 1.0 - exp(-dt * 7.0))
	var tren_dat := is_on_floor()
	var dung_dong_co := false
	# Ctrl: dưới đất đổi lướt / chạy bộ; trên không bật / tắt giữ độ cao
	if dk_ctrl:
		if tren_dat:
			di_bo = not di_bo
		elif not qua_nhiet:
			giu_do_cao = not giu_do_cao
			do_cao_giu = global_position.y
			su_kien.emit("giu_do_cao" if giu_do_cao else "tha_do_cao")
	dk_ctrl = false
	if tren_dat or qua_nhiet:
		giu_do_cao = false
	var di_bo_that := di_bo or qua_nhiet           # quá nhiệt: chỉ chạy bộ
	var ngang := Vector3(velocity.x, 0.0, velocity.z)
	# giữ Shift lúc đang đi (không chạy bộ): lướt nhanh liên tục, tốn nhiệt
	luot_nhanh = dk_giu_lao and not qua_nhiet and muon.length() > 0.1 and not (di_bo and tren_dat)
	var toc_luot: float = float(M["toc_luot_nhanh" if luot_nhanh else "toc_luot"]) * hs
	var toc_max := toc_di(dk_di) * hs if (di_bo_that and tren_dat) else toc_luot
	var gia := 75.0 if muon.length() > 0.1 else 50.0
	if di_bo_that and tren_dat:
		gia = M["gia_chay"]
	if not tren_dat:
		gia *= 0.6
	elif ngang.length() > toc_max + 1.0:
		gia = maxf(gia, 140.0)                               # nhanh hơn tốc độ cho phép (vd. vừa quá nhiệt): hãm gấp
	ngang = ngang.move_toward(muon * toc_max, gia * dt)
	# bật lao: tốn nhiệt một lần, quá nhiệt thì không được. Cơ động: lần hai liền ngay sau không tốn nhiệt.
	_hoi_lao -= dt
	_kep_con -= dt
	if dk_lao and not qua_nhiet and (_hoi_lao <= 0.0 or _kep_con > 0.0):
		var la_kep: bool = _kep_con > 0.0 and _hoi_lao > -0.01 and cs["kha_nang"] == "luot_kep"
		_lao_huong = muon.normalized() if muon.length() > 0.1 else toi
		_lao_con = M["thoi_lao"]
		_hoi_lao = M["hoi_lao"]
		di_bo = false
		_w_lao = trong_so_huong(Vector2(_lao_huong.dot(phai), _lao_huong.dot(toi)))
		_bat_dau("bat_lao_toi")
		if la_kep:
			_kep_con = 0.0
			su_kien.emit("lao_kep")
		else:
			nhiet += N["lao"]
			if cs["kha_nang"] == "luot_kep":
				_kep_con = float(M["thoi_lao"]) + float(CanBang.KHA_NANG["luot_kep"]["cua_so"])
		dung_dong_co = true
		AmThanh.phat("ne", tam_than())
		su_kien.emit("lao")
	dk_lao = false
	if _lao_con > 0.0:
		var k := _lao_con / float(M["thoi_lao"])
		ngang = _lao_huong * lerpf(toc_luot, float(M["toc_lao"]) * hs, k * k)
		_lao_con -= dt
	elif luot_nhanh:
		nhiet += float(N["giu_lao"]) * dt
		dung_dong_co = true
	# cận chiến (F: chém / lao chém)
	hoi_chem -= dt
	hoi_lao_chem -= dt
	_t_do -= dt
	if dk_lao_chem:
		_bat_dau_lao_chem()
	elif dk_chem and _t_do <= 0.0:
		_bat_dau_chem()
	dk_chem = false
	dk_lao_chem = false
	var dang_lao := false
	if not _cc.is_empty():
		var kq := _cap_nhat_can_chien(dt, ngang, toi)
		ngang = kq[0]
		if kq.size() > 1 and kq[1] != null:
			velocity.y = kq[1]
			dang_lao = true
	# T: rơi nhanh
	if dk_roi and not tren_dat and not dang_lao:
		_roi_nhanh = true
		giu_do_cao = false
		su_kien.emit("roi_nhanh")
	dk_roi = false
	if tren_dat:
		_roi_nhanh = false
	# độ cao mặt đất bên dưới (giới hạn bay cao)
	_hoi_do_dat -= dt
	if tren_dat:
		_mat_dat_y = global_position.y
	elif _hoi_do_dat <= 0.0:
		_hoi_do_dat = 0.2
		var q := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 400.0, 1)
		var kq_d := get_world_3d().direct_space_state.intersect_ray(q)
		if kq_d:
			_mat_dat_y = (kq_d["position"] as Vector3).y
	# bay / giữ độ cao
	if dang_lao:
		pass
	elif _roi_nhanh:
		velocity.y = -float(M["toc_roi"])
	elif dk_bay and not qua_nhiet:
		if tren_dat:
			_bat_dau("bat_bay")
			AmThanh.phat("bat_bay", global_position)
			su_kien.emit("bay")
			di_bo = false
		var muc := float(M["toc_len"]) * hs if global_position.y - _mat_dat_y < float(M["cao_bay"]) else 0.0
		velocity.y = move_toward(velocity.y, muc, 60.0 * dt)
		nhiet += float(N["bay"]) * dt
		dung_dong_co = true
		if giu_do_cao:
			do_cao_giu = global_position.y                  # giữ Space lúc đang giữ độ cao: lên cao hơn rồi giữ ở đó
	elif giu_do_cao:
		velocity.y = clampf((do_cao_giu - global_position.y) * 4.0, -12.0, 12.0)
		nhiet += float(N["giu_do_cao"]) * dt
		dung_dong_co = true
	elif not tren_dat:
		velocity.y -= float(M["trong_luc"]) * dt
	elif velocity.y < 0.0:
		velocity.y = 0.0
	# nhiệt
	if dung_dong_co:
		_cho_nguoi = N["cho_nguoi"]
	else:
		_cho_nguoi -= dt
	var nguoi: float = cs["he_so_nguoi"]
	if qua_nhiet:
		nhiet -= float(N["nguoi_qua_nhiet"]) * nguoi * dt
		if nhiet <= 0.0:
			nhiet = 0.0
			qua_nhiet = false
			AmThanh.phat("khoi_dong", tam_than())
			su_kien.emit("het_qua_nhiet")
	elif _cho_nguoi <= 0.0:
		nhiet = maxf(0.0, nhiet - float(N["nguoi"]) * nguoi * dt)
	_kiem_qua_nhiet()
	velocity = Vector3(ngang.x, velocity.y, ngang.z)
	_vy_truoc = velocity.y
	move_and_slide()
	if is_on_floor() and _tren_khong_truoc and _vy_truoc < -9.0:
		_bat_dau("dap")
		AmThanh.phat("cham_dat", global_position, clampf((-_vy_truoc - 30.0) / 10.0, -6.0, 3.0))   # rơi càng nhanh càng nặng
		su_kien.emit("dap")
		if _vy_truoc < -25.0:
			HieuUng.bui_dap(get_parent(), global_position, 6.0 * ty_le)
	_tren_khong_truoc = not is_on_floor()
	dang_bay = not is_on_floor()
	# vũ khí
	if laser_tay != "":
		_cap_nhat_laser(dt)
	for tay in ["phai", "trai"]:
		_ban(tay, dt)
	for ben in ["trai", "phai"]:
		hoi_tay_phu[ben] = maxf(0.0, hoi_tay_phu[ben] - dt)
		if dk_tay_phu[ben]:
			_dung_tay_phu(ben)
		dk_tay_phu[ben] = false
	_cap_nhat_tay_phu(dt)
	if dk_phao_nhiet:
		_phong_phao_nhiet()
	dk_phao_nhiet = false
	var P: Dictionary = CanBang.PHAO_NHIET
	if phao_nhiet < int(P["so_luot"]):
		hoi_phao -= dt
		if hoi_phao <= 0.0:
			phao_nhiet += 1
			hoi_phao = P["hoi"] if phao_nhiet < int(P["so_luot"]) else 0.0
	_am_dong_co(dt)


## Tiếng động cơ nhiều lớp, hòa mượt theo trạng thái:
## chờ (rì rì, cao dần khi nóng máy) · lướt (to và cao theo tốc độ) · lướt nhanh Shift (gầm) ·
## bay lên Space (phụt mạnh) · giữ độ cao (phụt nhịp nhẹ) · gió khi rơi. Quá nhiệt: tắt hết, chỉ còn gió.
func _am_dong_co(dt: float) -> void:
	if _am_lop.is_empty():
		return
	var toc := Vector2(velocity.x, velocity.z).length()
	var tren_dat := is_on_floor()
	var chay := song and visible and not dang_roi and not qua_nhiet    # động cơ đang nổ máy
	var lan_nhanh := chay and luot_nhanh and toc > 5.0
	var muc := {
		"dong_co_cho": 1.0 if chay else 0.0,
		"luot_lap": clampf(toc / 30.0, 0.0, 1.0) if (chay and tren_dat and not di_bo and not lan_nhanh) else 0.0,
		"luot_nhanh_lap": 1.0 if lan_nhanh else 0.0,
		"bay_lap": 1.0 if (chay and not tren_dat and dk_bay) else 0.0,
		"lo_lung_lap": 1.0 if (chay and not tren_dat and giu_do_cao and not dk_bay) else 0.0,
		"gio_roi": 1.0 if (song and dang_roi) else (clampf((-velocity.y - 15.0) / 40.0, 0.0, 1.0) if (song and not tren_dat) else 0.0),
	}
	var p_nong := clampf(nhiet / maxf(1.0, nhiet_toi_da()), 0.0, 1.0)
	var cao_do := {
		"dong_co_cho": 0.9 + 0.25 * p_nong,
		"luot_lap": 0.85 + clampf(toc / 90.0, 0.0, 0.45),
		"luot_nhanh_lap": 0.95 + clampf(toc / 160.0, 0.0, 0.25),
		"bay_lap": 1.0 + clampf(velocity.y / 60.0, -0.1, 0.15),
		"lo_lung_lap": 1.0,
		"gio_roi": 0.9 + clampf(-velocity.y / 300.0, 0.0, 0.3),
	}
	for ten in LOP_DONG_CO:
		var p: AudioStreamPlayer3D = _am_lop[ten]
		var dich: float = muc[ten]
		var cu: float = _am_muc[ten]
		var w := move_toward(cu, dich, dt * (5.0 if dich > cu else 2.5))    # lên nhanh ~0,2 s, tắt dần ~0,4 s
		_am_muc[ten] = w
		if w <= 0.01:
			if p.playing:
				p.stop()
			continue
		p.volume_db = float(p.get_meta("goc_db")) + linear_to_db(w)
		p.pitch_scale = lerpf(p.pitch_scale, cao_do[ten], 1.0 - exp(-dt * 6.0))
		if not p.playing and p.stream:
			p.play(randf() * p.stream.get_length())             # mỗi mecha bắt đầu ở chỗ khác nhau, không đồng thanh
			AmThanh.nhat_ky[ten] = int(AmThanh.nhat_ky.get(ten, 0)) + 1


func _bat_dau(ten_clip: String) -> void:
	if tron.co(ten_clip):
		_mot_lan[ten_clip] = 0.0


## Trọng số 4 hướng chính từ hướng đi so với thân (x: phải, y: tới). Cộng lại bằng 1.
static func trong_so_huong(d: Vector2) -> Dictionary:
	if d.length() < 0.01:
		return {"toi": 1.0, "lui": 0.0, "trai": 0.0, "phai": 0.0}
	d = d.normalized()
	var w := {"toi": maxf(0.0, d.y), "lui": maxf(0.0, -d.y), "phai": maxf(0.0, d.x), "trai": maxf(0.0, -d.x)}
	var tong := 0.0
	for k in w:
		tong += w[k]
	for k in w:
		w[k] /= tong
	return w


func _ten_di(h: String) -> String:
	var t := kieu_di if h == "toi" else kieu_di + "_" + h
	return t if tron.co(t) else kieu_di


## Tốc độ chạy bộ theo hướng (lấy từ dáng chạy để chân không trượt).
func toc_di(huong_l := Vector2(0, 1)) -> float:
	var w := trong_so_huong(huong_l)
	var v := 0.0
	for h in w:
		v += float(w[h]) * float(tron.meta(_ten_di(h), "toc_do", 3.0))
	return v


## Hồi sinh: rơi thẳng thật nhanh từ tàu sân bay xuống, chỉ hãm lại ở ~25 m cuối, chạm đất có bụi.
## Lúc rơi chỉ va chạm với mặt đất (lớp 1) nên không bị mắc trên ụ súng, máy bay hay mecha khác.
func _roi_tu_tau(_dt: float) -> void:
	var cao := global_position.y - _diem_dap.y
	velocity = Vector3(0.0, -clampf(cao * 6.0, 30.0, float(cs["roi_toc_do"])), 0.0)
	move_and_slide()
	if is_on_floor() or cao <= 0.5:
		dang_roi = false
		collision_mask = 1 | 2
		velocity = Vector3.ZERO
		bat_tu_con = 2.0
		_bat_dau("dap")
		HieuUng.bui_dap(get_tree().current_scene, global_position, 10.0 * ty_le)
		for c in get_tree().get_nodes_in_group("camera_rig"):
			if (c as Node3D).global_position.distance_to(global_position) < 120.0:
				c.rung(0.8)
		AmThanh.phat("ha_canh", global_position)
		AmThanh.phat("khoi_dong", tam_than(), -4.0)            # đáp xong thì nổ máy
		su_kien.emit("ha_canh")


# ================================================================ vũ khí tay

## Vũ khí "_dich" có laser: chiếu laser vào mục tiêu, 0,25 giây cuối đứng yên (để né được), hết giờ thì bắn.
func _cap_nhat_laser(dt: float) -> void:
	laser_con -= dt
	if laser_con > 0.25:
		laser_dich = diem_cua(khoa) if (is_instance_valid(khoa) and khoa.get("song")) else dk_ngam
	if laser_con <= 0.0 or not _cc.is_empty() or choang_con > 0.0:
		var tay := laser_tay
		laser_tay = ""
		_tia_laser.visible = false
		if laser_con <= 0.0 and _cc.is_empty() and choang_con <= 0.0:
			_ban_that(tay, laser_dich)
		return
	var g: Node3D = _sung[laser_tay]
	var nong: Vector3 = g.global_transform * Vector3(0, 0, float(CanBang.VU_KHI[vk[laser_tay]]["dai"]) * 0.5)
	var dai := nong.distance_to(laser_dich)
	_tia_laser.visible = dai > 1.0
	if dai > 1.0:
		_tia_laser.global_transform = Transform3D(Basis.looking_at((laser_dich - nong) / dai, Vector3.UP if absf((laser_dich - nong).normalized().y) < 0.98 else Vector3.RIGHT), (nong + laser_dich) * 0.5)
		_tia_laser.scale = Vector3(1.0 + 0.6 * sin(Time.get_ticks_msec() * 0.03), 1.0, dai)


func _ban(tay: String, dt: float) -> void:
	_hoi_ban[tay] -= dt
	if not dk_ban[tay] or laser_tay != "":
		return
	if not _cc.is_empty() or choang_con > 0.0:
		return                                             # đang chém / lao chém / choáng thì không bắn
	var d: Dictionary = CanBang.VU_KHI[vk[tay]]
	_giu_ngam[tay] = 0.9
	if _hoi_ban[tay] > 0.0 or float(_w["ngam_" + tay]) < 0.75:   # súng chưa nâng lên thì chưa bắn
		return
	_hoi_ban[tay] = d["nhip"]
	if d.has("laser"):
		laser_tay = tay
		laser_con = d["laser"]
		laser_dich = _diem_dich(d, Vector3.ZERO)
		return
	_ban_that(tay, Vector3.INF)


func _diem_dich(d: Dictionary, nong: Vector3) -> Vector3:
	if is_instance_valid(muc_tieu_ban):
		return muc_tieu_ban.global_position
	if is_instance_valid(khoa) and khoa.get("song") != false:
		var p := diem_cua(khoa)
		if d["kieu"] == "dan_cham" and nong != Vector3.ZERO and khoa is CharacterBody3D:
			p += (khoa as CharacterBody3D).velocity * (nong.distance_to(p) / float(d["toc_do_dan"]))
		return p
	if dk_ngam != Vector3.ZERO:
		return dk_ngam
	return tam_than() + huong_toi() * 300.0


func _ban_that(tay: String, dich_san: Vector3) -> void:
	var d: Dictionary = CanBang.VU_KHI[vk[tay]]
	var g: Node3D = _sung[tay]
	var nong: Vector3 = g.global_transform * Vector3(0, 0, float(d["dai"]) * 0.5)
	var dich := dich_san if dich_san != Vector3.INF else _diem_dich(d, nong)
	var huong := (dich - nong).normalized()
	var qua := muc_qua_tam(d, nong.distance_to(dich))       # ngoài tầm tối ưu: tỏa rộng hơn, yếu hơn
	var lech := deg_to_rad(float(d.get("do_lech", 0.0)) * lerpf(1.0, float(d.get("lech_xa", 1.0)), qua))
	if is_instance_valid(muc_tieu_ban):
		lech *= 0.3
	if lech > 0.0:
		var vuong := huong.cross(Vector3.UP).normalized()
		if vuong.length() < 0.1:
			vuong = Vector3.RIGHT
		huong = huong.rotated(vuong, randf_range(-lech, lech)).rotated(huong, randf() * TAU).normalized()
	(_chop[tay] as OmniLight3D).light_energy = 6.0
	_day("giat_" + tay, -float(d["giat"]) * 30.0)
	AmThanh.phat(_am_vk(vk[tay]), nong)
	su_kien.emit("ban")
	if d["kieu"] == "dan_cham":
		var dan := DanPlasma.new()
		dan.chu = self
		dan.phe = phe
		dan.van_toc = huong * float(d["toc_do_dan"])
		dan.sat_thuong = float(d["sat_thuong"]) * he_so_sat_thuong
		dan.ban_kinh_no = d["no"]
		dan.mau = d["mau"]
		dan.tam_toi_uu = d.get("tam_toi_uu", 1e9)
		dan.tam_toi_da = d.get("tam", 1e9)
		dan.dmg_xa = d.get("dmg_xa", 1.0)
		dan.nhiet_them = d.get("nhiet_them", 0.0)
		get_tree().current_scene.add_child(dan)
		dan.global_position = nong
		return
	var tam: float = d["tam"]
	var cuoi := nong + huong * tam
	var q := PhysicsRayQueryParameters3D.create(nong, cuoi, 1 | 2, [get_rid()])
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	var diem: Vector3 = kq["position"] if kq else cuoi
	# súng máy: đạn bắn rơi tên lửa địch nằm trên đường đạn (trước chỗ trúng)
	if d.get("chan_ten_lua", false):
		var tl := TenLua.tren_duong_dan(get_tree(), nong, diem, phe)
		if tl:
			diem = tl.global_position
			tl.bi_ban(self)
			kq = {}
			ban_roi_tl += 1
			su_kien.emit("ban_roi")
	var trung := false
	if kq and kq["collider"] and kq["collider"].has_method("nhan_sat_thuong"):
		var muc: Node = kq["collider"]
		if muc.get("phe") != phe:
			var dmg: float = float(d["sat_thuong"]) * he_so_sat_thuong * lerpf(1.0, float(d.get("dmg_xa", 1.0)), muc_qua_tam(d, nong.distance_to(diem)))
			muc.nhan_sat_thuong(dmg, self)
			if muc is Mecha and float(d.get("nhiet_them", 0.0)) > 0.0:
				(muc as Mecha).them_nhiet(d["nhiet_them"])
			ban_trung.emit(muc, dmg)
			trung = true
	if d.has("no_lan") and (kq or diem.distance_to(nong) < tam - 1.0):
		# súng pháo: nổ lan ở chỗ trúng, ai trong bán kính cũng dính (ít hơn ở rìa)
		var r: float = d["no_lan"]
		for n in get_tree().get_nodes_in_group("mecha") + get_tree().get_nodes_in_group("cong_trinh"):
			var x := n as Node3D
			if x == null or x == self or x.get("phe") == phe or x.get("song") == false or (kq and x == kq["collider"]):
				continue
			var kc := diem_cua(x).distance_to(diem)
			if kc < r:
				x.nhan_sat_thuong(float(d["sat_thuong_lan"]) * (1.0 - kc / r) * he_so_sat_thuong, self)
				trung = true
		HieuUng.vu_no(get_tree().current_scene, diem, r * 0.7, Color(1.0, 0.6, 0.25))
	HieuUng.vet_dan(get_tree().current_scene, nong, diem, d["mau"], 2.6 if d.get("tia_to", false) else 1.0)
	if trung or (kq and not kq.is_empty()):
		HieuUng.tia_lua(get_tree().current_scene, diem, -huong, Color(1.8, 1.1, 0.5), 8 if trung else 4)
		AmThanh.phat("trung_dan" if trung else "dan_cham_dat", diem)


## Tên âm thanh cho từng loại súng.
static func _am_vk(id: String) -> String:
	if id.begins_with("sung_ban_tia"):
		return "sung_ban_tia"
	if id.begins_with("sung_may"):
		return "sung_may"
	if id.begins_with("sung_tia"):
		return "tia_nang_luong"
	if id.begins_with("phao_plasma") or id.begins_with("sung_phao"):
		return "phao_plasma"
	if id.begins_with("sung_emp"):
		return "emp"
	return "sung_truong"


# ================================================================ cận chiến

## Đang lao chém vào d?
func dang_lao_chem_vao(d: Node) -> bool:
	return not _cc.is_empty() and _cc.get("kieu", "") == "lao" and _cc["pha"] != "thu" and _cc.get("muc") == d


## Phản ứng của đối thủ với cú lao chém đang ra: "" chưa phản ứng, "ne", "do", "sai".
func phan_ung_doi_thu() -> String:
	return _cc.get("phan_ung", "")


## Ước còn bao nhiêu giây tới cú chém (đang lao chém), không thì INF.
func t_toi_va_cham() -> float:
	if _cc.is_empty() or _cc.get("kieu", "") != "lao" or _cc["pha"] == "thu" or not is_instance_valid(_cc["muc"]):
		return INF
	var C: Dictionary = CanBang.CAN_CHIEN["lao_chem"]
	var d: float = maxf(0.0, tam_than().distance_to(diem_cua(_cc["muc"])) - float(C["trung_cach"]))
	var con := d / toc_lao_chem()
	if _cc["pha"] == "lay_da":
		con += maxf(0.0, lay_da_lao - float(_cc["t"]))
	return con


## Mecha địch đang lao chém vào mình (gần trúng nhất), không có thì null.
func ke_dang_lao_toi() -> Mecha:
	var tot: Mecha = null
	var con := INF
	for n in get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e and e != self and e.song and e.dang_lao_chem_vao(self):
			var t := e.t_toi_va_cham()
			if t < con:
				con = t
				tot = e
	return tot


## Tốc độ lao chém (m/s): gốc × nâng cấp hướng Cơ động.
func toc_lao_chem() -> float:
	return toc_lao_chem_goc * float(cs.get("he_so_lao_chem", 1.0))


## Có thể lao chém mục tiêu đang khóa không (mecha địch còn sống, trong tầm đánh dấu).
func co_the_lao_chem() -> bool:
	if not is_instance_valid(khoa) or not (khoa is Mecha) or not (khoa as Mecha).song or (khoa as Mecha).phe == phe:
		return false
	return global_position.distance_to(khoa.global_position) <= float(CanBang.CAN_CHIEN["lao_chem"]["tam_danh_dau"])


## Bấm Shift ("ne") / F ("do") lúc có kẻ đang lao chém mình: chỉ lần phản ứng đầu tiên tính.
## Đúng cửa sổ thì được né / đỡ; sớm quá thì "sai" — vẫn bị chém. Trả về true nếu lần bấm này được tính là phản ứng.
func _phan_ung(kieu: String) -> bool:
	var co := false
	for n in get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or e == self or not e.dang_lao_chem_vao(self) or e._cc.has("phan_ung"):
			continue
		var con := e.t_toi_va_cham()
		if con > 1.6:
			continue                                       # còn xa: chưa tính là phản ứng
		var cua_so: float = cs["cua_so_ne"] if kieu == "ne" else cs["cua_so_do"]
		e._cc["phan_ung"] = kieu if con <= cua_so else "sai"
		co = true
		if kieu == "do" and con <= cua_so:
			_t_do = 0.5
	return co


func _choang(t: float) -> void:
	choang_con = maxf(choang_con, t)
	_cc = {}
	_lao_con = 0.0
	laser_tay = ""
	_bat_dau("choang")
	su_kien.emit("choang")


func _bat_dau_chem() -> void:
	if not _cc.is_empty() or hoi_chem > 0.0 or choang_con > 0.0:
		return
	hoi_chem = CanBang.CAN_CHIEN["chem"]["hoi"]
	_cc = {"kieu": "chem", "t": 0.0, "da_trung": false, "pha": "vung"}
	_bat_dau("chem")
	AmThanh.phat("chem_vut", tam_than())
	su_kien.emit("chem")


func _bat_dau_lao_chem() -> void:
	if not co_the_lao_chem() or not _cc.is_empty() or hoi_lao_chem > 0.0 or qua_nhiet or choang_con > 0.0:
		_bat_dau_chem()                                    # không có mục tiêu lao tới: chém thường
		return
	var C: Dictionary = CanBang.CAN_CHIEN["lao_chem"]
	hoi_lao_chem = C["hoi"]
	nhiet += float(C["nhiet"])
	_lao_con = 0.0
	giu_do_cao = false
	_cc = {"kieu": "lao", "pha": "lay_da", "t": 0.0, "muc": khoa, "da_vung": false}
	_bat_dau("bat_lao_toi")
	AmThanh.phat("lao_phan_luc", tam_than())
	su_kien.emit("lao_chem")


## Trả về [vận tốc ngang mới, vận tốc dọc (null = không ép)].
func _cap_nhat_can_chien(dt: float, ngang: Vector3, toi: Vector3) -> Array:
	var C: Dictionary = CanBang.CAN_CHIEN
	_cc["t"] = float(_cc["t"]) + dt
	var t: float = _cc["t"]
	if _cc.get("kieu", "") == "chem":
		# chém nhanh: lướt nhẹ tới mục tiêu gần, trúng ở giây 0,3
		if t > 0.12 and t < 0.34 and is_instance_valid(khoa):
			var dv := khoa.global_position - global_position
			dv.y = 0.0
			if dv.length() < float(C["chem"]["lao_nhe"]) and dv.length() > 9.0:
				ngang = ngang.lerp(dv.normalized() * 95.0, 0.35)
		if t >= 0.3 and not _cc["da_trung"]:
			_cc["da_trung"] = true
			_chem_trung_quanh(toi)
		if t > 0.6:
			_cc = {}
		return [ngang, null]
	var L: Dictionary = C["lao_chem"]
	var muc: Node3D = _cc["muc"]
	match _cc["pha"]:
		"lay_da":
			ngang = ngang.move_toward(Vector3.ZERO, 120.0 * dt)
			if t >= lay_da_lao:
				_cc["pha"] = "lao"
				_cc["t"] = 0.0
			return [ngang, 0.0 if not is_on_floor() else null]
		"lao":
			if not is_instance_valid(muc) or (muc is Mecha and not (muc as Mecha).song):
				_cc["pha"] = "thu"
				_cc["t"] = 0.0
				return [ngang, null]
			var dv: Vector3 = diem_cua(muc) - tam_than()
			var dist: float = dv.length()
			if dist < 45.0 and not _cc["da_vung"]:
				_cc["da_vung"] = true
				_bat_dau("chem")
				AmThanh.phat("chem_vut", tam_than())
			if dist <= float(L["trung_cach"]):
				_ket_thuc_lao_chem(muc)
				if _cc.is_empty():                             # bị đỡ: đã choáng, đòn bị hủy
					return [ngang * 0.2, null]
				_cc["pha"] = "thu"
				_cc["t"] = 0.0
				return [ngang * 0.2, 0.0]
			if t > 1.2:                                    # hụt
				_cc["pha"] = "thu"
				_cc["t"] = 0.0
				su_kien.emit("chem_hut")
				return [ngang, null]
			var v: Vector3 = dv.normalized() * toc_lao_chem()
			rotation.y = atan2(-dv.x, -dv.z)
			dk_huong = rotation.y
			return [Vector3(v.x, 0, v.z), v.y]
		_:
			ngang = ngang.move_toward(Vector3.ZERO, 160.0 * dt)
			if t > 0.4:
				_cc = {}
			return [ngang, null]


func _kieu_cc() -> Dictionary:
	return CanBang.KIEU_CAN_CHIEN.get(can_chien, CanBang.KIEU_CAN_CHIEN["kiem"])


func _ket_thuc_lao_chem(muc: Node3D) -> void:
	var C: Dictionary = CanBang.CAN_CHIEN
	var kc: Dictionary = _kieu_cc()
	var pu: String = _cc.get("phan_ung", "")
	var dmg: float = float(C["lao_chem"]["sat_thuong"]) * he_so_can_chien * float(kc["he_so"])
	HieuUng.vet_chem(get_tree().current_scene, tam_than() + huong_toi() * 6.0, global_basis, kc["mau"])
	if muc is Mecha:
		var d := muc as Mecha
		if pu == "do":
			d.su_kien.emit("do_thanh_cong")
			su_kien.emit("bi_do")
			AmThanh.phat("do_don", d.tam_than())
			HieuUng.vu_no(get_tree().current_scene, (tam_than() + d.tam_than()) * 0.5, 6.0, Color(0.7, 1.2, 2.0))
			_choang(C["choang_bi_do"])
			return
		if pu == "ne" or d.bat_tu_con > 0.0:
			d.su_kien.emit("ne_thanh_cong")
			su_kien.emit("chem_hut")
			return
		d.nhan_sat_thuong(dmg, self, bool(kc["xuyen_khien"]))
		d.them_nhiet(kc["nhiet_them"])
		d.su_kien.emit("bi_chem")
		d._choang(float(C["choang_bi_chem"]) + float(kc["choang"]))
		d.velocity += huong_toi() * 30.0
		ban_trung.emit(d, dmg)
		su_kien.emit("chem_trung")
	elif muc.has_method("nhan_sat_thuong"):
		muc.nhan_sat_thuong(dmg, self)
		ban_trung.emit(muc, dmg)
		su_kien.emit("chem_trung")
	AmThanh.phat("chem_trung", diem_cua(muc))
	HieuUng.vu_no(get_tree().current_scene, diem_cua(muc), 6.0, kc["mau"])


## Chém nhanh (F): trúng mọi mecha và công trình địch trong tầm chém ở phía trước.
func _chem_trung_quanh(toi: Vector3) -> void:
	var C: Dictionary = CanBang.CAN_CHIEN["chem"]
	var kc: Dictionary = _kieu_cc()
	var tam := float(C["tam"]) + float(kc["tam_them"])
	var dmg: float = float(C["sat_thuong"]) * he_so_can_chien * float(kc["he_so"])
	HieuUng.vet_chem(get_tree().current_scene, tam_than() + toi * 6.0, global_basis, kc["mau"])
	var trung := false
	for n in get_tree().get_nodes_in_group("mecha") + get_tree().get_nodes_in_group("cong_trinh"):
		var x := n as Node3D
		if x == null or x == self or x.get("phe") == phe or x.get("song") == false or not x.has_method("nhan_sat_thuong"):
			continue
		var dv: Vector3 = diem_cua(x) - tam_than()
		var ngang := Vector2(dv.x, dv.z)
		if dv.length() < tam + (3.0 if not x is Mecha else 0.0) and ngang.normalized().dot(Vector2(toi.x, toi.z)) > float(kc["goc_dot"]):
			if x is Mecha:
				var m := x as Mecha
				if m.bat_tu_con > 0.0:
					continue
				m.nhan_sat_thuong(dmg, self, bool(kc["xuyen_khien"]))
				m.them_nhiet(kc["nhiet_them"])
				if float(kc["choang"]) > 0.0:
					m._choang(kc["choang"])
				m.su_kien.emit("bi_chem_nhe")
			else:
				x.nhan_sat_thuong(dmg, self)
			HieuUng.vu_no(get_tree().current_scene, diem_cua(x), 4.0, kc["mau"])
			ban_trung.emit(x, dmg)
			trung = true
	if trung:
		AmThanh.phat("chem_trung", tam_than() + toi * 8.0)
		su_kien.emit("chem_trung")


# ================================================================ tay phụ (Q / E)

func _dung_tay_phu(ben: String) -> void:
	var loai_tp: String = tay_phu[ben]
	if not CanBang.TAY_PHU.has(loai_tp) or hoi_tay_phu[ben] > 0.0 or choang_con > 0.0:
		return
	var P: Dictionary = CanBang.TAY_PHU[loai_tp]
	match loai_tp:
		"ten_lua", "ten_lua_loat":
			if not _phong_ten_lua(ben, P):
				return
		"sung_may_vai":
			sung_may_vai_con = P["thoi_gian"]
			su_kien.emit("sung_may_vai")
		"khien":
			khien_con = P["thoi_gian"]
			su_kien.emit("khien")
		"u_minigun":
			if not _dat_u_minigun():
				return
	hoi_tay_phu[ben] = float(P["hoi"]) * float(cs["he_so_hoi_tay_phu"])


func _cap_nhat_tay_phu(dt: float) -> void:
	if sung_may_vai_con > 0.0:
		sung_may_vai_con -= dt
		_hoi_smv -= dt
		var P: Dictionary = CanBang.TAY_PHU["sung_may_vai"]
		if _hoi_smv <= 0.0:
			var gan: TenLua = null
			var d_gan: float = P["tam"]
			for n in get_tree().get_nodes_in_group("ten_lua"):
				var tl := n as TenLua
				if tl == null or tl.phe == phe or tl.is_queued_for_deletion():
					continue
				var k := tl.global_position.distance_to(global_position)
				if k < d_gan:
					d_gan = k
					gan = tl
			if gan:
				_hoi_smv = P["nhip"]
				var ben := "trai" if (gan.global_position - global_position).dot(global_basis.x) < 0.0 else "phai"
				HieuUng.vet_dan(get_tree().current_scene, diem_phong(ben), gan.global_position, Color(1.0, 0.8, 0.4))
				gan.bi_ban(self)
				ban_roi_tl += 1
				su_kien.emit("ban_roi")
	if khien_con > 0.0:
		khien_con -= dt
	if is_instance_valid(_khien_mesh):
		_khien_mesh.visible = khien_con > 0.0


## Đổi món tay phụ một bên (bảng trang bị).
func doi_tay_phu(ben: String, loai_tp: String) -> void:
	tay_phu[ben] = loai_tp
	hoi_tay_phu[ben] = 0.5
	su_kien.emit("doi_sung")


## Đổi vũ khí một tay (bảng trang bị).
func doi_vu_khi(tay: String, id: String) -> void:
	if vk[tay] == id:
		return
	vk[tay] = id
	if laser_tay == tay:
		laser_tay = ""
	for n in [_sung.get(tay), _chop.get(tay)]:
		if is_instance_valid(n):
			n.queue_free()
	_tao_vu_khi_tay(tay)
	_hoi_ban[tay] = 0.5
	su_kien.emit("doi_sung")


## Đổi kiểu cận chiến (ô F).
func doi_can_chien(id: String) -> void:
	can_chien = id
	_cap_nhat_luoi()
	su_kien.emit("doi_sung")


func _phong_ten_lua(ben: String, P: Dictionary) -> bool:
	if not is_instance_valid(khoa) or khoa.get("song") == false:
		return false
	if khoa.global_position.distance_to(global_position) > float(CanBang.TEN_LUA["tam_khoa"]):
		return false
	var ong: Node3D = _ong[ben]
	var so: int = P["so_qua"]
	var loat := so > 3
	for i in so:
		var tl := TenLua.new()
		tl.phe = phe
		tl.muc_tieu = khoa
		tl.chu = self
		tl.sat_thuong = float(P["sat_thuong"]) * he_so_sat_thuong
		tl.quay = P["quay"]
		tl.toc_do = P["toc_max"]
		tl.ban_kinh_no = P["no"]
		tl.co = 0.6 if loat else 1.0
		get_tree().current_scene.add_child(tl)
		var lech := (float(i) - (so - 1) * 0.5) / maxf(1.0, so - 1)
		tl.global_position = ong.global_position + ong.global_basis.x.normalized() * 0.9 * lech
		var ra := ong.global_basis.z.normalized()
		var toa := Vector3(randf_range(-0.25, 0.25), randf_range(0.0, 0.3), randf_range(-0.25, 0.25)) if loat else Vector3.ZERO
		tl.huong = (ra + Vector3.UP * 0.7 + (global_basis.x * (1.0 if ben == "phai" else -1.0)) * 0.3 + toa).normalized()
	AmThanh.phat("ten_lua_phong", tam_than())
	su_kien.emit("ten_lua")
	return true


## Ụ minigun: đặt ngay trước mặt. Đặt quá số tối đa thì ụ cũ nhất bị thu hồi.
func _dat_u_minigun() -> bool:
	if dang_bay or not _cc.is_empty():
		return false
	u_minigun.assign(u_minigun.filter(func(x) -> bool: return is_instance_valid(x)))
	while u_minigun.size() >= int(cs["so_u_minigun"]):
		var cu: Node3D = u_minigun.pop_front()
		cu.queue_free()
	var u := UMinigun.new()
	u.phe = phe
	u.chu = self
	get_tree().current_scene.add_child(u)
	var p := global_position + huong_toi() * 8.0 * ty_le
	u.global_position = Vector3(p.x, global_position.y, p.z)
	u.rotation.y = rotation.y
	u_minigun.append(u)
	su_kien.emit("dat_u_minigun")
	return true


func _phong_phao_nhiet() -> void:
	var P: Dictionary = CanBang.PHAO_NHIET
	if phao_nhiet <= 0 or not song:
		return
	if phao_nhiet == int(P["so_luot"]):
		hoi_phao = P["hoi"]
	phao_nhiet -= 1
	var ds: Array = []
	for i in 6:
		var p := PhaoNhiet.new()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position + Vector3.UP * 7.0 * ty_le - huong_toi() * 2.0
		var goc := TAU * i / 6.0
		p.van_toc = Vector3(cos(goc) * 18.0, 14.0 + randf() * 6.0, sin(goc) * 18.0) - huong_toi() * 10.0 + velocity * 0.5
		ds.append(p)
	# tên lửa đang khóa mình, còn đủ xa: mất khóa, lao theo pháo nhiệt
	for tl in get_tree().get_nodes_in_group("ten_lua"):
		if (tl as TenLua).muc_tieu == self and tl.global_position.distance_to(global_position) > float(P["gan_qua"]):
			(tl as TenLua).muc_tieu = ds[randi() % ds.size()]
			tl_bi_lua += 1
			su_kien.emit("tl_mat_khoa")
	AmThanh.phat("phao_nhiet", tam_than())
	su_kien.emit("phao_nhiet")


# ================================================================ máu

func trung_ten_lua() -> void:
	bi_trung_tl += 1
	su_kien.emit("trung_ten_lua")


func nhan_sat_thuong(luong: float, tu: Node = null, xuyen := false) -> void:
	if not song or trung_bay:
		return
	if bat_tu_con > 0.0:
		return
	# khiên năng lượng (tay phụ): chặn đòn từ phía trước; thương xuyên đâm thủng được
	if khien_con > 0.0 and not xuyen and tu is Node3D and is_instance_valid(tu):
		var K: Dictionary = CanBang.TAY_PHU["khien"]
		var dv: Vector3 = (tu as Node3D).global_position - global_position
		dv.y = 0.0
		if dv.length() > 0.1 and rad_to_deg(dv.normalized().angle_to(huong_toi())) < float(K["goc"]):
			luong *= 0.0 if cs["kha_nang"] == "khien_day" else float(K["con_lai"])
			AmThanh.phat("khien_trung", tam_than() + huong_toi() * 6.0)
			su_kien.emit("khien_chan")
			if luong <= 0.01:
				return
	if tu != null and tu != self:
		ke_tan_cong = tu
	mau = maxf(mau - luong, mau_toi_thieu)
	if luong >= 150.0:
		_bat_dau("choang")
	su_kien.emit("trung")
	bi_trung.emit(tu, luong)
	if mau <= 0.0:
		mau = 0.0
		_bi_ha(tu)


func hoi_mau(luong: float) -> void:
	if song:
		mau = minf(mau_toi_da(), mau + luong)


func _bi_ha(tu: Node) -> void:
	song = false
	dang_bay = false
	dang_roi = false
	giu_do_cao = false
	_cc = {}
	laser_tay = ""
	_tia_laser.visible = false
	khien_con = 0.0
	sung_may_vai_con = 0.0
	velocity = Vector3.ZERO
	collision_layer = 0
	visible = false
	if tu is Mecha:
		(tu as Mecha).ha_dich += 1
	HieuUng.vu_no(get_tree().current_scene, tam_than(), 20.0, Color(1.0, 0.6, 0.2))
	bi_ha.emit(self)


## Hồi sinh: rơi từ trên cao xuống vi_tri (chạm đất ở đó).
func hoi_sinh(vi_tri: Vector3) -> void:
	_diem_dap = vi_tri
	dang_roi = true
	da_bi_khoa = false
	global_position = vi_tri + Vector3.UP * float(cs["roi_cao"])
	velocity = Vector3.ZERO
	collision_mask = 1                          # lúc rơi chỉ chạm đất, đáp xong mới va chạm lại với mecha / ụ súng
	collision_layer = 2
	mau = mau_toi_da()
	nhiet = 0.0
	qua_nhiet = false
	giu_do_cao = false
	phao_nhiet = CanBang.PHAO_NHIET["so_luot"]
	hoi_tay_phu = {"trai": 0.0, "phai": 0.0}
	_cc = {}
	choang_con = 0.0
	_roi_nhanh = false
	ke_tan_cong = null
	bat_tu_con = 99.0                           # bất bại suốt lúc rơi, chạm đất còn 2 giây
	song = true
	visible = true


## Đặt mecha xuống ngay một chỗ (không rơi từ tàu) — dùng khi bắt đầu nhiệm vụ / tự kiểm tra.
func dat_ngay(vi_tri: Vector3) -> void:
	global_position = vi_tri
	velocity = Vector3.ZERO
	dang_roi = false
	collision_mask = 1 | 2


# ================================================================ hoạt ảnh

func _lo_xo(ten_lx: String, dich: float, f: float, z: float, dt: float) -> float:
	var s: Vector2 = _lx.get(ten_lx, Vector2(dich, 0.0))
	var w := TAU * f
	var so := maxi(1, ceili(minf(dt, 0.1) * 120.0))
	var h := minf(dt, 0.1) / so
	for _k in so:
		s.y += (w * w * (dich - s.x) - 2.0 * z * w * s.y) * h
		s.x += s.y * h
	_lx[ten_lx] = s
	return s.x


func _day(ten_lx: String, luc: float) -> void:
	var s: Vector2 = _lx.get(ten_lx, Vector2.ZERO)
	s.y += luc
	_lx[ten_lx] = s


func _w_tien(ten_w: String, dich: float, toc: float, dt: float) -> float:
	_w[ten_w] = lerpf(_w[ten_w], dich, 1.0 - exp(-dt * toc))
	return _w[ten_w]


func _w_mot_lan(ten_clip: String, dt: float, mo_cuoi := 0.18) -> float:
	if not _mot_lan.has(ten_clip):
		return 0.0
	_mot_lan[ten_clip] += dt
	var t: float = _mot_lan[ten_clip]
	var d := tron.dai(ten_clip)
	if t >= d:
		_mot_lan.erase(ten_clip)
		return 0.0
	return minf(1.0, t / 0.05) * (1.0 - smoothstep(d - mo_cuoi, d, t))


func _process(dt: float) -> void:
	if dt <= 0.0 or not song or not visible:
		return
	var ngang := Vector3(velocity.x, 0.0, velocity.z)
	var s := ngang.length()
	var tren_dat := is_on_floor() or trung_bay
	var di_bo_that := di_bo or qua_nhiet
	var muc_di := 1.0 if (tren_dat and di_bo_that and s > 0.6) else 0.0
	var muc_luot := 1.0 if (tren_dat and not di_bo_that and s > 3.0) else 0.0
	var muc_bay := 0.0 if tren_dat else 1.0
	var w_di := _w_tien("di", muc_di, 5.0, dt)
	var w_luot := _w_tien("luot", muc_luot, 5.0, dt)
	var w_bay := _w_tien("bay", muc_bay, 4.0, dt)
	for t_ten in ["dung", "luot", "bay"]:
		_t[t_ten] = float(_t.get(t_ten, 0.0)) + dt
	var v_l := Vector2(ngang.dot(global_basis.x), ngang.dot(huong_toi()))
	if s > 1.0:
		var muc_h := trong_so_huong(v_l)
		for h in HUONG:
			_w_huong[h] = lerpf(_w_huong[h], muc_h[h], 1.0 - exp(-dt * 8.0))
	var tt := tron.mau("dung", _t["dung"])
	if w_luot > 0.001:
		tt = tron.phu(tt, _tron_huong("luot_", _t["luot"], _w_huong), w_luot)
	if w_di > 0.001 and tron.co(kieu_di):
		tt = tron.phu(tt, _tu_the_di(dt, s / maxf(ty_le, 0.1)), w_di)
	if w_bay > 0.001:
		var tt_bay := tron.phu(tron.mau("bay", _t["bay"]), _tron_huong("bay_", _t["bay"], _w_huong), clampf(s / 12.0, 0.0, 1.0))
		tt = tron.phu(tt, tt_bay, w_bay)
	var om := wrapf(rotation.y - _yaw_truoc, -PI, PI) / dt
	_yaw_truoc = rotation.y
	var om_m := _lo_xo("om", om, 3.0, 0.9, dt)
	var muc_re := clampf(absf(om_m) / 1.6, 0.0, 1.0) * clampf((s - 6.0) / 14.0, 0.0, 1.0) if (tren_dat and not di_bo_that) else 0.0
	var w_re := _w_tien("re", muc_re, 6.0, dt)
	if w_re > 0.01:
		tt = tron.phu(tt, tron.mau("re_trai" if om_m > 0.0 else "re_phai", 0.0), w_re)
	var w_lao := _w_mot_lan("bat_lao_toi", dt)
	if w_lao > 0.0:
		tt = tron.phu(tt, _tron_huong("bat_lao_", _mot_lan.get("bat_lao_toi", 0.0), _w_lao), w_lao)
	for ten_clip in ["bat_bay", "dap"]:
		var w := _w_mot_lan(ten_clip, dt)
		if w > 0.0:
			tt = tron.phu(tt, tron.mau(ten_clip, _mot_lan.get(ten_clip, 0.0)), w)
	# súng: lúc thường hạ ở tư thế chờ; bắn thì tay đó nâng súng lên ngắm, ngừng 0,9 s thì hạ
	for tay in ["phai", "trai"]:
		if laser_tay == tay:
			_giu_ngam[tay] = 0.9
		_giu_ngam[tay] = float(_giu_ngam[tay]) - dt
		var w_ng := _w_tien("ngam_" + tay, 1.0 if float(_giu_ngam[tay]) > 0.0 else 0.0, 16.0 if dk_ban[tay] else 5.0, dt)
		var clip := "ngam" if tay == "phai" else "ngam_trai"
		if w_ng > 0.01 and tron.co(clip):
			tt = tron.phu(tt, tron.mau(clip, 0.0), w_ng, TronHoatAnh.TAY_PHAI if tay == "phai" else TronHoatAnh.TAY_TRAI, false)
	# cận chiến: lưỡi năng lượng cẳng tay trái — chém bằng tay trái (tay phải vẫn cầm súng)
	var w_chem := _w_mot_lan("chem", dt, 0.3)
	if w_chem > 0.0:
		tt = tron.phu(tt, tron.mau("chem", _mot_lan.get("chem", 0.0)), w_chem, TronHoatAnh.COT_SONG + TronHoatAnh.TAY_TRAI)
	var w_do := _w_tien("do", 1.0 if _t_do > 0.0 else 0.0, 18.0, dt)
	if w_do > 0.01:
		tt = tron.phu(tt, tron.mau("do", 0.14), w_do, TronHoatAnh.COT_SONG + TronHoatAnh.TAY_TRAI, false)
	var w_ch := _w_mot_lan("choang", dt, 0.4)
	if w_ch > 0.0:
		tt = tron.phu(tt, tron.mau("choang", _mot_lan.get("choang", 0.0)), w_ch * (1.0 if choang_con > 0.0 else 0.6))
	tron.ap(tt)
	_lop_code(dt, s, tren_dat, w_chem)
	_trang_thai(tren_dat, s)


func _tron_huong(dau: String, t: float, w: Dictionary) -> Dictionary:
	var kq := {}
	var tong := 0.0
	for h in HUONG:
		var wh: float = w[h]
		if wh < 0.01 or not tron.co(dau + h):
			continue
		var tt := tron.mau(dau + h, t)
		tong += wh
		kq = tt if kq.is_empty() else tron.phu(kq, tt, wh / tong)
	return kq if not kq.is_empty() else tron.mau(dau + "toi", t)


func _tu_the_di(dt: float, s: float) -> Dictionary:
	var quang := 0.0
	for h in HUONG:
		var t_di := _ten_di(h)
		quang += float(_w_huong[h]) * float(tron.meta(t_di, "toc_do", 3.0)) * tron.dai(t_di)
	var pha_truoc := _pha_di
	_pha_di = fposmod(_pha_di + dt * s / maxf(0.5, quang), 1.0)
	if int(pha_truoc * 2.0) != int(_pha_di * 2.0) and is_on_floor():    # hai bước mỗi chu kỳ đi
		AmThanh.phat("buoc_chan", global_position)
	var kq := {}
	var tong := 0.0
	for h in HUONG:
		var wh: float = _w_huong[h]
		if wh < 0.01:
			continue
		var t_di := _ten_di(h)
		var d := tron.dai(t_di)
		var tt := tron.mau(t_di, fposmod(_pha_di * d + float(tron.meta(t_di, "pha_trai", 0.0)), d))
		tong += wh
		kq = tt if kq.is_empty() else tron.phu(kq, tt, wh / tong)
	return kq if not kq.is_empty() else tron.mau(kieu_di, 0.0)


## Dòng trạng thái (HUD hiện cho người chơi). Chữ ở đây là khóa dịch.
func _trang_thai(tren_dat: bool, s: float) -> void:
	var a := []
	if dang_roi:
		a.append(tr("ĐANG RƠI TỪ TÀU SÂN BAY XUỐNG"))
	if bat_tu_con > 0.0 and not dang_roi:
		a.append(tr("BẤT BẠI"))
	if choang_con > 0.0:
		a.append(tr("CHOÁNG"))
	if qua_nhiet:
		a.append(tr("QUÁ NHIỆT"))
	if not _cc.is_empty() and _cc.get("kieu", "") == "lao":
		a.append(tr("LAO CHÉM"))
	if _roi_nhanh:
		a.append(tr("RƠI NHANH"))
	if _lao_con > 0.0:
		a.append(tr("BẬT LAO"))
	elif luot_nhanh:
		a.append(tr("LƯỚT NHANH"))
	elif not _cc.is_empty() and _cc.get("kieu", "") == "lao":
		pass
	elif not tren_dat and not dang_roi:
		a.append(tr("GIỮ ĐỘ CAO") if giu_do_cao else (tr("BAY") if dk_bay else tr("RƠI")))
	elif di_bo or qua_nhiet:
		a.append(tr("CHẠY") if s > 0.6 else tr("ĐỨNG"))
	elif not dang_roi:
		a.append(tr("LƯỚT") if s > 3.0 else tr("ĐỨNG"))
	trang_thai = " · ".join(a) + "   %.0f m/s" % s


func _xoay_them(ten_x: String, e: Vector3) -> void:
	var i: int = _xuong.get(ten_x, -1)
	if i < 0 or e == Vector3.ZERO:
		return
	var r := Quaternion(Vector3.UP, deg_to_rad(e.y)) * Quaternion(Vector3.RIGHT, deg_to_rad(e.x)) * Quaternion(Vector3.BACK, deg_to_rad(e.z))
	var g: Quaternion = _rest_g[ten_x]
	sk.set_bone_pose_rotation(i, (sk.get_bone_pose_rotation(i) * (g.inverse() * r * g)).normalized())


func _lop_code(dt: float, s: float, tren_dat: bool, w_chem: float) -> void:
	_gia_toc = _gia_toc.lerp((velocity - _v_truoc) / dt, 1.0 - exp(-dt * 10.0))
	_v_truoc = velocity
	var toi := huong_toi()
	var phai := global_basis.x
	var ngang := Vector3(velocity.x, 0.0, velocity.z)
	var tl: float = float(cs["toc_luot"]) * float(cs["he_so_toc"])
	var n_toi := clampf(ngang.dot(toi) / tl * 7.0 + _gia_toc.dot(toi) * 0.06, -14.0, 20.0)
	var n_phai := clampf(ngang.dot(phai) / tl * 7.0 + _gia_toc.dot(phai) * 0.05, -18.0, 18.0)
	if (di_bo or qua_nhiet) and tren_dat:
		n_toi *= 0.3
		n_phai *= 0.3
	if not tren_dat:
		n_toi = clampf(ngang.dot(toi) / tl * 12.0, -15.0, 18.0)
		n_phai = clampf(ngang.dot(phai) / tl * 14.0, -18.0, 18.0)
	var p := _lo_xo("n_toi", n_toi, 1.8, 0.55, dt)
	var r := _lo_xo("n_phai", n_phai, 1.8, 0.55, dt)
	truc.rotation = Vector3(-deg_to_rad(p), 0.0, -deg_to_rad(r))
	var ngam := 0.0
	if dk_ngam != Vector3.ZERO:
		var dv := dk_ngam - tam_than()
		ngam = clampf(rad_to_deg(atan2(dv.y, Vector2(dv.x, dv.z).length())), -35.0, 45.0)
	var ngam_m := _lo_xo("ngam", ngam, 3.0, 0.8, dt)
	_xoay_them("UpperChest", Vector3(-ngam_m * 0.15, 0, 0))
	_xoay_them("Head", Vector3(-ngam_m * 0.25, 0, 0))
	for tay in ["phai", "trai"]:
		var cot := "RightUpperArm" if tay == "phai" else "LeftUpperArm"
		var w_ng: float = _w["ngam_" + tay]
		_xoay_them(cot, Vector3(-ngam_m * 0.7 * w_ng, 0, 0))
		var giat := _lo_xo("giat_" + tay, 0.0, 6.0, 0.45, dt)
		_xoay_them(cot, Vector3(giat * 0.7, 0, 0))
		_xoay_them("RightLowerArm" if tay == "phai" else "LeftLowerArm", Vector3(giat * 0.5, 0, 0))
		var chop: OmniLight3D = _chop.get(tay)
		if is_instance_valid(chop):
			chop.light_energy = maxf(0.0, chop.light_energy - dt * 60.0)
	var sang := maxf(w_chem, float(_w["do"]))
	if not _cc.is_empty() and _cc.get("kieu", "") == "lao":
		sang = 1.0
	_luoi.visible = sang > 0.05
	_luoi.scale = Vector3(1.0, 1.0, lerpf(0.2, 1.0, clampf(sang * 1.6, 0.0, 1.0)))
	_cap_nhat_lua(dt, s, tren_dat)


# ================================================================ dựng vũ khí, lửa

func _gan_vao_xuong(ten_x: String) -> BoneAttachment3D:
	var g := BoneAttachment3D.new()
	g.bone_name = ten_x
	sk.add_child(g)
	return g


## Trục đặt vật lên bàn tay: +Z của vật dọc xương tay (hướng ngón), +Y là "trước mặt" của bàn tay lúc nghỉ.
func _truc_tay(ten_x: String) -> Basis:
	var g: Quaternion = _rest_g[ten_x]
	var doc := Vector3(0, 1, 0)
	var len := (g.inverse() * Vector3(0, 0, 1)).normalized()
	len = (len - doc * len.dot(doc)).normalized()
	return Basis(len.cross(doc), len, doc)


func _tao_vu_khi() -> void:
	for tay in ["phai", "trai"]:
		_gan_tay[tay] = _gan_vao_xuong(XUONG_TAY[tay])
		_tao_vu_khi_tay(tay)
	# lưỡi năng lượng cận chiến: mọc ra từ cẳng tay trái, cạnh khẩu súng (chỉ hiện khi chém / đỡ / lao chém)
	_luoi = MeshInstance3D.new()
	_mat_luoi = StandardMaterial3D.new()
	_mat_luoi.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_luoi.visible = false
	_luoi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(_gan_tay["trai"] as Node3D).add_child(_luoi)
	_cap_nhat_luoi()
	# khiên năng lượng (tay phụ): tấm lục giác mờ phía trước
	_khien_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 6.5
	cm.bottom_radius = 6.5
	cm.height = 0.2
	cm.radial_segments = 6
	var mkh := StandardMaterial3D.new()
	mkh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mkh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mkh.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mkh.cull_mode = BaseMaterial3D.CULL_DISABLED
	mkh.albedo_color = Color(0.3, 0.7, 1.2, 0.25) if phe == 0 else Color(1.2, 0.4, 0.3, 0.25)
	cm.material = mkh
	_khien_mesh.mesh = cm
	_khien_mesh.visible = false
	_khien_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	truc.add_child(_khien_mesh)
	_khien_mesh.position = Vector3(0, 5.5, -4.5)
	_khien_mesh.rotation.x = PI * 0.5
	# ổ tên lửa: mẫu có sẵn ổ trên tay máy sau lưng (file .json) thì phóng từ mặt trước ổ đó;
	# không có thì phóng từ hai vai. _ong[ben] = điểm phóng, trục +Z hướng ra trước.
	var o_tl: Dictionary = cau_hinh.get("o_ten_lua", {})
	for ben in ["trai", "phai"]:
		var diem := Node3D.new()
		if o_tl.has(ben):
			var o: Array = o_tl[ben]
			var xg: String = o[0]
			var g := sk.get_bone_global_rest(_xuong[xg])
			_gan_vao_xuong(xg).add_child(diem)
			diem.transform = Transform3D(g.basis.inverse(), g.affine_inverse() * _v3(o[1]))
		else:
			var than := _gan_vao_xuong("UpperChest")
			var g := sk.get_bone_global_rest(_xuong["UpperChest"])
			than.add_child(diem)
			var x := 1.55 if ben == "trai" else -1.55      # +X khung xương = bên trái mecha
			diem.transform = Transform3D(g.basis.inverse(), g.affine_inverse() * Vector3(x, 9.3, 0.5))
		_ong[ben] = diem


## Lưỡi năng lượng theo kiểu cận chiến đang chọn: kiếm dài, thương rất dài và mảnh, nắm đấm EMP ngắn to.
func _cap_nhat_luoi() -> void:
	if not is_instance_valid(_luoi):
		return
	var kc: Dictionary = _kieu_cc()
	var kich: Vector3 = kc["luoi"]
	var b := _truc_tay("LeftHand")
	var bm := BoxMesh.new()
	bm.size = kich
	_mat_luoi.albedo_color = kc["mau"]
	bm.material = _mat_luoi
	_luoi.mesh = bm
	_luoi.transform = Transform3D(b, Vector3(0, 0.6, 0) + b.z * (kich.z * 0.5 + 0.1) - b.x * 0.9)


## Điểm phóng tên lửa của một bên ("trai" / "phai").
func diem_phong(ben: String) -> Vector3:
	return (_ong[ben] as Node3D).global_position


static func _v3(a: Variant) -> Vector3:
	return a if a is Vector3 else Vector3(float(a[0]), float(a[1]), float(a[2]))


func _tao_vu_khi_tay(tay: String) -> void:
	var gan: BoneAttachment3D = _gan_tay[tay]
	var b := _truc_tay(XUONG_TAY[tay])
	var d: Dictionary = CanBang.VU_KHI[vk[tay]]
	var chop := OmniLight3D.new()
	chop.light_color = Color(1.0, 0.75, 0.4)
	chop.omni_range = 18.0
	chop.light_energy = 0.0
	gan.add_child(chop)
	_chop[tay] = chop
	var sung := (load(d["model"]) as PackedScene).instantiate() as Node3D
	DoHoa.chinh_vat_lieu(sung, 0.65, 0.38, true)
	gan.add_child(sung)
	sung.transform = Transform3D(b, Vector3(0, 0.9, 0))
	sung.position += sung.basis.z * (float(d["dai"]) * 0.27) + sung.basis.y * 0.3
	_sung[tay] = sung
	chop.position = sung.position + sung.basis.z * (float(d["dai"]) * 0.55)


func _vat_lieu_lua(mau_l: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = mau_l
	return m


func _tao_lua() -> void:
	var ngoai := _vat_lieu_lua(Color(0.22, 0.45, 1.3, 0.55))
	var trong := _vat_lieu_lua(Color(1.0, 1.2, 1.5, 0.8))
	for v in cau_hinh.get("voi", VOI):
		var x: int = _xuong[v[0]]
		var g := sk.get_bone_global_rest(x)
		var giu := Node3D.new()
		giu.visible = false
		giu.top_level = true
		add_child(giu)
		var lop := []
		for k in 2:
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 0.5
			cm.height = 1.0
			cm.radial_segments = 12
			cm.rings = 1
			cm.material = ngoai if k == 0 else trong
			mi.mesh = cm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			giu.add_child(mi)
			lop.append(mi)
		var den := OmniLight3D.new()
		den.light_color = Color(0.5, 0.75, 1.0)
		den.omni_range = 14.0
		den.light_energy = 0.0
		giu.add_child(den)
		_lua.append({"giu": giu, "xuong": x, "lech": g.affine_inverse() * _v3(v[1]),
			"huong": (g.basis.inverse() * _v3(v[2])).normalized(), "loai": v[3], "lop": lop, "den": den})
	_bui = HieuUng.hat_bui()
	_bui.local_coords = false
	add_child(_bui)
	# khói xám xả ra từ động cơ lưng khi quá nhiệt
	_khoi = CPUParticles3D.new()
	_khoi.amount = 40
	_khoi.lifetime = 1.6
	_khoi.emitting = false
	_khoi.local_coords = false
	_khoi.direction = Vector3(0, 1, 0)
	_khoi.spread = 25.0
	_khoi.initial_velocity_min = 4.0
	_khoi.initial_velocity_max = 8.0
	_khoi.gravity = Vector3(0, 2.0, 0)
	_khoi.scale_amount_min = 1.5
	_khoi.scale_amount_max = 3.5
	var qm := QuadMesh.new()
	var mk := StandardMaterial3D.new()
	mk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mk.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mk.albedo_color = Color(0.35, 0.33, 0.32, 0.45)
	mk.albedo_texture = HieuUng.tron_mem()
	qm.material = mk
	_khoi.mesh = qm
	add_child(_khoi)


func _cap_nhat_lua(dt: float, s: float, tren_dat: bool) -> void:
	var lao_max: float = float(cs["toc_lao"]) * float(cs["he_so_toc"])
	var muc_vai := 0.0
	var muc_chan := 0.0
	if tren_dat and not (di_bo or qua_nhiet) and s > 2.0:
		var k := clampf((s - 2.0) / (lao_max - 2.0), 0.0, 1.0)
		muc_vai = 0.16 + 0.84 * pow(k, 0.8)
		muc_chan = 0.12 + 0.88 * pow(k, 0.8)
	if not tren_dat:
		muc_vai = 0.55 if (dk_bay or giu_do_cao or dang_roi) else 0.2
		muc_chan = 0.85 if (dk_bay or dang_roi) else (0.5 if giu_do_cao else 0.15)
		muc_vai = maxf(muc_vai, clampf(s / lao_max, 0.0, 1.0))
	if _lao_con > 0.0:
		muc_vai = maxf(muc_vai, 0.85)
		muc_chan = maxf(muc_chan, 0.75)
	if qua_nhiet or trung_bay:
		muc_vai = 0.0
		muc_chan = 0.0
	thu_lua(_lo_xo("lua_vai", muc_vai, 7.0, 0.85, dt), _lo_xo("lua_chan", muc_chan, 7.0, 0.85, dt), not tren_dat and (dk_bay or giu_do_cao or dang_roi))
	_bui.emitting = tren_dat and not (di_bo or qua_nhiet) and s > 6.0 and not trung_bay
	_bui.global_position = global_position + Vector3(0, 0.5, 0)
	_khoi.emitting = qua_nhiet
	_khoi.global_position = global_position + Vector3.UP * 7.5 * ty_le - huong_toi() * 1.5


func thu_lua(m_vai: float, m_chan: float, bay_len := false) -> void:
	var nhay := 0.88 + 0.12 * sin(Time.get_ticks_msec() * 0.09) + 0.05 * sin(Time.get_ticks_msec() * 0.23)
	var ngang := Vector3(velocity.x, 0.0, velocity.z)
	var nguoc := -ngang.normalized() if ngang.length() > 4.0 else Vector3.ZERO
	for d in _lua:
		var muc: float = (m_vai if d["loai"] == "vai" else m_chan) * nhay
		var giu: Node3D = d["giu"]
		giu.visible = muc > 0.03
		if not giu.visible:
			continue
		var t := sk.global_transform * sk.get_bone_global_pose(d["xuong"])
		var p: Vector3 = t * (d["lech"] as Vector3)
		var huong: Vector3 = (t.basis * (d["huong"] as Vector3)).normalized()
		if bay_len and d["loai"] == "chan":
			huong = (huong * 0.3 + Vector3.DOWN).normalized()
		elif nguoc != Vector3.ZERO:
			var n := nguoc
			if n.dot(huong) < 0.0:
				n -= huong * n.dot(huong)
			huong = (huong + n * 0.8).normalized()
		var tren := Vector3.UP if absf(huong.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		giu.global_transform = Transform3D(Basis.looking_at(-huong, tren) * Basis(Vector3.RIGHT, PI * 0.5), p)
		giu.scale = Vector3.ONE * ty_le
		var dai := 0.8 + 9.0 * muc
		var rong := 0.35 + 0.55 * muc
		var lop: Array = d["lop"]
		(lop[0] as MeshInstance3D).scale = Vector3(rong, dai, rong)
		(lop[0] as MeshInstance3D).position = Vector3(0, dai * 0.5, 0)
		(lop[1] as MeshInstance3D).scale = Vector3(rong * 0.55, dai * 0.6, rong * 0.55)
		(lop[1] as MeshInstance3D).position = Vector3(0, dai * 0.3, 0)
		(d["den"] as OmniLight3D).light_energy = 2.0 * muc
