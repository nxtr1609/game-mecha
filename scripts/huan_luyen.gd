class_name TranHuanLuyen
extends TranChienDich
## Màn huấn luyện ở bãi tập (nhiệm vụ 1 của chiến dịch, cũng mở từ nút HUẤN LUYỆN ở menu chính).
## 6 bài; trước mỗi bài game dừng và hiện BangHuongDan (chữ + ảnh minh họa + biểu tượng phím đang gán):
##   1 di chuyển & nhiệt · 2 nhắm bắn (bia đứng, bia chạy) · 3 khóa & tên lửa (bia bay) · 4 pháo nhiệt (né loạt tên lửa)
##   5 né & đỡ (mecha tập lao chém; cửa sổ rộng gấp đôi, thời gian chậm lại lúc sắp tới vạch) · 6 cận chiến & bài thi.
## Ở bãi tập giáp không xuống dưới 1 (không thể bị hạ). Trang bị cố định cho mọi người học giống nhau.
## Esc → "Xem lại hướng dẫn". Xong bài thi là hoàn thành nhiệm vụ (mở nhiệm vụ 2; huấn luyện không có điểm thưởng).
## --thu_chien_dich (kèm --nhiem_vu=0): máy tự chơi qua 6 bài. --chup_huong_dan=<thư mục>: chụp ảnh minh họa rồi thoát.

const VONG := [Vector3(0, 40, 300), Vector3(-110, 60, 180), Vector3(90, 45, 60)]
const BE_DAP := Vector3(0, 0, -40)
const BE_PHONG := Vector3(0, 0, -170)

## Nội dung từng bài (chữ là khóa dịch). dung: [x, z, hướng] chỗ đứng đầu bài. phim: [hành động, nhãn].
## mui_ten: [vị trí trên ảnh (0..1), nhãn] — ảnh chụp ở 1600 × 900.
const BAI := [
	{"ten": "DI CHUYỂN & NHIỆT", "anh": "bai_1", "dung": [0, 420, 0.0],
		"chu": "Mecha lướt sát mặt đất. Bấm lao để vọt nhanh; GIỮ lao để lướt nhanh liên tục. Bật lao, lướt nhanh, bay lên và giữ độ cao đều làm nóng động cơ: cung dưới vòng ngắm là thanh nhiệt. Đầy là QUÁ NHIỆT, chỉ chạy bộ được tới khi nguội. Thôi dùng động cơ một lúc thì tự nguội.",
		"viec": "bật lao 2 lần, bay qua 3 vòng sáng, giữ độ cao 3 giây, rồi rơi nhanh xuống bệ đáp vàng.",
		"phim": [["di", "Lướt"], ["lao", "Bấm: bật lao · giữ: lướt nhanh"], ["bay", "Giữ để bay lên"], ["doi_che_do", "Đang bay: giữ độ cao"], ["roi_nhanh", "Rơi nhanh"]],
		"mui_ten": [[Vector2(0.53, 0.66), "Cung nhiệt", Vector2(1, 0.4)], [Vector2(0.745, 0.5), "Vòng sáng", Vector2(0.2, -1)]]},
	{"ten": "NHẮM BẮN", "anh": "bai_2", "dung": [0, 330, 0.0],
		"chu": "Di chuột để nhắm. Mỗi tay một vũ khí: chuột trái bắn tay phải, chuột phải bắn tay trái. Đạn trúng thì tâm ngắm hiện dấu ×. Các ô tròn ở góc dưới phải (phím ghi bên dưới) cho biết món nào đang sẵn sàng (viền sáng) hay đang hồi (quạt tối, số giây).",
		"viec": "bắn hạ 4 bia đứng, rồi 3 bia chạy ngang.",
		"phim": [["ban_phai", "Vũ khí tay phải"], ["ban_trai", "Vũ khí tay trái"]],
		"mui_ten": [[Vector2(0.5, 0.5), "Tâm ngắm", Vector2(1, -0.5)], [Vector2(0.783, 0.92), "Ô vũ khí", Vector2(-0.6, -1)]]},
	{"ten": "KHÓA MỤC TIÊU & TÊN LỬA", "anh": "bai_3", "dung": [0, 330, 0.0],
		"chu": "Đưa mục tiêu vào trong vòng ngắm để khóa (khung đỏ, dưới khung là máu và khoảng cách). Cung trên vòng ngắm cũng là máu của thứ đang khóa. Tay phụ tên lửa chỉ bắn được khi đã khóa: ô tên lửa có dấu ổ khóa nghĩa là chưa khóa.",
		"viec": "hạ 3 bia bay bằng tên lửa.",
		"phim": [["tay_phu_trai", "Tay phụ trái"], ["tay_phu_phai", "Tay phụ phải"]],
		"mui_ten": [[Vector2(0.42, 0.33), "Máu mục tiêu", Vector2(-1, -0.4)], [Vector2(0.843, 0.92), "Ô tên lửa", Vector2(-0.4, -1)]]},
	{"ten": "PHÁO NHIỆT", "anh": "bai_4", "dung": [0, 330, 0.0],
		"chu": "Tên lửa địch đuổi theo thì có còi báo và mũi tên đỏ quanh vòng ngắm. Bấm pháo nhiệt: tên lửa mất khóa, lao theo pháo. Có 2 lượt, dùng hết thì phải chờ nạp. Tên lửa lọt vào vòng ngắm có tam giác rỗng đánh dấu: bắn súng máy (tay trái) lúc đó là bắn rơi nó.",
		"viec": "sống sót qua 3 loạt tên lửa mà không trúng quả nào.",
		"phim": [["phao_nhiet", "Pháo nhiệt"], ["ban_trai", "Súng máy bắn rơi tên lửa"]],
		"mui_ten": [[Vector2(0.5, 0.25), "Cảnh báo tên lửa", Vector2(-0.8, 0.6)], [Vector2(0.923, 0.92), "Ô pháo nhiệt", Vector2(-0.4, -1)]]},
	{"ten": "NÉ & ĐỠ ĐÒN", "anh": "bai_5", "dung": [0, 80, 0.0],
		"chu": "Địch lao chém thì quanh thân nó hiện vòng báo động nhỏ, co dần lại rất nhanh. Vòng chạm vạch VÀNG thì bấm lao để NÉ; chạm vạch TRẮNG (sát hơn) thì bấm cận chiến để ĐỠ, đỡ được thì đối thủ bị choáng. Bấm sớm quá hay chậm quá đều bị chém. Ở bãi tập, thời gian chậm lại lúc sắp tới vạch.",
		"viec": "né 2 lần, đỡ 1 lần.",
		"phim": [["lao", "Né"], ["can_chien", "Đỡ"]],
		"mui_ten": [[Vector2(0.473, 0.437), "Vạch vàng: né", Vector2(-1, -0.5)], [Vector2(0.502, 0.522), "Vạch trắng: đỡ", Vector2(1, 0.5)]]},
	{"ten": "CẬN CHIẾN & BÀI THI", "anh": "bai_6", "dung": [0, 80, 0.0],
		"chu": "Bấm cận chiến để chém. Mecha địch đang khóa trong 120 m có khung cam và chữ F bên cạnh: lúc đó bấm cận chiến là tự LAO CHÉM tới cực nhanh. Lao chém hồi 3 giây (cung cam quanh ô cận chiến). Nâng cấp hướng Cơ động thì lao nhanh hơn, địch khó né / đỡ hơn.",
		"viec": "chém trúng 1 lần, lao chém trúng 1 lần, rồi bài thi: hạ 2 mecha và 2 ụ tên lửa.",
		"phim": [["can_chien", "Chém · địch có chữ F: lao chém"]],
		"mui_ten": [[Vector2(0.497, 0.528), "Khung cam + chữ F: bấm để lao chém", Vector2(1, -0.6)], [Vector2(0.963, 0.92), "Ô cận chiến", Vector2(-0.4, -1)]]},
]

var bai := -1
var _bang: BangHuongDan
var _vat: Array = []              # vật của bài đang chơi (xóa khi sang bài)
var _dem := 0
var _dem2 := 0
var _buoc := 0
var _xong_con := -1.0             # đang báo hoàn thành: còn bao lâu thì sang bài kế
var _vong: Array = []             # bài 1: [MeshInstance3D, đã qua?]
var _t_giu := 0.0
var _tap: Mecha = null            # mecha tập (bài 5, 6)
var _dk_tap: DieuKhienTap = null
var _dot_tl: Array = []           # bài 4: tên lửa của loạt đang bay
var _tl_truoc := 0
var _hoi_tl := 3.0
var _cs_goc := {}
var _chup := ""
var _tu_hl: TuChoiHuanLuyen = null


## Mecha tập: đứng đối mặt người chơi, giữ cự ly ~80 m, thỉnh thoảng lao chém (tan_cong = true).
class DieuKhienTap:
	extends Node
	var muc: Mecha
	var tan_cong := true
	var _hoi := 2.5

	func dieu_khien(m: Mecha, dt: float) -> void:
		m.dk_di = Vector2.ZERO
		if not is_instance_valid(muc):
			return
		var dv := muc.global_position - m.global_position
		var d := Vector2(dv.x, dv.z).length()
		m.dk_huong = atan2(-dv.x, -dv.z)
		m.dk_ngam = muc.tam_than()
		m.khoa = muc if tan_cong else null
		if not tan_cong:
			return
		if d > 105.0:
			m.dk_di = Vector2(0, 0.6)
		elif d < 60.0:
			m.dk_di = Vector2(0, -0.7)
		_hoi -= dt
		if _hoi <= 0.0 and d < 115.0 and d > 35.0 and m.co_the_lao_chem() and m.hoi_lao_chem <= 0.0:
			m.dk_lao_chem = true
			_hoi = randf_range(4.0, 5.5)


func _doc_cau_hinh() -> void:
	super()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--chup_huong_dan"):
			_chup = a.get_slice("=", 1) if "=" in a else "user://anh_huong_dan"


func kich_thuoc() -> float:
	return 1400.0


func _bat_dau() -> void:
	var d: Array = BAI[0]["dung"]
	diem_xuat_phat = _vi_tri(d[0], d[1])
	_tao_nguoi_choi(diem_xuat_phat, 0.0)
	nguoi_choi.mau_toi_thieu = 1.0
	nguoi_choi.doi_vu_khi("phai", "sung_truong")
	nguoi_choi.doi_vu_khi("trai", "sung_may")
	nguoi_choi.doi_tay_phu("trai", "ten_lua")
	nguoi_choi.doi_tay_phu("phai", "ten_lua")
	nguoi_choi.doi_can_chien("kiem")
	nguoi_choi.su_kien.connect(_khi_su_kien_nguoi)
	_dung_giao_dien()
	var lop := CanvasLayer.new()
	lop.layer = 7
	lop.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lop)
	_bang = BangHuongDan.new()
	lop.add_child(_bang)
	_bang.bat_dau.connect(_khi_bat_dau_bai)
	_bang.bo_qua.connect(func() -> void:
		get_tree().paused = false
		_xong_bai(true))
	AmThanh.nhac("tran")
	if _chup != "":
		DirAccess.make_dir_recursive_absolute(_chup)
		_chup_minh_hoa()
		return
	if _tu_choi:
		DirAccess.make_dir_recursive_absolute(_thu_muc)
		_tu_hl = TuChoiHuanLuyen.new()
		_tu_hl.hl = self
		add_child(_tu_hl)
		nguoi_choi.dieu_khien = _tu_hl
	_sang_bai(0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- bảng hướng dẫn

func dang_mo_bang() -> bool:
	return super.dang_mo_bang() or (_bang != null and _bang.visible)


func _mo_bang() -> void:
	var b: Dictionary = (BAI[bai] as Dictionary).duplicate()
	b["so"] = bai + 1
	b["tong"] = BAI.size()
	Engine.time_scale = 1.0
	_bang.mo(b)
	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _tu_choi:
		await get_tree().create_timer(0.6, true, false, true).timeout
		if _bang.visible:
			_bang.visible = false
			_khi_bat_dau_bai()


func _khi_bat_dau_bai() -> void:
	get_tree().paused = false
	if DisplayServer.get_name() != "headless" and not _tu_choi and not dang_mo_bang():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Menu tạm dừng: mở lại bảng hướng dẫn của bài đang chơi.
func xem_lai_huong_dan() -> void:
	if bai >= 0 and not da_ket_thuc:
		_mo_bang()


## Huấn luyện dùng trang bị cố định.
func co_the_doi_sung(_m: Mecha) -> bool:
	return false


func mo_trang_bi() -> void:
	hud.thong_bao(tr("Huấn luyện dùng trang bị cố định. Bảng trang bị mở được ở các nhiệm vụ sau."))


# ---------------------------------------------------------------- chuyển bài

func _sang_bai(i: int) -> void:
	_don_bai()
	bai = i
	_dem = 0
	_dem2 = 0
	_buoc = 0
	_xong_con = -1.0
	var d: Array = BAI[i]["dung"]
	_dat_nguoi(Vector3(d[0], 0, d[1]), d[2])
	_dung_bai(i)
	print("[huan_luyen] bai %d bat dau luc %.0f s" % [i + 1, _t_nv])
	_mo_bang()


func _dat_nguoi(p: Vector3, huong: float) -> void:
	var m := nguoi_choi
	m.dat_ngay(_vi_tri(p.x, p.z))
	m.rotation.y = huong
	m.dk_huong = huong
	m.velocity = Vector3.ZERO
	m.nhiet = 0.0
	m.qua_nhiet = false
	m.giu_do_cao = false
	m.mau = m.mau_toi_da()
	m.khoa = null
	m.phao_nhiet = int(CanBang.PHAO_NHIET["so_luot"])
	m.hoi_phao = 0.0
	for ben in ["trai", "phai"]:
		m.hoi_tay_phu[ben] = 0.0
	cam.yaw = huong
	cam.pitch = -0.08
	diem_xuat_phat = m.global_position


func _don_bai() -> void:
	for n in _vat:
		if is_instance_valid(n):
			n.queue_free()
	_vat.clear()
	_vong.clear()
	for tl in get_tree().get_nodes_in_group("ten_lua"):
		(tl as Node).queue_free()                # tên lửa còn bay của bài trước
	_dot_tl.clear()
	if is_instance_valid(_tap):
		_tap.queue_free()
	_tap = null
	if not _cs_goc.is_empty():
		nguoi_choi.cs["cua_so_ne"] = _cs_goc["ne"]
		nguoi_choi.cs["cua_so_do"] = _cs_goc["do"]
		_cs_goc = {}
	Engine.time_scale = 1.0
	hud.danh_dau = []


func _xong_bai(bo_qua := false) -> void:
	if _xong_con >= 0.0 or da_ket_thuc:
		return
	if bai >= BAI.size() - 1:
		_don_bai()
		ket_thuc(1, tr("Đã hoàn thành huấn luyện."))
		return
	if bo_qua:
		_sang_bai(bai + 1)
		return
	hud._chu_giua = tr("HOÀN THÀNH BÀI %d!") % (bai + 1)
	hud._chu_giua_mau = Color(0.5, 1.0, 0.6)
	hud._chu_giua_con = 2.0
	AmThanh.ui("bam")
	_xong_con = 2.0


func _them(n: Node) -> Node:
	add_child(n)
	_vat.append(n)
	return n


func _bia(kieu: String, p: Vector3, mau := 150.0) -> Bia:
	var b := Bia.new()
	b.kieu = kieu
	b.mau = mau
	b.huong_nhin = Vector3(0, 0, 1)
	b.position = p
	_them(b)
	b.bi_pha.connect(func(_b: Bia) -> void: _khi_bia_vo())
	return b


## Dựng vật cho từng bài.
func _dung_bai(i: int) -> void:
	match i:
		0:
			var vl := StandardMaterial3D.new()
			vl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			vl.albedo_color = Color(0.4, 0.95, 1.0)
			vl.emission_enabled = true
			vl.emission = Color(0.3, 0.9, 1.2)
			for p in VONG:
				var mi := MeshInstance3D.new()
				var tm := TorusMesh.new()
				tm.inner_radius = 13.0
				tm.outer_radius = 15.0
				tm.material = vl.duplicate()
				mi.mesh = tm
				mi.rotation.x = PI * 0.5
				mi.position = p
				_them(mi)
				_vong.append([mi, false])
			var cot := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 1.2
			cm.bottom_radius = 1.2
			cm.height = 80.0
			var vc := StandardMaterial3D.new()
			vc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			vc.albedo_color = Color(1.0, 0.85, 0.3, 0.35)
			vc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cm.material = vc
			cot.mesh = cm
			cot.position = BE_DAP + Vector3.UP * 40.0
			_them(cot)
		1:
			for p in [Vector3(-50, 0, 230), Vector3(40, 0, 180), Vector3(-20, 0, 100), Vector3(60, 0, 30)]:
				_bia("dung", p)
		2:
			for k in 3:
				var b := Bia.new()
				b.kieu = "bay"
				b.mau = 300.0
				b.tam_vong = Vector3(0, 0, 90)
				b.ban_kinh_vong = 110.0
				b.do_cao = 45.0
				b.toc_do = 20.0
				b.pha = k * 2.1 * 110.0 / 20.0
				b.position = Vector3(0, 45, 90)
				_them(b)
				b.bi_pha.connect(func(_b: Bia) -> void: _khi_bia_vo())
		3:
			var be := TaiNguyen.tao(DungBanDo.SP + "rocket_baseA.glb", 7.0, Color(0.55, 0.52, 0.5))
			be.position = BE_PHONG
			_them(be)
			_hoi_tl = 3.0
		4, 5:
			_tao_tap(i == 4)
			if i == 4:
				_cs_goc = {"ne": nguoi_choi.cs["cua_so_ne"], "do": nguoi_choi.cs["cua_so_do"]}
				nguoi_choi.cs["cua_so_ne"] = float(_cs_goc["ne"]) * 2.0
				nguoi_choi.cs["cua_so_do"] = float(_cs_goc["do"]) * 2.0


func _tao_tap(tan_cong: bool) -> void:
	var tb: Dictionary = CanBang.BOT_TRANG_BI["co_ban"]
	_tap = _tao_mecha(1, tr("Mecha tập"), "co_ban", tb["vk"], tb["tay_phu"], "kiem", _vi_tri(0, -20))
	_tap.he_so_can_chien = 0.3
	_tap.he_so_sat_thuong = 0.2
	_tap.lay_da_lao = 0.6
	_dk_tap = DieuKhienTap.new()
	_dk_tap.muc = nguoi_choi
	_dk_tap.tan_cong = tan_cong
	_tap.dieu_khien = _dk_tap
	_tap.rotation.y = PI
	_them(_dk_tap)
	add_child(_tap)
	_tap.mau_toi_thieu = 1.0


func _khi_bia_vo() -> void:
	_dem += 1


func _khi_su_kien_nguoi(loai: String) -> void:
	match bai:
		0:
			if loai == "lao" or loai == "lao_kep":
				_dem2 += 1
		4:
			if loai == "ne_thanh_cong":
				_dem += 1
			elif loai == "do_thanh_cong":
				_dem2 += 1
		5:
			if loai == "chem_trung":
				if nguoi_choi._cc.get("kieu", "") == "lao":
					_dem2 = 1
				else:
					_dem = 1


# ---------------------------------------------------------------- mỗi khung hình

func _process(dt: float) -> void:
	if _thoi_tiet:
		var c := get_viewport().get_camera_3d()
		if c:
			_thoi_tiet.global_position = c.global_position
	if da_ket_thuc or get_tree().paused or hud == null or bai < 0:
		return
	_t_nv += dt
	if _xong_con >= 0.0:
		_xong_con -= dt / maxf(Engine.time_scale, 0.01)
		if _xong_con < 0.0:
			_sang_bai(bai + 1)
		return
	var viec := ""
	match bai:
		0:
			viec = _bai_1(dt)
		1:
			if _buoc == 0:
				viec = tr("Bắn hạ bia đứng %d/4") % _dem
				if _dem >= 4:
					_buoc = 1
					_dem = 0
					for k in 3:
						var b := _bia("chay", Vector3(-60 + k * 60, 0, 140 - k * 25))
						b.bien_do = 35.0
						b.toc_do = 12.0 + k * 3.0
						b.pha = k * 1.3
			else:
				viec = tr("Bắn hạ bia chạy %d/3") % _dem
				if _dem >= 3:
					_xong_bai()
		2:
			viec = tr("Hạ bia bay bằng tên lửa %d/3") % _dem
			if _dem >= 3:
				_xong_bai()
		3:
			viec = _bai_4(dt)
		4:
			viec = tr("Né %d/2 · Đỡ %d/1") % [mini(_dem, 2), mini(_dem2, 1)]
			_cham_lai()
			if _dem >= 2 and _dem2 >= 1:
				_xong_bai()
		5:
			viec = _bai_6()
	hud.nhiem_vu = ["%s %d/%d — %s" % [tr("BÀI"), bai + 1, BAI.size(), tr(String(BAI[bai]["ten"]))], viec]
	_cap_danh_dau()
	if _tu_choi and _t_nv > _gioi_han:
		ket_thuc(-1, tr("Hết giờ thử"))


func _bai_1(dt: float) -> String:
	var m := nguoi_choi
	match _buoc:
		0:
			if _dem2 >= 2:
				_buoc = 1
			return tr("Bật lao %d/2") % _dem2
		1:
			for i in _vong.size():
				var v: Array = _vong[i]
				if v[1]:
					continue
				var mi: MeshInstance3D = v[0]
				var mat := (mi.mesh as TorusMesh).material as StandardMaterial3D
				mat.albedo_color = Color(1.0, 0.85, 0.3) if i == _dem else Color(0.4, 0.95, 1.0, 0.6)
				if i == _dem and m.tam_than().distance_to(mi.position) < 17.0:
					v[1] = true
					mi.visible = false
					_dem += 1
					AmThanh.ui("bam")
				break
			if _dem >= VONG.size():
				_buoc = 2
			return tr("Bay qua vòng sáng %d/3") % _dem
		2:
			if m.giu_do_cao:
				_t_giu += dt
			if _t_giu >= 3.0:
				_buoc = 3
			return tr("Đang bay: giữ độ cao %.1f / 3 giây") % minf(_t_giu, 3.0)
		_:
			var tren_be := Vector2(m.global_position.x - BE_DAP.x, m.global_position.z - BE_DAP.z).length() < 24.0
			if tren_be and m.is_on_floor():
				_xong_bai()
			return tr("Rơi nhanh xuống bệ đáp vàng")


## Bài 4: cứ 7,5 giây bệ phóng bắn một loạt 2 tên lửa; loạt nào bay hết mà không trúng quả nào thì tính.
func _bai_4(dt: float) -> String:
	if _dot_tl.is_empty():
		_hoi_tl -= dt
		if _hoi_tl <= 0.0:
			_tl_truoc = nguoi_choi.bi_trung_tl
			for k in 2:
				var tl := TenLua.new()
				tl.phe = 1
				tl.muc_tieu = nguoi_choi
				tl.chu = _vat[0] if not _vat.is_empty() else self
				tl.sat_thuong = 80.0
				tl.toc_do = 80.0
				tl.quay = 1.5
				add_child(tl)
				tl.global_position = BE_PHONG + Vector3((k - 0.5) * 6.0, 12.0, 0)
				tl.huong = (Vector3.UP * 0.8 + (nguoi_choi.global_position - BE_PHONG).normalized()).normalized()
				_dot_tl.append(tl)
			AmThanh.phat("ten_lua_phong", BE_PHONG)
			_hoi_tl = 7.5
	else:
		_dot_tl = _dot_tl.filter(func(x) -> bool: return is_instance_valid(x))
		if _dot_tl.is_empty():
			if nguoi_choi.bi_trung_tl == _tl_truoc:
				_dem += 1
				hud.thong_bao(tr("Loạt %d/3: không trúng quả nào!") % _dem)
			else:
				hud.thong_bao(tr("Bị trúng tên lửa — thử lại loạt này"))
			if _dem >= 3:
				_xong_bai()
	return tr("Né loạt tên lửa: %d/3 loạt không trúng") % _dem


## Bài 5: thời gian chậm lại khi cú lao chém sắp tới vạch né (chưa phản ứng).
func _cham_lai() -> void:
	var ke := nguoi_choi.ke_dang_lao_toi()
	var cham := false
	if ke and ke.phan_ung_doi_thu() == "":
		var con := ke.t_toi_va_cham()
		cham = con > 0.0 and con < float(nguoi_choi.cs["cua_so_ne"]) + 0.35
	Engine.time_scale = 0.35 if cham else 1.0


func _bai_6() -> String:
	match _buoc:
		0:
			if _dem >= 1 and _dem2 >= 1:
				_buoc = 1
				_bai_thi()
			var c1 := "%d/1" % mini(_dem, 1)
			var c2 := "%d/1" % mini(_dem2, 1)
			return tr("Chém trúng %s · Lao chém trúng %s") % [c1, c2]
		_:
			var cl := _con_lai()
			if cl[0] == 0 and cl[1] == 0:
				_xong_bai()
			return tr("Bài thi: hạ hết địch — còn %d mecha, %d ụ") % [cl[0], cl[1]]


## Bài thi: mecha tập rút đi, 2 mecha địch tuần tra + 2 ụ tên lửa ở cuối sân.
func _bai_thi() -> void:
	if is_instance_valid(_tap):
		_tap.queue_free()
	_tap = null
	hud.thong_bao(tr("BÀI THI: hạ 2 mecha và 2 ụ tên lửa ở cuối sân!"))
	for d in [["co_ban", -160, -330, "tuan_tra"], ["co_dong", 160, -330, "tuan_tra"]]:
		var b := _tao_dich(d, _vi_tri(d[1], d[2]))
		_vat.append(b)
	for p in [Vector3(-60, 0, -420), Vector3(60, 0, -420)]:
		_tao_u("ten_lua", Vector3(p.x, chieu_cao(p.x, p.z), p.z))
		_vat.append(u_dich[u_dich.size() - 1])
	if _tu_choi and _tu_hl:
		_tu_hl.bat_bot()


func _kiem_thang() -> void:
	pass                                  # huấn luyện tự xét xong bài thi trong _bai_6


## Dấu cam trên HUD: thứ cần nhắm trong bài.
func _cap_danh_dau() -> void:
	var ds: Array = []
	match bai:
		0:
			if _buoc == 1 and _dem < _vong.size():
				ds.append([_vong[_dem][0], tr("Vòng")])
			elif _buoc == 3:
				ds.append([_vat[VONG.size()], tr("Bệ đáp")])
		1, 2:
			for n in _vat:
				if is_instance_valid(n) and n is Bia and (n as Bia).song:
					ds.append([n, ""])
		3:
			if not _vat.is_empty():
				ds.append([_vat[0], tr("Bệ phóng")])
		4, 5:
			if is_instance_valid(_tap):
				ds.append([_tap, ""])
			for e in dich:
				if is_instance_valid(e) and e.song:
					ds.append([e, ""])
			for u in u_dich:
				if is_instance_valid(u) and u.song:
					ds.append([u, tr("Ụ")])
	hud.danh_dau = ds


# ---------------------------------------------------------------- chụp ảnh minh họa (--chup_huong_dan)

func _chup_minh_hoa() -> void:
	var m := nguoi_choi
	_tu_hl = TuChoiHuanLuyen.new()
	_tu_hl.hl = self
	add_child(_tu_hl)
	m.dieu_khien = _tu_hl
	_tu_hl.chi_dung = true
	for i in BAI.size():
		_sang_bai(i)
		_bang.visible = false
		get_tree().paused = false
		await get_tree().create_timer(0.8).timeout
		match i:
			0:
				m.dat_ngay(Vector3(0, 24, 375))
				m.nhiet = m.nhiet_toi_da() * 0.55
				_buoc = 1
				cam.pitch = 0.05
				await get_tree().create_timer(0.7).timeout
			1:
				_tu_hl.chi_dung = false
				await get_tree().create_timer(1.3).timeout
			2:
				_tu_hl.chi_dung = false
				await get_tree().create_timer(2.2).timeout
			3:
				_hoi_tl = 0.0
				_tu_hl.chi_dung = true
				await get_tree().create_timer(2.4).timeout
			4:
				_tu_hl.chi_dung = true
				var t0 := Time.get_ticks_msec()
				while Time.get_ticks_msec() - t0 < 9000:
					var ke := m.ke_dang_lao_toi()
					if ke and ke.t_toi_va_cham() < float(m.cs["cua_so_ne"]) * 1.4:
						break
					await get_tree().process_frame
			5:
				_tu_hl.chi_dung = true
				m.dat_ngay(_vi_tri(0, 70))
				await get_tree().create_timer(1.2).timeout
		_tu_hl.chi_dung = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_chup.path_join("bai_%d.png" % (i + 1)))
		print("[huan_luyen] da chup bai_%d" % (i + 1))
		Engine.time_scale = 1.0
	# ảnh chính bảng hướng dẫn (để xem lại bố cục)
	for i in [0, 2, 4]:
		_sang_bai(i)
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_chup.path_join("bang_%d.png" % (i + 1)))
	get_tree().quit()


## Máy tự chơi bài huấn luyện (kiểm tra): làm từng việc của bài đang chơi; bài thi thì dùng bot thường.
class TuChoiHuanLuyen:
	extends Node
	var hl: TranHuanLuyen
	var chi_dung := false             # chụp ảnh: đứng yên ngắm, không bắn
	var _bot: DieuKhienBot = null
	var _hoi := 0.0

	func bat_bot() -> void:
		_bot = DieuKhienBot.new()
		_bot.san_lung = true
		_bot.danh_cong_trinh = true
		_bot.p_ne = 0.6
		_bot.p_do = 0.15
		add_child(_bot)

	func _ngam(m: Mecha, n: Node3D) -> void:
		var p := Mecha.diem_cua(n)
		var dv := p - m.global_position
		m.dk_huong = atan2(-dv.x, -dv.z)
		m.dk_ngam = p
		m.khoa = n if n.get("song") != null else null
		hl.cam.yaw = m.dk_huong
		hl.cam.pitch = clampf(atan2(dv.y - 6.0, Vector2(dv.x, dv.z).length()), -1.0, 0.8)

	func dieu_khien(m: Mecha, dt: float) -> void:
		if _bot:
			_bot.dieu_khien(m, dt)
			return
		m.dk_di = Vector2.ZERO
		m.dk_bay = false
		m.dk_ban["phai"] = false
		m.dk_ban["trai"] = false
		_hoi -= dt
		match hl.bai:
			0:
				if hl._buoc == 0 and _hoi <= 0.0:
					m.dk_di = Vector2(1, 0)
					m.dk_lao = true
					_hoi = 0.6
				elif hl._buoc == 1 and hl._dem < TranHuanLuyen.VONG.size():
					var v: Vector3 = TranHuanLuyen.VONG[hl._dem]
					if not chi_dung:
						m.dat_ngay(v - Vector3.UP * 5.5)
					var dv := v - m.global_position
					m.dk_huong = atan2(-dv.x, -dv.z)
					hl.cam.yaw = m.dk_huong
					m.dk_bay = true
				elif hl._buoc == 2:
					m.dk_bay = not m.giu_do_cao and m.global_position.y < 40.0
					if m.global_position.y > 25.0 and not m.giu_do_cao and _hoi <= 0.0:
						m.dk_ctrl = true
						_hoi = 1.0
				elif hl._buoc == 3:
					var be := TranHuanLuyen.BE_DAP
					if Vector2(m.global_position.x - be.x, m.global_position.z - be.z).length() > 20.0:
						m.dat_ngay(Vector3(be.x, 30.0, be.z))
					m.dk_roi = not m.is_on_floor()
			1, 2:
				for n in hl._vat:
					if is_instance_valid(n) and n is Bia and (n as Bia).song:
						_ngam(m, n)
						if not chi_dung:
							if hl.bai == 1:
								m.dk_ban["phai"] = true
							elif _hoi <= 0.0:
								m.dk_tay_phu["trai" if randf() < 0.5 else "phai"] = true
								_hoi = 0.5
						break
			3:
				if not hl._vat.is_empty():
					_ngam(m, hl._vat[0])
				for n in m.get_tree().get_nodes_in_group("ten_lua"):
					var tl := n as TenLua
					if tl and tl.muc_tieu == m and tl.global_position.distance_to(m.global_position) < 230.0 and m.phao_nhiet > 0 and _hoi <= 0.0:
						m.dk_phao_nhiet = true
						_hoi = 1.5
			4:
				if is_instance_valid(hl._tap):
					_ngam(m, hl._tap)
				var ke := m.ke_dang_lao_toi()
				if ke and ke.phan_ung_doi_thu() == "" and not chi_dung:
					var con := ke.t_toi_va_cham()
					if hl._dem >= 2:
						if con < float(m.cs["cua_so_do"]) * 0.6:
							m.dk_chem = true
					elif con < float(m.cs["cua_so_ne"]) * 0.6 and con > float(m.cs["cua_so_do"]):
						m.dk_di = Vector2(1, 0)
						m.dk_lao = true
			5:
				if is_instance_valid(hl._tap):
					_ngam(m, hl._tap)
					var d := m.global_position.distance_to(hl._tap.global_position)
					if chi_dung:
						return
					if hl._dem2 < 1 and m.co_the_lao_chem() and _hoi <= 0.0:
						m.dk_lao_chem = true
						_hoi = 2.0
					elif hl._dem < 1:
						m.dk_di = Vector2(0, 1) if d > 14.0 else Vector2.ZERO
						if d < 18.0 and _hoi <= 0.0:
							m.dk_chem = true
							_hoi = 1.0
