class_name ManNangCap
extends ManCon
## Màn nâng cấp: 3 thẻ Tàu sân bay / Mecha / Cứ điểm. Mỗi mục có cấp 1–5 (mua bằng điểm công trạng),
## mỗi cấp cho 2 điểm kỹ năng, chia vào 3 hướng (mỗi hướng 4 nút). Chia lại thoải mái.

const NHOM := [["san_bay", "TÀU SÂN BAY"], ["mecha", "MECHA"], ["cu_diem", "CỨ ĐIỂM"]]

var nhom := "san_bay"
var muc := "san_bay"
var _hang_the: HBoxContainer
var _cot_muc: VBoxContainer
var _chi_tiet: VBoxContainer


func _ready() -> void:
	_dung_khung(tr("NÂNG CẤP"), tr("Lên cấp để có thêm điểm kỹ năng, rồi chia điểm vào các hướng. Bấm \"Chia lại\" để lấy lại điểm bất cứ lúc nào."))
	_hang_the = GiaoDien.hang(10)
	noi_dung.add_child(_hang_the)
	var trai := GiaoDien.khung()
	trai.position = Vector2(0, 60)
	trai.custom_minimum_size = Vector2(380, 560)
	noi_dung.add_child(trai)
	_cot_muc = GiaoDien.cot(8)
	trai.add_child(_cot_muc)
	var phai := GiaoDien.khung()
	phai.position = Vector2(410, 60)
	phai.custom_minimum_size = Vector2(1100, 560)
	noi_dung.add_child(phai)
	_chi_tiet = GiaoDien.cot(14)
	phai.add_child(_chi_tiet)


func lam_moi() -> void:
	GiaoDien.xoa_con(_hang_the)
	for d in NHOM:
		var b := GiaoDien.nut(tr(d[1]), 20, 200)
		b.name = "the_" + d[0]
		GiaoDien.danh_dau(b, nhom == d[0])
		var ten: String = d[0]
		b.pressed.connect(func() -> void:
			nhom = ten
			for k in CanBang.CAY_KY_NANG:
				if CanBang.CAY_KY_NANG[k]["nhom"] == nhom:
					muc = k
					break
			lam_moi())
		_hang_the.add_child(b)
	GiaoDien.xoa_con(_cot_muc)
	for k in CanBang.CAY_KY_NANG:
		var cfg: Dictionary = CanBang.CAY_KY_NANG[k]
		if cfg["nhom"] != nhom:
			continue
		var b := GiaoDien.nut(tr("%s   ·   cấp %d   ·   còn %d điểm") % [tr(cfg["ten"]), TienTrinh.cap[k], TienTrinh.diem_con(k)], 17, 350)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.name = "muc_" + k
		GiaoDien.danh_dau(b, muc == k)
		var ten_muc: String = k
		b.pressed.connect(func() -> void:
			muc = ten_muc
			lam_moi())
		_cot_muc.add_child(b)
	_ve_chi_tiet()
	menu.cap_nhat_cong_trang()


func _ve_chi_tiet() -> void:
	GiaoDien.xoa_con(_chi_tiet)
	var cfg: Dictionary = CanBang.CAY_KY_NANG[muc]
	var c: int = TienTrinh.cap[muc]
	_chi_tiet.add_child(GiaoDien.nhan(tr("%s — cấp %d / %d") % [tr(cfg["ten"]), c, CanBang.CAP_TOI_DA], 26, Color(0.85, 0.93, 1.0)))
	var h := GiaoDien.hang(14)
	_chi_tiet.add_child(h)
	h.add_child(GiaoDien.nhan(tr("Điểm kỹ năng: dùng %d / %d") % [TienTrinh.diem_da_dung(muc), TienTrinh.diem_ky_nang(muc)], 19, GiaoDien.MAU_VANG))
	var nut_len := GiaoDien.nut("", 17)
	nut_len.name = "nut_len_cap"
	if c >= CanBang.CAP_TOI_DA:
		nut_len.text = tr("Đã đạt cấp tối đa")
		nut_len.disabled = true
	else:
		nut_len.text = tr("Lên cấp %d (+%d điểm kỹ năng) — %d công trạng") % [c + 1, CanBang.DIEM_MOI_CAP, TienTrinh.gia_len_cap(muc)]
		nut_len.disabled = TienTrinh.cong_trang < TienTrinh.gia_len_cap(muc)
	nut_len.pressed.connect(func() -> void:
		if TienTrinh.len_cap(muc):
			AmThanh.ui("mua")
		lam_moi())
	h.add_child(nut_len)
	var chia := GiaoDien.nut(tr("Chia lại"), 17)
	chia.name = "nut_chia_lai"
	chia.pressed.connect(func() -> void:
		TienTrinh.chia_lai(muc)
		lam_moi())
	h.add_child(chia)
	var ba := GiaoDien.hang(18)
	_chi_tiet.add_child(ba)
	for i in 3:
		var huong: Array = cfg["huong"][i]
		var k := GiaoDien.khung()
		k.custom_minimum_size = Vector2(340, 330)
		ba.add_child(k)
		var v := GiaoDien.cot(10)
		k.add_child(v)
		v.add_child(GiaoDien.nhan(tr("HƯỚNG %d") % (i + 1), 14, GiaoDien.MAU_MO))
		v.add_child(GiaoDien.nhan(tr(huong[0]), 22, GiaoDien.MAU_NHAN))
		var mt := GiaoDien.nhan(tr("Mỗi nút: ") + tr(huong[1]), 15)
		mt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mt.custom_minimum_size = Vector2(310, 60)
		v.add_child(mt)
		var n := TienTrinh.so_nut(muc, i)
		var cham := GiaoDien.hang(8)
		v.add_child(cham)
		for j in CanBang.NUT_MOI_HUONG:
			var o := Panel.new()
			o.custom_minimum_size = Vector2(56, 56)
			var s := StyleBoxFlat.new()
			s.set_corner_radius_all(28)
			s.bg_color = Color(0.35, 0.75, 1.0) if j < n else Color(0.1, 0.14, 0.2)
			s.border_color = Color(0.5, 0.8, 1.0)
			s.set_border_width_all(2)
			o.add_theme_stylebox_override("panel", s)
			cham.add_child(o)
		v.add_child(GiaoDien.nhan(tr("Đã mở %d / %d nút") % [n, CanBang.NUT_MOI_HUONG], 16))
		var them := GiaoDien.nut(tr("+ Mở nút tiếp theo"), 17)
		them.name = "nut_them_%d" % i
		them.disabled = TienTrinh.diem_con(muc) <= 0 or n >= CanBang.NUT_MOI_HUONG
		var hi := i
		them.pressed.connect(func() -> void:
			if TienTrinh.them_nut(muc, hi):
				AmThanh.ui("mua")
			lam_moi())
		v.add_child(them)
	var ghi := GiaoDien.nhan(tr("Tổng 12 nút nhưng tối đa 10 điểm: không thể có tất cả cùng lúc, phải chọn hướng. Phe địch có nâng cấp theo độ khó."), 15, GiaoDien.MAU_MO)
	_chi_tiet.add_child(ghi)
