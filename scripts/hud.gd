class_name HUD
extends Control
## Giao diện trong trận. Thông tin cần nhìn khi đánh nằm quanh tâm ngắm (Iron Valiant): thanh nhiệt là cung dưới
## vòng ngắm, máu thứ đang khóa là cung trên. Bố cục gọn học từ Wuthering Waves: ô kỹ năng tròn nhỏ góc dưới phải
## (phím ghi dưới ô), thanh giáp mảnh giữa dưới, nhiệm vụ gọn bên trái.
## Khóa = mục tiêu nằm trong vòng ngắm (cach_tam). Địch: chỉ con đang khóa mới có khung + máu + khoảng cách (cam + chữ F
## = bấm F là lao chém); con đã từng bị khóa có tam giác đỏ nhỏ; tên lửa địch lọt vào vòng ngắm bị tam giác rỗng đánh dấu.
## Bị lao chém: vòng báo động nhỏ quanh thân kẻ lao tới (vàng = né, trắng = đỡ).
## Mọi chữ đi qua tr() để dịch.

var nguoi_choi: Mecha
var cam: CameraRig
var ho_tro: HoTro
var ban_do: Node
var nhiem_vu: Array = []          # khung nhiệm vụ bên trái (chiến dịch, huấn luyện): [tên, dòng việc, dòng phụ...]
var danh_dau: Array = []          # chiến dịch: các mục tiêu cần đánh dấu [Node3D, nhãn]
var font: Font
var _tin: Array = []              # [chữ, giây còn lại] — bảng thông báo bên phải
var _o_hoi_sinh: Array = []       # [Rect2, tên điểm] — các ô bấm được trên màn hình hồi sinh
var _trung_con := 0.0
var _chu_giua := ""
var _chu_giua_mau := Color.WHITE
var _chu_giua_con := 0.0
var _so_ha := 0
var _t := 0.0
var _bip_khoa := 0.0
var _bip_ten_lua := 0.0
var _bip_minigun := 0.0
var _bip_chem := 0.0
var _bip_bi_trung := 0.0
var _ha_con := 0.0                # dấu × đỏ to ở tâm khi vừa hạ địch
var _bi_ban: Array = []           # [vị trí kẻ bắn, giây còn lại] — mũi tên đỏ chỉ hướng bị bắn
var _mau_hien := -1.0             # thanh giáp: phần "vừa mất" tụt dần theo sau
var _thay: Dictionary = {}        # mecha địch -> [có nhìn thấy không, lúc kiểm tra lại]

const R := 150.0              # bán kính vòng ngắm (px)
const TRANG := Color(1, 1, 1, 0.9)
const MO := Color(1, 1, 1, 0.4)
const DO := Color(1.0, 0.3, 0.25, 0.95)
const CAM := Color(1.0, 0.65, 0.2, 0.95)

const CHU_SU_KIEN := {
	"ne_thanh_cong": ["NÉ ĐƯỢC cú lao chém!", Color(1, 0.9, 0.4)],
	"do_thanh_cong": ["ĐỠ ĐƯỢC! Đối thủ bị choáng", Color(0.7, 1.0, 1.3)],
	"bi_do": ["Bị đối thủ ĐỠ — choáng!", Color(1, 0.5, 0.3)],
	"bi_chem": ["Bị lao chém trúng", Color(1, 0.4, 0.3)],
	"chem_hut": ["Chém hụt", Color(0.8, 0.8, 0.8)],
	"ban_roi": ["Bắn rơi tên lửa!", Color(1, 0.85, 0.4)],
	"qua_nhiet": ["QUÁ NHIỆT — không bay, không bật lao, chỉ chạy bộ được tới khi nguội", Color(1, 0.4, 0.3)],
	"het_qua_nhiet": ["Động cơ đã nguội", Color(0.6, 0.9, 1.0)],
	"tl_mat_khoa": ["Tên lửa địch mất khóa, lao theo pháo nhiệt", Color(1, 0.85, 0.55)],
	"ha_canh": ["ĐÃ HẠ CÁNH", Color(0.6, 0.9, 1.0)],
	"khien_chan": ["KHIÊN CHẶN ĐẠN", Color(0.5, 0.85, 1.2)],
	"doi_sung": ["ĐÃ ĐỔI TRANG BỊ", Color(0.6, 0.9, 1.0)],
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = GiaoDien.font()
	nguoi_choi.ban_trung.connect(func(_m, _d) -> void:
		_trung_con = 0.14
		AmThanh.phat("trung_xac_nhan"))                # tích nhỏ: mình bắn trúng
	nguoi_choi.su_kien.connect(_khi_su_kien)
	nguoi_choi.bi_trung.connect(_khi_bi_trung)


func _khi_bi_trung(tu: Node, luong: float) -> void:
	# mình bị trúng: tiếng thân máy rung trong buồng lái, đòn càng nặng càng to (tối đa ~7 lần/giây)
	if _bip_bi_trung <= 0.0 and luong > 1.0:
		_bip_bi_trung = 0.14
		AmThanh.phat("bi_trung", null, clampf(linear_to_db(luong / 150.0), -10.0, 3.0))
	if tu is Node3D and is_instance_valid(tu) and tu != nguoi_choi:
		_bi_ban.push_front([(tu as Node3D).global_position, 1.4])
		if _bi_ban.size() > 6:
			_bi_ban.pop_back()


func _khi_su_kien(loai: String) -> void:
	if CHU_SU_KIEN.has(loai):
		_chu_giua = tr(CHU_SU_KIEN[loai][0])
		_chu_giua_mau = CHU_SU_KIEN[loai][1]
		_chu_giua_con = 1.6


func thong_bao(s: String) -> void:
	_tin.push_front([s, 7.0])
	if _tin.size() > 5:
		_tin.pop_back()


func bao_ha() -> void:
	_so_ha += 1
	_chu_giua = tr("ĐÃ HẠ MỘT MECHA ĐỊCH")
	_chu_giua_mau = Color(1, 0.55, 0.3)
	_chu_giua_con = 1.5
	_ha_con = 0.5


func _process(dt: float) -> void:
	size = get_viewport_rect().size
	_t += dt
	_trung_con = maxf(0.0, _trung_con - dt)
	_chu_giua_con = maxf(0.0, _chu_giua_con - dt)
	for x in _tin:
		x[1] -= dt
	_tin = _tin.filter(func(x: Array) -> bool: return x[1] > 0.0)
	_bip_khoa = maxf(0.0, _bip_khoa - dt)
	_bip_ten_lua = maxf(0.0, _bip_ten_lua - dt)
	_bip_minigun = maxf(0.0, _bip_minigun - dt)
	_bip_chem = maxf(0.0, _bip_chem - dt)
	_bip_bi_trung = maxf(0.0, _bip_bi_trung - dt)
	_ha_con = maxf(0.0, _ha_con - dt)
	for x in _bi_ban:
		x[1] -= dt
	_bi_ban = _bi_ban.filter(func(x: Array) -> bool: return x[1] > 0.0)
	if is_instance_valid(nguoi_choi):
		if _mau_hien < 0.0 or nguoi_choi.mau > _mau_hien:
			_mau_hien = nguoi_choi.mau
		else:
			_mau_hien = move_toward(_mau_hien, nguoi_choi.mau, nguoi_choi.mau_toi_da() * 0.35 * dt)
	queue_redraw()


func _chu(p: Vector2, s: String, co: int, mau: Color, can_giua := false) -> void:
	GiaoDien.ve_chu(self, font, p, s, co, mau, can_giua, 4)


func _thanh(p: Vector2, kich: Vector2, ti_le: float, mau: Color) -> void:
	draw_rect(Rect2(p, kich), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(p + Vector2(2, 2), Vector2((kich.x - 4) * clampf(ti_le, 0.0, 1.0), kich.y - 4)), mau)


func _len_man_hinh(p: Vector3) -> Variant:
	if cam.cam.is_position_behind(p):
		return null
	return cam.cam.unproject_position(p)


func _draw() -> void:
	if not is_instance_valid(nguoi_choi):
		return
	var m := nguoi_choi
	var c := size * 0.5
	if not m.song and ban_do and ban_do.get("hoi_sinh_con") != null and ban_do.hoi_sinh_con > 0.0:
		_ve_hoi_sinh(m, c)                # đang chờ hồi sinh: chỉ hiện màn hình chọn điểm
		return

	# đồng hồ trận
	if ban_do and ban_do.get("thoi_gian_con") != null and ban_do.get("dem_gio") != false:
		var con: float = ban_do.thoi_gian_con
		var mau_dh := Color(1, 0.4, 0.3) if con < 120.0 else Color(1, 1, 1, 0.9)
		_chu(Vector2(size.x - 200, 54), tr("Còn %d:%02d") % [int(con) / 60, int(con) % 60], 17, mau_dh)
	_ve_nhiem_vu()

	# tâm ngắm + dấu trúng (× trắng khi đạn trúng, × đỏ to khi vừa hạ địch)
	for v in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_line(c + v * 7.0, c + v * 17.0, TRANG, 2.0)
	if _trung_con > 0.0 or _ha_con > 0.0:
		var to := _ha_con > 0.0
		var mau_x := Color(1, 0.3, 0.25, minf(1.0, _ha_con * 3.0)) if to else Color(1, 1, 1, minf(1.0, _trung_con * 8.0))
		var r0 := 12.0 if to else 9.0
		var r1 := 30.0 if to else 18.0
		for v in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(c + v.normalized() * r0, c + v.normalized() * r1, mau_x, 3.0 if to else 2.0)

	_ve_vong_ngam(m, c)
	_ve_huong_bi_ban(m, c)
	_ve_la_ban(m)
	_ve_canh_bao_ten_lua(m, c)
	_ve_ten_lua_trong_vong(m, c)
	_ve_cu_diem(m, c)
	_ve_danh_dau(m, c)

	# mecha khác: thoi xanh + tên đồng đội. Địch: chỉ con đã từng bị khóa (Mecha.da_bi_khoa) mới có tam giác đỏ nhỏ
	# trên đầu (không chữ) khi nhìn thấy; quét radar (hỗ trợ 3) thì thấy hết, kể cả sau nhà. Con đang khóa có khung khóa.
	for n in m.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or e == m or not e.song:
			continue
		var sp: Variant = _len_man_hinh(e.tam_than() + Vector3.UP * 6.5 * e.ty_le)
		if sp == null:
			continue
		var p2: Vector2 = sp
		if not Rect2(Vector2(-100, -100), size + Vector2(200, 200)).has_point(p2):
			continue
		var kc := int(e.global_position.distance_to(m.global_position))
		if e.phe == m.phe:
			var xanh := Color(0.45, 0.8, 1.0, 0.85)
			draw_colored_polygon(PackedVector2Array([p2 + Vector2(0, -6), p2 + Vector2(5, 0), p2 + Vector2(0, 6), p2 + Vector2(-5, 0)]), xanh)
			_chu(p2 + Vector2(0, -10), e.ten, 12, xanh, true)
			continue
		if e == m.khoa:
			continue                      # đang khóa: khung khóa đã chỉ rồi
		var radar := ho_tro != null and ho_tro.radar_con > 0.0
		if radar or (e.da_bi_khoa and kc <= 1500 and _nhin_thay(e)):
			draw_colored_polygon(PackedVector2Array([p2 + Vector2(-5, -7), p2 + Vector2(5, -7), p2 + Vector2(0, 1)]), Color(1, 0.3, 0.22, 0.85))

	# hòm tiếp tế: dấu xanh, khoảng cách, giây còn lại
	for n in m.get_tree().get_nodes_in_group("thung_tiep_te"):
		var th := n as ThungTiepTe
		if th == null or not th.da_dap:
			continue
		var sp4: Variant = _len_man_hinh(th.global_position + Vector3.UP * 7.0)
		if sp4 == null:
			continue
		var p4: Vector2 = sp4
		var mau_xanh := Color(0.4, 1.0, 0.55)
		draw_rect(Rect2(p4 - Vector2(11, 11), Vector2(22, 22)), mau_xanh, false, 3.0)
		draw_line(p4 - Vector2(6, 0), p4 + Vector2(6, 0), mau_xanh, 3.0)
		draw_line(p4 - Vector2(0, 6), p4 + Vector2(0, 6), mau_xanh, 3.0)
		var kc4 := int(th.global_position.distance_to(m.global_position))
		_chu(p4 + Vector2(0, -18), tr("TIẾP TẾ  %d m  (%d s)") % [kc4, int(ceil(th.con))], 15, mau_xanh, true)

	# khung khóa mục tiêu: chỉ máu (thanh mảnh) + khoảng cách. Cam + chữ F cạnh địch = bấm F là lao chém.
	if is_instance_valid(m.khoa) and m.khoa.get("song") != false:
		var pk := Mecha.diem_cua(m.khoa)
		var sp2: Variant = _len_man_hinh(pk)
		if sp2 != null:
			var s: Vector2 = sp2
			var r2 := clampf(2200.0 / maxf(cam.cam.global_position.distance_to(pk), 1.0), 22.0, 70.0)
			var lc := lao_chem_duoc(m)
			var mau_k := CAM if lc else DO
			for g in 4:
				var gx := 1.0 if g % 2 == 0 else -1.0
				var gy := 1.0 if g < 2 else -1.0
				var goc := s + Vector2(gx, gy) * r2
				draw_line(goc, goc - Vector2(gx * 10, 0), mau_k, 2.0)
				draw_line(goc, goc - Vector2(0, gy * 10), mau_k, 2.0)
			var y_d := s.y + r2 + 7.0
			if m.khoa.get("mau") != null:
				var kk := clampf(float(m.khoa.get("mau")) / maxf(1.0, _mau_toi_da(m.khoa)), 0.0, 1.0)
				draw_rect(Rect2(Vector2(s.x - 30, y_d), Vector2(60, 4)), Color(0, 0, 0, 0.55))
				draw_rect(Rect2(Vector2(s.x - 30, y_d), Vector2(60 * kk, 4)), mau_mau(kk))
			_chu(Vector2(s.x, y_d + 17), "%d m" % int(m.global_position.distance_to(m.khoa.global_position)), 13, Color(1, 1, 1, 0.85), true)
			if lc and m.ke_dang_lao_toi() == null:      # đang bị lao chém thì F là đỡ (vòng báo động chỉ phím)
				var nhay := 0.7 + 0.3 * absf(sin(_t * 6.0))
				VeBieuTuong.nut(self, font, "can_chien", s + Vector2(r2 + 20, 0), 0.5, Color(1, 1, 1, nhay))

	# báo động bị lao chém: vòng co dần về cú chém; vào vòng vàng = bấm Shift né, vào vòng trắng = bấm F đỡ
	_ve_bao_lao_chem(m, c)
	if m.dang_bi_choang():
		_chu(Vector2(c.x, c.y - R - 44), tr("CHOÁNG"), 26, Color(1, 0.5, 0.3), true)
	# bị khóa
	var bi_khoa := false
	for n in m.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e and e.song and e.phe != m.phe and e.khoa == m:
			bi_khoa = true
	if bi_khoa and m.ke_dang_lao_toi() == null:
		_chu(Vector2(c.x, 206), "⚠  " + tr("ĐANG BỊ KHÓA MỤC TIÊU"), 16, Color(1, 0.55, 0.3), true)
		if _bip_khoa <= 0.0:
			_bip_khoa = 1.2
			AmThanh.phat("khoa_bip")
	# ụ minigun địch đang khóa mình (khi đang bay): còi báo dồn dập, hạ xuống kịp thì thoát
	for n in m.get_tree().get_nodes_in_group("u_minigun"):
		var u := n as UMinigun
		if u and u.phe != m.phe and u.muc == m:
			var nhay3 := 0.5 + 0.5 * absf(sin(_t * 24.0))
			_chu_phim(Vector2(c.x, 182), "⚠ " + tr("Ụ MINIGUN ĐANG KHÓA — HẠ XUỐNG ĐẤT"), 18, Color(1, 0.25, 0.2, nhay3), "roi_nhanh")
			if _bip_minigun <= 0.0:
				_bip_minigun = 0.12
				AmThanh.phat("canh_bao_minigun")
			break

	_ve_giap(m)
	_ve_o_trang_thai(m)
	if _chu_giua_con > 0.0:
		_chu(Vector2(c.x, c.y + R + 110), _chu_giua, 21, _chu_giua_mau, true)      # dưới vòng ngắm, không đè cảnh báo phía trên
	_chu(Vector2(size.x - 200, 30), tr("Đã hạ: %d") % _so_ha, 16, TRANG)

	# hỗ trợ từ chiến hạm (chế độ cứ điểm): danh sách nhỏ góc dưới trái
	if ho_tro:
		var x0 := 22.0
		var y0 := size.y - 112.0
		_chu(Vector2(x0, y0 - 26), tr("Điểm Chỉ Huy: %d") % ho_tro.dch, 14, Color(1.0, 0.85, 0.4))
		for i in HoTro.THU_TU.size():
			var id: String = HoTro.THU_TU[i]
			var cfg: Dictionary = CanBang.HO_TRO[id]
			var ly_do := ho_tro.ly_do_khong_goi(id)
			var gia := ho_tro.gia(id)
			var san := ho_tro.hoi[i] <= 0.0 and ly_do == "" and ho_tro.dch >= gia
			var yy := y0 + i * 21.0
			VeBieuTuong.nut(self, font, "ho_tro_%d" % (i + 1), Vector2(x0 + 8, yy - 5), 0.36, Color.WHITE if san else Color(0.6, 0.6, 0.6))
			var dong := tr(cfg["ten"])
			if gia > 0:
				dong += tr("  (%d ĐCH)") % gia
			if ly_do != "":
				dong += "  — " + ly_do.to_lower()
			elif ho_tro.hoi[i] > 0.0:
				dong += "   %.0f s" % ho_tro.hoi[i]
			if id == "radar" and ho_tro.radar_con > 0.0:
				dong += "  · " + tr("đang quét %.0f s") % ho_tro.radar_con
			_chu(Vector2(x0 + 26, yy), dong, 14, Color(1, 1, 1, 0.85) if san else Color(0.6, 0.6, 0.6, 0.85))
		if ho_tro.thong_bao_con > 0.0:
			_chu(Vector2(c.x, 270), ho_tro.thong_bao, 20, Color(0.6, 0.9, 1.0), true)


## Có lao chém được mục tiêu đang khóa ngay bây giờ không (bấm F là lao): khung khóa cam + chữ F cạnh địch.
static func lao_chem_duoc(m: Mecha) -> bool:
	return m.co_the_lao_chem() and m.hoi_lao_chem <= 0.0 and not m.qua_nhiet and not m.dang_bi_choang()


## Khoảng cách (px) từ điểm p (thế giới) tới tâm màn hình (= tâm vòng ngắm); INF nếu p ở sau camera.
## Khóa mục tiêu và súng máy chặn tên lửa dùng chung: nằm trong vòng ngắm = cach_tam ≤ R.
static func cach_tam(cam3: Camera3D, p: Vector3) -> float:
	if cam3.is_position_behind(p):
		return INF
	return cam3.unproject_position(p).distance_to(cam3.get_viewport().get_visible_rect().size * 0.5)


## Khung nhiệm vụ gọn bên trái (kiểu Wuthering Waves): hình thoi + tên, rồi dòng việc cần làm, dòng phụ mờ hơn.
func _ve_nhiem_vu() -> void:
	if nhiem_vu.is_empty():
		return
	var x := 24.0
	var y := size.y * 0.34
	var q := Vector2(x + 6, y - 6)
	draw_colored_polygon(PackedVector2Array([q + Vector2(0, -7), q + Vector2(6, 0), q + Vector2(0, 7), q + Vector2(-6, 0)]), Color(1, 0.8, 0.45, 0.95))
	_chu(Vector2(x + 20, y), String(nhiem_vu[0]), 18, Color(1, 1, 1, 0.95))
	y += 6.0
	for i in range(1, nhiem_vu.size()):
		var co := 15 if i == 1 else 13
		for dong in _ngat_dong(String(nhiem_vu[i]), co, 330.0):
			y += co + 6.0
			_chu(Vector2(x + 20, y), dong, co, Color(1, 1, 1, 0.82) if i == 1 else Color(1, 1, 1, 0.58))


## Chia chữ thành nhiều dòng không rộng quá `rong` px.
func _ngat_dong(s: String, co: int, rong: float) -> PackedStringArray:
	var kq := PackedStringArray()
	var dong := ""
	for tu in s.split(" ", false):
		var thu := tu if dong == "" else dong + " " + tu
		if dong != "" and font.get_string_size(thu, HORIZONTAL_ALIGNMENT_LEFT, -1, co).x > rong:
			kq.append(dong)
			dong = tu
		else:
			dong = thu
	if dong != "":
		kq.append(dong)
	return kq


## Tên lửa địch lọt vào vòng ngắm (trong 700 m): tam giác rỗng đỏ bao quanh — súng máy đang bắn sẽ nhắm vào nó.
func _ve_ten_lua_trong_vong(m: Mecha, _c: Vector2) -> void:
	for n in m.get_tree().get_nodes_in_group("ten_lua"):
		var tl := n as TenLua
		if tl == null or tl.phe == m.phe or tl.global_position.distance_to(m.global_position) > 700.0:
			continue
		if cach_tam(cam.cam, tl.global_position) > R:
			continue
		var p := cam.cam.unproject_position(tl.global_position)
		var r := 15.0 + 3.0 * absf(sin(_t * 9.0))
		draw_polyline(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.87, r * 0.5), p + Vector2(-r * 0.87, r * 0.5), p + Vector2(0, -r)]),
			Color(1, 0.3, 0.25, 0.95), 2.0, true)


## Dòng chữ giữa màn hình kèm biểu tượng phím nên bấm ở cuối dòng.
func _chu_phim(p: Vector2, s: String, co: int, mau: Color, hanh_dong: String) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, co).x
	var wp := VeBieuTuong.rong_nut(font, hanh_dong, 0.5)
	var x := p.x - (w + 12.0 + wp) * 0.5
	_chu(Vector2(x, p.y), s, co, mau)
	VeBieuTuong.nut(self, font, hanh_dong, Vector2(x + w + 12.0 + wp * 0.5, p.y - co * 0.35), 0.5)


## Có nhìn thấy mecha này không (tia từ camera tới thân không bị nhà / đất che). Kiểm lại mỗi 0,25 giây.
func _nhin_thay(e: Mecha) -> bool:
	var bay: Array = _thay.get(e, [false, 0.0])
	if _t >= float(bay[1]):
		var q := PhysicsRayQueryParameters3D.create(cam.cam.global_position, e.tam_than(), 1)
		bay = [e.get_world_3d().direct_space_state.intersect_ray(q).is_empty(), _t + 0.25]
		_thay[e] = bay
	return bool(bay[0])


## Mũi tên đỏ quanh vòng ngắm chỉ hướng vừa bị bắn (mờ dần trong 1,4 giây).
func _ve_huong_bi_ban(m: Mecha, c: Vector2) -> void:
	var nghich := cam.cam.global_basis.inverse()
	for x in _bi_ban:
		var v: Vector3 = nghich * ((x[0] as Vector3) - m.global_position)
		var h := Vector2(v.x, v.z)
		if h.length() < 0.5:
			continue
		var g := h.angle()
		var a := clampf(float(x[1]) / 0.6, 0.0, 1.0)
		draw_arc(c, R + 52.0, g - 0.3, g + 0.3, 16, Color(1, 0.2, 0.15, 0.85 * a), 9.0, true)
		var u := Vector2.from_angle(g)
		var b := Vector2(-u.y, u.x)
		var dinh := c + u * (R + 74.0)
		draw_colored_polygon(PackedVector2Array([dinh, dinh - u * 14 + b * 10, dinh - u * 14 - b * 10]), Color(1, 0.2, 0.15, 0.9 * a))


## Giáp (giữa dưới, kiểu Wuthering Waves): thanh mảnh có số ở giữa, phần vừa mất tụt dần theo sau, nhấp nháy khi
## dưới 30%. Dòng trạng thái chữ nhỏ ngay trên thanh.
func _ve_giap(m: Mecha) -> void:
	var w := 420.0
	var h := 13.0
	var p0 := Vector2(size.x * 0.5 - w * 0.5, size.y - 38.0)
	var k := clampf(m.mau / maxf(1.0, m.mau_toi_da()), 0.0, 1.0)
	var k_hien := clampf(_mau_hien / maxf(1.0, m.mau_toi_da()), 0.0, 1.0)
	var mau := mau_mau(k)
	if k < 0.3 and fmod(_t, 0.5) < 0.25:
		mau = Color(1, 0.55, 0.45)
	var r := Rect2(p0, Vector2(w, h))
	draw_rect(r.grow(2.0), Color(0.02, 0.03, 0.05, 0.55))
	draw_rect(Rect2(p0, Vector2(w * k_hien, h)), Color(1, 1, 1, 0.45))
	draw_rect(Rect2(p0, Vector2(w * k, h)), Color(mau.r, mau.g, mau.b, 0.85))
	for i in range(1, 10):
		var x := p0.x + w * i / 10.0
		draw_line(Vector2(x, p0.y + 2), Vector2(x, p0.y + h - 2), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(r, Color(1, 1, 1, 0.4), false, 1.0)
	for d in [-1.0, 1.0]:                          # hai đầu nhọn
		var dau := Vector2(size.x * 0.5 + d * (w * 0.5 + 6.0), p0.y + h * 0.5)
		draw_colored_polygon(PackedVector2Array([dau + Vector2(d * 8.0, 0), dau + Vector2(0, -5), dau + Vector2(0, 5)]), Color(1, 1, 1, 0.6))
	_chu(Vector2(size.x * 0.5, p0.y + h - 1.5), "%d / %d" % [int(m.mau), int(m.mau_toi_da())], 12, Color.WHITE, true)
	if m.trang_thai != "":
		_chu(Vector2(size.x * 0.5, p0.y - 9), m.trang_thai, 13, Color(1, 0.88, 0.5, 0.8), true)


const O_R := 25.0                 # bán kính ô kỹ năng tròn (px)
const O_CACH := 14.0
const K_PHIM := 0.38              # cỡ biểu tượng phím dưới ô


## Trạng thái từng ô (góc dưới phải): vũ khí trái, vũ khí phải, tay phụ trái, tay phụ phải, pháo nhiệt, cận chiến.
## tt: "san" (sẵn sàng) / "hoi" (đang hồi) / "khong" (chưa dùng được) / "bat" (đang bật).
## Ô cận chiến có thêm "lao_chem" (bấm là lao chém được) và "hoi_lao" (phần hồi lao chém còn lại, 0..1).
func trang_thai_o(m: Mecha) -> Array:
	var ds: Array = []
	var co_khoa: bool = is_instance_valid(m.khoa) and m.khoa.get("song") != false
	var kc_khoa := m.global_position.distance_to(m.khoa.global_position) if co_khoa else INF
	for tay in ["trai", "phai"]:
		var d: Dictionary = CanBang.VU_KHI[m.vk[tay]]
		var o := {"o": tay, "id": m.vk[tay], "phim": "ban_trai" if tay == "trai" else "ban_phai", "tt": "san", "ti_le": 0.0, "giay": 0.0, "dau": ""}
		var con := m.hoi_ban_con(tay)
		if con > 0.05:
			o["tt"] = "hoi"
			o["ti_le"] = con / float(d["nhip"])
			o["giay"] = con
		elif co_khoa and Mecha.muc_qua_tam(d, kc_khoa) >= 1.0:
			o["tt"] = "khong"
			o["dau"] = "xa"
		ds.append(o)
	for ben in ["trai", "phai"]:
		var tp: String = m.tay_phu[ben]
		var o := {"o": "q" if ben == "trai" else "e", "id": tp, "phim": "tay_phu_" + ben, "tt": "san", "ti_le": 0.0, "giay": 0.0, "dau": ""}
		var P: Dictionary = CanBang.TAY_PHU.get(tp, {})
		if tp == "sung_may_vai" and m.sung_may_vai_con > 0.0:
			o["tt"] = "bat"
			o["ti_le"] = m.sung_may_vai_con / float(P["thoi_gian"])
			o["giay"] = m.sung_may_vai_con
		elif tp == "khien" and m.khien_con > 0.0:
			o["tt"] = "bat"
			o["ti_le"] = m.khien_con / float(P["thoi_gian"])
			o["giay"] = m.khien_con
		elif m.hoi_tay_phu[ben] > 0.0:
			o["tt"] = "hoi"
			o["ti_le"] = m.hoi_tay_phu[ben] / maxf(0.1, m.hoi_tay_phu_toi_da(ben))
			o["giay"] = m.hoi_tay_phu[ben]
		elif tp.begins_with("ten_lua") and (not co_khoa or kc_khoa > float(CanBang.TEN_LUA["tam_khoa"])):
			o["tt"] = "khong"
			o["dau"] = "khoa"
		ds.append(o)
	var PN: Dictionary = CanBang.PHAO_NHIET
	var o_x := {"o": "x", "id": "phao_nhiet", "phim": "phao_nhiet", "tt": "san", "ti_le": 0.0, "giay": 0.0, "dau": "",
		"luot": m.phao_nhiet, "luot_toi_da": int(PN["so_luot"]), "nap": 1.0 - m.hoi_phao / float(PN["hoi"]) if m.hoi_phao > 0.0 else 0.0}
	if m.phao_nhiet <= 0:
		o_x["tt"] = "hoi"
		o_x["ti_le"] = m.hoi_phao / float(PN["hoi"])
		o_x["giay"] = m.hoi_phao
	ds.append(o_x)
	var o_f := {"o": "f", "id": m.can_chien, "phim": "can_chien", "tt": "san", "ti_le": 0.0, "giay": 0.0, "dau": "",
		"lao_chem": lao_chem_duoc(m), "hoi_lao": maxf(0.0, m.hoi_lao_chem) / float(CanBang.CAN_CHIEN["lao_chem"]["hoi"])}
	if m.hoi_chem > 0.05:
		o_f["tt"] = "hoi"
		o_f["ti_le"] = m.hoi_chem / float(CanBang.CAN_CHIEN["chem"]["hoi"])
		o_f["giay"] = m.hoi_chem
	ds.append(o_f)
	return ds


## Ô kỹ năng tròn nhỏ một hàng ở góc dưới phải (kiểu Wuthering Waves), phím ghi ngay dưới mỗi ô.
func _ve_o_trang_thai(m: Mecha) -> void:
	var ds := trang_thai_o(m)
	var buoc := O_R * 2.0 + O_CACH
	var x := size.x - 34.0 - O_R - (ds.size() - 1) * buoc
	var y := size.y - 62.0
	for o in ds:
		_ve_o(o, Vector2(x, y))
		x += buoc


func _ve_o(o: Dictionary, tam: Vector2) -> void:
	var tt: String = o["tt"]
	draw_circle(tam, O_R, Color(0.03, 0.05, 0.08, 0.62))
	var vien := Color(1, 1, 1, 0.7)
	var mo := Color.WHITE
	var day := 1.5
	match tt:
		"hoi":
			vien = Color(1, 1, 1, 0.25)
			mo = Color(0.6, 0.6, 0.65, 0.85)
			day = 1.0
		"khong":
			vien = Color(1, 1, 1, 0.16)
			mo = Color(0.38, 0.38, 0.42, 0.6)
			day = 1.0
		"bat":
			vien = Color(1.0, 0.85, 0.3, 0.55 + 0.45 * absf(sin(_t * 6.0)))
			day = 2.5
	if o.get("lao_chem", false):
		vien = Color(CAM.r, CAM.g, CAM.b, 0.6 + 0.4 * absf(sin(_t * 7.0)))
		day = 2.5
	var k := O_R * 0.74
	VeBieuTuong.mon(self, font, String(o["o"]), String(o["id"]), Rect2(tam - Vector2(k, k), Vector2(k, k) * 2.0), mo, 2.2)
	if tt == "hoi":
		VeBieuTuong.quat_tron(self, tam, O_R, float(o["ti_le"]))
		var g: float = o["giay"]
		_chu(tam + Vector2(0, 5), "%.1f" % g if g < 10.0 else "%d" % int(ceil(g)), 14, Color.WHITE, true)
	elif tt == "bat":
		draw_arc(tam, O_R + 4.0, -PI * 0.5, -PI * 0.5 + TAU * float(o["ti_le"]), 32, Color(1.0, 0.85, 0.3), 2.5, true)
	draw_arc(tam, O_R, 0, TAU, 40, vien, day, true)
	# lao chém đang hồi: cung cam mảnh bên ngoài ô cận chiến
	if float(o.get("hoi_lao", 0.0)) > 0.0:
		draw_arc(tam, O_R + 4.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - float(o["hoi_lao"])), 32, Color(CAM.r, CAM.g, CAM.b, 0.7), 2.0, true)
	if o["o"] == "x":
		# số lượt pháo nhiệt trên đầu ô: chấm sáng = còn, vòng rỗng = đã dùng
		var n: int = o["luot_toi_da"]
		for i in n:
			var q := tam + Vector2((i - (n - 1) * 0.5) * 10.0, -O_R - 7.0)
			if i < int(o["luot"]):
				draw_circle(q, 3.2, Color(1.0, 0.85, 0.5))
			else:
				draw_arc(q, 3.2, 0, TAU, 12, Color(1, 1, 1, 0.5), 1.2)
	VeBieuTuong.nut(self, font, String(o["phim"]), tam + Vector2(0, O_R + 14.0), K_PHIM, Color(1, 1, 1, 0.9))
	match o["dau"]:
		"khoa":
			VeBieuTuong.dau_khoa(self, tam + Vector2(O_R * 0.72, O_R * 0.62), 0.75)
		"lua":
			VeBieuTuong.dau_lua(self, tam + Vector2(O_R * 0.72, O_R * 0.6), 0.75)
		"xa":
			_chu(tam + Vector2(O_R * 0.62, O_R * 0.92), tr("XA"), 11, CAM, true)


func _mau_toi_da(n: Node) -> float:
	if n is Mecha:
		return (n as Mecha).mau_toi_da()
	if n.has_method("mau_toi_da"):
		return float(n.call("mau_toi_da"))
	if n.get("mau_toi_da") != null:
		return float(n.get("mau_toi_da"))
	if n.get("mau_max") != null:
		return float(n.get("mau_max"))
	return maxf(1.0, float(n.get("mau")))


## Màu theo phần máu còn lại: xanh → vàng → đỏ.
static func mau_mau(k: float) -> Color:
	return DO.lerp(Color(1.0, 0.85, 0.3, 0.95), smoothstep(0.15, 0.45, k)).lerp(Color(0.45, 0.95, 0.55, 0.95), smoothstep(0.5, 0.8, k))


## Vòng ngắm + thanh nhiệt (cung dưới vòng), máu của thứ đang khóa (cung trên), độ cao (bên trái vòng).
func _ve_vong_ngam(m: Mecha, c: Vector2) -> void:
	draw_arc(c, R, 0, TAU, 96, Color(1, 1, 1, 0.22), 1.5, true)
	for g in [0.0, PI * 0.5, PI, PI * 1.5]:
		var u := Vector2(cos(g), sin(g))
		draw_line(c + u * (R - 10), c + u * (R + 10), Color(1, 1, 1, 0.6), 2.0)
	# ---- thanh nhiệt: cung dưới vòng ngắm (từ trái sang phải)
	var k := clampf(m.nhiet / m.nhiet_toi_da(), 0.0, 1.0)
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(30.0)
	draw_arc(c, R + 14, a0, a1, 48, Color(1, 1, 1, 0.18), 7.0, true)
	var mau_n := Color(1, 1, 1).lerp(CAM, smoothstep(0.35, 0.7, k)).lerp(DO, smoothstep(0.75, 0.95, k))
	if m.qua_nhiet:
		mau_n = DO if int(Time.get_ticks_msec() / 180) % 2 == 0 else Color(1, 0.6, 0.5, 0.6)
	if k > 0.001:
		draw_arc(c, R + 14, a0, lerpf(a0, a1, k), 48, mau_n, 7.0, true)
	_chu(c + Vector2(0, R + 46), tr("NHIỆT %d%%") % int(k * 100.0), 15, mau_n, true)
	if m.qua_nhiet:
		_chu(c + Vector2(0, R + 68), tr("QUÁ NHIỆT — chờ động cơ nguội"), 20, mau_n, true)
	# ---- máu của thứ đang khóa (cung trên, từ trái sang phải): mecha, ụ súng, bia, công trình
	if is_instance_valid(m.khoa) and m.khoa.get("song") != false and m.khoa.get("mau") != null:
		var mt: Node3D = m.khoa
		var km := clampf(float(mt.get("mau")) / maxf(1.0, _mau_toi_da(mt)), 0.0, 1.0)
		var b0 := deg_to_rad(-150.0)
		var b1 := deg_to_rad(-30.0)
		draw_arc(c, R + 14, b0, b1, 48, Color(1, 1, 1, 0.15), 7.0, true)
		var mau_m := mau_mau(km)
		if km > 0.001:
			draw_arc(c, R + 14, b0, lerpf(b0, b1, km), 48, mau_m, 7.0, true)
		_chu(c + Vector2(0, -R - 26), "%d%%" % int(ceil(km * 100.0)), 13, mau_m, true)
	# ---- độ cao (bên trái vòng)
	if not m.is_on_floor() or m.giu_do_cao:
		_chu(c + Vector2(-R - 160, 6), tr("ĐỘ CAO %d m") % int(m.global_position.y - m._mat_dat_y), 16, TRANG)
	if m.giu_do_cao:
		_chu(c + Vector2(-R - 160, 30), tr("GIỮ ĐỘ CAO"), 17, Color(0.5, 0.9, 1.0))


## Báo động bị lao chém: vòng nhỏ quanh thân kẻ đang lao tới, co dần về thân nó. Vòng chạm vạch VÀNG thì bấm lao
## để NÉ, chạm vạch TRẮNG (sát hơn) thì bấm cận chiến để ĐỠ; bấm chậm là trúng đòn. Chỉ hiện BAO_LAO_CHEM giây cuối.
## Kẻ lao tới ở sau lưng / ngoài màn hình: mũi tên nhấp nháy ở mép vòng ngắm chỉ về phía nó.
const BAO_LAO_CHEM := 1.0
const PX_GIAY := 80.0             # vòng báo động co bao nhiêu px mỗi giây


func _ve_bao_lao_chem(m: Mecha, c: Vector2) -> void:
	var ke := m.ke_dang_lao_toi()
	if ke == null:
		return
	var con := ke.t_toi_va_cham()
	if con > BAO_LAO_CHEM:
		return
	if _bip_chem <= 0.0:
		_bip_chem = 0.45
		AmThanh.phat("canh_bao_chem")
	var cua_ne: float = m.cs["cua_so_ne"]
	var cua_do: float = m.cs["cua_so_do"]
	var pu := ke.phan_ung_doi_thu()
	var mau := DO
	if con <= cua_do:
		mau = Color(1, 1, 1, 0.95)
	elif con <= cua_ne:
		mau = Color(1, 0.85, 0.2, 0.95)
	var p_ke := ke.tam_than()
	var sp: Variant = _len_man_hinh(p_ke)
	if sp == null or not Rect2(Vector2(20, 20), size - Vector2(40, 40)).has_point(sp):
		var v: Vector3 = cam.cam.global_basis.inverse() * (p_ke - m.global_position)
		var u := Vector2(v.x, v.z).normalized() if Vector2(v.x, v.z).length() > 0.5 else Vector2(0, -1)
		var b := Vector2(-u.y, u.x)
		var dinh := c + u * (R + 70.0)
		var a := 0.6 + 0.4 * absf(sin(_t * 18.0))
		draw_colored_polygon(PackedVector2Array([dinh, dinh - u * 18 + b * 12, dinh - u * 18 - b * 12]), Color(mau.r, mau.g, mau.b, a))
		return
	var p: Vector2 = sp
	var r0 := clampf(1800.0 / maxf(cam.cam.global_position.distance_to(p_ke), 1.0), 16.0, 55.0)
	var r_ne := r0 + cua_ne * PX_GIAY
	draw_arc(p, r_ne, 0, TAU, 48, Color(1, 0.85, 0.2, 0.55), 2.0, true)
	draw_arc(p, r0 + cua_do * PX_GIAY, 0, TAU, 48, Color(1, 1, 1, 0.6), 2.0, true)
	draw_arc(p, r0 + con * PX_GIAY, 0, TAU, 48, mau, 3.5, true)
	if pu == "sai":
		_chu(p + Vector2(0, r_ne + 22), tr("SAI LÚC!"), 15, DO, true)
	elif pu == "ne":
		_chu(p + Vector2(0, r_ne + 22), tr("NÉ!"), 15, mau, true)
	elif pu == "do":
		_chu(p + Vector2(0, r_ne + 22), tr("ĐỠ!"), 15, mau, true)
	else:
		# phím nhỏ hai bên vòng: lao = né (vạch vàng), cận chiến = đỡ (vạch trắng)
		VeBieuTuong.nut(self, font, "lao", p + Vector2(-r_ne - 24, 0), 0.36, Color(1, 0.9, 0.5))
		VeBieuTuong.nut(self, font, "can_chien", p + Vector2(r_ne + 18, 0), 0.36)


## Thước la bàn trên cùng: hướng camera đang nhìn, dấu mục tiêu khóa (đỏ), hòm tiếp tế (xanh), cứ điểm.
func _ve_la_ban(m: Mecha) -> void:
	var rong := 560.0
	var x0 := size.x * 0.5 - rong * 0.5
	var y0 := 64.0
	var px_do := rong / 120.0                    # thước hiện 120°
	var huong := fposmod(rad_to_deg(-cam.yaw), 360.0)
	draw_rect(Rect2(x0, y0, rong, 26), Color(0, 0, 0, 0.3))
	var nhan := {0: tr("Bắc").left(1), 90: tr("Đông").left(1), 180: tr("Nam").left(1), 270: tr("Tây").left(1)}
	for k in range(-60, 61):
		var goc := int(round(huong)) + k
		if goc % 15 != 0:
			continue
		var x := x0 + rong * 0.5 + (goc - huong) * px_do
		var g := posmod(goc, 360)
		if nhan.has(g):
			_chu(Vector2(x, y0 + 20), nhan[g], 16, Color(1, 0.9, 0.5), true)
		else:
			draw_line(Vector2(x, y0 + 4), Vector2(x, y0 + (14 if g % 45 == 0 else 9)), Color(1, 1, 1, 0.6), 1.5)
	draw_line(Vector2(x0 + rong * 0.5, y0 - 4), Vector2(x0 + rong * 0.5, y0 + 30), Color(1, 1, 1, 0.9), 2.0)
	_chu(Vector2(x0 + rong * 0.5, y0 + 46), "%03d°" % int(huong), 14, Color(1, 1, 1, 0.8), true)
	var dau: Array = []
	if is_instance_valid(m.khoa):
		dau.append([m.khoa.global_position, Color(1, 0.3, 0.25)])
	for n in m.get_tree().get_nodes_in_group("thung_tiep_te"):
		dau.append([(n as Node3D).global_position, Color(0.4, 1.0, 0.55)])
	for x in danh_dau:
		if is_instance_valid(x[0]) and x[0].get("song") != false:
			dau.append([(x[0] as Node3D).global_position, Color(1, 0.75, 0.3)])
	if ban_do and ban_do.get("cu_diem") != null:
		for cd in ban_do.cu_diem as Array:
			var x_cd: CuDiem = cd
			var v_cd := x_cd.global_position - m.global_position
			var lech_cd := wrapf(rad_to_deg(atan2(v_cd.x, -v_cd.z)) - huong, -180.0, 180.0)
			if absf(lech_cd) <= 60.0:
				var mau_cd: Color = CuDiem.MAU_TRUNG_LAP if x_cd.chu < 0 else CuDiem.MAU_PHE[x_cd.chu]
				_chu(Vector2(x0 + rong * 0.5 + lech_cd * px_do, y0 - 4), x_cd.ten, 15, mau_cd, true)
	for d in dau:
		var v: Vector3 = (d[0] as Vector3) - m.global_position
		var bearing := rad_to_deg(atan2(v.x, -v.z))
		var lech := wrapf(bearing - huong, -180.0, 180.0)
		var x := x0 + rong * 0.5 + clampf(lech, -60.0, 60.0) * px_do
		var mau: Color = d[1]
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y0 + 28), Vector2(x + 6, y0 + 28), Vector2(x, y0 + 18)]), mau)


## Tên lửa đang bay tới: mũi tên ở mép vòng ngắm chỉ về phía từng quả + dòng cảnh báo.
## Bị súng bắn tỉa ngắm: cảnh báo laser.
func _ve_canh_bao_ten_lua(m: Mecha, c: Vector2) -> void:
	var dem := 0
	var gan := INF
	for n in m.get_tree().get_nodes_in_group("ten_lua"):
		var tl := n as TenLua
		if tl == null or tl.phe == m.phe or tl.muc_tieu != m:
			continue
		dem += 1
		var d := tl.global_position.distance_to(m.global_position)
		gan = minf(gan, d)
		var sp := cam.cam.unproject_position(tl.global_position)
		var huong := sp - c
		if cam.cam.is_position_behind(tl.global_position):
			huong = -huong
		if huong.length() < 1.0:
			huong = Vector2(0, -1)
		huong = huong.normalized()
		var dinh := c + huong * (R + 34)
		var ben := Vector2(-huong.y, huong.x)
		draw_colored_polygon(PackedVector2Array([dinh + huong * 16, dinh + ben * 10, dinh - ben * 10]), DO)
	if dem > 0:
		if _bip_ten_lua <= 0.0:
			# nhịp còi theo quả gần nhất: ≥ 500 m bíp mỗi 0,7 s, sát 30 m gần như kêu liền (0,08 s)
			_bip_ten_lua = lerpf(0.08, 0.7, clampf((gan - 30.0) / 470.0, 0.0, 1.0))
			AmThanh.phat("canh_bao")
		var nhay := int(Time.get_ticks_msec() / 150) % 2 == 0
		_chu_phim(Vector2(c.x, 230), "⚠ " + tr("TÊN LỬA x%d — %d m") % [dem, int(gan)], 20, DO if nhay else CAM, "phao_nhiet")
	for n in m.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e and e.song and e.phe != m.phe and e.laser_tay != "" and e.khoa == m:
			var nhay2 := 0.5 + 0.5 * absf(sin(_t * (8.0 if e.laser_con > 0.4 else 22.0)))
			_chu_phim(Vector2(c.x, 254), "⚠ " + tr("BỊ BẮN TỈA NGẮM — %.1f s") % e.laser_con, 19, Color(1, 0.25, 0.2, nhay2), "lao")


## Chiến dịch: dấu cam trên các mục tiêu nhiệm vụ (trong màn hình: hình thoi + khoảng cách; ngoài: mũi tên ở mép).
func _ve_danh_dau(m: Mecha, c: Vector2) -> void:
	for x in danh_dau:
		if not is_instance_valid(x[0]) or x[0].get("song") == false:
			continue
		var n: Node3D = x[0]
		var p: Vector3 = Mecha.diem_cua(n) + Vector3.UP * 6.0
		var d := m.global_position.distance_to(n.global_position)
		var s := cam.cam.unproject_position(p)
		var sau := cam.cam.is_position_behind(p)
		var trong := not sau and Rect2(Vector2(30, 30), (size - Vector2(60, 60)).max(Vector2.ZERO)).has_point(s)
		var mau := Color(1, 0.7, 0.25, 0.9)
		if trong:
			var r := 8.0
			draw_colored_polygon(PackedVector2Array([s + Vector2(0, -r), s + Vector2(r, 0), s + Vector2(0, r), s + Vector2(-r, 0)]), mau)
			_chu(s + Vector2(0, -14), "%s %d m" % [x[1], int(d)], 13, mau, true)
		else:
			var h := (s - c) * (-1.0 if sau else 1.0)
			if h.length() < 1.0:
				h = Vector2(0, -1)
			h = h.normalized()
			var k := minf((size.x * 0.5 - 40) / maxf(absf(h.x), 0.001), (size.y * 0.5 - 40) / maxf(absf(h.y), 0.001))
			var q := c + h * k
			var b := Vector2(-h.y, h.x)
			draw_colored_polygon(PackedVector2Array([q + h * 14, q + b * 8, q - b * 8]), mau)


## Cứ điểm (chế độ cứ điểm): dải A–E dưới la bàn, máu tàu sân bay hai phe, nhãn từng cứ điểm,
## thanh tiến độ khi đang đứng trong vòng chiếm. Bảng thông báo bên phải dùng cho mọi chế độ.
func _ve_cu_diem(m: Mecha, c: Vector2) -> void:
	var yt := 362.0                     # dưới bản đồ nhỏ
	for x in _tin:
		var a := clampf(float(x[1]) / 1.0, 0.0, 1.0)
		var s: String = x[0]
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		_chu(Vector2(size.x - 24 - w, yt), s, 15, Color(1, 1, 1, 0.9 * a))
		yt += 22.0
	if ban_do == null or ban_do.get("che_do") != "cu_diem":
		return
	# máu tàu sân bay hai phe (trái: phe ta, phải: phe địch) + ô nhỏ cho từng tàu hỗ trợ
	var rong := 300.0
	var tr_troi: TranTrenTroi = ban_do.get("tran_troi")
	for phe in 2:
		var ti: float = tr_troi.ti_le_san_bay(phe) if tr_troi else float(ban_do.mau_tau[phe]) / CanBang.MAU_TAU_SAN_BAY
		var mau: Color = CuDiem.MAU_PHE[phe]
		var x0 := c.x - 300.0 - rong - 20.0 if phe == 0 else c.x + 300.0 + 20.0
		var nhan := tr("TÀU SÂN BAY TA") if phe == m.phe else tr("TÀU SÂN BAY ĐỊCH")
		_chu(Vector2(x0, 72), "%s  %d%%" % [nhan, int(ceil(ti * 100.0))] + ("   " + tr("ĐÃ BỊ HẠ") if ti <= 0.0 else ""), 14, mau)
		_thanh(Vector2(x0, 78), Vector2(rong, 12), ti, mau)
	# dải A–E
	var ds: Array = ban_do.cu_diem
	var o := 64.0
	var xd := c.x - ds.size() * o * 0.5
	for i in ds.size():
		var cd: CuDiem = ds[i]
		var r := Rect2(Vector2(xd + i * o + 6, 122), Vector2(o - 12, 34))
		var mau: Color = CuDiem.MAU_TRUNG_LAP if cd.chu < 0 else CuDiem.MAU_PHE[cd.chu]
		var tranh: bool = cd.co_mat[0] > 0 and cd.co_mat[1] > 0
		var nen := Color(mau.r, mau.g, mau.b, 0.35)
		if tranh and fmod(_t, 0.6) < 0.3:
			nen = Color(1, 1, 1, 0.35)
		draw_rect(r, nen)
		draw_rect(r, mau, false, 2.0)
		_chu(r.position + Vector2(r.size.x * 0.5, 25), cd.ten, 20, Color.WHITE, true)
		var tb := r.position + Vector2(0, 38)
		draw_rect(Rect2(tb, Vector2(r.size.x, 5)), Color(0, 0, 0, 0.5))
		var phe_thanh := 0 if cd.thanh >= 0.0 else 1
		draw_rect(Rect2(tb, Vector2(r.size.x * absf(cd.thanh), 5)), CuDiem.MAU_PHE[phe_thanh])
		var viet := {"phao_dai": tr("PĐ"), "ten_lua": tr("TL"), "hau_can": tr("HC")}
		var ky: String = viet.get(cd.loai, "…" if cd.chu >= 0 else "")
		if cd.dang_xay:
			ky += "▲"
		_chu(r.position + Vector2(r.size.x * 0.5, 58), ky, 13, mau, true)
	# nhãn trên màn hình
	for cd in ds:
		var x: CuDiem = cd
		var sp: Variant = _len_man_hinh(x.global_position + Vector3.UP * 40.0)
		if sp == null:
			continue
		var p: Vector2 = sp
		var mau: Color = CuDiem.MAU_TRUNG_LAP if x.chu < 0 else CuDiem.MAU_PHE[x.chu]
		var kc := int(x.global_position.distance_to(m.global_position))
		draw_circle(p, 15.0, Color(0, 0, 0, 0.5))
		draw_arc(p, 15.0, 0, TAU, 24, mau, 2.5)
		_chu(p + Vector2(0, 7), x.ten, 18, mau, true)
		var chu := "%d m · %s" % [kc, x.ten_loai()]
		if x.chu >= 0:
			chu += " · " + (tr("phe ta") if x.chu == m.phe else tr("phe địch"))
		_chu(p + Vector2(0, 34), chu, 13, Color(1, 1, 1, 0.85), true)
	# đang đứng trong vòng chiếm
	for cd in ds:
		var x: CuDiem = cd
		if not x.trong_vong(m.global_position) or not m.song:
			continue
		var dich := 1 - m.phe
		var trang_thai := ""
		var mau_tt := Color(1, 1, 1)
		if x.co_mat[dich] > 0 and x.co_mat[m.phe] > 0:
			trang_thai = tr("ĐANG TRANH CHẤP — đuổi địch ra khỏi vòng")
			mau_tt = Color(1, 0.85, 0.3)
		elif x.chu == m.phe and absf(x.thanh) >= 0.999:
			trang_thai = tr("ĐANG GIỮ — %s") % x.ten_loai()
			mau_tt = CuDiem.MAU_PHE[m.phe]
		elif x.chu == dich:
			trang_thai = tr("ĐANG PHÁ CỨ ĐIỂM ĐỊCH (về 0 là phá sạch công trình)")
			mau_tt = Color(1, 0.6, 0.4)
		else:
			trang_thai = tr("ĐANG CHIẾM")
			mau_tt = CuDiem.MAU_PHE[m.phe]
		var ti := absf(x.thanh)
		var huong_phe := (x.thanh >= 0.0) == (m.phe == 0)
		var phan_tram := int(ti * 100.0) if huong_phe else -int(ti * 100.0)
		_chu(Vector2(c.x, size.y - 176), tr("CỨ ĐIỂM %s — %s   %d%%") % [x.ten, trang_thai, phan_tram], 20, mau_tt, true)
		var bx := Rect2(Vector2(c.x - 200, size.y - 168), Vector2(400, 10))
		draw_rect(bx, Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bx.position, Vector2(bx.size.x * ti, bx.size.y)), CuDiem.MAU_PHE[0 if x.thanh >= 0.0 else 1])


func _input(e: InputEvent) -> void:
	if not is_instance_valid(nguoi_choi) or nguoi_choi.song or ban_do == null or ban_do.get("hoi_sinh_con") == null or ban_do.hoi_sinh_con <= 0.0:
		return
	if not ban_do.has_method("diem_hoi_sinh"):
		return
	var ds: Array = ban_do.diem_hoi_sinh(nguoi_choi.phe)
	if e is InputEventKey and (e as InputEventKey).pressed:
		var k := (e as InputEventKey).physical_keycode
		if k >= KEY_1 and k < KEY_1 + ds.size():
			ban_do.hoi_sinh_chon = ds[k - KEY_1][0]
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		for o in _o_hoi_sinh:
			if (o[0] as Rect2).has_point((e as InputEventMouseButton).position):
				ban_do.hoi_sinh_chon = o[1]


## Màn hình chọn điểm hồi sinh (khi mecha người chơi bị hạ): bản đồ nhỏ + danh sách điểm, đếm ngược.
func _ve_hoi_sinh(m: Mecha, c: Vector2) -> void:
	_o_hoi_sinh.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	_chu(Vector2(c.x, c.y - 250), tr("MECHA BỊ HẠ — CHỌN ĐIỂM HỒI SINH"), 32, Color(1, 0.5, 0.4), true)
	_chu(Vector2(c.x, c.y - 214), tr("Mecha sẽ rơi từ tàu sân bay xuống sau %.1f giây. Bấm phím số hoặc bấm chuột để chọn.") % ban_do.hoi_sinh_con, 17, Color(1, 1, 1, 0.85), true)
	if not ban_do.has_method("diem_hoi_sinh"):
		return
	var ds: Array = ban_do.diem_hoi_sinh(m.phe)
	var chon: String = ban_do.hoi_sinh_chon
	var hop_le := false
	for d in ds:
		if d[0] == chon:
			hop_le = true
	if not hop_le:
		chon = ds[0][0]
	# bản đồ nhỏ: bắc ở trên
	var co := 340.0
	var goc := Vector2(c.x - co - 30.0, c.y - 180.0)
	var ti := co / float(ban_do.kich_thuoc())
	draw_rect(Rect2(goc, Vector2(co, co)), Color(0.12, 0.13, 0.12, 0.92))
	draw_rect(Rect2(goc, Vector2(co, co)), Color(1, 1, 1, 0.4), false, 1.5)
	var len_ban_do := func(p: Vector3) -> Vector2: return goc + Vector2(co * 0.5 + p.x * ti, co * 0.5 + p.z * ti)
	if ban_do.get("che_do") == "cu_diem":
		for phe in 2:
			var q: Vector2 = len_ban_do.call(ban_do.can_cu(phe))
			draw_rect(Rect2(q - Vector2(9, 9), Vector2(18, 18)), CuDiem.MAU_PHE[phe])
		for cd in ban_do.cu_diem:
			var x: CuDiem = cd
			var q: Vector2 = len_ban_do.call(x.global_position)
			var mau: Color = CuDiem.MAU_TRUNG_LAP if x.chu < 0 else CuDiem.MAU_PHE[x.chu]
			draw_circle(q, 11.0, Color(mau.r, mau.g, mau.b, 0.5))
			draw_arc(q, 11.0, 0, TAU, 24, mau, 2.0)
			_chu(q + Vector2(0, 6), x.ten, 15, Color.WHITE, true)
	var cho_chet: Vector2 = len_ban_do.call(m.global_position)
	draw_line(cho_chet - Vector2(6, 6), cho_chet + Vector2(6, 6), Color(1, 0.3, 0.2), 2.5)
	draw_line(cho_chet - Vector2(6, -6), cho_chet + Vector2(6, -6), Color(1, 0.3, 0.2), 2.5)
	# danh sách điểm
	var x0 := c.x + 10.0
	for i in ds.size():
		var d: Array = ds[i]
		var o := Rect2(Vector2(x0, c.y - 180.0 + i * 54.0), Vector2(330, 46))
		var dang_chon: bool = d[0] == chon
		draw_rect(o, Color(0.15, 0.3, 0.45, 0.95) if dang_chon else Color(0.08, 0.12, 0.18, 0.9))
		draw_rect(o, Color(0.5, 0.85, 1.0) if dang_chon else Color(1, 1, 1, 0.35), false, 2.0)
		var kc := int((d[1] as Vector3).distance_to(m.global_position))
		_chu(o.position + Vector2(16, 30), "%d   %s" % [i + 1, tr(d[0]) if not String(d[0]).begins_with("Cứ điểm ") else tr("Cứ điểm %s") % String(d[0]).substr(8)], 20, Color(1, 0.9, 0.5) if dang_chon else Color.WHITE)
		_chu(o.position + Vector2(230, 30), "%d m" % kc, 15, Color(1, 1, 1, 0.7))
		_o_hoi_sinh.append([o, d[0]])
		var q: Vector2 = len_ban_do.call(d[1])
		_o_hoi_sinh.append([Rect2(q - Vector2(14, 14), Vector2(28, 28)), d[0]])
		if dang_chon:
			draw_arc(q, 18.0, 0, TAU, 24, Color(1, 0.9, 0.4), 3.0)
	if ds.size() == 1 and ban_do.get("che_do") == "cu_diem":
		_chu(Vector2(x0, c.y - 180.0 + 80.0), tr("Phe ta chưa giữ cứ điểm nào (hoặc đang bị tranh chấp):"), 15, Color(1, 1, 1, 0.75))
		_chu(Vector2(x0, c.y - 180.0 + 102.0), tr("chỉ hồi sinh được ở căn cứ."), 15, Color(1, 1, 1, 0.75))
