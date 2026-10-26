class_name ManChinh
extends Control
## Màn chính: tên game và các nút lớn bên trái. Góc trên bên phải (MenuChinh) có điểm công trạng và nút ngôn ngữ.

var menu: MenuChinh


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nen := ColorRect.new()
	nen.color = Color(0.02, 0.03, 0.05, 0.55)
	nen.position = Vector2.ZERO
	nen.size = Vector2(560, 2000)
	nen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nen)
	var c := GiaoDien.cot(10)
	c.position = Vector2(70, 70)
	c.custom_minimum_size = Vector2(420, 0)
	add_child(c)
	c.add_child(GiaoDien.nhan("GAME MECHA", 60, Color(0.85, 0.93, 1.0)))
	c.add_child(GiaoDien.nhan(tr("Liên Hiệp – Đế Chế · Mecha · Chiến dịch · Cứ điểm"), 17, GiaoDien.MAU_NHAN))
	var cach := Control.new()
	cach.custom_minimum_size.y = 18
	c.add_child(cach)
	var ds := []
	if TienTrinh.da_choi():
		ds.append([tr("TIẾP TỤC"), "tiep_tuc"])
	ds.append_array([[tr("HUẤN LUYỆN"), "huan_luyen"], [tr("CHIẾN DỊCH"), "chien_dich"], [tr("CHIẾM CỨ ĐIỂM"), "chuan_bi"], [tr("MECHA & VŨ KHÍ"), "mecha"],
		[tr("NÂNG CẤP"), "nang_cap"], [tr("LƯU / TẢI"), "luu_tai"], [tr("CÀI ĐẶT"), "cai_dat"], [tr("GHI CÔNG"), "ghi_cong"]])
	for d in ds:
		var b := GiaoDien.nut(d[0], 24, 380)
		b.custom_minimum_size.y = 50
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ten: String = d[1]
		b.pressed.connect(func() -> void: _bam(ten))
		b.name = "nut_" + ten
		c.add_child(b)
	var h := GiaoDien.hang(10)
	c.add_child(h)
	var moi := GiaoDien.nut(tr("CHƠI MỚI"), 19, 185)
	moi.name = "nut_choi_moi"
	moi.custom_minimum_size.y = 44
	moi.pressed.connect(_hoi_choi_moi)
	h.add_child(moi)
	var thoat := GiaoDien.nut(tr("THOÁT"), 19, 185)
	thoat.name = "nut_thoat"
	thoat.custom_minimum_size.y = 44
	thoat.pressed.connect(func() -> void:
		TienTrinh.luu()
		get_tree().quit())
	h.add_child(thoat)
	var ghi := GiaoDien.nhan(tr("Godot 4.7 · mẫu 3D của người làm game · tài nguyên miễn phí: xem mục Ghi công"), 14, GiaoDien.MAU_MO)
	ghi.position = Vector2(70, 860)
	add_child(ghi)


func _bam(ten: String) -> void:
	match ten:
		"tiep_tuc":
			if TienTrinh.dang_nhiem_vu >= 0:
				menu.bat_dau_chien_dich(TienTrinh.dang_nhiem_vu)
			else:
				menu.mo("chien_dich")
		"luu_tai":
			var lt := ManLuuTai.new()
			lt.name = "man_luu_tai"
			menu.giao_dien.add_child(lt)
			lt.dong.connect(func() -> void:
				lt.queue_free()
				menu.dung_lai())
			lt.da_tai.connect(func(nv: int) -> void:
				if nv >= 0:
					menu.bat_dau_chien_dich(nv))
		"mecha":
			(menu.man["mecha"] as ManCon).quay_lai_toi = "chinh"
			menu.mo(ten)
		"huan_luyen":
			menu.bat_dau_chien_dich(0)
		_:
			menu.mo(ten)


func _hoi_choi_moi() -> void:
	var phu := ColorRect.new()
	phu.color = Color(0, 0, 0, 0.6)
	phu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(phu)
	GiaoDien.lop_esc(phu, phu.queue_free)
	var k := GiaoDien.khung()
	k.position = Vector2(560, 340)
	k.custom_minimum_size = Vector2(500, 0)
	phu.add_child(k)
	var c := GiaoDien.cot(16)
	k.add_child(c)
	var l := GiaoDien.nhan(tr("Chơi mới từ đầu? Tiến trình đang chơi (điểm, nâng cấp, chiến dịch) sẽ bị xóa. Các ô lưu riêng vẫn giữ nguyên."), 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 460
	c.add_child(l)
	var h := GiaoDien.hang(12)
	h.alignment = BoxContainer.ALIGNMENT_END
	c.add_child(h)
	var khong := GiaoDien.nut(tr("Hủy"), 18)
	khong.pressed.connect(phu.queue_free)
	h.add_child(khong)
	var co := GiaoDien.nut(tr("Đồng ý"), 18)
	co.name = "nut_dong_y"
	co.pressed.connect(func() -> void:
		TienTrinh._mac_dinh()
		TienTrinh.luu()
		menu.dung_lai())
	h.add_child(co)


## Esc ở màn chính: hỏi có thoát game không.
func hoi_thoat() -> void:
	var phu := ColorRect.new()
	phu.name = "hoi_thoat"
	phu.color = Color(0, 0, 0, 0.6)
	phu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(phu)
	GiaoDien.lop_esc(phu, phu.queue_free)
	var k := GiaoDien.khung()
	k.position = Vector2(600, 360)
	k.custom_minimum_size = Vector2(400, 0)
	phu.add_child(k)
	var c := GiaoDien.cot(16)
	k.add_child(c)
	c.add_child(GiaoDien.nhan(tr("Thoát game?"), 22))
	var h := GiaoDien.hang(12)
	h.alignment = BoxContainer.ALIGNMENT_END
	c.add_child(h)
	var khong := GiaoDien.nut(tr("Hủy"), 18)
	khong.pressed.connect(phu.queue_free)
	h.add_child(khong)
	var co := GiaoDien.nut(tr("THOÁT"), 18)
	co.name = "nut_thoat_han"
	co.pressed.connect(func() -> void:
		TienTrinh.luu()
		get_tree().quit())
	h.add_child(co)
