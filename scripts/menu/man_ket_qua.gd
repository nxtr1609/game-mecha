class_name ManKetQua
extends Control
## Màn kết quả khi trận kết thúc: thắng / thua / hòa, lý do, thời gian, thành tích, điểm công trạng.

var ban_do: BanDoThu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = GiaoDien.theme()
	var kq: Dictionary = TienTrinh.ket_qua
	var nen := ColorRect.new()
	nen.color = Color(0.02, 0.03, 0.05, 0.0)
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(nen)
	create_tween().tween_property(nen, "color:a", 0.8, 1.2)
	var k := GiaoDien.khung()
	k.position = Vector2(470, 190)
	k.custom_minimum_size = Vector2(660, 0)
	add_child(k)
	var c := GiaoDien.cot(12)
	k.add_child(c)
	var thang: int = kq.get("thang", 0)
	if kq.get("che_do", "") == "chien_dich":
		_ket_qua_chien_dich(c, kq)
		return
	var tieu_de := tr("CHIẾN THẮNG") if thang > 0 else (tr("HÒA") if thang == 0 else tr("THẤT BẠI"))
	var mau := GiaoDien.MAU_XANH if thang > 0 else (GiaoDien.MAU_VANG if thang == 0 else GiaoDien.MAU_DO)
	c.add_child(GiaoDien.nhan(tieu_de, 54, mau))
	c.add_child(GiaoDien.nhan(String(kq.get("ly_do", "")), 19))
	var tg: float = kq.get("thoi_gian", 0.0)
	var s := tr("Thời gian trận: %d:%02d\nTàu sân bay ta còn %d%% · tàu sân bay địch còn %d%%\nMecha địch bạn tự tay hạ: %d\nCứ điểm phe ta chiếm được: %d") % [
		int(tg) / 60, int(tg) % 60, int(float(kq.get("ta", 0.0)) * 100), int(float(kq.get("dich", 0.0)) * 100),
		int(kq.get("so_ha", 0)), int(kq.get("cu_diem", 0))]
	c.add_child(GiaoDien.nhan(s, 18, Color(1, 1, 1, 0.9)))
	c.add_child(GiaoDien.nhan(tr("+%d điểm công trạng   (tổng: %d)") % [int(kq.get("thuong", 0)), TienTrinh.cong_trang], 24, GiaoDien.MAU_VANG))
	c.add_child(GiaoDien.nhan(tr("Dùng điểm công trạng ở mục Nâng cấp, Hạm đội hoặc Mecha & vũ khí."), 15, GiaoDien.MAU_MO))
	var b := GiaoDien.nut(tr("VỀ MENU"), 24, 300)
	b.name = "nut_ve_menu"
	b.pressed.connect(func() -> void: ban_do.ve_menu())
	c.add_child(b)


## Kết quả một nhiệm vụ chiến dịch: hoàn thành / thất bại, thời gian, số hạ, số lần bị hạ, điểm; chơi lại / nhiệm vụ kế.
func _ket_qua_chien_dich(c: VBoxContainer, kq: Dictionary) -> void:
	var thang: int = kq.get("thang", 0)
	var i: int = kq.get("nhiem_vu", 0)
	var nv: Dictionary = CanBang.CHIEN_DICH[i]
	c.add_child(GiaoDien.nhan(tr("HOÀN THÀNH NHIỆM VỤ") if thang > 0 else tr("NHIỆM VỤ THẤT BẠI"), 50, GiaoDien.MAU_XANH if thang > 0 else GiaoDien.MAU_DO))
	c.add_child(GiaoDien.nhan("%s %d: %s" % [tr("Nhiệm vụ"), i + 1, tr(nv["ten"])], 22, GiaoDien.MAU_NHAN))
	c.add_child(GiaoDien.nhan(String(kq.get("ly_do", "")), 19))
	var tg: float = kq.get("thoi_gian", 0.0)
	c.add_child(GiaoDien.nhan(tr("Thời gian: %d:%02d
Mecha địch bạn tự tay hạ: %d
Số lần bị hạ: %d") % [int(tg) / 60, int(tg) % 60, int(kq.get("so_ha", 0)), int(kq.get("so_chet", 0))], 18, Color(1, 1, 1, 0.9)))
	if thang > 0 and int(kq.get("thuong", 0)) > 0:
		c.add_child(GiaoDien.nhan(tr("+%d điểm công trạng   (tổng: %d)") % [int(kq.get("thuong", 0)), TienTrinh.cong_trang], 24, GiaoDien.MAU_VANG))
	var h := GiaoDien.hang(12)
	c.add_child(h)
	if thang > 0 and i + 1 < CanBang.CHIEN_DICH.size():
		var tiep := GiaoDien.nut(tr("NHIỆM VỤ TIẾP THEO"), 20, 260)
		tiep.name = "nut_tiep"
		tiep.pressed.connect(func() -> void: ban_do.choi_nhiem_vu(i + 1))
		h.add_child(tiep)
	var lai := GiaoDien.nut(tr("CHƠI LẠI"), 20, 180)
	lai.name = "nut_choi_lai"
	lai.pressed.connect(func() -> void: ban_do.choi_nhiem_vu(i))
	h.add_child(lai)
	var b := GiaoDien.nut(tr("VỀ MENU"), 20, 180)
	b.name = "nut_ve_menu"
	b.pressed.connect(func() -> void: ban_do.ve_menu())
	h.add_child(b)


## Esc: về menu chính.
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("tha_chuot"):
		get_viewport().set_input_as_handled()
		ban_do.ve_menu()
