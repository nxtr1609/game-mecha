class_name BangHuongDan
extends Control
## Bảng hướng dẫn trước mỗi bài huấn luyện (game tạm dừng): tiêu đề, ảnh minh họa chụp từ game (có mũi tên chỉ
## chỗ cần nhìn), lời giải thích, việc cần làm, hàng biểu tượng phím (vẽ theo phím đang gán — đổi phím thì đổi theo).
## Nút BẮT ĐẦU (Enter / Space / Esc) và "Bỏ qua bài này".
## bai: {"so", "tong", "ten", "anh", "chu", "viec", "phim": [[hành động, nhãn]...], "mui_ten": [[Vector2 (0..1), nhãn]...]}

signal bat_dau
signal bo_qua

var bai: Dictionary = {}
var font: Font
var _khung := Rect2()
var _o_anh := Rect2()
var _o_phim := Rect2()
var _nut_bat_dau: Button
var _nut_bo_qua: Button
var _chu: Label
var _viec: Label
var _anh: Texture2D
var _t_mo := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = GiaoDien.theme()
	font = GiaoDien.font()
	visible = false
	_chu = GiaoDien.nhan("", 18)
	_chu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_chu)
	_viec = GiaoDien.nhan("", 18, GiaoDien.MAU_VANG)
	_viec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_viec)
	_nut_bat_dau = GiaoDien.nut(tr("BẮT ĐẦU  (Enter)"), 22, 300)
	_nut_bat_dau.name = "nut_bat_dau"
	_nut_bat_dau.pressed.connect(_bat_dau)
	add_child(_nut_bat_dau)
	_nut_bo_qua = GiaoDien.nut(tr("Bỏ qua bài này"), 15, 180)
	_nut_bo_qua.name = "nut_bo_qua"
	_nut_bo_qua.pressed.connect(func() -> void:
		visible = false
		bo_qua.emit())
	add_child(_nut_bo_qua)


func mo(b: Dictionary) -> void:
	bai = b
	# ảnh theo ngôn ngữ đang dùng (chữ trên HUD trong ảnh khớp ngôn ngữ), không có thì dùng ảnh chung
	_anh = null
	for duong in ["res://anh/huong_dan/%s_%s.png" % [String(b.get("anh", "")), TranslationServer.get_locale().left(2)],
			"res://anh/huong_dan/%s.png" % String(b.get("anh", ""))]:
		if ResourceLoader.exists(duong):
			_anh = load(duong)
			break
	_chu.text = tr(String(b["chu"]))
	_viec.text = tr("VIỆC CẦN LÀM: ") + tr(String(b["viec"]))
	_nut_bo_qua.visible = b.get("cho_bo_qua", true)
	visible = true
	_t_mo = Time.get_ticks_msec()
	_xep()
	queue_redraw()


func _bat_dau() -> void:
	if not visible or Time.get_ticks_msec() - _t_mo < 250:
		return
	visible = false
	bat_dau.emit()


func _input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		var k := (e as InputEventKey).keycode
		if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE or k == KEY_ESCAPE:
			_bat_dau()
			get_viewport().set_input_as_handled()


func _process(_dt: float) -> void:
	if visible:
		_xep()
		queue_redraw()


## Xếp chỗ theo cỡ cửa sổ: khung giữa màn hình, ảnh bên trái, chữ bên phải, hàng phím và nút ở dưới.
func _xep() -> void:
	var vp := get_viewport_rect().size
	var w := minf(vp.x - 80.0, 1180.0)
	var h := minf(vp.y - 60.0, 600.0)
	_khung = Rect2((vp - Vector2(w, h)) * 0.5, Vector2(w, h))
	var aw := w * 0.52
	_o_anh = Rect2(_khung.position + Vector2(24, 78), Vector2(aw, aw * 9.0 / 16.0))
	var x_chu := _o_anh.end.x + 24.0
	var rong_chu := _khung.end.x - 24.0 - x_chu
	_chu.position = Vector2(x_chu, _o_anh.position.y)
	_chu.size = Vector2(rong_chu, 0)
	_chu.custom_minimum_size.x = rong_chu
	_viec.position = Vector2(x_chu, _chu.position.y + _chu.get_combined_minimum_size().y + 16.0)
	_viec.size = Vector2(rong_chu, 0)
	_viec.custom_minimum_size.x = rong_chu
	_o_phim = Rect2(Vector2(_khung.position.x + 24, maxf(_o_anh.end.y, _viec.position.y + _viec.get_combined_minimum_size().y) + 18.0),
		Vector2(w - 48, 86))
	_nut_bat_dau.position = Vector2(_khung.end.x - 24 - 300, _khung.end.y - 64)
	_nut_bo_qua.position = Vector2(_khung.end.x - 24 - 300 - 200, _khung.end.y - 56)


func _draw() -> void:
	if bai.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.01, 0.02, 0.04, 0.72))
	draw_rect(_khung, Color(0.06, 0.09, 0.13, 0.97))
	draw_rect(_khung, GiaoDien.MAU_VIEN, false, 2.0)
	draw_rect(Rect2(_khung.position, Vector2(6, _khung.size.y)), GiaoDien.MAU_VIEN)
	var tieu_de := tr("BÀI %d / %d — %s") % [int(bai["so"]), int(bai["tong"]), tr(String(bai["ten"]))]
	draw_string(font, _khung.position + Vector2(28, 50), tieu_de, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GiaoDien.MAU_VANG)
	# ảnh minh họa
	draw_rect(_o_anh, Color(0.02, 0.03, 0.05))
	if _anh:
		draw_texture_rect(_anh, _o_anh, false)
	else:
		draw_string(font, _o_anh.get_center() - Vector2(60, 0), tr("(ảnh minh họa)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GiaoDien.MAU_MO)
	draw_rect(_o_anh, Color(1, 1, 1, 0.35), false, 1.5)
	for mt in bai.get("mui_ten", []):
		_mui_ten(_o_anh.position + _o_anh.size * (mt[0] as Vector2), tr(String(mt[1])), (mt[0] as Vector2), mt[2] if mt.size() > 2 else Vector2.ZERO)
	# hàng phím
	var x := _o_phim.position.x
	var y := _o_phim.position.y + 30.0
	for ph in bai.get("phim", []):
		var hd: String = ph[0]
		var nhan := tr(String(ph[1]))
		var w := 0.0
		if hd == "di":
			w = _ve_wasd(Vector2(x, y))
		elif "+" in hd:
			var hai := hd.split("+")
			w = VeBieuTuong.nut_ghep(self, font, hai[0], hai[1], Vector2(x, y), 0.8)
		else:
			var wp := VeBieuTuong.rong_nut(font, hd, 0.8)
			VeBieuTuong.nut(self, font, hd, Vector2(x + wp * 0.5, y), 0.8)
			w = wp
		draw_string(font, Vector2(x + w + 10.0, y + 7.0), nhan, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.9, 0.95, 1.0))
		x += w + 26.0 + font.get_string_size(nhan, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		if x > _o_phim.end.x - 160.0:
			x = _o_phim.position.x
			y += 46.0


## Bốn phím đi (tới / trái / lùi / phải) xếp như bàn phím. Trả về bề rộng.
func _ve_wasd(trai: Vector2) -> float:
	var k := 0.7
	var w := VeBieuTuong.rong_nut(font, "di_trai", k)
	var o := w + 4.0
	VeBieuTuong.nut(self, font, "di_toi", trai + Vector2(o * 1.5, -15), k)
	VeBieuTuong.nut(self, font, "di_trai", trai + Vector2(o * 0.5, 15), k)
	VeBieuTuong.nut(self, font, "di_lui", trai + Vector2(o * 1.5, 15), k)
	VeBieuTuong.nut(self, font, "di_phai", trai + Vector2(o * 2.5, 15), k)
	return o * 3.0


## Mũi tên vàng chỉ vào một điểm trên ảnh; nhãn đặt theo hướng "phia" (mặc định: lệch về phía giữa ảnh).
func _mui_ten(dich: Vector2, nhan: String, uv: Vector2, phia := Vector2.ZERO) -> void:
	var huong := phia if phia != Vector2.ZERO else (Vector2(0.5, 0.5) - uv)
	if huong.length() < 0.05:
		huong = Vector2(0.3, -0.4)
	huong = huong.normalized()
	var goc := dich + huong * 70.0
	var mau := Color(1.0, 0.85, 0.2)
	draw_line(goc, dich + huong * 10.0, Color(0, 0, 0, 0.6), 6.0)
	draw_line(goc, dich + huong * 10.0, mau, 3.0)
	var b := Vector2(-huong.y, huong.x)
	draw_colored_polygon(PackedVector2Array([dich, dich + huong * 16.0 + b * 8.0, dich + huong * 16.0 - b * 8.0]), mau)
	var w := font.get_string_size(nhan, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var p := goc + huong * 12.0 - Vector2(w * 0.5, -6.0)
	p.x = clampf(p.x, _o_anh.position.x + 4.0, _o_anh.end.x - w - 4.0)
	p.y = clampf(p.y, _o_anh.position.y + 20.0, _o_anh.end.y - 6.0)
	draw_rect(Rect2(p - Vector2(5, 17), Vector2(w + 10, 23)), Color(0, 0, 0, 0.75))
	draw_string(font, p, nhan, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, mau)
