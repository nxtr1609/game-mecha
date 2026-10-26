class_name ManLuuTai
extends Control
## Lưu / tải: ô tự động lưu (tiến trình đang chơi, tự lưu sau mỗi nhiệm vụ / trận và khi thoát) + 3 ô tự lưu.
## Mỗi ô hiện ngày giờ lưu, tổng thời gian chơi, tiến độ chiến dịch, điểm công trạng, loại mecha.
## Ở menu: lưu đè, tải, xóa (có hỏi xác nhận). Trong trận (menu tạm dừng): chỉ lưu.
## Lưu giữa nhiệm vụ chiến dịch: tải lại thì chơi lại nhiệm vụ đó từ đầu. Lưu giữa trận cứ điểm: chỉ lưu tiến trình.

signal dong
signal da_tai(nhiem_vu: int)       # tải xong; nhiem_vu >= 0: bản lưu đang ở giữa nhiệm vụ đó

var trong_tran := false
var _cot: VBoxContainer
var _bao: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = GiaoDien.theme()
	GiaoDien.lop_esc(self, func() -> void: dong.emit())
	var nen := ColorRect.new()
	nen.color = Color(0.02, 0.03, 0.05, 0.93)
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(nen)
	var k := GiaoDien.khung()
	k.position = Vector2(250, 70)
	k.custom_minimum_size = Vector2(1100, 0)
	add_child(k)
	var c := GiaoDien.cot(12)
	k.add_child(c)
	var h := GiaoDien.hang(18)
	c.add_child(h)
	var lui := GiaoDien.nut(tr("← QUAY LẠI"), 18)
	lui.name = "nut_quay_lai"
	lui.pressed.connect(func() -> void: dong.emit())
	h.add_child(lui)
	h.add_child(GiaoDien.nhan(tr("LƯU GAME") if trong_tran else tr("LƯU / TẢI"), 30, Color(0.85, 0.93, 1.0)))
	var mo_ta := tr("Lưu giữa nhiệm vụ: khi tải lại sẽ chơi lại nhiệm vụ đó từ đầu, với trang bị lúc lưu.") if trong_tran \
		else tr("Tiến trình tự động lưu sau mỗi nhiệm vụ / trận và khi thoát. Dùng 3 ô bên dưới để giữ thêm bản lưu riêng.")
	c.add_child(GiaoDien.nhan(mo_ta, 15, GiaoDien.MAU_MO))
	_cot = GiaoDien.cot(10)
	c.add_child(_cot)
	_bao = GiaoDien.nhan("", 17, GiaoDien.MAU_VANG)
	c.add_child(_bao)
	lam_moi()


func lam_moi() -> void:
	GiaoDien.xoa_con(_cot)
	for i in TienTrinh.SO_O + 1:
		_cot.add_child(_o(i))


func _o(i: int) -> Control:
	var k := GiaoDien.khung()
	k.name = "o_%d" % i
	var h := GiaoDien.hang(16)
	k.add_child(h)
	var trai := GiaoDien.cot(4)
	trai.custom_minimum_size.x = 640
	h.add_child(trai)
	var ten := tr("TỰ ĐỘNG LƯU (đang chơi)") if i == 0 else tr("Ô LƯU %d") % i
	trai.add_child(GiaoDien.nhan(ten, 20, GiaoDien.MAU_NHAN))
	var tt := TienTrinh.thong_tin_o(i)
	if tt.is_empty():
		trai.add_child(GiaoDien.nhan(tr("— trống —"), 16, GiaoDien.MAU_MO))
	else:
		var gio: float = tt["gio_choi"]
		var dong1 := tr("Lưu lúc %s · đã chơi %d giờ %02d phút") % [String(tt["luc_luu"]).replace("T", " "), int(gio) / 3600, (int(gio) % 3600) / 60]
		var dong2 := tr("Chiến dịch: %d / %d nhiệm vụ · %d điểm công trạng · mecha %s") % [
			int(tt["nhiem_vu_xong"]), CanBang.CHIEN_DICH.size(), int(tt["cong_trang"]), tr(CanBang.LOAI_MECHA.get(tt["loai"], CanBang.LOAI_MECHA["co_ban"])["ten"])]
		trai.add_child(GiaoDien.nhan(dong1, 15, Color(1, 1, 1, 0.85)))
		trai.add_child(GiaoDien.nhan(dong2, 15, Color(1, 1, 1, 0.85)))
		if int(tt["dang_nhiem_vu"]) >= 0:
			trai.add_child(GiaoDien.nhan(tr("Đang ở giữa nhiệm vụ %d: %s") % [int(tt["dang_nhiem_vu"]) + 1, tr(CanBang.CHIEN_DICH[int(tt["dang_nhiem_vu"])]["ten"])], 15, GiaoDien.MAU_VANG))
	if i == 0:
		return k
	var nut_luu := GiaoDien.nut(tr("LƯU VÀO ĐÂY"), 17)
	nut_luu.name = "luu_%d" % i
	nut_luu.pressed.connect(func() -> void:
		var lam := func() -> void:
			TienTrinh.luu_o(i)
			_bao.text = tr("Đã lưu vào ô %d.") % i
			AmThanh.ui("bam")
			lam_moi()
		if tt.is_empty():
			lam.call()
		else:
			_hoi(tr("Lưu đè lên ô %d? Bản lưu cũ trong ô này sẽ mất.") % i, lam))
	h.add_child(nut_luu)
	if not trong_tran:
		var nut_tai := GiaoDien.nut(tr("TẢI"), 17)
		nut_tai.name = "tai_%d" % i
		nut_tai.disabled = tt.is_empty()
		nut_tai.pressed.connect(func() -> void:
			_hoi(tr("Tải ô %d? Tiến trình đang chơi sẽ được thay bằng bản lưu này.") % i, func() -> void:
				if TienTrinh.tai_o(i):
					_bao.text = tr("Đã tải ô %d.") % i
					AmThanh.ui("bam")
					da_tai.emit(TienTrinh.dang_nhiem_vu)
				lam_moi()))
		h.add_child(nut_tai)
		var nut_xoa := GiaoDien.nut(tr("XÓA"), 17)
		nut_xoa.name = "xoa_%d" % i
		nut_xoa.disabled = tt.is_empty()
		nut_xoa.pressed.connect(func() -> void:
			_hoi(tr("Xóa ô %d? Không hoàn tác được.") % i, func() -> void:
				TienTrinh.xoa_o(i)
				_bao.text = tr("Đã xóa ô %d.") % i
				lam_moi()))
		h.add_child(nut_xoa)
	return k


## Hộp thoại xác nhận nhỏ.
func _hoi(cau_hoi: String, khi_dong_y: Callable) -> void:
	var phu := ColorRect.new()
	phu.color = Color(0, 0, 0, 0.6)
	phu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(phu)
	GiaoDien.lop_esc(phu, phu.queue_free)
	var k := GiaoDien.khung()
	k.position = Vector2(560, 360)
	k.custom_minimum_size = Vector2(480, 0)
	phu.add_child(k)
	var c := GiaoDien.cot(16)
	k.add_child(c)
	var l := GiaoDien.nhan(cau_hoi, 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 440
	c.add_child(l)
	var h := GiaoDien.hang(12)
	h.alignment = BoxContainer.ALIGNMENT_END
	c.add_child(h)
	var khong := GiaoDien.nut(tr("Hủy"), 18)
	khong.name = "nut_huy"
	khong.pressed.connect(phu.queue_free)
	h.add_child(khong)
	var co := GiaoDien.nut(tr("Đồng ý"), 18)
	co.name = "nut_dong_y"
	co.pressed.connect(func() -> void:
		phu.queue_free()
		khi_dong_y.call())
	h.add_child(co)
