class_name ManTamDung
extends Control
## Menu tạm dừng trong trận (phím Esc): Tiếp tục / Cài đặt / Rời trận.
## Esc luôn lùi một bước: đóng lớp đè trên cùng (cài đặt, đổi phím, lưu game, hộp xác nhận), rồi menu tạm dừng,
## bảng B, bản đồ M; không có gì mở thì mở menu tạm dừng.

var ban_do: BanDoThu
var _cot: VBoxContainer
var _cai_dat: ManCaiDat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = GiaoDien.theme()
	visible = false
	var nen := ColorRect.new()
	nen.color = Color(0.02, 0.03, 0.05, 0.75)
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(nen)
	var k := GiaoDien.khung()
	k.position = Vector2(600, 230)
	k.custom_minimum_size = Vector2(400, 0)
	add_child(k)
	_cot = GiaoDien.cot(14)
	k.add_child(_cot)
	_cot.add_child(GiaoDien.nhan(tr("TẠM DỪNG"), 34, Color(0.85, 0.93, 1.0)))
	var tiep := GiaoDien.nut(tr("TIẾP TỤC"), 22, 360)
	tiep.pressed.connect(dong)
	_cot.add_child(tiep)
	if ban_do.has_method("xem_lai_huong_dan"):
		var hd := GiaoDien.nut(tr("XEM LẠI HƯỚNG DẪN"), 22, 360)
		hd.name = "nut_huong_dan"
		hd.pressed.connect(func() -> void:
			visible = false
			_cai_dat.visible = false
			ban_do.call("xem_lai_huong_dan"))
		_cot.add_child(hd)
	var luu := GiaoDien.nut(tr("LƯU GAME"), 22, 360)
	luu.name = "nut_luu_game"
	luu.pressed.connect(func() -> void:
		var lt := ManLuuTai.new()
		lt.trong_tran = true
		add_child(lt)
		lt.dong.connect(lt.queue_free))
	_cot.add_child(luu)
	var cd := GiaoDien.nut(tr("CÀI ĐẶT"), 22, 360)
	cd.name = "nut_cai_dat"
	cd.pressed.connect(func() -> void:
		_cai_dat.visible = true
		k.visible = false)
	_cot.add_child(cd)
	var chien_dich: bool = ban_do.get("che_do") == "chien_dich"
	var roi := GiaoDien.nut(tr("RỜI NHIỆM VỤ") if chien_dich else tr("RỜI TRẬN (tính là thua)"), 20, 360)
	roi.pressed.connect(func() -> void:
		visible = false
		ban_do.ket_thuc(-1, tr("Đã rời nhiệm vụ.") if chien_dich else tr("Đã rời trận.")))
	_cot.add_child(roi)
	_cot.add_child(GiaoDien.nhan(tr("Phím đổi được ở Cài đặt → Điều khiển."), 14, GiaoDien.MAU_MO))
	_cai_dat = ManCaiDat.new()
	_cai_dat.trong_tran = true
	_cai_dat.visible = false
	_cai_dat.dong.connect(func() -> void:
		_cai_dat.visible = false
		k.visible = true)
	add_child(_cai_dat)


func mo() -> void:
	if ban_do.da_ket_thuc:
		return
	visible = true
	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.ui("mo")


func dong() -> void:
	visible = false
	_cai_dat.visible = false
	get_tree().paused = false
	if DisplayServer.get_name() != "headless" and not ban_do.dang_mo_bang():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AmThanh.ui("dong")


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("tha_chuot"):
		return
	get_viewport().set_input_as_handled()
	if GiaoDien.lui_lop_tren(get_tree()):
		return
	if visible:
		dong()
		return
	var bang = ban_do.get("bang_trang_bi")
	var bd_mat = ban_do.get("ban_do_mat")
	if bang and bang.visible:
		bang.dong_bang()
	elif bd_mat and bd_mat.visible:
		bd_mat.bat_tat()
	elif not ban_do.da_ket_thuc and not (ban_do.get("menu") and ban_do.menu.visible):
		mo()
