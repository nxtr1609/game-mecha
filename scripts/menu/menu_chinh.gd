class_name MenuChinh
extends Node3D
## Cảnh menu đầu game: nền 3D (mecha của người chơi đứng trong hangar, xoay chậm) + các màn:
## chính, chuẩn bị trận, mecha & vũ khí, nâng cấp, cài đặt, ghi công.
## Tham số dòng lệnh: --autotest / --quansat → vào thẳng trận; --thu_menu=<thư mục> → tự bấm thử các màn.

const CANH_TRAN := "res://scenes/ban_do_thu.tscn"
const CANH_CHIEN_DICH := "res://scenes/chien_dich.tscn"

var giao_dien: Control
var man: Dictionary = {}           # tên -> Control
var dang_mo := ""
var nhan_cong_trang: Label
var _mecha_trung_bay: Mecha
var _cam: Camera3D
var _goc_xoay := 0.0
var _tai_trang_bi := ""            # tránh dựng lại mecha khi trang bị không đổi
static var mo_lai := ""            # màn cần mở lại sau khi dựng lại menu (đổi ngôn ngữ)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest") or a.begins_with("--quansat"):
			get_tree().change_scene_to_file.call_deferred(CANH_TRAN)
			return
		if a.begins_with("--thu_chien_dich") or a.begins_with("--chup_huong_dan"):
			var i := TienTrinh.nhiem_vu
			for b in OS.get_cmdline_user_args():
				if b.begins_with("--nhiem_vu="):
					i = int(b.get_slice("=", 1))
			if a.begins_with("--chup_huong_dan"):
				i = 0
			TienTrinh.nhiem_vu = i
			get_tree().change_scene_to_file.call_deferred(canh_nhiem_vu(i))
			return
		if a.begins_with("--thu_troi"):
			add_child(ThuTroi.new())
			return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_dung_hangar()
	var lop := CanvasLayer.new()
	add_child(lop)
	giao_dien = Control.new()
	giao_dien.set_anchors_preset(Control.PRESET_FULL_RECT)
	giao_dien.theme = GiaoDien.theme()
	giao_dien.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lop.add_child(giao_dien)
	_thanh_tren()
	man["chinh"] = ManChinh.new()
	man["chien_dich"] = ManChienDich.new()
	man["chuan_bi"] = ManChuanBi.new()
	man["mecha"] = ManMecha.new()
	man["nang_cap"] = ManNangCap.new()
	man["cai_dat"] = ManCaiDat.new()
	man["ghi_cong"] = ManGhiCong.new()
	for k in man:
		var c: Control = man[k]
		c.set("menu", self)
		c.visible = false
		giao_dien.add_child(c)
	mo(mo_lai if mo_lai != "" and man.has(mo_lai) else "chinh")
	mo_lai = ""
	AmThanh.nhac("menu")
	cap_nhat_trung_bay()
	if "--thu_vao_tran" in " ".join(OS.get_cmdline_user_args()) and TienTrinh.so_tran > 0:
		# đã đánh xong một trận và quay về menu: kết thúc phép thử
		await get_tree().create_timer(3.0).timeout
		await RenderingServer.frame_post_draw
		var anh := get_viewport().get_texture().get_image()
		for a2 in OS.get_cmdline_user_args():
			if a2.begins_with("--thu_menu="):
				anh.save_png(a2.get_slice("=", 1).path_join("m12_ve_menu_sau_tran.png"))
		print("[thu_menu] da ve menu sau tran: so tran %d, cong trang %d" % [TienTrinh.so_tran, TienTrinh.cong_trang])
		get_tree().quit()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--thu_menu") and not ThuMenu.da_tao:
			# gắn vào gốc cây để còn sống khi menu được dựng lại (đổi ngôn ngữ)
			ThuMenu.da_tao = true
			var tk := ThuMenu.new()
			tk.thu_muc = a.get_slice("=", 1) if "=" in a else "user://anh_thu_menu"
			get_tree().root.add_child.call_deferred(tk)


## Esc lùi một bước: đóng lớp đè trên cùng (hộp xác nhận, lưu / tải, đổi phím), không có thì quay lại màn trước;
## ở màn chính thì hỏi có thoát game không.
func _unhandled_input(e: InputEvent) -> void:
	if giao_dien == null or not e.is_action_pressed("tha_chuot"):
		return
	get_viewport().set_input_as_handled()
	if GiaoDien.lui_lop_tren(get_tree()):
		return
	if dang_mo != "chinh" and man.has(dang_mo):
		var ve: Variant = (man[dang_mo] as Control).get("quay_lai_toi")
		AmThanh.ui("dong")
		mo(String(ve) if ve != null and man.has(String(ve)) else "chinh")
	else:
		(man["chinh"] as ManChinh).hoi_thoat()


func mo(ten: String) -> void:
	if dang_mo != "" and man.has(dang_mo):
		(man[dang_mo] as Control).visible = false
	dang_mo = ten
	var c: Control = man[ten]
	c.visible = true
	if c.has_method("lam_moi"):
		c.call("lam_moi")
	cap_nhat_cong_trang()
	# màn hạm đội và nâng cấp che kín: dời camera để mecha không bị che dở dang
	_cam_muc = {"chinh": 0, "chuan_bi": 1, "chien_dich": 2, "mecha": 2, "nang_cap": 2, "cai_dat": 2, "ghi_cong": 2}.get(ten, 0)


## Dựng lại toàn bộ menu (sau khi đổi ngôn ngữ), mở lại đúng màn đang xem.
func dung_lai() -> void:
	mo_lai = dang_mo
	get_tree().reload_current_scene()


func cap_nhat_cong_trang() -> void:
	if nhan_cong_trang:
		nhan_cong_trang.text = tr("Điểm công trạng: %d    ·    Trận: %d (thắng %d)") % [TienTrinh.cong_trang, TienTrinh.so_tran, TienTrinh.so_thang]


func _thanh_tren() -> void:
	var h := GiaoDien.hang(16)
	h.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	h.position = Vector2(-900, 14)
	h.size = Vector2(880, 40)
	h.alignment = BoxContainer.ALIGNMENT_END
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nhan_cong_trang = GiaoDien.nhan("", 18, GiaoDien.MAU_VANG)
	h.add_child(nhan_cong_trang)
	# nút ngôn ngữ ở góc trên bên phải: bấm ra danh sách 3 thứ tiếng
	var nn := MenuButton.new()
	nn.name = "nut_ngon_ngu"
	nn.text = "🌐 " + NgonNgu.ten_hien()
	nn.flat = false
	nn.focus_mode = Control.FOCUS_NONE
	nn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nn.add_theme_font_size_override("font_size", 18)
	var pm := nn.get_popup()
	pm.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	pm.add_theme_font_size_override("font_size", 18)
	for i in NgonNgu.DS.size():
		pm.add_radio_check_item(NgonNgu.DS[i][1], i)
		pm.set_item_checked(i, NgonNgu.DS[i][0] == NgonNgu.ngon_ngu)
	pm.id_pressed.connect(func(id: int) -> void: GiaoDien.doi_ngon_ngu(NgonNgu.DS[id][0]))
	h.add_child(nn)
	giao_dien.add_child(h)


func bat_dau_chien_dich(i: int) -> void:
	TienTrinh.nhiem_vu = i
	TienTrinh.luu()
	_man_tai(tr("ĐANG TẢI NHIỆM VỤ..."), tr("Mẹo: bị tên lửa đuổi thì bấm %s phóng pháo nhiệt, hoặc lấy súng máy bắn rơi.") % Phim.ten("phao_nhiet"))
	AmThanh.dung_nhac()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file(canh_nhiem_vu(i))


## Cảnh của một nhiệm vụ chiến dịch (huấn luyện có cảnh riêng).
static func canh_nhiem_vu(i: int) -> String:
	return String(CanBang.CHIEN_DICH[clampi(i, 0, CanBang.CHIEN_DICH.size() - 1)].get("canh", CANH_CHIEN_DICH))


## Màn hình tải: nền tối, chữ lớn, một dòng mẹo.
func _man_tai(tieu_de: String, meo: String) -> void:
	var phu := ColorRect.new()
	phu.color = Color(0.02, 0.03, 0.05, 1.0)
	phu.set_anchors_preset(Control.PRESET_FULL_RECT)
	giao_dien.add_child(phu)
	var l := GiaoDien.nhan(tieu_de, 34, GiaoDien.MAU_NHAN)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(-500, -30)
	l.custom_minimum_size.x = 1000
	phu.add_child(l)
	var g := GiaoDien.nhan(meo, 17, GiaoDien.MAU_MO)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.set_anchors_preset(Control.PRESET_CENTER)
	g.position = Vector2(-600, 30)
	g.custom_minimum_size.x = 1200
	phu.add_child(g)


func bat_dau_tran() -> void:
	TienTrinh.luu()
	var phu := ColorRect.new()
	phu.color = Color(0.02, 0.03, 0.05, 1.0)
	phu.set_anchors_preset(Control.PRESET_FULL_RECT)
	giao_dien.add_child(phu)
	var l := GiaoDien.nhan(tr("ĐANG TẢI TRẬN ĐẤU..."), 34, GiaoDien.MAU_NHAN)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(-200, -30)
	phu.add_child(l)
	var g := GiaoDien.nhan(tr("Mẹo: giữ cứ điểm và chọn mục tiêu cho hạm đội bằng phím Tab để hạ tàu sân bay địch nhanh hơn."), 17, GiaoDien.MAU_MO)
	g.set_anchors_preset(Control.PRESET_CENTER)
	g.position = Vector2(-420, 30)
	phu.add_child(g)
	AmThanh.dung_nhac()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file(CANH_TRAN)


# ---------------------------------------------------------------- nền 3D

var _cam_muc := 0
const _VI_TRI_CAM := [
	[Vector3(-7.0, 7.5, 24.0), Vector3(-5.0, 5.5, 0.0)],     # màn chính: mecha bên phải
	[Vector3(1.0, 7.0, 23.0), Vector3(0.0, 5.2, 0.0)],       # chọn mecha: mecha ở giữa, giữa hai khung
	[Vector3(0.0, 9.0, 34.0), Vector3(0.0, 6.0, 0.0)],
]


func _dung_hangar() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.42, 0.55)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.1, 0.14)
	env.fog_density = 0.012
	we.environment = env
	add_child(we)
	# hangar tối: sương thể tích dày hơn để đèn rọi thành vệt sáng
	DoHoa.ap_moi_truong(we, null, {"suong": 0.03, "mau_suong": Color(0.5, 0.58, 0.7), "bao_hoa": 1.05, "tuong_phan": 1.08}, TienTrinh.cai_dat["do_hoa"])
	# sàn
	var san := StaticBody3D.new()
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(200, 2, 200)
	hinh.shape = hop
	hinh.position.y = -1.0
	san.add_child(hinh)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	var mat := StandardMaterial3D.new()
	var tex := load("res://assets_ngoai/mat_dat/concrete_floor_worn_001_diff_2k.jpg") as Texture2D
	if tex:
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3(12, 12, 1)
	mat.albedo_color = Color(0.45, 0.48, 0.52)
	mat.roughness = 0.6
	mat.metallic = 0.2
	pm.material = mat
	mi.mesh = pm
	san.add_child(mi)
	add_child(san)
	# vòng sáng dưới chân mecha
	var vong := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 7.5
	tm.outer_radius = 8.0
	tm.rings = 64
	var mv := StandardMaterial3D.new()
	mv.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mv.albedo_color = Color(0.4, 0.8, 1.6)
	tm.material = mv
	vong.mesh = tm
	vong.scale = Vector3(1, 0.05, 1)
	vong.position = Vector3(0, 0.05, 0)
	add_child(vong)
	# vài khối hangar phía sau (mẫu Space Kit nếu có)
	for d in [["hangar_largeA", Vector3(-6, 0, -58), PI * 0.5, 16.0], ["hangar_roundA", Vector3(46, 0, -46), -0.5, 9.0],
			["structure_detailed", Vector3(-40, 0, -30), 0.3, 10.0], ["machine_generatorLarge", Vector3(16, 0, -14), -0.4, 5.0],
			["satelliteDish_large", Vector3(30, 0, -24), -0.6, 9.0], ["rocket_baseA", Vector3(-22, 0, -16), 0.0, 5.0]]:
		var duong := "res://assets_ngoai/kenney_space/%s.glb" % d[0]
		if ResourceLoader.exists(duong):
			var n := TaiNguyen.tao(duong, float(d[3]), Color(0.75, 0.78, 0.82))
			add_child(n)
			n.position = d[1]
			n.rotation.y = d[2]
	# đèn
	var den := SpotLight3D.new()
	den.position = Vector3(6, 26, 14)
	den.light_energy = 9.0
	den.spot_range = 60.0
	den.spot_angle = 32.0
	den.shadow_enabled = true
	add_child(den)
	den.look_at(Vector3(0, 4, 0))
	var den2 := OmniLight3D.new()
	den2.position = Vector3(-14, 6, 8)
	den2.light_color = Color(0.4, 0.7, 1.0)
	den2.light_energy = 3.0
	den2.omni_range = 30.0
	add_child(den2)
	var den3 := OmniLight3D.new()
	den3.position = Vector3(12, 4, -6)
	den3.light_color = Color(1.0, 0.55, 0.3)
	den3.light_energy = 2.0
	den3.omni_range = 26.0
	add_child(den3)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	_cam.position = _VI_TRI_CAM[0][0]
	_cam.look_at(_VI_TRI_CAM[0][1])


## Dựng lại mecha trưng bày theo trang bị đang chọn.
func cap_nhat_trung_bay() -> void:
	var tb: Dictionary = TienTrinh.trang_bi
	var khoa := "%s|%s|%s|%s" % [tb["loai"], tb["phai"], tb["trai"], tb["can_chien"]]
	if khoa == _tai_trang_bi and is_instance_valid(_mecha_trung_bay):
		return
	_tai_trang_bi = khoa
	if is_instance_valid(_mecha_trung_bay):
		_mecha_trung_bay.queue_free()
	var m := Mecha.new()
	m.phe = 0
	m.loai = tb["loai"]
	m.vk = {"phai": tb["phai"], "trai": tb["trai"]}
	m.tay_phu = {"trai": tb["tay_phu_trai"], "phai": tb["tay_phu_phai"]}
	m.can_chien = tb["can_chien"]
	m.trung_bay = true
	m.position = Vector3(0, 0.5, 0)
	m.rotation.y = _goc_xoay
	add_child(m)
	_mecha_trung_bay = m


func _process(dt: float) -> void:
	if _cam == null:
		return
	_goc_xoay += dt * 0.25
	if is_instance_valid(_mecha_trung_bay):
		_mecha_trung_bay.dk_huong = _goc_xoay
		_mecha_trung_bay.dk_ngam = _mecha_trung_bay.global_position + Vector3(sin(_goc_xoay) * -40.0, 5.0, cos(_goc_xoay) * -40.0)
	var muc: Array = _VI_TRI_CAM[_cam_muc]
	var k := 1.0 - exp(-dt * 3.0)
	_cam.position = _cam.position.lerp(muc[0], k)
	var nhin: Vector3 = _cam.get_meta("nhin", muc[1])
	nhin = nhin.lerp(muc[1], k)
	_cam.set_meta("nhin", nhin)
	_cam.look_at(nhin)
