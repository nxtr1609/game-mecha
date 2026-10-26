class_name VeBieuTuong
extends RefCounted
## Vẽ biểu tượng món (vũ khí tay, tay phụ, cận chiến, pháo nhiệt) và biểu tượng phím / chuột lên một CanvasItem
## (gọi trong _draw() của nó). Dùng chung cho bảng trang bị B, ô trạng thái trên HUD và bảng hướng dẫn,
## nên mọi chỗ cùng một kiểu hình. Phím vẽ theo phím người chơi đang gán (Phim).

const MAU_CAM := Color(1.0, 0.7, 0.3)
const MAU_PHIM := Color(0.85, 0.9, 1.0)
const NEN_PHIM := Color(0.12, 0.16, 0.22)

static var _anh := {}


static func anh(ten: String) -> Texture2D:
	if not _anh.has(ten):
		var duong := "res://models/bieu_tuong/%s.png" % ten
		_anh[ten] = load(duong) if ResourceLoader.exists(duong) else null
	return _anh[ten]


static func _vua(ci: CanvasItem, t: Texture2D, r: Rect2, mo: Color) -> void:
	if t == null:
		return
	var tl := minf(r.size.x / t.get_width(), r.size.y / t.get_height())
	var co := Vector2(t.get_width(), t.get_height()) * tl
	ci.draw_texture_rect(t, Rect2(r.get_center() - co * 0.5, co), false, mo)


## Một món trong ô r. o: "trai" / "phai" (vũ khí tay), "q" / "e" (tay phụ), "f" (cận chiến), "x" (pháo nhiệt).
## mo: màu nhân thêm (làm tối / mờ khi chưa dùng được). sang: làm sáng ảnh render (súng tối màu trên nền tối của HUD).
static func mon(ci: CanvasItem, font: Font, o: String, id: String, r: Rect2, mo := Color.WHITE, sang := 1.0) -> void:
	var tam := r.get_center()
	var k := minf(r.size.x, r.size.y) / 100.0          # hình vẽ bằng code theo ô cỡ 100 px
	if o == "x":
		_phao_nhiet(ci, tam, k, mo)
		return
	if o == "f":
		var kc: Dictionary = CanBang.KIEU_CAN_CHIEN[id]
		var mau: Color = kc["mau"]
		mau = Color(minf(mau.r, 1.0), minf(mau.g, 1.0), minf(mau.b, 1.0)) * mo
		var w := r.size.x * 0.42
		match id:
			"kiem":
				ci.draw_colored_polygon(PackedVector2Array([tam + Vector2(-w, 6 * k), tam + Vector2(w * 0.8, -10 * k), tam + Vector2(w, -4 * k), tam + Vector2(-w, 14 * k)]), mau)
				ci.draw_rect(Rect2(tam + Vector2(-w - 14 * k, 2 * k), Vector2(16, 16) * k), Color(0.5, 0.5, 0.55) * mo)
			"thuong":
				ci.draw_line(tam + Vector2(-w - 10 * k, 10 * k), tam + Vector2(w + 6 * k, -6 * k), mau, maxf(2.0, 4.0 * k))
				ci.draw_colored_polygon(PackedVector2Array([tam + Vector2(w + 18 * k, -10 * k), tam + Vector2(w, -12 * k), tam + Vector2(w + 2 * k, 0)]), mau)
			_:
				var rr := minf(r.size.y * 0.32, 26.0)
				ci.draw_circle(tam, rr, Color(mau.r, mau.g, mau.b, 0.35 * mau.a))
				ci.draw_arc(tam, rr, 0, TAU, 32, mau, maxf(2.0, 3.0 * k))
				ci.draw_polyline(PackedVector2Array([tam + Vector2(-6, -16) * k, tam + Vector2(4, -2) * k, tam + Vector2(-4, 2) * k, tam + Vector2(6, 16) * k]), Color.WHITE * mo, maxf(2.0, 3.0 * k))
		return
	if id == "khien":
		var pts := PackedVector2Array()
		var rr2 := minf(r.size.x, r.size.y) * 0.42
		for i in 6:
			pts.append(tam + Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * rr2)
		ci.draw_colored_polygon(pts, Color(0.3, 0.7, 1.0, 0.35) * mo)
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(0.5, 0.9, 1.0) * mo, maxf(2.0, 2.5 * k))
		return
	var tep: String = {"ten_lua_loat": "ten_lua", "sung_may_vai": "sung_may"}.get(id, id)
	_vua(ci, anh(tep), r, Color(mo.r * sang, mo.g * sang, mo.b * sang, mo.a))
	var co := maxi(11, int(16 * k))
	if id == "ten_lua_loat":
		ci.draw_string(font, r.position + Vector2(r.size.x - 30 * k, r.size.y - 4 * k), "×6", HORIZONTAL_ALIGNMENT_LEFT, -1, co, MAU_CAM * mo)
	elif id == "sung_may_vai":
		ci.draw_string(font, r.position + Vector2(r.size.x - 40 * k, r.size.y - 4 * k), TranslationServer.translate("VAI"), HORIZONTAL_ALIGNMENT_LEFT, -1, co, MAU_CAM * mo)


## Pháo nhiệt: ba quả sáng bay tỏa ra, kéo vệt cong.
static func _phao_nhiet(ci: CanvasItem, tam: Vector2, k: float, mo: Color) -> void:
	var goc := tam + Vector2(0, 30) * k
	for i in 3:
		var huong := float(i - 1) * 0.75
		var pts := PackedVector2Array()
		for j in 9:
			var t := j / 8.0
			pts.append(goc + Vector2(sin(huong) * 52.0 * t, -48.0 * t + 22.0 * t * t * absf(huong)) * k)
		ci.draw_polyline(pts, Color(1.0, 0.75, 0.35, 0.55) * mo, maxf(2.0, 4.0 * k), true)
		var cuoi: Vector2 = pts[pts.size() - 1]
		ci.draw_circle(cuoi, 9.0 * k, Color(1.0, 0.6, 0.2, 0.45) * mo)
		ci.draw_circle(cuoi, 5.0 * k, Color(1.0, 0.95, 0.7) * mo)
	ci.draw_rect(Rect2(goc + Vector2(-10, 0) * k, Vector2(20, 10) * k), Color(0.55, 0.6, 0.68) * mo)


## Bề rộng biểu tượng phím của một hành động ở tỉ lệ co.
static func rong_nut(font: Font, hanh_dong: String, co := 1.0) -> float:
	if Phim.nut_chuot(hanh_dong) != 0:
		return 34.0 * co
	return maxf(40.0, font.get_string_size(Phim.ten(hanh_dong), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 16.0) * co


## Biểu tượng phím của một hành động: hình chuột (sáng nút đang dùng) hoặc phím chữ. tam: tâm, co: tỉ lệ.
static func nut(ci: CanvasItem, font: Font, hanh_dong: String, tam: Vector2, co := 1.0, mo := Color.WHITE) -> void:
	var nut_c := Phim.nut_chuot(hanh_dong)
	var vien := MAU_PHIM * mo
	var nen := NEN_PHIM * mo
	var day := maxf(1.5, 2.0 * co)
	if nut_c != 0:
		var r := Rect2(tam - Vector2(17, 24) * co, Vector2(34, 48) * co)
		ci.draw_rect(r, nen)
		ci.draw_rect(r, vien, false, day)
		var nua := Rect2(r.position, Vector2(17, 20) * co)
		if nut_c == MOUSE_BUTTON_RIGHT:
			nua.position.x += 17 * co
		if nut_c == MOUSE_BUTTON_LEFT or nut_c == MOUSE_BUTTON_RIGHT:
			ci.draw_rect(nua, MAU_CAM * mo)
		elif nut_c == MOUSE_BUTTON_MIDDLE:
			ci.draw_rect(Rect2(r.position + Vector2(13, 4) * co, Vector2(8, 12) * co), MAU_CAM * mo)
		ci.draw_line(r.position + Vector2(0, 20) * co, r.position + Vector2(34, 20) * co, vien, day)
		ci.draw_line(r.position + Vector2(17, 0) * co, r.position + Vector2(17, 20) * co, vien, day)
		if nut_c != MOUSE_BUTTON_LEFT and nut_c != MOUSE_BUTTON_RIGHT and nut_c != MOUSE_BUTTON_MIDDLE:
			ci.draw_string(font, tam + Vector2(-17, 18) * co, str(nut_c), HORIZONTAL_ALIGNMENT_CENTER, 34 * co, maxi(9, int(13 * co)), vien)
		return
	var chu := Phim.ten(hanh_dong)
	var w := rong_nut(font, hanh_dong, co)
	var r2 := Rect2(tam - Vector2(w * 0.5, 20 * co), Vector2(w, 40 * co))
	ci.draw_rect(r2, nen)
	ci.draw_rect(Rect2(r2.position + Vector2(0, 34 * co), Vector2(w, 6 * co)), Color(0.06, 0.08, 0.12) * mo)
	ci.draw_rect(r2, vien, false, day)
	ci.draw_string(font, r2.position + Vector2(0, 27 * co), chu, HORIZONTAL_ALIGNMENT_CENTER, w, maxi(9, int(20 * co)), Color.WHITE * mo)


## Hai phím bấm cùng nhau (vd. lao chém = lao + cận chiến): "[Shift] + [F]". Trả về bề rộng đã vẽ.
static func nut_ghep(ci: CanvasItem, font: Font, a: String, b: String, trai: Vector2, co := 1.0, mo := Color.WHITE) -> float:
	var wa := rong_nut(font, a, co)
	var wb := rong_nut(font, b, co)
	var cong := 18.0 * co
	nut(ci, font, a, trai + Vector2(wa * 0.5, 0), co, mo)
	ci.draw_string(font, trai + Vector2(wa, 7 * co), "+", HORIZONTAL_ALIGNMENT_CENTER, cong, maxi(10, int(20 * co)), MAU_PHIM * mo)
	nut(ci, font, b, trai + Vector2(wa + cong + wb * 0.5, 0), co, mo)
	return wa + cong + wb


## Dấu nhỏ: ổ khóa (chưa khóa mục tiêu).
static func dau_khoa(ci: CanvasItem, tam: Vector2, co := 1.0, mau := Color(1.0, 0.45, 0.3)) -> void:
	ci.draw_arc(tam + Vector2(0, -3) * co, 5.0 * co, PI, TAU, 12, mau, 2.0 * co)
	ci.draw_rect(Rect2(tam + Vector2(-7, -3) * co, Vector2(14, 11) * co), mau)
	ci.draw_rect(Rect2(tam + Vector2(-1, 0) * co, Vector2(2, 5) * co), Color(0, 0, 0, 0.8))


## Dấu nhỏ: ngọn lửa (quá nhiệt).
static func dau_lua(ci: CanvasItem, tam: Vector2, co := 1.0, mau := Color(1.0, 0.4, 0.25)) -> void:
	ci.draw_colored_polygon(PackedVector2Array([tam + Vector2(0, -10) * co, tam + Vector2(6, -1) * co, tam + Vector2(5, 6) * co,
		tam + Vector2(0, 9) * co, tam + Vector2(-5, 6) * co, tam + Vector2(-6, -1) * co, tam + Vector2(-2, -4) * co]), mau)
	ci.draw_colored_polygon(PackedVector2Array([tam + Vector2(0, -2) * co, tam + Vector2(3, 4) * co, tam + Vector2(0, 7) * co, tam + Vector2(-3, 4) * co]), Color(1, 0.9, 0.5))


## Quạt tối phủ lên ô tròn (HUD): phần ti_le (0..1) còn phải chờ, quét theo chiều kim đồng hồ từ đỉnh.
static func quat_tron(ci: CanvasItem, tam: Vector2, ban_kinh: float, ti_le: float, mau := Color(0, 0, 0, 0.62)) -> void:
	ti_le = clampf(ti_le, 0.0, 1.0)
	if ti_le <= 0.001:
		return
	var a0 := -PI * 0.5 + TAU * (1.0 - ti_le)
	var so := maxi(3, int(ti_le * 40.0))
	var truoc := tam + Vector2.from_angle(a0) * ban_kinh
	for i in range(1, so + 1):
		var p := tam + Vector2.from_angle(lerpf(a0, PI * 1.5, float(i) / so)) * ban_kinh
		ci.draw_colored_polygon(PackedVector2Array([tam, truoc, p]), mau)
		truoc = p
