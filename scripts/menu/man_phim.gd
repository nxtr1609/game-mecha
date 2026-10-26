class_name ManPhim
extends Control
## Đổi phím (Cài đặt → Điều khiển). Bấm vào một dòng → "Bấm phím mới…" → bấm phím hoặc nút chuột. Esc: hủy.
## Phím đã thuộc hành động khác thì hai bên hoán đổi (có báo). Lưu ngay vào user://cai_dat.cfg (Phim.luu).
## Dùng cả ở menu chính (màn con) và trong trận (mở từ menu tạm dừng).

signal dong

var _luoi: GridContainer
var _bao: Label
var _dang_doi := ""                # hành động đang chờ phím mới
var _nut := {}                     # hành động -> Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = GiaoDien.theme()
	var nen := ColorRect.new()
	nen.color = Color(0.02, 0.03, 0.05, 0.92)
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(nen)
	var k := GiaoDien.khung()
	k.position = Vector2(170, 60)
	k.custom_minimum_size = Vector2(1260, 0)
	add_child(k)
	var c := GiaoDien.cot(12)
	k.add_child(c)
	var h := GiaoDien.hang(18)
	c.add_child(h)
	var lui := GiaoDien.nut(tr("← QUAY LẠI"), 18)
	lui.name = "nut_quay_lai"
	lui.pressed.connect(func() -> void:
		_dang_doi = ""
		dong.emit())
	h.add_child(lui)
	GiaoDien.lop_esc(self, lui.pressed.emit)
	h.add_child(GiaoDien.nhan(tr("ĐIỀU KHIỂN"), 30, Color(0.85, 0.93, 1.0)))
	c.add_child(GiaoDien.nhan(tr("Bấm vào một phím để đổi, rồi bấm phím hoặc nút chuột mới. Esc: hủy. Phím đang dùng cho việc khác thì hai bên đổi chỗ cho nhau."), 15, GiaoDien.MAU_MO))
	_luoi = GridContainer.new()
	_luoi.columns = 4
	_luoi.add_theme_constant_override("h_separation", 16)
	_luoi.add_theme_constant_override("v_separation", 6)
	c.add_child(_luoi)
	for d in Phim.DANH_SACH:
		var a: String = d[0]
		var l := GiaoDien.nhan(d[1], 17)
		l.custom_minimum_size.x = 300
		_luoi.add_child(l)
		var b := GiaoDien.nut("", 17, 260)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED      # tên phím ("B", "T"...) không dịch
		b.name = "phim_" + a
		b.pressed.connect(func() -> void: _bat_dau_doi(a))
		_luoi.add_child(b)
		_nut[a] = b
	_bao = GiaoDien.nhan("", 17, GiaoDien.MAU_VANG)
	c.add_child(_bao)
	var h2 := GiaoDien.hang(14)
	c.add_child(h2)
	var md := GiaoDien.nut(tr("Khôi phục mặc định"), 17)
	md.name = "nut_mac_dinh"
	md.pressed.connect(func() -> void:
		Phim.mac_dinh_tat_ca()
		_bao.text = tr("Đã khôi phục toàn bộ phím mặc định.")
		lam_moi())
	h2.add_child(md)
	h2.add_child(GiaoDien.nhan(tr("Esc luôn là phím tạm dừng (không đổi được)."), 15, GiaoDien.MAU_MO))
	lam_moi()


func lam_moi() -> void:
	for a in _nut:
		var b: Button = _nut[a]
		b.text = tr("Bấm phím mới…") if a == _dang_doi else Phim.ten(a)
		GiaoDien.danh_dau(b, a == _dang_doi)


func _bat_dau_doi(a: String) -> void:
	_dang_doi = a
	_bao.text = ""
	lam_moi()


## Đổi phím (cũng dùng cho tự kiểm tra). Trả về hành động bị hoán đổi ("" nếu không có).
func doi_phim(a: String, g: Array) -> String:
	var cu := Phim.ten(a)
	var bi_doi := Phim.doi(a, g)
	_dang_doi = ""
	if bi_doi != "":
		var ten_kia := ""
		for d in Phim.DANH_SACH:
			if d[0] == bi_doi:
				ten_kia = tr(d[1])
		_bao.text = tr("%s đang dùng cho «%s» — đã đổi chỗ: «%s» giờ là %s.") % [Phim.ten(a), ten_kia, ten_kia, cu]
	else:
		_bao.text = ""
	AmThanh.ui("bam")
	lam_moi()
	return bi_doi


func _input(e: InputEvent) -> void:
	if not visible or _dang_doi == "":
		return
	if e is InputEventKey and (e as InputEventKey).pressed and (e as InputEventKey).physical_keycode == KEY_ESCAPE:
		_dang_doi = ""
		lam_moi()
		get_viewport().set_input_as_handled()
		return
	var g: Variant = Phim.tu_su_kien(e)
	if g == null:
		return
	get_viewport().set_input_as_handled()
	doi_phim(_dang_doi, g)
