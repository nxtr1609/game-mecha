class_name ManGhiCong
extends ManCon
## Màn ghi công: mọi tài nguyên tải từ internet, tác giả, giấy phép, đường link.


func _ready() -> void:
	_dung_khung(tr("GHI CÔNG"), tr("Cảm ơn các tác giả đã chia sẻ miễn phí. Danh sách này giống file GHI_CONG.md trong thư mục game."))
	var k := GiaoDien.khung()
	k.custom_minimum_size = Vector2(1500, 640)
	noi_dung.add_child(k)
	var cuon := ScrollContainer.new()
	cuon.custom_minimum_size = Vector2(1470, 620)
	k.add_child(cuon)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size.x = 1440
	r.add_theme_font_size_override("normal_font_size", 17)
	r.add_theme_font_size_override("bold_font_size", 19)
	r.meta_clicked.connect(func(m: Variant) -> void: OS.shell_open(str(m)))
	var s := tr("[b]Mẫu mecha (2 loại, mỗi loại 2 màu phe), chiến hạm, máy bay vận chuyển, súng, ụ súng, 13 mẫu nhà nội / ngoại thành[/b]: do người làm game cung cấp.\n\n")
	for d in GhiCong.DANH_SACH:
		s += "[b][color=#9fd8ff]%s[/color][/b] — %s\n" % [d["ten"], tr(d["tac_gia"])]
		s += tr("    Giấy phép: %s · Dùng cho: %s\n    [url=%s]%s[/url]\n\n") % [tr(d["giay_phep"]), tr(d["dung_cho"]), d["link"], d["link"]]
	s += tr("Phần mềm: Godot Engine 4.7 (giấy phép MIT), Blender (xử lý mô hình).")
	r.text = s
	cuon.add_child(r)
