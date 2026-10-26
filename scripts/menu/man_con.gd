class_name ManCon
extends Control
## Khung chung cho các màn con: tiêu đề, nút Quay lại, vùng nội dung.

var menu: MenuChinh
var noi_dung: Control              # vùng nội dung bên dưới tiêu đề
var quay_lai_toi := "chinh"


func _dung_khung(tieu_de: String, mo_ta := "", nen_toi := true) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if nen_toi:
		var nen := ColorRect.new()
		nen.color = Color(0.02, 0.03, 0.05, 0.78)
		nen.set_anchors_preset(Control.PRESET_FULL_RECT)
		nen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(nen)
	var h := GiaoDien.hang(18)
	h.position = Vector2(40, 22)
	add_child(h)
	var lui := GiaoDien.nut(tr("← QUAY LẠI"), 18)
	lui.pressed.connect(func() -> void:
		AmThanh.ui("dong")
		menu.mo(quay_lai_toi))
	lui.name = "nut_quay_lai"
	h.add_child(lui)
	h.add_child(GiaoDien.nhan(tieu_de, 32, Color(0.85, 0.93, 1.0)))
	if mo_ta != "":
		var l := GiaoDien.nhan(mo_ta, 16, GiaoDien.MAU_MO)
		l.position = Vector2(44, 72)
		add_child(l)
	noi_dung = Control.new()
	noi_dung.position = Vector2(40, 104)
	noi_dung.size = Vector2(1520, 770)
	noi_dung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(noi_dung)
