class_name BangTrangBi
extends Control
## Bảng trang bị (phím B trong trận; cũng nằm trong màn "Mecha & vũ khí" ở menu).
## Giữa bảng là hình mecha nhìn từ sau lưng (đúng như khi chơi), chữ L bên trái, R bên phải.
## 5 ô nối tới đúng bộ phận, mỗi ô có biểu tượng nút bấm đang gán (đổi phím thì biểu tượng đổi theo):
##   tay phụ trái (Q) · tay phụ phải (E) · vũ khí trái (chuột phải) · vũ khí phải (chuột trái) · cận chiến (F).
## Bấm một ô → hàng dưới hiện các món của ô đó; bấm món là lắp. Trong trận game tạm dừng khi mở.
## Chế độ cứ điểm chỉ mở được ở căn cứ / trạm hậu cần (BanDoThu.mo_trang_bi kiểm tra).

signal dong
signal da_doi

var ban_do: Node = null            # trong trận: cảnh trận (có nguoi_choi); null = ở menu
var trong_menu := false            # ở màn Mecha & vũ khí: không có nền tối, không tạm dừng, mở khóa được món
var o_chon := "phai"
var font: Font
var _o_rect := {}                  # ô -> Rect2
var _mon_rect: Array = []          # [Rect2, id]
var _di_chuot := ""                # món đang rê chuột
var _bao := ""                     # dòng báo (vd. chưa mở khóa)
var _bao_con := 0.0
var t_dong := 0                    # lúc đóng (ms) — tránh phím B vừa đóng lại mở ngay

const O := ["trai", "phai", "q", "e", "f"]
## Điểm nối trên hình mecha (tỉ lệ 0..1 của ảnh 360×400) theo thân: ổ tên lửa trái / phải, tay trái / phải, cẳng tay trái.
const DIEM_NOI := {
	"to": {"q": Vector2(0.36, 0.11), "e": Vector2(0.65, 0.11), "trai": Vector2(0.31, 0.53), "phai": Vector2(0.70, 0.53), "f": Vector2(0.29, 0.46)},
	"thon": {"q": Vector2(0.37, 0.07), "e": Vector2(0.64, 0.07), "trai": Vector2(0.30, 0.53), "phai": Vector2(0.71, 0.53), "f": Vector2(0.29, 0.45)},
}
const MAU_VIEN := Color(0.35, 0.7, 1.0)
const MAU_CHON := Color(0.45, 0.95, 1.3)
const MAU_MO := Color(1, 1, 1, 0.45)
const MAU_CAM := Color(1.0, 0.7, 0.3)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = GiaoDien.font()
	if not trong_menu:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func mo() -> void:
	visible = true
	_bao = ""
	if not trong_menu:
		get_tree().paused = true
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.ui("mo")
	queue_redraw()


func dong_bang() -> void:
	visible = false
	t_dong = Time.get_ticks_msec()
	if not trong_menu:
		get_tree().paused = false
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AmThanh.ui("dong")
	dong.emit()


func _process(dt: float) -> void:
	if not trong_menu:
		position = Vector2.ZERO
		size = get_viewport_rect().size
	if visible:
		_bao_con = maxf(0.0, _bao_con - dt)
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not visible or trong_menu:
		return
	if e.is_action_pressed("trang_bi"):
		get_viewport().set_input_as_handled()
		dong_bang()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_di_chuot = ""
		for x in _mon_rect:
			if (x[0] as Rect2).has_point((e as InputEventMouseMotion).position):
				_di_chuot = x[1]
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		bam((e as InputEventMouseButton).position)
		accept_event()


# ---------------------------------------------------------------- dữ liệu

func _mecha() -> Mecha:
	return ban_do.get("nguoi_choi") as Mecha if ban_do else null


func _loai() -> String:
	var m := _mecha()
	return m.loai if m else String(TienTrinh.trang_bi.get("loai", "co_ban"))


## Món đang lắp ở một ô.
func dang_lap(o: String) -> String:
	var m := _mecha()
	var tb: Dictionary = TienTrinh.trang_bi
	match o:
		"trai", "phai":
			return m.vk[o] if m else String(tb[o])
		"q":
			return m.tay_phu["trai"] if m else String(tb["tay_phu_trai"])
		"e":
			return m.tay_phu["phai"] if m else String(tb["tay_phu_phai"])
		_:
			return m.can_chien if m else String(tb["can_chien"])


func danh_sach(o: String) -> Array:
	if o in ["trai", "phai"]:
		return CanBang.DS_VU_KHI
	if o in ["q", "e"]:
		return CanBang.DS_TAY_PHU
	return CanBang.KIEU_CAN_CHIEN.keys()


static func ten_mon(o: String, id: String) -> String:
	if o in ["trai", "phai"]:
		return TranslationServer.translate(CanBang.VU_KHI[id]["ten"])
	if o in ["q", "e"]:
		return TranslationServer.translate(CanBang.TAY_PHU[id]["ten"])
	return TranslationServer.translate(CanBang.KIEU_CAN_CHIEN[id]["ten"])


static func mo_ta_mon(o: String, id: String) -> String:
	if o in ["trai", "phai"]:
		var d: Dictionary = CanBang.VU_KHI[id]
		var s := String(TranslationServer.translate("%d sát thương · %.1f phát/giây · tầm %d m")) % [int(d["sat_thuong"]), 1.0 / float(d["nhip"]), int(d["tam"])]
		if d.get("chan_ten_lua", false):
			s += " · " + TranslationServer.translate("chặn được tên lửa")
		if d.has("no_lan") or d.has("no"):
			s += " · " + String(TranslationServer.translate("nổ lan %d m")) % int(d.get("no_lan", d.get("no", 0.0)))
		if d.get("kieu", "") == "dan_cham":
			s += " · " + TranslationServer.translate("đạn bay chậm")
		if float(d.get("nhiet_them", 0.0)) > 0.0:
			s += " · " + String(TranslationServer.translate("làm nóng địch +%d")) % int(d["nhiet_them"])
		return s
	if o in ["q", "e"]:
		return TranslationServer.translate(CanBang.TAY_PHU[id]["mo_ta"])
	return TranslationServer.translate(CanBang.KIEU_CAN_CHIEN[id]["mo_ta"])


## Bấm chuột trong bảng.
func bam(p: Vector2) -> void:
	for k in _o_rect:
		if (_o_rect[k] as Rect2).has_point(p):
			o_chon = k
			AmThanh.ui("bam")
			queue_redraw()
			return
	for x in _mon_rect:
		if (x[0] as Rect2).has_point(p):
			chon_mon(o_chon, x[1])
			return


## Lắp món id vào ô o (chưa mở khóa: ở menu thì mở bằng điểm công trạng nếu đủ, trong trận thì báo).
func chon_mon(o: String, id: String) -> bool:
	if not TienTrinh.da_mo(id):
		if trong_menu and TienTrinh.mo_khoa_vk(id):
			AmThanh.ui("mo_khoa")
		else:
			_bao = tr("Chưa mở khóa — cần %d điểm công trạng (mở ở menu Mecha & vũ khí)") % int(CanBang.GIA_MO_KHOA[id]) if not trong_menu \
				else tr("Không đủ điểm công trạng (cần %d)") % int(CanBang.GIA_MO_KHOA[id])
			_bao_con = 3.0
			AmThanh.ui("loi")
			return false
	var m := _mecha()
	var tb: Dictionary = TienTrinh.trang_bi
	match o:
		"trai", "phai":
			tb[o] = id
			if m:
				m.doi_vu_khi(o, id)
		"q", "e":
			tb["tay_phu_trai" if o == "q" else "tay_phu_phai"] = id
			if m:
				m.doi_tay_phu("trai" if o == "q" else "phai", id)
		_:
			tb["can_chien"] = id
			if m:
				m.doi_can_chien(id)
	TienTrinh.luu()
	AmThanh.ui("bam")
	da_doi.emit()
	queue_redraw()
	return true


# ---------------------------------------------------------------- vẽ

func _chu(p: Vector2, s: String, co: int, mau: Color, can := HORIZONTAL_ALIGNMENT_LEFT, rong := -1.0) -> void:
	draw_string(font, p, s, can, rong, co, mau)


## Biểu tượng một món (ảnh render từ mẫu thật; khiên và cận chiến vẽ bằng code) — dùng chung VeBieuTuong.
func ve_bieu_tuong(o: String, id: String, r: Rect2) -> void:
	VeBieuTuong.mon(self, font, o, id, r)


## Biểu tượng nút bấm: hình chuột (sáng nút đang dùng) hoặc phím chữ.
func ve_nut(hanh_dong: String, tam: Vector2) -> void:
	VeBieuTuong.nut(self, font, hanh_dong, tam)


const HANH_DONG_O := {"trai": "ban_trai", "phai": "ban_phai", "q": "tay_phu_trai", "e": "tay_phu_phai", "f": "can_chien"}
const TEN_O := {"trai": "VŨ KHÍ TRÁI", "phai": "VŨ KHÍ PHẢI", "q": "TAY PHỤ TRÁI", "e": "TAY PHỤ PHẢI", "f": "CẬN CHIẾN"}


func _draw() -> void:
	if not visible:
		return
	var y0 := 0.0
	if trong_menu:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.08, 0.9))
		y0 = 8.0
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.05, 0.86))
		_chu(Vector2(60, 56), tr("TRANG BỊ"), 32, Color(0.85, 0.93, 1.0))
		_chu(Vector2(60, 86), tr("Game tạm dừng · bấm một ô rồi chọn món ở hàng dưới · %s / Esc: đóng") % Phim.ten("trang_bi"), 17, MAU_MO)
		y0 = 110.0
	var cx := size.x * 0.5
	_o_rect.clear()
	_mon_rect.clear()
	# ---- hình mecha nhìn từ sau lưng + L / R
	var than: String = CanBang.LOAI_MECHA[_loai()]["than"]
	var anh_r := Rect2(Vector2(cx - 162, y0 + 4), Vector2(324, 360))
	draw_rect(anh_r, Color(0.06, 0.09, 0.13, 0.9))
	draw_rect(anh_r, Color(0.25, 0.45, 0.65), false, 1.5)
	VeBieuTuong._vua(self, VeBieuTuong.anh("mecha_" + than), anh_r.grow(-6), Color.WHITE)
	_chu(anh_r.position + Vector2(10, 52), "L", 46, Color(0.6, 0.9, 1.0, 0.9))
	_chu(anh_r.position + Vector2(anh_r.size.x - 44, 52), "R", 46, Color(0.6, 0.9, 1.0, 0.9))
	_chu(anh_r.position + Vector2(0, anh_r.size.y - 10), tr("nhìn từ sau lưng"), 13, MAU_MO, HORIZONTAL_ALIGNMENT_CENTER, anh_r.size.x)
	var vi_tri := {
		"q": Rect2(cx - 480, y0 + 14, 290, 106), "e": Rect2(cx + 190, y0 + 14, 290, 106),
		"trai": Rect2(cx - 510, y0 + 140, 290, 106), "phai": Rect2(cx + 220, y0 + 140, 290, 106),
		"f": Rect2(cx - 480, y0 + 266, 290, 106),
	}
	var noi: Dictionary = DIEM_NOI[than]
	for o in O:
		var r: Rect2 = vi_tri[o]
		_o_rect[o] = r
		var ben_trai: bool = o in ["trai", "q", "f"]
		var chon: bool = o == o_chon
		draw_rect(r, Color(0.08, 0.12, 0.17, 0.96))
		draw_rect(r, MAU_CHON if chon else Color(1, 1, 1, 0.25), false, 3.0 if chon else 1.5)
		# đường nối tới bộ phận
		var diem: Vector2 = anh_r.position + (noi[o] as Vector2) * anh_r.size
		var mep := Vector2(r.end.x if ben_trai else r.position.x, r.get_center().y)
		draw_line(mep, diem, Color(MAU_CHON.r, MAU_CHON.g, MAU_CHON.b, 0.8) if chon else Color(1, 1, 1, 0.35), 2.0)
		draw_circle(diem, 5.0, MAU_CHON if chon else Color(1, 1, 1, 0.6))
		# biểu tượng nút bấm ở phía ngoài ô
		var x_nut := r.position.x + 32 if ben_trai else r.end.x - 32
		ve_nut(HANH_DONG_O[o], Vector2(x_nut, r.get_center().y + 6))
		var id := dang_lap(o)
		var x_noi_dung := r.position.x + 64 if ben_trai else r.position.x + 12
		_chu(Vector2(x_noi_dung, r.position.y + 22), tr(TEN_O[o]), 15, MAU_CHON if chon else MAU_MO)
		ve_bieu_tuong(o, id, Rect2(Vector2(x_noi_dung, r.position.y + 28), Vector2(150, 52)))
		_chu(Vector2(x_noi_dung, r.position.y + 98), ten_mon(o, id), 16, Color(0.95, 0.97, 1.0))
	# ---- thông tin loại mecha (ô phải dưới, không bấm)
	var ri := Rect2(cx + 190, y0 + 266, 290, 106)
	var lm: Dictionary = CanBang.LOAI_MECHA[_loai()]
	draw_rect(ri, Color(0.06, 0.09, 0.13, 0.85))
	draw_rect(ri, Color(1, 1, 1, 0.15), false, 1.0)
	_chu(ri.position + Vector2(12, 24), tr("MECHA %s") % tr(lm["ten"]).to_upper(), 16, Color(0.6, 0.9, 1.0))
	var kn: String = lm["kha_nang"]
	var dong_kn := tr("Khả năng: %s") % tr(CanBang.KHA_NANG[kn]["ten"]) if kn != "" else tr("Cân bằng mọi mặt.")
	_chu(ri.position + Vector2(12, 50), dong_kn, 14, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, ri.size.x - 20)
	_chu(ri.position + Vector2(12, 74), tr("Luôn có: %s pháo nhiệt · %s rơi nhanh") % [Phim.ten("phao_nhiet"), Phim.ten("roi_nhanh")], 13, MAU_MO, HORIZONTAL_ALIGNMENT_LEFT, ri.size.x - 20)
	_chu(ri.position + Vector2(12, 96), tr("%s + %s: lao chém") % [Phim.ten("lao"), Phim.ten("can_chien")], 13, MAU_MO, HORIZONTAL_ALIGNMENT_LEFT, ri.size.x - 20)
	# ---- hàng món của ô đang chọn
	var ds := danh_sach(o_chon)
	var dang := dang_lap(o_chon)
	var w_the := 150.0
	var tong := ds.size() * (w_the + 10.0) - 10.0
	var x0 := cx - tong * 0.5
	var y_the := y0 + 414.0
	_chu(Vector2(x0, y_the - 10), tr("Chọn cho ô %s:") % tr(TEN_O[o_chon]), 16, Color(0.6, 0.9, 1.0))
	for i in ds.size():
		var id: String = ds[i]
		var r := Rect2(Vector2(x0 + i * (w_the + 10.0), y_the), Vector2(w_the, 112))
		_mon_rect.append([r, id])
		var mo_khoa := TienTrinh.da_mo(id)
		var la_dang := id == dang
		draw_rect(r, Color(0.08, 0.12, 0.16, 0.96) if mo_khoa else Color(0.06, 0.07, 0.09, 0.96))
		var vien := MAU_CAM if la_dang else (MAU_CHON if id == _di_chuot else Color(1, 1, 1, 0.2))
		draw_rect(r, vien, false, 2.5 if (la_dang or id == _di_chuot) else 1.0)
		ve_bieu_tuong(o_chon, id, Rect2(r.position + Vector2(8, 8), Vector2(w_the - 16, 56)))
		_chu(r.position + Vector2(6, 86), ten_mon(o_chon, id), 13, Color.WHITE if mo_khoa else MAU_MO, HORIZONTAL_ALIGNMENT_CENTER, w_the - 12)
		if la_dang:
			_chu(r.position + Vector2(6, 104), tr("đang lắp"), 12, MAU_CAM, HORIZONTAL_ALIGNMENT_CENTER, w_the - 12)
		elif not mo_khoa:
			_chu(r.position + Vector2(6, 104), "🔒 %d" % int(CanBang.GIA_MO_KHOA[id]), 12, Color(1, 0.85, 0.4), HORIZONTAL_ALIGNMENT_CENTER, w_the - 12)
	# mô tả món đang rê chuột (không thì món đang lắp)
	var xem := _di_chuot if _di_chuot != "" else dang
	if ds.has(xem):
		_chu(Vector2(x0, y_the + 140), ten_mon(o_chon, xem), 18, Color.WHITE)
		_chu(Vector2(x0, y_the + 164), mo_ta_mon(o_chon, xem), 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, maxf(tong, 700.0))
		if not TienTrinh.da_mo(xem):
			var gia := int(CanBang.GIA_MO_KHOA[xem])
			var chu_gia := tr("Bấm để mở khóa: %d điểm công trạng (đang có %d)") % [gia, TienTrinh.cong_trang] if trong_menu \
				else tr("Chưa mở khóa — %d điểm công trạng, mở ở menu Mecha & vũ khí") % gia
			_chu(Vector2(x0, y_the + 188), chu_gia, 15, Color(1, 0.85, 0.4))
	if _bao_con > 0.0:
		_chu(Vector2(0, y_the + 216), _bao, 17, Color(1, 0.5, 0.4), HORIZONTAL_ALIGNMENT_CENTER, size.x)
