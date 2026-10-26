class_name GiaoDien
extends RefCounted
## Kiểu giao diện dùng chung cho mọi màn menu: màu, khung, nút, chữ.

const MAU_NEN := Color(0.05, 0.07, 0.1, 0.92)
const MAU_KHUNG := Color(0.09, 0.13, 0.19, 0.95)
const MAU_VIEN := Color(0.35, 0.7, 1.0)
const MAU_NHAN := Color(0.6, 0.85, 1.0)
const MAU_VANG := Color(1.0, 0.85, 0.4)
const MAU_DO := Color(1.0, 0.4, 0.35)
const MAU_XANH := Color(0.45, 1.0, 0.6)
const MAU_MO := Color(1, 1, 1, 0.55)

static var _theme: Theme = null
static var _font: Font = null


static func font() -> Font:
	if _font == null:
		# chữ Latin / tiếng Việt: Segoe UI; chữ Nhật thiếu thì tự lấy font tiếng Nhật có sẵn của Windows (Yu Gothic, Meiryo)
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma"])
		sf.allow_system_fallback = true
		var nhat := SystemFont.new()
		nhat.font_names = PackedStringArray(["Yu Gothic UI", "Yu Gothic", "Meiryo UI", "Meiryo", "MS Gothic"])
		sf.fallbacks = [nhat]
		_font = sf
	return _font


static func _hop(nen: Color, vien: Color, day := 1, bo := 4, trai := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = nen
	s.border_color = vien
	s.set_border_width_all(day)
	if trai > 0:
		s.border_width_left = trai          # vạch sáng bên trái (nút đang rê chuột / đang bấm)
	s.set_corner_radius_all(bo)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 18
	t.set_stylebox("normal", "Button", _hop(Color(0.1, 0.16, 0.24, 0.95), Color(0.3, 0.55, 0.8), 1, 3, 3))
	t.set_stylebox("hover", "Button", _hop(Color(0.15, 0.27, 0.4, 0.98), MAU_VIEN, 2, 3, 6))
	t.set_stylebox("pressed", "Button", _hop(Color(0.2, 0.38, 0.55, 1.0), MAU_VANG, 2, 3, 6))
	t.set_stylebox("disabled", "Button", _hop(Color(0.08, 0.1, 0.13, 0.8), Color(0.25, 0.28, 0.32)))
	t.set_stylebox("focus", "Button", _hop(Color(0, 0, 0, 0), Color(0.7, 0.9, 1.0, 0.6), 1))
	t.set_color("font_color", "Button", Color(0.9, 0.95, 1.0))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", MAU_VANG)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.52, 0.55))
	t.set_stylebox("panel", "PanelContainer", _hop(MAU_KHUNG, Color(0.25, 0.45, 0.65), 1, 6))
	t.set_stylebox("panel", "Panel", _hop(MAU_KHUNG, Color(0.25, 0.45, 0.65), 1, 6))
	t.set_color("font_color", "Label", Color(0.92, 0.95, 1.0))
	t.set_stylebox("normal", "LineEdit", _hop(Color(0.06, 0.09, 0.13), Color(0.3, 0.5, 0.7)))
	t.set_stylebox("slider", "HSlider", _hop(Color(0.15, 0.2, 0.28), Color(0.15, 0.2, 0.28), 0, 3))
	t.set_stylebox("grabber_area", "HSlider", _hop(Color(0.3, 0.6, 0.9), Color(0.3, 0.6, 0.9), 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", _hop(Color(0.45, 0.75, 1.0), Color(0.45, 0.75, 1.0), 0, 3))
	t.set_stylebox("panel", "TooltipPanel", _hop(Color(0.05, 0.08, 0.12, 0.97), MAU_VIEN))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_color("default_color", "RichTextLabel", Color(0.92, 0.95, 1.0))
	_theme = t
	return t


static func nut(chu: String, co := 20, rong := 0.0) -> Button:
	var b := Button.new()
	b.text = chu
	b.add_theme_font_size_override("font_size", co)
	if rong > 0.0:
		b.custom_minimum_size.x = rong
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: GiaoDien.am_ui("bam"))
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			GiaoDien.am_ui("luot"))
	return b


## Gọi bộ âm thanh (autoload AmThanh) từ hàm tĩnh.
static func am_ui(ten: String) -> void:
	var cay := Engine.get_main_loop() as SceneTree
	var a: Node = cay.root.get_node_or_null("AmThanh") if cay else null
	if a:
		a.call("ui", ten)


static func nhan(chu: String, co := 18, mau := Color(0.92, 0.95, 1.0)) -> Label:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	return l


static func khung() -> PanelContainer:
	return PanelContainer.new()


static func hang(cach := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", cach)
	return h


static func cot(cach := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", cach)
	return v


## Nút bật tắt kiểu "chọn một trong nhiều": nút đang chọn sáng viền vàng.
static func danh_dau(b: Button, dang_chon: bool) -> void:
	if dang_chon:
		b.add_theme_stylebox_override("normal", _hop(Color(0.2, 0.32, 0.45, 1.0), MAU_VANG, 2))
		b.add_theme_stylebox_override("hover", _hop(Color(0.24, 0.38, 0.52, 1.0), MAU_VANG, 2))
		b.add_theme_color_override("font_color", MAU_VANG)
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")
		b.remove_theme_color_override("font_color")


## Thanh 1–5 chấm (thang so sánh loại mecha).
static func thang_diem(so: int, toi_da := 5) -> String:
	return "■".repeat(so) + "□".repeat(toi_da - so)


## Xóa hết con của một nút (đổi tên trước để nút mới dựng lại dùng được đúng tên cũ).
static func xoa_con(n: Node) -> void:
	for c in n.get_children():
		c.name = "cu_%d" % c.get_instance_id()
		c.queue_free()


## Đổi ngôn ngữ (NgonNgu) rồi dựng lại menu đang mở cho chữ mới.
static func doi_ngon_ngu(ma: String) -> void:
	var cay := Engine.get_main_loop() as SceneTree
	var nn: Node = cay.root.get_node_or_null("NgonNgu") if cay else null
	if nn == null:
		return
	nn.call("dat", ma)
	am_ui("bam")
	var canh := cay.current_scene
	if canh and canh.has_method("dung_lai"):
		canh.call("dung_lai")


## Esc lùi một bước: đăng ký một lớp đè (hộp thoại xác nhận, màn đổi phím, lưu / tải, cài đặt trong trận);
## bấm Esc thì gọi lui để đóng lớp đó. Lớp nằm trên cùng (thêm vào sau) đóng trước.
static func lop_esc(n: CanvasItem, lui: Callable) -> void:
	n.add_to_group("lop_esc")
	n.set_meta("lui", lui)


## Đóng lớp đè trên cùng đang hiện (xem lop_esc). Trả về true nếu đã đóng được một lớp.
static func lui_lop_tren(cay: SceneTree) -> bool:
	var ds := cay.get_nodes_in_group("lop_esc")
	for i in range(ds.size() - 1, -1, -1):
		var n := ds[i] as CanvasItem
		if n and n.is_visible_in_tree() and not n.is_queued_for_deletion():
			(n.get_meta("lui") as Callable).call()
			am_ui("dong")
			return true
	return false


## Vẽ một dòng chữ có viền đen mảnh cho dễ đọc trên nền 3D (HUD, bản đồ, bảng chọn cứ điểm dùng chung).
## giua: căn giữa theo p.x. vien: độ dày viền (px), 0 = không viền.
static func ve_chu(ci: CanvasItem, f: Font, p: Vector2, s: String, co: int, mau: Color, giua := false, vien := 3) -> void:
	var x := p.x
	if giua:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, co).x * 0.5
	if vien > 0:
		ci.draw_string_outline(f, Vector2(x, p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, co, vien, Color(0, 0, 0, 0.7))
	ci.draw_string(f, Vector2(x, p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, co, mau)
