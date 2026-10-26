class_name ManChuanBi
extends ManCon
## Màn chuẩn bị trận: chọn bản đồ, độ khó, quân số, xem lại mecha, rồi bắt đầu.

var _hang_kho: HBoxContainer
var _hang_quan: HBoxContainer
var _hang_ban_do: HBoxContainer
var _mo_ta_ban_do: Label
var _tom_tat: Label
var _nut_bat_dau: Button


func _ready() -> void:
	_dung_khung(tr("VÀO TRẬN"), tr("Chế độ Hạ tàu sân bay: hạ tàu sân bay địch là thắng. Trận dài tối đa 15 phút; hết giờ thì phe có tàu sân bay còn nhiều % hơn thắng."))
	var trai := GiaoDien.khung()
	trai.custom_minimum_size = Vector2(800, 620)
	noi_dung.add_child(trai)
	var c := GiaoDien.cot(12)
	trai.add_child(c)
	c.add_child(GiaoDien.nhan(tr("BẢN ĐỒ"), 20, GiaoDien.MAU_NHAN))
	_hang_ban_do = GiaoDien.hang(10)
	c.add_child(_hang_ban_do)
	_mo_ta_ban_do = GiaoDien.nhan("", 15, GiaoDien.MAU_MO)
	_mo_ta_ban_do.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mo_ta_ban_do.custom_minimum_size.x = 760
	c.add_child(_mo_ta_ban_do)
	c.add_child(GiaoDien.nhan(tr("ĐỘ KHÓ"), 20, GiaoDien.MAU_NHAN))
	_hang_kho = GiaoDien.hang(10)
	c.add_child(_hang_kho)
	c.add_child(GiaoDien.nhan(tr("Độ khó quyết định sức bắn của bot địch và nâng cấp của phe địch."), 15, GiaoDien.MAU_MO))
	c.add_child(GiaoDien.nhan(tr("QUÂN SỐ"), 20, GiaoDien.MAU_NHAN))
	_hang_quan = GiaoDien.hang(10)
	c.add_child(_hang_quan)
	_tom_tat = GiaoDien.nhan("", 17)
	_tom_tat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tom_tat.custom_minimum_size.x = 760
	c.add_child(_tom_tat)
	var h := GiaoDien.hang(12)
	c.add_child(h)
	var sua_m := GiaoDien.nut(tr("Sửa mecha & vũ khí"), 17)
	sua_m.pressed.connect(func() -> void: menu.mo("mecha"))
	h.add_child(sua_m)
	_nut_bat_dau = GiaoDien.nut(tr("BẮT ĐẦU TRẬN"), 30, 420)
	_nut_bat_dau.custom_minimum_size.y = 70
	_nut_bat_dau.name = "nut_bat_dau"
	_nut_bat_dau.pressed.connect(func() -> void: menu.bat_dau_tran())
	c.add_child(_nut_bat_dau)


func lam_moi() -> void:
	var ch: Dictionary = TienTrinh.cau_hinh_tran
	GiaoDien.xoa_con(_hang_ban_do)
	for k in CanBang.BAN_DO:
		var b := GiaoDien.nut(tr(CanBang.BAN_DO[k]["ten"]), 18, 245)
		b.name = "ban_do_" + k
		GiaoDien.danh_dau(b, ch.get("ban_do", "thanh_pho") == k)
		var kk: String = k
		b.pressed.connect(func() -> void:
			TienTrinh.cau_hinh_tran["ban_do"] = kk
			TienTrinh.luu()
			lam_moi())
		_hang_ban_do.add_child(b)
	_mo_ta_ban_do.text = tr(CanBang.BAN_DO[ch.get("ban_do", "thanh_pho")]["mo_ta"])
	GiaoDien.xoa_con(_hang_kho)
	for k in CanBang.DO_KHO:
		var dk: Dictionary = CanBang.DO_KHO[k]
		var phu := tr("Địch nâng cấp %d nút") % int(dk["nut_dich"])
		var b := GiaoDien.nut("%s\n%s" % [tr(dk["ten"]), phu], 18, 230)
		b.name = "kho_" + k
		GiaoDien.danh_dau(b, ch["do_kho"] == k)
		var kk: String = k
		b.pressed.connect(func() -> void:
			TienTrinh.cau_hinh_tran["do_kho"] = kk
			TienTrinh.luu()
			lam_moi())
		_hang_kho.add_child(b)
	GiaoDien.xoa_con(_hang_quan)
	for q in [3, 6]:
		var b := GiaoDien.nut(tr("%d đấu %d") % [q, q], 20, 230)
		b.name = "quan_%d" % q
		GiaoDien.danh_dau(b, int(ch["quan_so"]) == q)
		var qq: int = q
		b.pressed.connect(func() -> void:
			TienTrinh.cau_hinh_tran["quan_so"] = qq
			TienTrinh.luu()
			lam_moi())
		_hang_quan.add_child(b)
	TienTrinh.sua_trang_bi()
	var tb: Dictionary = TienTrinh.trang_bi
	var s := tr("Mecha: %s\nVũ khí phải: %s · Vũ khí trái: %s\nTay phụ: %s / %s · Cận chiến: %s") % [
		tr(CanBang.LOAI_MECHA[tb["loai"]]["ten"]), tr(CanBang.VU_KHI[tb["phai"]]["ten"]), tr(CanBang.VU_KHI[tb["trai"]]["ten"]),
		tr(CanBang.TAY_PHU[tb["tay_phu_trai"]]["ten"]), tr(CanBang.TAY_PHU[tb["tay_phu_phai"]]["ten"]),
		tr(CanBang.KIEU_CAN_CHIEN[tb["can_chien"]]["ten"])]
	s += tr("\n\nTrên trời: hai tàu sân bay bắn nhau ngang sức. Giúp tàu ta bằng cách giữ cứ điểm\nTrạm tên lửa (bắn tàu địch) và Trạm hậu cần (sửa tàu ta).")
	_tom_tat.text = s
