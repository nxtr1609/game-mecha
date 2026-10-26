class_name TranChienDich
extends BanDoThu
## Một nhiệm vụ chiến dịch (đi một mình, kiểu Iron Valiant): người chơi đi trên bản đồ rộng, đánh mecha địch
## tuần tra / đi săn / phục kích và ụ súng địch theo mục tiêu nhiệm vụ (CanBang.CHIEN_DICH).
## Dùng lại cảnh và giao diện của BanDoThu (bản đồ 3,2 km). Nhiệm vụ huấn luyện là lớp con riêng (TranHuanLuyen, bãi tập).
## Có CanBang.CHIEN_DICH_HOI_SINH lần hồi sinh; hết lượt là thất bại. Bảng trang bị B mở ở đâu cũng được.
## Địch chỉ đánh khi đã phát hiện người chơi; số địch tấn công cùng lúc theo độ khó (CanBang.DO_KHO[..]["tan_cong_cung_luc"]).
## Mecha địch chỉ được đánh dấu (HUD, bản đồ) sau khi người chơi đã khóa nó (Mecha.da_bi_khoa).
## --thu_chien_dich=<thư mục>: máy tự chơi nhiệm vụ đang chọn, in kết quả rồi thoát (tham số --nhiem_vu=<số>).

var nv: Dictionary
var chi_so_nv := 0
var dich: Array[Mecha] = []
var dot2: Array = []               # [loại, ...] mecha đợt hai chưa thả
var u_dich: Array[USung] = []
var chi_huy: Mecha = null
var diem_den: Array = []           # Node3D các điểm phải tới (phục kích)
var diem_den_toi := 0              # đã tới bao nhiêu điểm
var luot_hoi_sinh := 2
var so_chet := 0
var diem_xuat_phat := Vector3.ZERO
var dem_gio := false               # HUD: không hiện đồng hồ đếm ngược
var _t_nv := 0.0                   # thời gian đã chơi nhiệm vụ
var _thu_muc := ""
var _tu_choi := false
var _gioi_han := 600.0             # máy tự chơi: dừng sau bấy nhiêu giây (--thoi_gian=)
var luot_tan_cong := LuotTanCong.new()     # giới hạn số địch tấn công cùng lúc (theo độ khó)


func _doc_cau_hinh() -> void:
	che_do = "chien_dich"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nhiem_vu="):
			TienTrinh.nhiem_vu = clampi(int(a.get_slice("=", 1)), 0, CanBang.CHIEN_DICH.size() - 1)
		elif a.begins_with("--thoi_gian="):
			_gioi_han = float(a.get_slice("=", 1))
		elif a.begins_with("--thu_chien_dich"):
			_tu_choi = true
			_thu_muc = a.get_slice("=", 1) if "=" in a else "user://anh_chien_dich"
	do_kho = TienTrinh.cau_hinh_tran.get("do_kho", "thuong")
	if not CanBang.DO_KHO.has(do_kho):
		do_kho = "thuong"
	luot_tan_cong.so_toi_da = int(CanBang.DO_KHO[do_kho]["tan_cong_cung_luc"])
	chi_so_nv = TienTrinh.nhiem_vu
	nv = CanBang.CHIEN_DICH[chi_so_nv]
	TienTrinh.dang_nhiem_vu = chi_so_nv           # lưu giữa nhiệm vụ: tải lại thì chơi lại nhiệm vụ này
	TienTrinh.luu()
	kieu_ban_do = nv["ban_do"]
	luot_hoi_sinh = CanBang.CHIEN_DICH_HOI_SINH
	cho_ket_thuc = true


func _vi_tri(x: float, z: float) -> Vector3:
	return Vector3(x, chieu_cao(x, z) + 1.0, z)


func _bat_dau() -> void:
	var bd: Array = nv["bat_dau"]
	diem_xuat_phat = _vi_tri(bd[0], bd[1])
	_tao_nguoi_choi(diem_xuat_phat, 0.0)
	# mecha địch
	for d in nv["dich"]:
		var kieu: String = d[3]
		if kieu.begins_with("dot2"):
			dot2.append(d)
			continue
		_tao_dich(d, _vi_tri(d[1], d[2]))
	# ụ súng địch
	for u in nv.get("u", []):
		_tao_u(u[0], Vector3(u[1], chieu_cao(u[1], u[2]), u[2]))
	# điểm phải đi qua (phục kích)
	for p in nv.get("diem_den", []):
		var n := Node3D.new()
		n.name = "diem_den_%d" % diem_den.size()
		add_child(n)
		n.global_position = _vi_tri(p[0], p[1])
		diem_den.append(n)
	_dung_giao_dien()
	_cap_nhat_danh_dau()
	hud.thong_bao(tr("NHIỆM VỤ: %s") % tr(nv["ten"]))
	hud.thong_bao(tr(nv["mo_ta"]))
	AmThanh.nhac("tran")
	if _tu_choi:
		var bk := DieuKhienBot.new()
		bk.san_lung = true
		bk.danh_cong_trinh = true
		bk.p_ne = 0.6
		bk.p_do = 0.15
		add_child(bk)
		nguoi_choi.dieu_khien = bk
		DirAccess.make_dir_recursive_absolute(_thu_muc)
	elif DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _tao_dich(d: Array, vi_tri: Vector3) -> Mecha:
	var loai: String = d[0]
	var kieu: String = d[3]
	var ten_m := "%s · %s" % [tr("Đế Chế"), tr(CanBang.LOAI_MECHA[loai]["ten"])]
	if kieu == "chi_huy":
		ten_m = tr("Chỉ huy Đế Chế")
	var b := _tao_bot_loai(1, loai, ten_m, vi_tri)
	b.rotation.y = PI
	b.dk_huong = PI
	b.he_so_sat_thuong = float(nv["sat_thuong_dich"]) * float(b.cs["he_so_hoa_luc"])
	b.he_so_can_chien = CanBang.BOT["he_so_can_chien"]
	b.he_so_mau = float(nv["mau_dich"])
	var bk := b.dieu_khien as DieuKhienBot
	bk.ban_do = null
	bk.dieu_phoi = luot_tan_cong
	bk.ban_tia = kieu.ends_with("_ban_tia")
	bk.tuan_tra = true
	if kieu.begins_with("tuan_tra") or kieu == "chi_huy":
		bk.tam_phat_hien = CanBang.CHIEN_DICH_PHAT_HIEN["tuan_tra"] * (2.0 if bk.ban_tia else 1.0)
	elif kieu.begins_with("phuc_kich"):
		bk.tam_phat_hien = CanBang.CHIEN_DICH_PHAT_HIEN["phuc_kich"]
	else:
		# đội săn, đợt hai: đi tuần khắp vùng, phát hiện thì mới lao vào
		bk.lang_thang = true
		bk.tam_phat_hien = CanBang.CHIEN_DICH_PHAT_HIEN["san"] * (2.0 if bk.ban_tia else 1.0)
	bk.diem_canh = vi_tri
	if kieu == "chi_huy":
		var C: Dictionary = CanBang.CHIEN_DICH_CHI_HUY
		b.he_so_mau = float(nv["mau_dich"]) * float(C["he_so_mau"])
		bk.p_ne = C["p_ne"]
		bk.p_do = C["p_do"]
		bk.hay_lao_chem = C["hay_lao_chem"]
		chi_huy = b
	b.mau = b.mau_toi_da()
	dich.append(b)
	bots.append(b)
	return b


func _tao_u(loai_u: String, vi_tri: Vector3) -> void:
	var u := USung.new()
	u.loai = loai_u
	u.phe = 1
	u.tam_phat_hien = 420.0
	u.he_so_sat_thuong = float(nv["sat_thuong_dich"])
	add_child(u)
	u.global_position = vi_tri
	u.xay(0.2)
	u.bi_pha.connect(func(_x: USung) -> void:
		hud.thong_bao(tr("Đã phá một %s") % tr(u.ten_hien))
		_kiem_thang())
	u_dich.append(u)


## Dấu cam trên HUD / bản đồ: mục tiêu nhiệm vụ còn lại.
func _cap_nhat_danh_dau() -> void:
	var ds: Array = []
	if diem_den_toi < diem_den.size():
		ds.append([diem_den[diem_den_toi], tr("Điểm %d/%d") % [diem_den_toi + 1, diem_den.size()]])
	match nv["muc_tieu"]:
		"pha_u":
			for u in u_dich:
				if is_instance_valid(u) and u.song:
					ds.append([u, tr("Ụ")])
		"chi_huy":
			if is_instance_valid(chi_huy) and chi_huy.song:
				ds.append([chi_huy, tr("Chỉ huy")])
		_:
			for e in dich:
				if is_instance_valid(e) and e.song and e.da_bi_khoa:
					ds.append([e, ""])
			for u in u_dich:
				if is_instance_valid(u) and u.song:
					ds.append([u, tr("Ụ")])
	hud.danh_dau = ds


func _con_lai() -> Array:
	var me := 0
	for e in dich:
		if is_instance_valid(e) and e.song:
			me += 1
	me += dot2.size()
	var ut := 0
	for u in u_dich:
		if is_instance_valid(u) and u.song:
			ut += 1
	return [me, ut]


func _process(dt: float) -> void:
	if _thoi_tiet:
		var c := get_viewport().get_camera_3d()
		if c:
			_thoi_tiet.global_position = c.global_position
	if da_ket_thuc or get_tree().paused or hud == null:
		return
	_t_nv += dt
	var cl := _con_lai()
	var dong := ""
	match nv["muc_tieu"]:
		"pha_u":
			dong = tr("Phá hết ụ tên lửa — còn %d") % cl[1]
		"chi_huy":
			dong = tr("Hạ mecha chỉ huy Đế Chế")
		_:
			dong = tr("Hạ hết địch — còn %d mecha") % cl[0] + ((tr(", %d ụ") % cl[1]) if cl[1] > 0 else "")
	if diem_den_toi < diem_den.size():
		dong = tr("Tới điểm %d/%d") % [diem_den_toi + 1, diem_den.size()] + " · " + dong
	hud.nhiem_vu = [tr(nv["ten"]).to_upper(), dong, "%s   ·   %s" % [tr("hồi sinh còn %d") % luot_hoi_sinh, _dong_ho(_t_nv)]]
	# đợt hai: thả khi đợt đầu bị hạ hết
	if not dot2.is_empty() and cl[0] == dot2.size() and nguoi_choi.song:
		_tha_dot2()
	# điểm phải tới
	if diem_den_toi < diem_den.size() and nguoi_choi.song:
		var dd: Node3D = diem_den[diem_den_toi]
		if Vector2(dd.global_position.x - nguoi_choi.global_position.x, dd.global_position.z - nguoi_choi.global_position.z).length() < 90.0:
			diem_den_toi += 1
			diem_xuat_phat = dd.global_position
			hud.thong_bao(tr("Đã tới điểm %d/%d") % [diem_den_toi, diem_den.size()])
	_cap_nhat_danh_dau()
	if _tu_choi:
		if int(_t_nv / 20.0) != int((_t_nv - dt) / 20.0):
			_chup_thu("cd_%d_%03d" % [chi_so_nv, int(_t_nv)])
		if _t_nv > _gioi_han:
			ket_thuc(-1, tr("Hết giờ thử"))


func _tha_dot2() -> void:
	hud.thong_bao(tr("ĐỢT HAI: mecha Đế Chế đang rơi xuống!"))
	var i := 0
	for d in dot2:
		var g := randf() * TAU
		var p := nguoi_choi.global_position + Vector3(cos(g), 0, sin(g)) * (380.0 + 60.0 * i)
		p.x = clampf(p.x, -1400.0, 1400.0)
		p.z = clampf(p.z, -1400.0, 1400.0)
		var b := _tao_dich(d, _vi_tri(p.x, p.z))
		b.hoi_sinh(_cho_dap_trong(_vi_tri(p.x, p.z)))
		i += 1
	dot2.clear()


func _chup_thu(ten: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_thu_muc.path_join(ten + ".png"))
	print("[chien_dich] %s: con %s, nguoi mau %d, chet %d" % [ten, str(_con_lai()), int(nguoi_choi.mau), so_chet])


static func _dong_ho(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _kiem_thang() -> void:
	if da_ket_thuc:
		return
	var cl := _con_lai()
	match nv["muc_tieu"]:
		"pha_u":
			if cl[1] == 0:
				ket_thuc(1, tr("Đã phá hết ụ tên lửa."))
		"chi_huy":
			if is_instance_valid(chi_huy) and not chi_huy.song:
				ket_thuc(1, tr("Mecha chỉ huy Đế Chế đã bị hạ."))
		_:
			if cl[0] == 0 and cl[1] == 0:          # điểm đến chỉ để dẫn đường, hạ hết địch là xong
				ket_thuc(1, tr("Đã hạ hết địch."))


func _khi_bi_ha(m: Mecha) -> void:
	if m.phe != nguoi_choi.phe:
		hud.bao_ha()
		if m.ke_tan_cong == nguoi_choi or (m.ke_tan_cong is UMinigun and (m.ke_tan_cong as UMinigun).chu == nguoi_choi):
			so_ha += 1
		_kiem_thang()
		return
	if m != nguoi_choi:
		return
	so_chet += 1
	if luot_hoi_sinh <= 0:
		await get_tree().create_timer(1.5).timeout
		ket_thuc(-1, tr("Mecha của bạn bị hạ, hết lượt hồi sinh."))
		return
	luot_hoi_sinh -= 1
	hoi_sinh_con = 3.0
	while hoi_sinh_con > 0.0:
		await get_tree().process_frame
		if not get_tree().paused:
			hoi_sinh_con -= get_process_delta_time()
	hoi_sinh_con = 0.0
	if da_ket_thuc:
		return
	m.hoi_sinh(_cho_dap_trong(diem_xuat_phat))
	if DisplayServer.get_name() != "headless" and not get_tree().paused and not _tu_choi:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func diem_hoi_sinh(_phe: int) -> Array:
	return [["Điểm xuất phát", diem_xuat_phat]]


func can_cu(phe: int) -> Vector3:
	return diem_xuat_phat if phe == 0 else Vector3(0, 0, -99999)


## Chiến dịch: bảng trang bị mở ở đâu cũng được.
func co_the_doi_sung(_m: Mecha) -> bool:
	return true


func mo_trang_bi() -> void:
	if bang_trang_bi and not dang_mo_bang() and Time.get_ticks_msec() - bang_trang_bi.t_dong > 300:
		bang_trang_bi.mo()


func ket_thuc(thang: int, ly_do: String) -> void:
	if da_ket_thuc:
		return
	da_ket_thuc = true
	var diem := TienTrinh.ghi_ket_qua_chien_dich(chi_so_nv, thang > 0)
	TienTrinh.ket_qua = {"che_do": "chien_dich", "nhiem_vu": chi_so_nv, "thang": thang, "ly_do": ly_do, "thoi_gian": _t_nv,
		"so_ha": so_ha, "so_chet": so_chet, "thuong": diem}
	print("[chien_dich] %s: %s sau %.0f s, chet %d lan, ha %d" % [nv["id"], "THANG" if thang > 0 else "THUA", _t_nv, so_chet, so_ha])
	if _tu_choi:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_thu_muc.path_join("cd_%d_ket_thuc.png" % chi_so_nv))
		get_tree().quit()
		return
	AmThanh.nhac("thang" if thang > 0 else "thua", false)
	var kq := ManKetQua.new()
	kq.ban_do = self
	var lop := CanvasLayer.new()
	lop.layer = 9
	lop.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lop)
	lop.add_child(kq)
	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Vào một nhiệm vụ (chơi lại / nhiệm vụ kế tiếp).
func choi_nhiem_vu(i: int) -> void:
	get_tree().paused = false
	TienTrinh.nhiem_vu = i
	TienTrinh.luu()
	get_tree().change_scene_to_file(MenuChinh.canh_nhiem_vu(i))

