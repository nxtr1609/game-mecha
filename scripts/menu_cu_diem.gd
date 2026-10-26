class_name MenuCuDiem
extends Control
## Bảng chọn loại cứ điểm khi phe ta vừa chiếm được. Game tạm dừng cho tới khi chọn.
## Bấm 1 / 2 / 3 hoặc bấm chuột vào ô. Nhiều cứ điểm chiếm cùng lúc thì hỏi lần lượt.

const THU_TU := ["phao_dai", "ten_lua", "hau_can"]

var font: Font
var tu_chon_sau := -1.0            # >= 0: tự chọn ô đầu sau từng ấy giây (chế độ tự kiểm tra)
var _hang: Array[CuDiem] = []
var _dang_hoi: CuDiem = null
var _cho := 0.0
var _o: Array[Rect2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma"])
	font = sf


func hoi(cd: CuDiem) -> void:
	_hang.append(cd)
	if _dang_hoi == null:
		_hoi_tiep()


func _hoi_tiep() -> void:
	while not _hang.is_empty():
		var cd: CuDiem = _hang.pop_front()
		if is_instance_valid(cd) and cd.chu == 0 and cd.loai == "":
			_dang_hoi = cd
			_cho = 0.0
			visible = true
			get_tree().paused = true
			if DisplayServer.get_name() != "headless":
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			queue_redraw()
			return
	_dang_hoi = null
	visible = false
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func chon(i: int) -> void:
	if _dang_hoi == null:
		return
	var cd := _dang_hoi
	_dang_hoi = null
	get_tree().paused = false
	cd.chon_loai(THU_TU[i])
	_hoi_tiep()


func _process(dt: float) -> void:
	size = get_viewport_rect().size
	if _dang_hoi == null:
		return
	_cho += dt
	if tu_chon_sau >= 0.0 and _cho >= tu_chon_sau:
		chon(0)
		return
	queue_redraw()


func _input(e: InputEvent) -> void:
	if _dang_hoi == null:
		return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		var k := (e as InputEventKey).physical_keycode
		if k >= KEY_1 and k <= KEY_3:
			chon(k - KEY_1)
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			chon(0)                                   # Esc: đóng bảng, chọn loại đầu (như khi hết giờ tự chọn)
			get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		for i in _o.size():
			if _o[i].has_point((e as InputEventMouseButton).position):
				chon(i)
				get_viewport().set_input_as_handled()
				return


func _chu(p: Vector2, s: String, co: int, mau: Color, can_giua := false) -> void:
	GiaoDien.ve_chu(self, font, p, s, co, mau, can_giua, 0)


func _draw() -> void:
	if _dang_hoi == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	var c := size * 0.5
	_chu(Vector2(c.x, c.y - 210), tr("ĐÃ CHIẾM CỨ ĐIỂM %s — CHỌN LOẠI XÂY DỰNG") % _dang_hoi.ten, 34, Color(0.6, 0.85, 1.0), true)
	_chu(Vector2(c.x, c.y - 172), tr("Game đang tạm dừng. Bấm 1, 2, 3 hoặc bấm chuột vào ô. Đã chọn thì không đổi được (trừ khi mất rồi chiếm lại)."), 17, Color(1, 1, 1, 0.8), true)
	_o.clear()
	var rong := 420.0
	var cao := 240.0
	var cach := 30.0
	var x0 := c.x - (rong * 3 + cach * 2) * 0.5
	for i in 3:
		var cfg: Dictionary = CanBang.LOAI_CU_DIEM[THU_TU[i]]
		var o := Rect2(Vector2(x0 + i * (rong + cach), c.y - 120), Vector2(rong, cao))
		_o.append(o)
		var tren := o.has_point(get_local_mouse_position())
		draw_rect(o, Color(0.08, 0.12, 0.18, 0.92) if not tren else Color(0.12, 0.2, 0.3, 0.95))
		draw_rect(o, Color(0.5, 0.8, 1.0), false, 2.0)
		_chu(o.position + Vector2(20, 44), "%d   %s" % [i + 1, tr(cfg["ten"])], 26, Color(1, 0.9, 0.5))
		var y := 84.0
		for dong in tr(cfg["mo_ta"]).split("\n"):
			_chu(o.position + Vector2(20, y), dong, 15, Color(1, 1, 1, 0.9))
			y += 24.0
		var so_u := 2 + (cfg["u"] as Array).size()
		_chu(o.position + Vector2(20, cao - 18), tr("Tổng số ụ súng: %d (gồm 2 ụ súng máy cơ bản)") % so_u, 13, Color(0.7, 0.8, 0.9))
