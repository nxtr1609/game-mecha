class_name ManCaiDat
extends ManCon
## Cài đặt: âm lượng, độ nhạy chuột, toàn màn hình, bóng đổ, hiện hướng dẫn phím. Dùng cả trong menu tạm dừng.

signal dong

var trong_tran := false            # true: mở từ menu tạm dừng (không có nút Quay lại về menu chính)
var _cot: VBoxContainer


func _ready() -> void:
	if trong_tran:
		GiaoDien.lop_esc(self, func() -> void:
			TienTrinh.luu_cai_dat()
			dong.emit())
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var nen := ColorRect.new()
		nen.color = Color(0.02, 0.03, 0.05, 0.85)
		nen.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(nen)
		noi_dung = Control.new()
		noi_dung.position = Vector2(480, 120)
		add_child(noi_dung)
	else:
		_dung_khung(tr("CÀI ĐẶT"))
	var k := GiaoDien.khung()
	k.custom_minimum_size = Vector2(640, 0)
	noi_dung.add_child(k)
	_cot = GiaoDien.cot(14)
	k.add_child(_cot)
	if trong_tran:
		_cot.add_child(GiaoDien.nhan(tr("CÀI ĐẶT"), 28, Color(0.85, 0.93, 1.0)))
	if not trong_tran:
		_hang_ngon_ngu()                 # đổi ngôn ngữ ở menu chính (menu dựng lại cho đủ chữ mới)
	_thanh_truot(tr("Âm lượng tổng"), "am_luong_tong", 0.0, 1.0)
	_thanh_truot(tr("Nhạc"), "am_luong_nhac", 0.0, 1.0)
	_thanh_truot(tr("Hiệu ứng âm thanh"), "am_luong_hieu_ung", 0.0, 1.0)
	_thanh_truot(tr("Độ nhạy chuột"), "do_nhay_chuot", 0.3, 2.5)
	_o_chon(tr("Toàn màn hình"), "toan_man_hinh")
	_o_chon(tr("Bóng đổ (tắt để chạy nhẹ hơn)"), "bong")
	_hang_do_hoa()
	var dk := GiaoDien.nut(tr("ĐIỀU KHIỂN — ĐỔI PHÍM"), 18)
	dk.name = "nut_dieu_khien"
	dk.pressed.connect(mo_phim)
	_cot.add_child(dk)
	if trong_tran:
		var b := GiaoDien.nut("Xong", 20)
		b.pressed.connect(func() -> void:
			TienTrinh.luu_cai_dat()
			dong.emit())
		_cot.add_child(b)


func _thanh_truot(ten: String, khoa: String, tu: float, den: float) -> void:
	var h := GiaoDien.hang(14)
	var l := GiaoDien.nhan(ten, 18)
	l.custom_minimum_size.x = 230
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = tu
	s.max_value = den
	s.step = 0.05
	s.value = TienTrinh.cai_dat[khoa]
	s.custom_minimum_size = Vector2(280, 28)
	s.focus_mode = Control.FOCUS_NONE
	var so := GiaoDien.nhan("%d%%" % int(s.value * 100), 16)
	s.value_changed.connect(func(v: float) -> void:
		TienTrinh.cai_dat[khoa] = v
		so.text = "%d%%" % int(v * 100)
		TienTrinh.ap_dung_cai_dat())
	s.drag_ended.connect(func(_c: bool) -> void:
		TienTrinh.luu_cai_dat()
		AmThanh.ui("bam"))
	h.add_child(s)
	h.add_child(so)
	_cot.add_child(h)


func _o_chon(ten: String, khoa: String) -> void:
	var o := CheckButton.new()
	o.text = ten
	o.button_pressed = TienTrinh.cai_dat[khoa]
	o.focus_mode = Control.FOCUS_NONE
	o.add_theme_font_size_override("font_size", 18)
	o.toggled.connect(func(v: bool) -> void:
		TienTrinh.cai_dat[khoa] = v
		TienTrinh.luu_cai_dat()
		AmThanh.ui("bam"))
	_cot.add_child(o)


## Hàng chọn chất lượng đồ họa: Thấp (nhẹ nhất) / Vừa / Cao (ánh sáng gián tiếp, phản chiếu). Đổi là áp ngay.
func _hang_do_hoa() -> void:
	var h := GiaoDien.hang(10)
	h.name = "hang_do_hoa"
	var l := GiaoDien.nhan(tr("Chất lượng đồ họa"), 18)
	l.custom_minimum_size.x = 230
	h.add_child(l)
	for m in DoHoa.MUC:
		var b := GiaoDien.nut(tr(DoHoa.TEN_MUC[m]), 17, 90)
		b.name = "do_hoa_" + m
		GiaoDien.danh_dau(b, TienTrinh.cai_dat["do_hoa"] == m)
		var mm: String = m
		b.pressed.connect(func() -> void:
			TienTrinh.cai_dat["do_hoa"] = mm
			TienTrinh.luu_cai_dat()
			AmThanh.ui("bam")
			for x in h.get_children():
				if x is Button:
					GiaoDien.danh_dau(x, x.name == "do_hoa_" + mm))
		h.add_child(b)
	_cot.add_child(h)


## Hàng chọn ngôn ngữ (English / 日本語 / Tiếng Việt).
func _hang_ngon_ngu() -> void:
	var h := GiaoDien.hang(10)
	var l := GiaoDien.nhan(tr("Ngôn ngữ"), 18)
	l.custom_minimum_size.x = 230
	h.add_child(l)
	for d in NgonNgu.DS:
		var b := GiaoDien.nut(d[1], 17)
		b.name = "nn_" + d[0]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		GiaoDien.danh_dau(b, NgonNgu.ngon_ngu == d[0])
		var ma: String = d[0]
		b.pressed.connect(func() -> void: GiaoDien.doi_ngon_ngu(ma))
		h.add_child(b)
	_cot.add_child(h)


## Mở màn đổi phím (đè lên màn cài đặt).
func mo_phim() -> ManPhim:
	var mp := ManPhim.new()
	mp.name = "man_phim"
	add_child(mp)
	mp.dong.connect(mp.queue_free)
	return mp
