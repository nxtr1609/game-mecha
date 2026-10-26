class_name ManMecha
extends ManCon
## Màn chọn loại mecha và trang bị. Bên trái: loại mecha (4 loại), chỉ số, loại mecha của đồng đội bot.
## Bên phải: bảng trang bị dùng chung với phím B trong trận (hình mecha L / R, 5 ô có biểu tượng nút bấm),
## ở đây mở khóa được món mới bằng điểm công trạng.

var _cot_loai: VBoxContainer
var _nhan_chi_so: Label
var _cot_dong_doi: GridContainer
var _bang: BangTrangBi


func _ready() -> void:
	_dung_khung(tr("MECHA & VŨ KHÍ"), tr("Trang bị chọn trước trận. Trong trận bấm B để đổi (chế độ cứ điểm: chỉ ở căn cứ hoặc trạm hậu cần phe ta)."), true)
	var trai := GiaoDien.khung()
	trai.custom_minimum_size = Vector2(390, 0)
	noi_dung.add_child(trai)
	var c := GiaoDien.cot(8)
	trai.add_child(c)
	c.add_child(GiaoDien.nhan(tr("LOẠI MECHA"), 20, GiaoDien.MAU_NHAN))
	_cot_loai = GiaoDien.cot(6)
	c.add_child(_cot_loai)
	_nhan_chi_so = GiaoDien.nhan("", 13)
	_nhan_chi_so.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nhan_chi_so.custom_minimum_size.x = 360
	c.add_child(_nhan_chi_so)
	c.add_child(GiaoDien.nhan(tr("ĐỒNG ĐỘI BOT (chế độ cứ điểm)"), 16, GiaoDien.MAU_NHAN))
	_cot_dong_doi = GridContainer.new()
	_cot_dong_doi.columns = 2
	_cot_dong_doi.add_theme_constant_override("h_separation", 10)
	_cot_dong_doi.add_theme_constant_override("v_separation", 4)
	c.add_child(_cot_dong_doi)
	_bang = BangTrangBi.new()
	_bang.trong_menu = true
	_bang.position = Vector2(410, 0)
	_bang.size = Vector2(1110, 770)
	_bang.name = "bang_trang_bi"
	_bang.da_doi.connect(func() -> void:
		menu.cap_nhat_trung_bay()
		menu.cap_nhat_cong_trang())
	noi_dung.add_child(_bang)


func lam_moi() -> void:
	TienTrinh.sua_trang_bi()
	var tb: Dictionary = TienTrinh.trang_bi
	GiaoDien.xoa_con(_cot_loai)
	for loai in ["co_ban", "co_dong", "hang_nang", "ho_tro"]:
		var lm: Dictionary = CanBang.LOAI_MECHA[loai]
		var th: Array = lm["thang"]
		var b := GiaoDien.nut("%s\n   %s %s  %s %s\n   %s %s  %s %s" % [tr(lm["ten"]),
			tr("Tốc độ"), GiaoDien.thang_diem(th[0]), tr("Giáp"), GiaoDien.thang_diem(th[1]),
			tr("Hỏa lực"), GiaoDien.thang_diem(th[2]), tr("Chiếm"), GiaoDien.thang_diem(th[3])], 15, 370)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.name = "nut_loai_" + loai
		GiaoDien.danh_dau(b, tb["loai"] == loai)
		b.pressed.connect(func() -> void:
			TienTrinh.trang_bi["loai"] = loai
			TienTrinh.luu()
			lam_moi())
		_cot_loai.add_child(b)
	var nut: Array = [TienTrinh.so_nut(tb["loai"], 0), TienTrinh.so_nut(tb["loai"], 1), TienTrinh.so_nut(tb["loai"], 2)]
	var cs := CanBang.chi_so_mecha(tb["loai"], nut)
	var lm2: Dictionary = CanBang.LOAI_MECHA[tb["loai"]]
	var kn: String = lm2["kha_nang"]
	var chu_kn: String = (tr("Khả năng: %s — %s") % [tr(CanBang.KHA_NANG[kn]["ten"]), tr(CanBang.KHA_NANG[kn]["mo_ta"])]) if kn != "" else ""
	_nhan_chi_so.text = tr("%s\n%s\n\nGiáp %d · Lướt %d m/s · Bật lao %d m/s\nNhiệt tối đa %d · Hỏa lực ×%.2f · Chiếm cứ điểm ×%.1f\nCửa sổ né %.2f s · đỡ %.2f s\n(đã tính nâng cấp: cấp %d)") % [
		tr(lm2["mo_ta"]), chu_kn, int(cs["mau"]), int(float(cs["toc_luot"]) * float(cs["he_so_toc"])), int(float(cs["toc_lao"]) * float(cs["he_so_toc"])),
		int(cs["nhiet_toi_da"]), float(cs["he_so_hoa_luc"]), float(cs["he_so_chiem"]), float(cs["cua_so_ne"]), float(cs["cua_so_do"]),
		int(TienTrinh.cap.get(tb["loai"], 1))]
	# ---- đồng đội
	GiaoDien.xoa_con(_cot_dong_doi)
	var ten_loai := ["ngau_nhien", "co_ban", "co_dong", "hang_nang", "ho_tro"]
	for i in 5:
		var hd := GiaoDien.cot(2)
		hd.add_child(GiaoDien.nhan(tr("Đồng đội %d") % (i + 1) + ("" if i < 2 else " (6v6)"), 13))
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.add_theme_font_size_override("font_size", 14)
		ob.custom_minimum_size.x = 170
		for k in ten_loai:
			ob.add_item(tr("Ngẫu nhiên") if k == "ngau_nhien" else tr(CanBang.LOAI_MECHA[k]["ten"]))
		ob.selected = maxi(0, ten_loai.find(TienTrinh.dong_doi[i]))
		var chi_so := i
		ob.item_selected.connect(func(j: int) -> void:
			TienTrinh.dong_doi[chi_so] = ten_loai[j]
			TienTrinh.luu())
		hd.add_child(ob)
		_cot_dong_doi.add_child(hd)
	_bang.visible = true
	_bang.queue_redraw()
	menu.cap_nhat_trung_bay()
	menu.cap_nhat_cong_trang()
