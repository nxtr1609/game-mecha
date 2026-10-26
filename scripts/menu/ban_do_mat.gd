class_name BanDoMat
extends Control
## Bản đồ chiến trường (phím M), game vẫn chạy khi mở. Bắc ở trên (phía căn cứ địch).
## Thấy: vị trí và hướng nhìn của bạn (mũi tên vàng), đồng đội bot (chấm xanh có số) và việc từng con đang làm
## (đường mảnh nối tới cứ điểm nó nhắm, bảng bên phải), cứ điểm (chủ, thanh chiếm, loại), căn cứ, hòm tiếp tế.
## Mecha địch chỉ hiện khi đang quét radar hoặc bạn đã từng khóa nó (Mecha.da_bi_khoa).
## Hàm ve() dùng chung với bản đồ nhỏ góc màn hình (BanDoNho).

var ban_do: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func bat_tat() -> void:
	visible = not visible
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	AmThanh.ui("mo" if visible else "dong")


func _process(_dt: float) -> void:
	size = get_viewport_rect().size
	if visible:
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ban_do") and not get_tree().paused:
		bat_tat()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- vẽ dùng chung

static func _chu(ci: CanvasItem, f: Font, p: Vector2, s: String, co: int, mau: Color, giua := false) -> void:
	GiaoDien.ve_chu(ci, f, p, s, co, mau, giua, 3)


## Mecha địch e có hiện trên bản đồ không: đang quét radar, hoặc người chơi đã từng khóa nó.
static func dich_lo(bd: Node, e: Mecha) -> bool:
	return (bd.ho_tro != null and bd.ho_tro.radar_con > 0.0) or e.da_bi_khoa


## Việc đồng đội bot đang làm: [chữ, màu].
static func viec_bot(e: Mecha, bd: Node) -> Array:
	if not e.song:
		return [String(TranslationServer.translate("bị hạ — chờ hồi sinh")), Color(1, 0.45, 0.4)]
	if e.dang_roi:
		return [String(TranslationServer.translate("đang rơi xuống từ tàu sân bay")), Color(0.6, 0.85, 1.0)]
	var dk := e.dieu_khien as DieuKhienBot
	if dk == null:
		return [String(TranslationServer.translate("đứng yên")), Color(0.8, 0.8, 0.8)]
	if is_instance_valid(dk.muc_tieu) and dk.muc_tieu.song and dk.muc_tieu.global_position.distance_to(e.global_position) < dk.tam_giao_tranh + 60.0:
		return [String(TranslationServer.translate("giao chiến với %s (%d m)")) % [dk.muc_tieu.ten, int(dk.muc_tieu.global_position.distance_to(e.global_position))], Color(1, 0.6, 0.35)]
	var cd: CuDiem = dk.cu_diem_muc
	if cd == null:
		return [String(TranslationServer.translate("chờ ở căn cứ")), Color(0.8, 0.8, 0.8)]
	if dk.ban_tia:
		return [String(TranslationServer.translate("bắn tỉa canh cứ điểm %s")) % cd.ten, Color(0.75, 0.9, 1.0)]
	if cd.trong_vong(e.global_position):
		var phe := e.phe
		if cd.co_mat[1 - phe] > 0:
			return [String(TranslationServer.translate("tranh chấp cứ điểm %s")) % cd.ten, Color(1, 0.85, 0.3)]
		if cd.chu == phe and absf(cd.thanh) >= 0.999:
			return [String(TranslationServer.translate("giữ cứ điểm %s")) % cd.ten, Color(0.55, 0.85, 1.0)]
		return [String(TranslationServer.translate("đang chiếm cứ điểm %s (%d%%)")) % [cd.ten, int(absf(cd.thanh) * 100.0)], Color(0.55, 0.85, 1.0)]
	return [String(TranslationServer.translate("đang tới cứ điểm %s — %d m")) % [cd.ten, int(cd.global_position.distance_to(e.global_position))], Color(0.85, 0.9, 1.0)]


## Đồng đội bot của người chơi (gồm cả mecha tiếp viện), theo thứ tự cố định.
static func dong_doi(bd: Node) -> Array:
	var ds: Array = []
	for b in bd.dong_doi:
		if is_instance_valid(b):
			ds.append(b)
	for n in bd.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e and e != bd.nguoi_choi and e.phe == bd.nguoi_choi.phe and not ds.has(e):
			ds.append(e)
	return ds


## Vẽ bản đồ vào khung (gọi trong _draw của ci). tam: điểm (x, z) nằm giữa khung; px_m: số px mỗi mét.
## day_du: bản đồ lớn (có chữ, đường nối tới cứ điểm); không thì bản đồ nhỏ (gọn).
static func ve(ci: CanvasItem, bd: Node, khung: Rect2, tam: Vector2, px_m: float, day_du: bool, f: Font) -> void:
	var giua := khung.get_center()
	var doi := func(p: Vector3) -> Vector2: return giua + (Vector2(p.x, p.z) - tam) * px_m
	if bd.anh_ban_do:
		ci.draw_texture_rect(bd.anh_ban_do, Rect2(giua + (Vector2(-1600, -1600) - tam) * px_m, Vector2(3200, 3200) * px_m), false)
	var m: Mecha = bd.nguoi_choi
	var co := 15 if day_du else 11
	var t := Time.get_ticks_msec() / 1000.0
	# căn cứ hai phe (chế độ cứ điểm)
	for phe in (2 if bd.get("che_do") == "cu_diem" else 0):
		var p: Vector2 = doi.call(bd.CAN_CU[phe])
		var mau: Color = CuDiem.MAU_PHE[phe]
		var r := maxf(5.0, 110.0 * px_m)
		ci.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color(mau.r, mau.g, mau.b, 0.25))
		ci.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), mau, false, 2.0)
		if day_du:
			_chu(ci, f, p + Vector2(0, r + 18), String(TranslationServer.translate("CĂN CỨ TA")) if phe == m.phe else String(TranslationServer.translate("CĂN CỨ ĐỊCH")), 14, mau, true)
	# cứ điểm: vòng màu chủ, cung ngoài là thanh chiếm, chữ cái ở giữa
	var viet := {"phao_dai": String(TranslationServer.translate("Pháo đài")), "ten_lua": String(TranslationServer.translate("Trạm tên lửa")), "hau_can": String(TranslationServer.translate("Trạm hậu cần"))}
	for x in bd.cu_diem:
		var cd: CuDiem = x
		var p: Vector2 = doi.call(cd.global_position)
		var mau: Color = CuDiem.MAU_TRUNG_LAP if cd.chu < 0 else CuDiem.MAU_PHE[cd.chu]
		var r := maxf(8.0 if not day_du else 11.0, float(CanBang.CU_DIEM["ban_kinh"]) * px_m)
		var nen := Color(mau.r, mau.g, mau.b, 0.3)
		if cd.co_mat[0] > 0 and cd.co_mat[1] > 0 and fmod(t, 0.6) < 0.3:
			nen = Color(1, 1, 1, 0.45)
		ci.draw_circle(p, r, nen)
		ci.draw_arc(p, r, 0, TAU, 32, mau, 2.0)
		if absf(cd.thanh) > 0.01:
			ci.draw_arc(p, r + 3.0, -PI * 0.5, -PI * 0.5 + TAU * absf(cd.thanh), 32, CuDiem.MAU_PHE[0 if cd.thanh >= 0.0 else 1], 3.0)
		_chu(ci, f, p + Vector2(0, co * 0.4), cd.ten, co + 3, Color.WHITE, true)
		if day_du and cd.chu >= 0:
			_chu(ci, f, p + Vector2(0, r + 18), viet.get(cd.loai, String(TranslationServer.translate("đang chọn loại"))) + (String(TranslationServer.translate("  ▲ đang xây")) if cd.dang_xay else ""), 13, mau, true)
	# hòm tiếp tế
	for n in ci.get_tree().get_nodes_in_group("thung_tiep_te"):
		var th := n as ThungTiepTe
		if th and th.da_dap:
			var p: Vector2 = doi.call(th.global_position)
			ci.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(0.4, 1.0, 0.55))
	# chiến dịch: mục tiêu nhiệm vụ (dấu cam)
	var hud_bd = bd.get("hud")
	if hud_bd and bd.get("che_do") == "chien_dich":
		for x in hud_bd.danh_dau:
			if not is_instance_valid(x[0]) or x[0].get("song") == false:
				continue
			var n: Node3D = x[0]
			var p: Vector2 = doi.call(n.global_position)
			var s := 7.0 if day_du else 5.0
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s, 0), p + Vector2(0, s), p + Vector2(-s, 0)]), Color(1, 0.7, 0.25))
			if day_du and String(x[1]) != "":
				_chu(ci, f, p + Vector2(0, -10), x[1], 12, Color(1, 0.75, 0.35), true)
	# mecha địch bị lộ
	for n in ci.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or not e.song or e.phe == m.phe or not dich_lo(bd, e):
			continue
		var p: Vector2 = doi.call(e.global_position)
		var s := 6.0 if day_du else 5.0
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s, 0), p + Vector2(0, s), p + Vector2(-s, 0)]), Color(1, 0.3, 0.22))
	# đồng đội: chấm xanh có số; bản đồ lớn có đường mảnh nối tới cứ điểm đang nhắm
	var ds := dong_doi(bd)
	for i in ds.size():
		var e: Mecha = ds[i]
		var p: Vector2 = doi.call(e.global_position)
		var dk := e.dieu_khien as DieuKhienBot
		if day_du and e.song and dk and dk.cu_diem_muc:
			ci.draw_dashed_line(p, doi.call(dk.cu_diem_muc.global_position), Color(0.5, 0.8, 1.0, 0.45), 1.5, 6.0)
		var mau := Color(0.45, 0.75, 1.0) if e.song else Color(0.45, 0.5, 0.6, 0.7)
		var r := 7.0 if day_du else 5.0
		ci.draw_circle(p, r, Color(0, 0, 0, 0.6))
		ci.draw_circle(p, r - 1.5, mau)
		if day_du:
			_chu(ci, f, p + Vector2(0, 5), "TV" if e.has_meta("tiep_vien") else str(i + 1), 12, Color(0.02, 0.05, 0.1), true)
			if not e.song:
				ci.draw_line(p - Vector2(5, 5), p + Vector2(5, 5), Color(1, 0.4, 0.35), 2.0)
	# bạn: mũi tên vàng theo hướng camera
	var yaw: float = bd.cam.yaw if bd.cam else m.rotation.y
	var huong := Vector2(-sin(yaw), -cos(yaw))
	var pm: Vector2 = doi.call(m.global_position)
	var dai := 13.0 if day_du else 10.0
	var mui := PackedVector2Array([pm + huong * dai, pm + huong.rotated(2.5) * dai * 0.7, pm - huong * dai * 0.25, pm + huong.rotated(-2.5) * dai * 0.7])
	ci.draw_colored_polygon(mui, Color(1.0, 0.86, 0.2) if m.song else Color(0.6, 0.55, 0.4))
	ci.draw_polyline(mui + PackedVector2Array([mui[0]]), Color(0, 0, 0, 0.8), 1.5)
	if day_du:
		_chu(ci, f, pm + Vector2(0, -16), String(TranslationServer.translate("BẠN")), 13, Color(1.0, 0.86, 0.2), true)


# ---------------------------------------------------------------- bản đồ lớn

func _draw() -> void:
	if ban_do == null or not is_instance_valid(ban_do.nguoi_choi):
		return
	var f := GiaoDien.font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.04, 0.94))
	var canh := minf(size.y - 130.0, size.x * 0.6)
	var khung := Rect2(Vector2(40, 90), Vector2(canh, canh))
	draw_rect(khung.grow(4), Color(0.05, 0.08, 0.12))
	ve(self, ban_do, khung, Vector2.ZERO, canh / 3200.0, true, f)
	draw_rect(khung.grow(4), Color(0.5, 0.65, 0.85), false, 2.0)
	var ten_bd: String = tr(CanBang.BAN_DO.get(ban_do.kieu_ban_do, {"ten": ""})["ten"])
	_chu(self, f, Vector2(40, 52), tr("BẢN ĐỒ CHIẾN TRƯỜNG — %s") % ten_bd.to_upper(), 26, Color(0.85, 0.93, 1.0))
	_chu(self, f, Vector2(khung.get_center().x, khung.position.y - 10), tr("▲ phía địch (bắc)"), 13, Color(1, 0.6, 0.5), true)
	_chu(self, f, Vector2(khung.get_center().x, khung.end.y + 24), tr("▼ phía ta (nam)"), 13, Color(0.6, 0.8, 1.0), true)
	# bảng bên phải: bạn, đồng đội, chú thích
	var x0 := khung.end.x + 40.0
	var y := 120.0
	var m: Mecha = ban_do.nguoi_choi
	_chu(self, f, Vector2(x0, y), tr("BẠN"), 20, Color(1.0, 0.86, 0.2))
	y += 26.0
	var ten_loai: String = tr(CanBang.LOAI_MECHA.get(m.loai, {"ten": m.loai})["ten"])
	var gan := ""
	var kc_gan := INF
	for x in ban_do.cu_diem:
		var kc := (x as CuDiem).global_position.distance_to(m.global_position)
		if kc < kc_gan:
			kc_gan = kc
			gan = (x as CuDiem).ten
	var tt_ban := (tr("giáp %d%% · cách cứ điểm %s %d m") % [int(100.0 * m.mau / float(m.cs["mau"])), gan, int(kc_gan)]) if m.song else tr("bị hạ — chờ hồi sinh")
	_chu(self, f, Vector2(x0, y), "%s · %s" % [ten_loai, tt_ban], 16, Color(1, 1, 1, 0.9))
	y += 40.0
	_chu(self, f, Vector2(x0, y), tr("ĐỒNG ĐỘI"), 20, Color(0.55, 0.8, 1.0))
	y += 28.0
	var ds := dong_doi(ban_do)
	if ds.is_empty():
		_chu(self, f, Vector2(x0, y), tr("(không có)"), 16, Color(1, 1, 1, 0.6))
		y += 24.0
	for i in ds.size():
		var e: Mecha = ds[i]
		var so := "TV" if e.has_meta("tiep_vien") else str(i + 1)
		var lt: String = tr(CanBang.LOAI_MECHA.get(e.loai, {"ten": e.loai})["ten"])
		var giap := "%d%%" % int(100.0 * maxf(0.0, e.mau) / float(e.cs["mau"])) if e.song else "—"
		_chu(self, f, Vector2(x0, y), tr("%s. %s (%s) · giáp %s") % [so, e.ten, lt, giap], 16, Color(1, 1, 1, 0.9))
		y += 21.0
		var v: Array = viec_bot(e, ban_do)
		_chu(self, f, Vector2(x0 + 22, y), v[0], 15, v[1])
		y += 27.0
	y += 14.0
	var dong := [
		[tr("Mũi tên vàng: bạn và hướng đang nhìn"), Color(1.0, 0.86, 0.2)],
		[tr("Chấm xanh có số: đồng đội · nét đứt: cứ điểm nó đang tới"), Color(0.55, 0.8, 1.0)],
		[tr("Hình thoi đỏ: mecha địch bạn đã khóa (quét radar thì thấy hết)"), Color(1, 0.45, 0.4)],
		[tr("Vòng tròn: cứ điểm (màu chủ), cung ngoài: thanh chiếm"), Color(1, 1, 1, 0.8)],
		[tr("Ô vuông xanh lá: hòm tiếp tế"), Color(0.4, 1.0, 0.55)],
	]
	for d in dong:
		_chu(self, f, Vector2(x0, y), d[0], 14, d[1])
		y += 21.0
	y += 14.0
	var tt = ban_do.get("tran_troi")
	if tt:
		_chu(self, f, Vector2(x0, y), tr("Tàu sân bay ta %d%% · tàu sân bay địch %d%% · còn %d:%02d") % [int(tt.ti_le_san_bay(0) * 100), int(tt.ti_le_san_bay(1) * 100),
			int(ban_do.thoi_gian_con) / 60, int(ban_do.thoi_gian_con) % 60], 15, Color(1, 1, 1, 0.85))
	elif ban_do.get("hud"):
		for dong_nv in ban_do.hud.nhiem_vu:
			_chu(self, f, Vector2(x0, y), String(dong_nv), 15, Color(1, 0.85, 0.6))
			y += 21.0
	y += 30.0
	_chu(self, f, Vector2(x0, y), tr("M / Esc: đóng bản đồ (game vẫn đang chạy)"), 15, Color(1, 1, 1, 0.6))
