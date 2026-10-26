class_name ManChienDich
extends ManCon
## Màn Chiến dịch: danh sách 5 nhiệm vụ (mở lần lượt), lời giới thiệu, phần thưởng, trang bị đang lắp,
## độ khó (số mecha địch tấn công cùng lúc, dùng chung với chế độ cứ điểm), nút Trang bị (sang màn Mecha & vũ khí) và Bắt đầu.

var _cot_ds: VBoxContainer
var _tieu_de: Label
var _mo_ta: Label
var _thong_tin: Label
var _nut_bat_dau: Button
var _hang_kho: HBoxContainer


func _ready() -> void:
	_dung_khung(tr("CHIẾN DỊCH"), tr("Đi một mình trên bản đồ rộng, đánh mecha Đế Chế. Hoàn thành nhiệm vụ để mở nhiệm vụ kế và nhận điểm công trạng."), true)
	var trai := GiaoDien.khung()
	trai.custom_minimum_size = Vector2(440, 0)
	noi_dung.add_child(trai)
	_cot_ds = GiaoDien.cot(10)
	trai.add_child(_cot_ds)
	var phai := GiaoDien.khung()
	phai.position = Vector2(480, 0)
	phai.custom_minimum_size = Vector2(760, 0)
	noi_dung.add_child(phai)
	var c := GiaoDien.cot(14)
	phai.add_child(c)
	_tieu_de = GiaoDien.nhan("", 30, Color(0.85, 0.93, 1.0))
	c.add_child(_tieu_de)
	_mo_ta = GiaoDien.nhan("", 18)
	_mo_ta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mo_ta.custom_minimum_size.x = 720
	c.add_child(_mo_ta)
	_thong_tin = GiaoDien.nhan("", 16, Color(1, 1, 1, 0.85))
	_thong_tin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thong_tin.custom_minimum_size.x = 720
	c.add_child(_thong_tin)
	c.add_child(GiaoDien.nhan(tr("ĐỘ KHÓ"), 18, GiaoDien.MAU_NHAN))
	_hang_kho = GiaoDien.hang(10)
	c.add_child(_hang_kho)
	var h := GiaoDien.hang(14)
	c.add_child(h)
	var tb := GiaoDien.nut(tr("TRANG BỊ"), 20, 220)
	tb.name = "nut_trang_bi"
	tb.pressed.connect(func() -> void:
		(menu.man["mecha"] as ManCon).quay_lai_toi = "chien_dich"
		menu.mo("mecha"))
	h.add_child(tb)
	_nut_bat_dau = GiaoDien.nut(tr("BẮT ĐẦU"), 24, 260)
	_nut_bat_dau.name = "nut_bat_dau"
	_nut_bat_dau.pressed.connect(func() -> void: menu.bat_dau_chien_dich(TienTrinh.nhiem_vu))
	h.add_child(_nut_bat_dau)


func lam_moi() -> void:
	GiaoDien.xoa_con(_cot_ds)
	_cot_ds.add_child(GiaoDien.nhan(tr("NHIỆM VỤ"), 20, GiaoDien.MAU_NHAN))
	if not TienTrinh.nhiem_vu_mo(TienTrinh.nhiem_vu):
		TienTrinh.nhiem_vu = 0
	for i in CanBang.CHIEN_DICH.size():
		var nv: Dictionary = CanBang.CHIEN_DICH[i]
		var trang_thai := ""
		if TienTrinh.nhiem_vu_xong(i):
			trang_thai = "  ✓"
		elif not TienTrinh.nhiem_vu_mo(i):
			trang_thai = "  🔒"
		var b := GiaoDien.nut("%d. %s%s" % [i + 1, tr(nv["ten"]), trang_thai], 20, 400)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 52
		b.name = "nv_%d" % i
		b.disabled = not TienTrinh.nhiem_vu_mo(i)
		GiaoDien.danh_dau(b, TienTrinh.nhiem_vu == i)
		var ii := i
		b.pressed.connect(func() -> void:
			TienTrinh.nhiem_vu = ii
			TienTrinh.luu()
			lam_moi())
		_cot_ds.add_child(b)
	var so_xong := 0
	for i in CanBang.CHIEN_DICH.size():
		if TienTrinh.nhiem_vu_xong(i):
			so_xong += 1
	_cot_ds.add_child(GiaoDien.nhan(tr("Đã hoàn thành %d / %d nhiệm vụ") % [so_xong, CanBang.CHIEN_DICH.size()], 15, GiaoDien.MAU_MO))
	var i_nv := TienTrinh.nhiem_vu
	var nv: Dictionary = CanBang.CHIEN_DICH[i_nv]
	_tieu_de.text = "%s %d: %s" % [tr("Nhiệm vụ"), i_nv + 1, tr(nv["ten"])]
	_mo_ta.text = tr(nv["mo_ta"])
	var ten_bd := tr("Bãi tập") if nv["ban_do"] == "bai_tap" else tr(CanBang.BAN_DO[nv["ban_do"]]["ten"])
	var muc := {"ha_het": tr("Hạ hết địch"), "pha_u": tr("Phá hết ụ tên lửa"), "chi_huy": tr("Hạ mecha chỉ huy")}
	var thuong: int = nv["thuong"]
	var chu_thuong := tr("%d điểm công trạng") % thuong if not TienTrinh.nhiem_vu_xong(i_nv) \
		else tr("%d điểm công trạng (đã hoàn thành — chơi lại được %d%%)") % [int(thuong * CanBang.CHIEN_DICH_CHOI_LAI), int(CanBang.CHIEN_DICH_CHOI_LAI * 100)]
	if thuong <= 0:
		chu_thuong = tr("không có")
	TienTrinh.sua_trang_bi()
	var tb: Dictionary = TienTrinh.trang_bi
	_thong_tin.text = tr("Bản đồ: %s\nMục tiêu: %s\nPhần thưởng: %s\nHồi sinh: %d lần (hết lượt là thất bại)\n\nTrang bị: %s · %s / %s · %s / %s · %s\n(trong nhiệm vụ bấm %s để đổi trang bị ở bất cứ đâu)") % [
		ten_bd, muc.get(nv["muc_tieu"], ""), chu_thuong, CanBang.CHIEN_DICH_HOI_SINH,
		tr(CanBang.LOAI_MECHA[tb["loai"]]["ten"]), tr(CanBang.VU_KHI[tb["phai"]]["ten"]), tr(CanBang.VU_KHI[tb["trai"]]["ten"]),
		tr(CanBang.TAY_PHU[tb["tay_phu_trai"]]["ten"]), tr(CanBang.TAY_PHU[tb["tay_phu_phai"]]["ten"]),
		tr(CanBang.KIEU_CAN_CHIEN[tb["can_chien"]]["ten"]), Phim.ten("trang_bi")]
	_nut_bat_dau.disabled = not TienTrinh.nhiem_vu_mo(i_nv)
	GiaoDien.xoa_con(_hang_kho)
	var kho_dang: String = TienTrinh.cau_hinh_tran.get("do_kho", "thuong")
	for k in CanBang.DO_KHO:
		var dk: Dictionary = CanBang.DO_KHO[k]
		var b := GiaoDien.nut("%s\n%s" % [tr(dk["ten"]), tr("%d địch tấn công cùng lúc") % int(dk["tan_cong_cung_luc"])], 17, 230)
		b.name = "kho_" + k
		GiaoDien.danh_dau(b, kho_dang == k)
		var kk: String = k
		b.pressed.connect(func() -> void:
			TienTrinh.cau_hinh_tran["do_kho"] = kk
			TienTrinh.luu()
			lam_moi())
		_hang_kho.add_child(b)
