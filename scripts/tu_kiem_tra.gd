class_name TuKiemTra
extends Node
## Tự chơi thử để kiểm tra (chỉ chạy khi có tham số --autotest): đặt lệnh như bấm phím, đo kết quả từng cơ chế,
## chụp ảnh màn hình, in "[kiem] DAT / KHONG DAT" và tổng kết rồi thoát.
## --quansat=<giây>: chỉ đứng xem bot hai phe tự đánh / chiếm cứ điểm, in tình hình và FPS mỗi 10 giây.
## --chup_ban_do: chụp bản đồ từ trên cao và vài góc dưới đất.

var ban_do: Node
var thu_muc := "user://anh_thu"
var quan_sat := 0.0
var _ket_qua: Array = []
var nguoi: Mecha


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(thu_muc)
	ban_do.ho_tro.dch = 99999                  # tự kiểm tra: đủ Điểm Chỉ Huy để gọi mọi hỗ trợ
	nguoi = ban_do.nguoi_choi
	if quan_sat > 0.0:
		_quan_sat()
	elif "--chup_ban_do" in " ".join(OS.get_cmdline_user_args()):
		await _cho(3.0)
		ban_do.dat_cu_diem(false)
		await _chup_ban_do()
		get_tree().quit()
	else:
		_chay()


func _cho(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _chup(ten: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(thu_muc.path_join(ten + ".png"))


func _ghi(ten: String, dat: bool, chi_tiet: String) -> void:
	_ket_qua.append([ten, dat, chi_tiet])
	print("[kiem] %s %s — %s" % ["DAT" if dat else "KHONG DAT", ten, chi_tiet])


func _y(x: float, z: float) -> float:
	return ban_do.dia_hinh.chieu_cao(x, z)


## Đặt một mecha đứng ngay tại (x, z), nhìn theo hướng huong, xóa mọi lệnh.
func _dat(m: Mecha, x: float, z: float, huong := 0.0) -> void:
	if not m.song:
		m.hoi_sinh(Vector3(x, _y(x, z), z))
	m.dat_ngay(Vector3(x, _y(x, z) + 1.0, z))
	m.bat_tu_con = 0.0
	m.mau = m.mau_toi_da()
	m.nhiet = 0.0
	m.qua_nhiet = false
	m.giu_do_cao = false
	m.choang_con = 0.0
	m._cc = {}
	m.di_bo = false
	m.rotation.y = huong
	m.dk_huong = huong
	m.dk_di = Vector2.ZERO
	m.dk_bay = false
	m.dk_ban = {"phai": false, "trai": false}
	m.khoa = null
	m.muc_tieu_ban = null
	m.dk_ngam = m.tam_than() + Vector3(-sin(huong), 0, -cos(huong)) * 300.0
	if m == nguoi:
		ban_do.cam.yaw = huong
		ban_do.cam.pitch = -0.12


func _xoa_ten_lua() -> void:
	for n in get_tree().get_nodes_in_group("ten_lua"):
		n.queue_free()


## Phóng n tên lửa từ điểm `tu` vào mục tiêu (như ụ tên lửa địch).
func _phong_vao(muc: Mecha, tu: Vector3, n := 2) -> void:
	for k in n:
		var tl := TenLua.new()
		tl.phe = 1 - muc.phe
		tl.muc_tieu = muc
		tl.toc_do = 120.0
		tl.quay = 1.7
		tl.sat_thuong = 170.0
		get_tree().current_scene.add_child(tl)
		tl.global_position = tu + Vector3(k * 3.0, 0, 0)
		tl.huong = (Vector3.UP + (muc.global_position - tu).normalized()).normalized()


func _chay() -> void:
	var bot: Mecha = ban_do.bots[0]
	ban_do.dat_cu_diem(false)               # tắt luật chiếm cứ điểm khi thử các phần khác
	ban_do.menu.tu_chon_sau = 2.0
	nguoi.dieu_khien = null
	for b in ban_do.bots + ban_do.dong_doi:
		(b as Mecha).dieu_khien = null
	await _cho(2.5)
	var X := 0.0
	var Z := 1100.0
	_dat(nguoi, X, Z)
	await _cho(0.8)
	await _chup("01_bat_dau")

	# ---- 1. nhiệt: bật lao liên tục tới quá nhiệt; quá nhiệt không lao / bay được; nguội hết thì dùng lại
	var so_lao := 0
	while not nguoi.qua_nhiet and so_lao < 14:
		nguoi.dk_di = Vector2(1 if so_lao % 2 == 0 else -1, 0)
		nguoi.dk_lao = true
		so_lao += 1
		await _cho(0.5)
	await _chup("02_qua_nhiet")
	var t0 := Mecha.gio()
	nguoi.dk_lao = true
	nguoi.dk_bay = true
	nguoi.dk_di = Vector2(0, 1)
	await _cho(0.6)
	var y_bay := nguoi.global_position.y - _y(nguoi.global_position.x, nguoi.global_position.z)
	var toc := Vector2(nguoi.velocity.x, nguoi.velocity.z).length()
	nguoi.dk_bay = false
	nguoi.dk_di = Vector2.ZERO
	_ghi("Quá nhiệt sau %d lần bật lao" % so_lao, nguoi.qua_nhiet and so_lao >= 6 and so_lao <= 10, "nhiệt %.0f" % nguoi.nhiet)
	_ghi("Lúc quá nhiệt không bay, không bật lao, chỉ chạy bộ (≤ 21 m/s)", y_bay < 2.5 and toc < 21.5, "cao %.1f m, tốc độ %.1f m/s" % [y_bay, toc])
	while nguoi.qua_nhiet and Mecha.gio() - t0 < 8.0:
		await _cho(0.1)
	var t_nguoi := Mecha.gio() - t0
	_ghi("Nguội hết mới dùng lại (khoảng 3 s)", not nguoi.qua_nhiet and t_nguoi > 2.0 and t_nguoi < 4.5, "%.1f s" % t_nguoi)

	# ---- 2. giữ độ cao bằng Ctrl
	_dat(nguoi, X, Z)
	await _cho(0.5)
	nguoi.dk_bay = true
	await _cho(1.6)
	nguoi.dk_ctrl = true
	await _cho(0.1)
	nguoi.dk_bay = false
	var y0 := nguoi.global_position.y
	var n0 := nguoi.nhiet
	await _cho(3.0)
	await _chup("03_giu_do_cao")
	var lech := absf(nguoi.global_position.y - y0)
	_ghi("Ctrl giữ độ cao", nguoi.giu_do_cao and lech < 1.5 and y0 - _y(X, Z) > 15.0, "cao %.0f m, lệch %.2f m sau 3 s" % [y0 - _y(X, Z), lech])
	_ghi("Giữ độ cao tốn nhiệt chậm", nguoi.nhiet > n0 and nguoi.nhiet - n0 < 25.0, "nhiệt %.0f -> %.0f trong 3 s" % [n0, nguoi.nhiet])
	nguoi.nhiet = nguoi.nhiet_toi_da() - 1.5
	await _cho(1.4)
	_ghi("Quá nhiệt lúc giữ độ cao thì rơi", nguoi.qua_nhiet and not nguoi.giu_do_cao and nguoi.velocity.y < -2.0, "vy %.1f" % nguoi.velocity.y)
	await _cho(3.5)

	# ---- 2b. bay liên tục từ lúc nguội: ít nhất 12 giây mới quá nhiệt (20/10: tăng năng lượng bay)
	_dat(nguoi, X, Z)
	await _cho(0.5)
	nguoi.nhiet = 0.0
	var t_bay := Mecha.gio()
	nguoi.dk_bay = true
	while not nguoi.qua_nhiet and Mecha.gio() - t_bay < 16.0:
		await _cho(0.1)
	t_bay = Mecha.gio() - t_bay
	nguoi.dk_bay = false
	_ghi("Bay liên tục ≥ 12 giây mới quá nhiệt", t_bay >= 12.0, "%.1f s" % t_bay)
	await _cho(4.0)

	# ---- 3. T: rơi nhanh khi đang bay
	_dat(nguoi, X, Z)
	await _cho(0.4)
	nguoi.dk_bay = true
	await _cho(1.6)
	nguoi.dk_bay = false
	var cao_m := nguoi.global_position.y - _y(X, Z)
	nguoi.dk_roi = true
	var t_r := Mecha.gio()
	await get_tree().physics_frame
	await get_tree().physics_frame
	while not nguoi.is_on_floor() and Mecha.gio() - t_r < 4.0:
		await get_tree().physics_frame
	var t_roi := Mecha.gio() - t_r
	_ghi("T: rơi nhanh", cao_m > 20.0 and t_roi < 0.9, "rơi %.0f m mất %.2f s (rơi thường ~%.1f s)" % [cao_m, t_roi, sqrt(2.0 * cao_m / 34.0)])

	# ---- 4. chạy bộ nhanh (Ctrl dưới đất)
	_dat(nguoi, X, Z)
	await _cho(0.4)
	nguoi.dk_ctrl = true
	nguoi.dk_di = Vector2(0, 1)
	await _cho(2.0)
	var v_chay := Vector2(nguoi.velocity.x, nguoi.velocity.z).length()
	await _chup("04_chay_bo")
	nguoi.dk_di = Vector2.ZERO
	_ghi("Chạy bộ nhanh (≥ 18 m/s)", nguoi.di_bo and v_chay >= 18.0, "%.1f m/s" % v_chay)
	nguoi.dk_ctrl = true
	await _cho(0.3)
	_dat(nguoi, X, Z)
	nguoi.dk_di = Vector2(0, 1)
	await _cho(1.8)
	var v_luot := Vector2(nguoi.velocity.x, nguoi.velocity.z).length()
	nguoi.dk_di = Vector2.ZERO
	_ghi("Lướt nhanh hơn chạy bộ", v_luot > v_chay + 15.0, "lướt %.1f m/s" % v_luot)

	# ---- 4b. GIỮ Shift (phím thật qua bộ điều khiển người chơi): lướt nhanh liên tục, nóng máy; thả ra về lướt thường
	_dat(nguoi, X, Z)
	await _cho(0.4)
	var dk_phim := DieuKhienNguoiChoi.new()
	dk_phim.cam = ban_do.cam
	dk_phim.ban_do = ban_do
	ban_do.add_child(dk_phim)
	nguoi.dieu_khien = dk_phim
	var n_giu := nguoi.nhiet
	Input.action_press("di_toi")
	Input.action_press("lao")
	await _cho(2.0)
	var v_giu := Vector2(nguoi.velocity.x, nguoi.velocity.z).length()
	var n_giu2 := nguoi.nhiet
	var luot_nhanh := nguoi.luot_nhanh
	await _chup("04b_giu_shift")
	Input.action_release("lao")
	await _cho(1.5)
	var v_tha := Vector2(nguoi.velocity.x, nguoi.velocity.z).length()
	Input.action_release("di_toi")
	nguoi.dieu_khien = null
	dk_phim.queue_free()
	_ghi("Giữ Shift: lướt nhanh liên tục (≥ 80 m/s)", luot_nhanh and v_giu >= 80.0, "%.1f m/s (lướt thường %.1f m/s)" % [v_giu, v_luot])
	_ghi("Giữ Shift làm nóng động cơ", n_giu2 - n_giu >= 24.0, "nhiệt %.0f → %.0f trong 2 s" % [n_giu, n_giu2])
	_ghi("Thả Shift thì về tốc độ lướt thường", absf(v_tha - v_luot) < 6.0, "%.1f m/s" % v_tha)

	# ---- 5. pháo nhiệt cứu khỏi tên lửa (so với không phóng)
	for co_phao in [false, true]:
		_xoa_ten_lua()
		_dat(nguoi, X, Z)
		await _cho(0.5)
		var mau0 := nguoi.mau
		_phong_vao(nguoi, nguoi.global_position + Vector3(0, 10, -260))
		var da_phong := false
		var t_dau := Mecha.gio()
		while Mecha.gio() - t_dau < 5.0:
			var gan := INF
			for n in get_tree().get_nodes_in_group("ten_lua"):
				if (n as TenLua).muc_tieu == nguoi:
					gan = minf(gan, n.global_position.distance_to(nguoi.global_position))
			if co_phao and not da_phong and gan < 110.0:
				nguoi.dk_phao_nhiet = true
				da_phong = true
				await _cho(0.15)
				await _chup("05_phao_nhiet")
			await _cho(0.05)
		var mat := mau0 - nguoi.mau
		if co_phao:
			_ghi("Pháo nhiệt: tên lửa mất khóa, không trúng", mat < 1.0, "mất %.0f giáp" % mat)
		else:
			_ghi("Không phóng pháo nhiệt thì trúng (đối chứng)", mat > 50.0, "mất %.0f giáp" % mat)

	# ---- 6. chặn tên lửa: súng máy bắn rơi được, súng trường / bắn tỉa thì không
	for vk in ["sung_may", "sung_truong", "sung_ban_tia"]:
		_xoa_ten_lua()
		nguoi.doi_vu_khi("phai", vk)
		_dat(nguoi, X, Z)
		await _cho(0.8)
		var roi0 := nguoi.ban_roi_tl
		_phong_vao(nguoi, nguoi.global_position + Vector3(0, 10, -300))
		var t_dau := Mecha.gio()
		var chup := false
		while Mecha.gio() - t_dau < 4.5:
			var gan: TenLua = null
			for n in get_tree().get_nodes_in_group("ten_lua"):
				if (n as TenLua).muc_tieu == nguoi:
					gan = n
			nguoi.muc_tieu_ban = gan if gan and gan.global_position.distance_to(nguoi.global_position) < 170.0 else null
			nguoi.dk_ban["phai"] = nguoi.muc_tieu_ban != null
			if nguoi.muc_tieu_ban and not chup and vk == "sung_may":
				chup = true
				await _cho(0.2)
				await _chup("06_sung_may_ban_ten_lua")
			await _cho(0.02)
		nguoi.dk_ban["phai"] = false
		nguoi.muc_tieu_ban = null
		var roi := nguoi.ban_roi_tl - roi0
		if vk == "sung_may":
			_ghi("Súng máy bắn rơi tên lửa", roi >= 1, "bắn rơi %d / 2" % roi)
		else:
			_ghi("%s KHÔNG chặn được tên lửa" % CanBang.VU_KHI[vk]["ten"], roi == 0, "bắn rơi %d" % roi)
	nguoi.doi_vu_khi("phai", "sung_may")

	# ---- 7. tay phụ Q / E: tên lửa vào mục tiêu đang khóa, phóng từ ổ sau lưng
	_xoa_ten_lua()
	_dat(nguoi, X, Z)
	_dat(bot, X, Z - 220.0, PI)
	await _cho(1.0)
	var mau_b := bot.mau
	nguoi.khoa = bot
	var cu_tl := get_tree().get_nodes_in_group("ten_lua")
	nguoi.dk_tay_phu["trai"] = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var lech_o := INF
	for n in get_tree().get_nodes_in_group("ten_lua"):
		if not n in cu_tl:
			lech_o = minf(lech_o, n.global_position.distance_to(nguoi.diem_phong("trai")))
	_ghi("Tên lửa phóng ra từ ổ trên tay máy sau lưng", lech_o < 6.0, "cách ổ trái %.1f m" % lech_o)
	await _cho(0.35)
	nguoi.khoa = bot
	nguoi.dk_tay_phu["phai"] = true
	await _cho(0.5)
	await _chup("07_ten_lua_tay_phu")
	var t_d := Mecha.gio()
	while Mecha.gio() - t_d < 4.0:
		nguoi.khoa = bot
		await _cho(0.05)
	_ghi("Q / E phóng tên lửa trúng mục tiêu khóa", bot.mau < mau_b - 100.0, "địch mất %.0f giáp" % (mau_b - bot.mau))

	# ---- 8. bot tự dùng pháo nhiệt / súng máy khi bị tên lửa
	_xoa_ten_lua()
	_dat(bot, X, Z - 220.0, PI)
	bot.phao_nhiet = int(CanBang.PHAO_NHIET["so_luot"])
	bot.hoi_phao = 0.0
	await _cho(0.5)
	var bk := DieuKhienBot.new()
	bk.ban_do = ban_do
	ban_do.add_child(bk)
	bot.dieu_khien = bk
	var phao0 := bot.phao_nhiet
	var roi_b0 := bot.ban_roi_tl
	for i in 4:
		nguoi.khoa = bot
		nguoi.hoi_tay_phu = {"trai": 0.0, "phai": 0.0}
		nguoi.dk_tay_phu["trai" if i % 2 == 0 else "phai"] = true
		await _cho(3.0)
	_ghi("Bot phản ứng với tên lửa (pháo nhiệt hoặc súng máy)", bot.phao_nhiet < phao0 or bot.ban_roi_tl > roi_b0 or bot.tl_bi_lua > 0,
		"pháo nhiệt dùng %d, bắn rơi %d" % [phao0 - bot.phao_nhiet, bot.ban_roi_tl - roi_b0])
	bot.dieu_khien = null
	_xoa_ten_lua()

	# ---- 9. lao chém mecha địch đang khóa (máy không phản ứng); bấm F thật thử ở phần HUD bên dưới
	_dat(nguoi, X, Z)
	_dat(bot, X, Z - 90.0, PI)
	await _cho(0.8)
	nguoi.khoa = bot
	_ghi("Mecha địch trong 120 m được đánh dấu lao chém", nguoi.co_the_lao_chem(), "cách %.0f m" % nguoi.global_position.distance_to(bot.global_position))
	var mau_b2 := bot.mau
	nguoi.dk_lao_chem = true
	await _cho(0.35)
	await _chup("08_lao_chem")
	await _cho(1.2)
	_ghi("Lao chém trúng", mau_b2 - bot.mau >= 600.0, "địch mất %.0f giáp" % (mau_b2 - bot.mau))
	await _cho(0.6)

	# ---- 10. bị máy lao chém: không làm gì / né đúng lúc / né sớm / đỡ đúng lúc / đỡ sớm
	for ca in [["Không phản ứng: bị chém", -1.0, "", true, false],
			["Shift đúng lúc: NÉ được", 0.22, "ne", false, false],
			["Shift quá sớm: vẫn bị chém", 0.9, "ne", true, false],
			["F đúng lúc: ĐỠ được, địch choáng", 0.08, "do", false, true],
			["F quá sớm: vẫn bị chém", 0.6, "do", true, false]]:
		_dat(nguoi, X, Z)
		_dat(bot, X, Z - 80.0, PI)
		bot.hoi_lao_chem = 0.0
		await _cho(0.6)
		var mau0 := nguoi.mau
		bot.khoa = nguoi
		bot.dk_lao_chem = true
		await get_tree().physics_frame
		await get_tree().physics_frame
		var da_m := false
		var chup_m := false
		var t_bd := Mecha.gio()
		var bi_choang := false
		while Mecha.gio() - t_bd < 2.5:
			var con := bot.t_toi_va_cham()
			if not da_m and ca[2] != "" and con <= float(ca[1]):
				da_m = true
				if ca[2] == "ne":
					nguoi.dk_di = Vector2(1, 0)
					nguoi.dk_lao = true
				else:
					nguoi.dk_chem = true
			if not chup_m and ca[2] == "do" and float(ca[1]) < 0.1 and con <= 0.3:
				chup_m = true
				await _chup("09_bao_dong_lao_chem")
			bi_choang = bi_choang or bot.dang_bi_choang()
			if bot._cc.is_empty() and Mecha.gio() - t_bd > 0.3:
				break
			await get_tree().physics_frame
		nguoi.dk_di = Vector2.ZERO
		var mat_m := mau0 - nguoi.mau
		var dat_m: bool = (mat_m > 300.0) == ca[3] and (not ca[4] or bi_choang)
		_ghi("Địch lao chém — " + ca[0], dat_m, "mất %.0f giáp%s" % [mat_m, " · địch bị choáng" if bi_choang else ""])
		await _cho(0.6)
	bot.khoa = null

	# ---- 11. kiểu cận chiến: thương xuyên khiên, đấm EMP làm nóng + choáng
	_dat(nguoi, X, Z)
	_dat(bot, X, Z - 12.0, PI)
	await _cho(0.5)
	bot.khien_con = 4.0
	nguoi.doi_can_chien("kiem")
	var m_k := bot.mau
	nguoi.khoa = bot
	nguoi.dk_chem = true
	await _cho(0.8)
	var mat_kiem := m_k - bot.mau
	bot.khien_con = 4.0
	nguoi.doi_can_chien("thuong")
	nguoi.hoi_chem = 0.0
	m_k = bot.mau
	nguoi.dk_chem = true
	await _cho(0.8)
	var mat_thuong := m_k - bot.mau
	_ghi("Thương xuyên đâm thủng khiên (kiếm thì bị khiên chặn 75%)", mat_thuong > mat_kiem * 3.0, "kiếm %.0f · thương %.0f" % [mat_kiem, mat_thuong])
	bot.khien_con = 0.0
	nguoi.doi_can_chien("dam_emp")
	nguoi.hoi_chem = 0.0
	bot.nhiet = 0.0
	nguoi.dk_chem = true
	await _cho(0.5)
	_ghi("Đấm EMP: địch nóng máy và choáng", bot.nhiet >= 30.0 and bot.dang_bi_choang(), "nhiệt địch %.0f, choáng %.1f s" % [bot.nhiet, bot.choang_con])
	nguoi.doi_can_chien("kiem")
	await _cho(1.6)

	# ---- 12. súng EMP / súng tia làm nóng địch
	_dat(nguoi, X, Z)
	_dat(bot, X, Z - 150.0, PI)
	nguoi.doi_vu_khi("trai", "sung_tia_nang_luong")
	await _cho(0.6)
	bot.nhiet = 0.0
	var t_b := Mecha.gio()
	while Mecha.gio() - t_b < 2.0:
		nguoi.khoa = bot
		nguoi.dk_ban["trai"] = true
		await get_tree().physics_frame
	nguoi.dk_ban["trai"] = false
	_ghi("Súng tia năng lượng làm nóng địch", bot.nhiet > 5.0, "nhiệt địch %.0f" % bot.nhiet)
	nguoi.doi_vu_khi("trai", "sung_truong")

	# ---- 13. tay phụ: súng máy vai, khiên, ụ minigun
	_xoa_ten_lua()
	_dat(nguoi, X, Z)
	_dat(bot, 600.0, 900.0)
	nguoi.doi_tay_phu("trai", "sung_may_vai")
	nguoi.doi_tay_phu("phai", "khien")
	await _cho(0.8)
	var roi0_v := nguoi.ban_roi_tl
	nguoi.dk_tay_phu["trai"] = true
	await _cho(0.2)
	_phong_vao(nguoi, nguoi.global_position + Vector3(0, 10, -280))
	await _cho(4.0)
	_ghi("Tay phụ súng máy vai tự bắn rơi tên lửa", nguoi.ban_roi_tl - roi0_v >= 1, "bắn rơi %d" % (nguoi.ban_roi_tl - roi0_v))
	nguoi.dk_tay_phu["phai"] = true
	await _cho(0.2)
	_dat(bot, X, Z - 200.0, PI)
	var m_s := nguoi.mau
	nguoi.nhan_sat_thuong(400.0, bot)
	var mat_khien := m_s - nguoi.mau
	_dat(bot, X, Z + 60.0)
	m_s = nguoi.mau
	nguoi.nhan_sat_thuong(400.0, bot)
	var mat_sau := m_s - nguoi.mau
	_ghi("Khiên chặn đòn phía trước (75%), không chặn phía sau", absf(mat_khien - 100.0) < 1.0 and absf(mat_sau - 400.0) < 1.0, "trước mất %.0f · sau mất %.0f" % [mat_khien, mat_sau])
	await _chup("10_khien")
	nguoi.doi_tay_phu("trai", "u_minigun")
	nguoi.hoi_tay_phu["trai"] = 0.0
	nguoi.dk_tay_phu["trai"] = true
	await _cho(0.3)
	nguoi.hoi_tay_phu["trai"] = 0.0
	nguoi.dk_tay_phu["trai"] = true
	await _cho(0.3)
	var so_u := 0
	for u in nguoi.u_minigun:
		if is_instance_valid(u):
			so_u += 1
	_ghi("Ụ minigun: loại Cơ bản đặt tối đa 1 ụ", so_u == 1, "%d ụ" % so_u)
	nguoi.doi_tay_phu("trai", "ten_lua")
	nguoi.doi_tay_phu("phai", "ten_lua")

	# ---- 14. bảng B: chế độ cứ điểm chỉ mở ở căn cứ / trạm hậu cần
	_dat(nguoi, 0.0, 0.0)
	await _cho(0.3)
	ban_do.mo_trang_bi()
	var mo_xa: bool = ban_do.bang_trang_bi.visible
	_dat(nguoi, X, 1250.0)
	await _cho(0.4)
	ban_do.mo_trang_bi()
	var mo_gan: bool = ban_do.bang_trang_bi.visible
	_ghi("Bảng B chỉ mở ở căn cứ / trạm hậu cần (chế độ cứ điểm)", not mo_xa and mo_gan, "xa căn cứ: %s · ở căn cứ: %s" % [mo_xa, mo_gan])
	if mo_gan:
		ban_do.bang_trang_bi.o_chon = "q"
		for i in 3:
			await RenderingServer.frame_post_draw
		await _chup("11_bang_trang_bi")
		ban_do.bang_trang_bi.chon_mon("phai", "sung_ban_tia")
		_ghi("Bảng B đổi vũ khí tay phải", nguoi.vk["phai"] == "sung_ban_tia" and TienTrinh.trang_bi["phai"] == "sung_ban_tia", "")
		ban_do.bang_trang_bi.chon_mon("phai", "sung_may")
		ban_do.bang_trang_bi.dong_bang()

	# ---- 15. khả năng riêng các loại mecha
	var kq_loai := await _thu_loai_mecha()
	_ghi("Cơ động: bật lao lần hai liền không tốn nhiệt", kq_loai[0], kq_loai[1])
	_ghi("Hạng nặng: khiên chặn hết đạn phía trước", kq_loai[2], kq_loai[3])

	# ---- 16. hồi sinh: rơi từ tàu sân bay xuống
	_dat(nguoi, X, Z)
	await _cho(0.3)
	nguoi.nhan_sat_thuong(99999.0, bot)
	await _cho(0.2)
	var t_hs := Mecha.gio()
	while not nguoi.dang_roi and Mecha.gio() - t_hs < 12.0:
		await _cho(0.1)
	var t_roi_hs := Mecha.gio()
	while nguoi.dang_roi and Mecha.gio() - t_roi_hs < 6.0:
		await get_tree().physics_frame
	_ghi("Bị hạ thì hồi sinh, rơi từ tàu sân bay xuống", nguoi.song and not nguoi.dang_roi and Mecha.gio() - t_roi_hs < 3.0, "rơi %.1f s" % (Mecha.gio() - t_roi_hs))
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# ---- 17. chiếm cứ điểm vẫn chạy với mecha mới
	ban_do.dat_cu_diem(true)
	var cd_b: CuDiem = null
	for cd in ban_do.cu_diem:
		if (cd as CuDiem).ten == "B":
			cd_b = cd
	_dat(bot, 600.0, -600.0)
	_dat(nguoi, cd_b.global_position.x, cd_b.global_position.z + 10.0)
	var t_c := Mecha.gio()
	while cd_b.chu != nguoi.phe and Mecha.gio() - t_c < 20.0:
		await _cho(0.25)
	_ghi("Chiếm cứ điểm B", cd_b.chu == nguoi.phe, "%.0f s" % (Mecha.gio() - t_c))
	ban_do.dat_cu_diem(false)

	# ---- 18. địch chiến dịch: chỉ đánh khi đã phát hiện (trong tầm + nhìn thấy); giới hạn số con tấn công cùng lúc
	var kq_ph := await _thu_phat_hien(bot, ban_do.bots[1])
	_ghi("Địch tuần tra ở xa 600 m: chưa phát hiện, không đánh", kq_ph[0], kq_ph[3])
	_ghi("Tới gần 250 m (nhìn thấy): bị phát hiện, chỉ 1 con tấn công (giới hạn 1)", kq_ph[1], kq_ph[3])
	_ghi("Bắn trúng con đang chờ thì nó đánh trả ngay", kq_ph[2], kq_ph[3])

	# ---- ảnh cận cảnh: mecha người chơi và mecha địch
	_dat(nguoi, X, Z)
	_dat(bot, X - 14.0, Z - 40.0, 0.0)
	var b2: Mecha = ban_do.bots[1]
	_dat(b2, X + 14.0, Z - 40.0, 0.0)
	nguoi.doi_vu_khi("trai", "sung_phao")
	await _cho(1.0)
	nguoi.dk_ban["phai"] = true
	await _cho(0.6)
	ban_do.cam.yaw = PI
	ban_do.cam.pitch = -0.15
	await _cho(0.6)
	await _chup("12_can_canh_truoc")
	nguoi.dk_ban["phai"] = false
	ban_do.cam.yaw = 0.0
	await _cho(0.8)
	await _chup("13_hai_mecha_dich")

	# ---- HUD mới: bia tập khóa được, cung máu đọc đúng máu thứ đang khóa, ô trạng thái tay phụ / pháo nhiệt
	nguoi.doi_vu_khi("trai", "sung_may")
	_dat(bot, X + 300.0, Z + 200.0, 0.0)
	_dat(b2, X + 340.0, Z + 200.0, 0.0)             # không đặt chồng một chỗ (hai thân đè nhau thì bị đẩy văng lên trời)
	_dat(nguoi, X, Z)
	ban_do.cam.yaw = 0.0
	ban_do.cam.pitch = -0.05
	var bia := Bia.new()
	bia.position = Vector3(X, _y(X, Z - 150.0), Z - 150.0)
	ban_do.add_child(bia)
	# bộ điều khiển người chơi thật (không bấm phím nào) để thử tự khóa theo tâm ngắm
	var dk_that := DieuKhienNguoiChoi.new()
	dk_that.cam = ban_do.cam
	dk_that.ban_do = ban_do
	ban_do.add_child(dk_that)
	nguoi.dieu_khien = dk_that
	await _cho(0.8)
	var hud: HUD = ban_do.hud
	_ghi("Bia tập khóa được như mục tiêu thật", nguoi.khoa == bia, "khóa: %s" % (nguoi.khoa.name if is_instance_valid(nguoi.khoa) else "không"))
	bia.nhan_sat_thuong(60.0, nguoi)
	var ti_mau := float(bia.mau) / hud._mau_toi_da(bia)
	_ghi("Cung máu trên vòng ngắm đọc đúng máu mục tiêu khóa", absf(ti_mau - 0.6) < 0.01, "%d%%" % int(ti_mau * 100.0))
	var o_co_khoa: Dictionary = hud.trang_thai_o(nguoi)[2]
	bia.nhan_sat_thuong(999.0, nguoi)
	await _cho(0.3)
	var o_mat_khoa: Dictionary = hud.trang_thai_o(nguoi)[2]
	# F (phím thật): mecha địch đang khóa trong 120 m thì chữ F hiện cạnh nó, bấm F là lao chém (không cần Shift)
	for u in get_tree().get_nodes_in_group("u_minigun"):
		u.queue_free()                          # ụ minigun của phép thử trước đứng chắn đường lao
	_dat(bot, X, Z - 90.0, PI)
	_dat(nguoi, X, Z)
	await _cho(0.8)
	var f_hien: bool = nguoi.khoa == bot and HUD.lao_chem_duoc(nguoi) and bool(hud.trang_thai_o(nguoi)[5]["lao_chem"])
	await _chup("14c_chu_f_lao_chem")
	var mau_f := bot.mau
	await get_tree().physics_frame
	Input.action_press("can_chien")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("can_chien")
	await _cho(1.2)
	_ghi("Khóa địch trong 120 m: chữ F hiện cạnh địch", f_hien, "khóa: %s" % (nguoi.khoa.name if is_instance_valid(nguoi.khoa) else "không"))
	_ghi("Bấm F (không cần Shift): lao chém trúng", mau_f - bot.mau >= 500.0, "địch mất %.0f giáp" % (mau_f - bot.mau))
	_dat(bot, X + 300.0, Z + 200.0, 0.0)
	_dat(nguoi, X, Z)
	await _cho(0.3)
	_ghi("Không có địch trong tầm: không hiện chữ F", not HUD.lao_chem_duoc(nguoi), "")
	nguoi.dieu_khien = null
	dk_that.queue_free()
	_ghi("Ô tên lửa: sẵn sàng khi khóa, dấu ổ khóa khi chưa khóa", o_co_khoa["tt"] == "san" and o_mat_khoa["tt"] == "khong" and o_mat_khoa["dau"] == "khoa",
		"%s → %s/%s" % [o_co_khoa["tt"], o_mat_khoa["tt"], o_mat_khoa["dau"]])
	nguoi.phao_nhiet = 0
	nguoi.hoi_phao = 9.0
	nguoi.doi_tay_phu("phai", "khien")
	await _cho(0.6)
	nguoi.dk_tay_phu["phai"] = true
	await _cho(0.3)
	var ds_o: Array = hud.trang_thai_o(nguoi)
	_ghi("Ô pháo nhiệt đang hồi, ô khiên đang bật", ds_o[4]["tt"] == "hoi" and ds_o[3]["tt"] == "bat", "pháo nhiệt %s, khiên %s" % [ds_o[4]["tt"], ds_o[3]["tt"]])
	await _chup("14b_o_trang_thai")
	nguoi.doi_tay_phu("phai", "ten_lua")
	nguoi.phao_nhiet = int(CanBang.PHAO_NHIET["so_luot"])
	_ghi("Không còn phím ẩn / hiện dòng hướng dẫn", not Phim.gan.has("huong_dan") and not hud.has_method("_huong_dan"), "")
	# ---- Esc lùi một bước: đóng bản đồ M → đóng bảng B → mở menu tạm dừng → lùi khỏi Cài đặt → đóng menu
	ban_do.ban_do_mat.bat_tat()
	await _cho(0.3)
	await _bam_esc()
	var esc_m: bool = not ban_do.ban_do_mat.visible and not ban_do.tam_dung.visible
	_dat(nguoi, X, 1250.0)
	await _cho(0.4)
	ban_do.mo_trang_bi()
	await _cho(0.4)
	var co_b: bool = ban_do.bang_trang_bi.visible
	await _bam_esc()
	var esc_b: bool = co_b and not ban_do.bang_trang_bi.visible and not ban_do.tam_dung.visible
	await _cho(0.3)
	await _bam_esc()
	var esc_mo: bool = ban_do.tam_dung.visible and get_tree().paused
	(ban_do.tam_dung.find_child("nut_cai_dat", true, false) as Button).pressed.emit()
	await _cho(0.2)
	await _bam_esc()
	var esc_cd: bool = ban_do.tam_dung.visible and not ban_do.tam_dung._cai_dat.visible
	await _bam_esc()
	var esc_dong: bool = not ban_do.tam_dung.visible and not get_tree().paused
	_ghi("Esc: đóng bản đồ M (không mở menu tạm dừng)", esc_m, "")
	_ghi("Esc: đóng bảng B", esc_b, "")
	_ghi("Esc: mở menu tạm dừng, lùi khỏi Cài đặt, rồi đóng menu", esc_mo and esc_cd and esc_dong, "mở %s · lùi cài đặt %s · đóng %s" % [esc_mo, esc_cd, esc_dong])
	_dat(nguoi, X, Z)
	# ---- menu tạm dừng: Lưu game vào ô 1
	ban_do.tam_dung.mo()
	await _cho(0.3)
	var nut_luu := ban_do.tam_dung.find_child("nut_luu_game", true, false) as Button
	nut_luu.pressed.emit()
	await _cho(0.4)
	var o1 := ban_do.tam_dung.find_child("luu_1", true, false) as Button
	if o1:
		o1.pressed.emit()
		await _cho(0.2)
		var dy := ban_do.tam_dung.find_child("nut_dong_y", true, false) as Button
		if dy:
			dy.pressed.emit()
	await _cho(0.4)
	await _chup("15_luu_game_trong_tran")
	_ghi("Lưu game từ menu tạm dừng (ô 1)", not TienTrinh.thong_tin_o(1).is_empty(), "")
	ban_do.tam_dung.dong()
	var dat := _ket_qua.filter(func(k): return k[1]).size()
	print("[kiem] TONG: %d / %d dat" % [dat, _ket_qua.size()])
	print("[kiem] am thanh da phat: ", AmThanh.nhat_ky, " · thieu file: ", AmThanh.thieu)
	get_tree().quit()


## Bấm Esc như người chơi (qua hàng sự kiện nhập), chờ vài khung hình cho game xử lý.
func _bam_esc() -> void:
	for nhan in [true, false]:
		var e := InputEventKey.new()
		e.keycode = KEY_ESCAPE
		e.physical_keycode = KEY_ESCAPE
		e.pressed = nhan
		Input.parse_input_event(e)
		await get_tree().process_frame
		await get_tree().process_frame


## Hai mecha địch tuần tra kiểu chiến dịch (giới hạn 1 con tấn công): xa 600 m thì chưa đánh; tới 250 m thì chỉ 1 con
## đánh; bắn trúng con đang chờ thì nó đánh trả. Chọn chỗ có tầm nhìn thông. Trả về [xa, gần, bắn, chi tiết].
func _thu_phat_hien(a: Mecha, b: Mecha) -> Array:
	var luot := LuotTanCong.new()
	luot.so_toi_da = 1
	var x := 0.0
	var kg := nguoi.get_world_3d().direct_space_state
	for thu in [0.0, 60.0, -60.0, 120.0, -120.0, 200.0, -200.0, 300.0, -300.0]:
		var ok := true
		for lech in [-30.0, 30.0]:
			var p0 := Vector3(thu, _y(thu, 950.0) + 8.0, 950.0)
			var p1 := Vector3(thu + lech, _y(thu + lech, 700.0) + 8.0, 700.0)
			if not kg.intersect_ray(PhysicsRayQueryParameters3D.create(p0, p1, 1)).is_empty():
				ok = false
		if ok:
			x = thu
			break
	var bks: Array = []
	for m in [a, b]:
		var bk := DieuKhienBot.new()
		bk.tuan_tra = true
		bk.tam_phat_hien = CanBang.CHIEN_DICH_PHAT_HIEN["tuan_tra"]
		bk.dieu_phoi = luot
		ban_do.add_child(bk)
		m.dieu_khien = bk
		bks.append(bk)
	_dat(a, x - 30.0, 700.0)
	_dat(b, x + 30.0, 700.0)
	(bks[0] as DieuKhienBot).diem_canh = a.global_position
	(bks[1] as DieuKhienBot).diem_canh = b.global_position
	_dat(nguoi, x, 1300.0)
	await _cho(2.5)
	var xa := a.khoa == null and b.khoa == null
	_dat(nguoi, x, 950.0)
	await _cho(2.5)
	var so_danh := int(a.khoa == nguoi) + int(b.khoa == nguoi)
	await _chup("16_phat_hien_1_con_danh")
	var cho: Mecha = b if a.khoa == nguoi else a
	cho.nhan_sat_thuong(60.0, nguoi)
	await _cho(0.8)
	var ban := cho.khoa == nguoi
	var chi_tiet := "x = %.0f · gần: %d con đánh · con chờ bị bắn: %s" % [x, so_danh, "đánh trả" if ban else "vẫn chờ"]
	for m in [a, b]:
		m.dieu_khien = null
		m.khoa = null
	for bk in bks:
		(bk as Node).queue_free()
	return [xa, so_danh == 1, ban, chi_tiet]


## Tạo tạm mecha Cơ động và Hạng nặng để thử khả năng riêng. Trả về [đạt lướt kép, chi tiết, đạt khiên dày, chi tiết].
func _thu_loai_mecha() -> Array:
	var kq := []
	var cd := Mecha.new()
	cd.loai = "co_dong"
	cd.phe = 0
	ban_do.add_child(cd)
	_dat(cd, 200.0, 1100.0)
	await _cho(0.6)
	cd.dk_di = Vector2(1, 0)
	cd.dk_lao = true
	await _cho(0.4)
	var n1 := cd.nhiet
	cd.dk_lao = true
	await _cho(0.1)
	var n2 := cd.nhiet
	kq.append(n1 > 10.0 and absf(n2 - n1) < 3.0)
	kq.append("nhiệt sau lần 1: %.0f, sau lần 2: %.0f" % [n1, n2])
	cd.queue_free()
	var hn := Mecha.new()
	hn.loai = "hang_nang"
	hn.phe = 0
	hn.tay_phu = {"trai": "khien", "phai": "khien"}
	ban_do.add_child(hn)
	_dat(hn, 200.0, 1100.0)
	await _cho(0.4)
	hn.dk_tay_phu["trai"] = true
	await _cho(0.2)
	var dich := Node3D.new()
	ban_do.add_child(dich)
	dich.global_position = hn.global_position + hn.huong_toi() * 50.0
	var m0 := hn.mau
	hn.nhan_sat_thuong(500.0, dich)
	kq.append(hn.mau == m0 and hn.cs["ty_le"] > 1.0)
	kq.append("mất %.0f giáp, to ×%.2f" % [m0 - hn.mau, hn.cs["ty_le"]])
	dich.queue_free()
	await _chup("14_hang_nang_khien")
	hn.queue_free()
	return kq


func _quan_sat() -> void:
	nguoi.dieu_khien = null
	ban_do.menu.tu_chon_sau = 0.5
	var t := 0.0
	var lan := 0
	while t < quan_sat:
		await _cho(10.0)
		t += 10.0
		var dong := "[quan_sat] %3d s |" % int(t)
		for cd in ban_do.cu_diem:
			var x := cd as CuDiem
			var chu := "-" if x.chu < 0 else ("T" if x.chu == 0 else "D")
			dong += " %s:%s %+.2f %s(%d/%d)" % [x.ten, chu, x.thanh, x.loai.substr(0, 3), x.co_mat[0], x.co_mat[1]]
		dong += " | tau T %d%% D %d%% | FPS %d" % [int(ban_do.tran_troi.ti_le_san_bay(0) * 100), int(ban_do.tran_troi.ti_le_san_bay(1) * 100), Engine.get_frames_per_second()]
		print(dong)
		var bot_dong := "[quan_sat]       bot:"
		var so_ket := 0
		for b in ban_do.bots + ban_do.dong_doi:
			var bm := b as Mecha
			var dk := bm.dieu_khien as DieuKhienBot
			var cu: Vector3 = bm.get_meta("vi_tri_cu", bm.global_position)
			var di := Vector2(bm.global_position.x - cu.x, bm.global_position.z - cu.z).length()
			bm.set_meta("vi_tri_cu", bm.global_position)
			var trong_vong := dk != null and dk.cu_diem_muc != null and dk.cu_diem_muc.trong_vong(bm.global_position)
			var ket := bm.song and di < 15.0 and not trong_vong and dk != null and dk.muc_tieu == null
			if ket:
				so_ket += 1
			bot_dong += " %s->%s(%s nhiet %d%s)" % [bm.loai, dk.cu_diem_muc.ten if dk and dk.cu_diem_muc else "-", "song" if bm.song else "ha", int(bm.nhiet), (" KET o %s" % str(bm.global_position.round())) if ket else ""]
		print(bot_dong)
		if so_ket > 0:
			print("[quan_sat]       bot dung yen ngoai cu diem (co the bi ket): %d" % so_ket)
		lan += 1
		if lan % 3 == 0:
			ban_do.cam.pitch = -0.6
			await _chup("qs_%03d" % int(t))
	print("[quan_sat] XONG")
	get_tree().quit()


## Chụp bản đồ từ nhiều góc (--chup_ban_do): nhìn từ trên cao, rồi đặt mecha ở vài chỗ và chụp sau lưng.
func _chup_ban_do() -> void:
	nguoi.dieu_khien = null
	var cam_cao := Camera3D.new()
	cam_cao.far = 9000.0
	cam_cao.fov = 60.0
	ban_do.add_child(cam_cao)
	for g in [[Vector3(0, 1500, 1900), Vector3(0, 0, 200), "bd1_tong_quan"], [Vector3(-900, 450, 700), Vector3(0, 0, 0), "bd2_thanh_co"],
			[Vector3(700, 160, 300), Vector3(150, 0, -50), "bd3_phe_tich_gan"]]:
		cam_cao.global_position = g[0]
		cam_cao.look_at(g[1])
		cam_cao.current = true
		await _cho(1.5)
		await _chup(g[2])
	cam_cao.current = false
	ban_do.cam.cam.current = true
	for d in [[Vector3(0, 0, 900), 0.0, "bd4_dai_lo_nhin_ve_C"], [Vector3(220, 0, 380), 2.6, "bd5_trong_thanh"],
			[Vector3(-1050, 0, 300), 1.0, "bd6_doi_cat"], [Vector3(0, 0, 740), 0.0, "bd7_cong_vom"]]:
		var p: Vector3 = d[0]
		_dat(nguoi, p.x, p.z, d[1])
		await _cho(1.5)
		await _chup(d[2])
