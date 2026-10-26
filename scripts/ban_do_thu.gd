class_name BanDoThu
extends Node3D
## Bản đồ trận đấu 3,2 × 3,2 km, căn cứ phe Trắng ở phía nam, phe Đen ở phía bắc, 5 cứ điểm A–E ở giữa.
## Ba kiểu cảnh (chọn ở màn Vào trận): thành phố đổ nát (DungThanhPho), ngoại ô (DungNgoaiO), đồng quê (DungDongQue);
## chiến dịch còn có bãi huấn luyện (DungBaiTap).
## Cấu hình trận (loại mecha, vũ khí, quân số 3v3 / 6v6, độ khó, hạm đội) lấy từ TienTrinh (chọn ở menu).
## Trên trời là trận chiến chiến hạm (TranTrenTroi). Hạ tàu sân bay địch là thắng; trận dài tối đa 15 phút,
## hết giờ thì phe có tàu sân bay còn nhiều % hơn thắng.
## Chạy với tham số "-- --autotest=<thư mục>" để tự chơi thử và chụp ảnh.

const KICH_THUOC := 3200.0
const CAN_CU := [Vector3(0, 0, 1350), Vector3(0, 0, -1350)]      # [phe Trắng, phe Đen]
## 5 cứ điểm, đặt xa nhau: A, B gần phe Trắng; C ở giữa; D, E gần phe Đen.
const VI_TRI_CU_DIEM := {
	"A": Vector3(-750, 0, 820), "B": Vector3(750, 0, 820), "C": Vector3(0, 0, 0),
	"D": Vector3(-750, 0, -820), "E": Vector3(750, 0, -820),
}

var nguoi_choi: Mecha
var cam: CameraRig
var hud: HUD
var ho_tro: HoTro
var menu: MenuCuDiem
var bots: Array[Mecha] = []        # mecha phe Đen
var dong_doi: Array[Mecha] = []    # bot phe Trắng
var cu_diem: Array[CuDiem] = []
var mau_tau := [CanBang.MAU_TAU_SAN_BAY, CanBang.MAU_TAU_SAN_BAY]
var tau_san_bay: Node3D            # tàu sân bay phe Trắng
var _tau: Array[Node3D] = []
var _t := 0.0
var _so_tiep_vien := 0
var hoi_sinh_con := 0.0             # người chơi đang chờ hồi sinh: còn bao nhiêu giây
var hoi_sinh_chon := "Căn cứ"      # tên điểm hồi sinh người chơi đang chọn
var tran_troi: TranTrenTroi
var do_kho := "thuong"
var quan_so := 3
var thoi_gian_con := 900.0          # thời gian trận còn lại
var cho_ket_thuc := true            # tắt khi tự kiểm tra để trận không tự kết thúc giữa chừng
var da_ket_thuc := false
var so_ha := 0                      # số mecha địch người chơi tự tay hạ
var so_cu_diem := 0                 # số lần phe ta chiếm được cứ điểm
var tam_dung: ManTamDung
var bang_trang_bi: BangTrangBi
var ban_do_mat: BanDoMat               # bản đồ chiến trường (phím M)
var anh_ban_do: ImageTexture           # ảnh nền bản đồ (vẽ một lần lúc vào trận)
var _moc_tau: Array[Node3D] = []    # vị trí tàu sân bay lúc đầu trận (máy bay vẫn bay về đây nếu tàu đã mất)
var _tu_kiem_tra := false
var dia_hinh: DiaHinh                # địa hình (chieu_cao(x, z) để biết độ cao mặt đất)
var _dung_ban_do: DungBanDo
var kieu_ban_do := "thanh_pho"       # thanh_pho / ngoai_o / dong_que (chiến dịch: thêm bai_tap)
var _thoi_tiet: GPUParticles3D       # tuyết rơi / bụi phấn bay theo camera
var che_do := "cu_diem"              # "cu_diem" / "chien_dich" (TranChienDich)


func _ready() -> void:
	randomize()
	get_tree().paused = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			_tu_kiem_tra = true
	_doc_cau_hinh()
	_dung_canh()
	_bat_dau()


## Cấu hình trận từ menu (độ khó, quân số, bản đồ).
func _doc_cau_hinh() -> void:
	do_kho = TienTrinh.cau_hinh_tran.get("do_kho", "thuong")
	quan_so = int(TienTrinh.cau_hinh_tran.get("quan_so", 3))
	thoi_gian_con = CanBang.THOI_GIAN_TRAN
	kieu_ban_do = TienTrinh.cau_hinh_tran.get("ban_do", "thanh_pho")
	if not CanBang.BAN_DO.has(kieu_ban_do):
		kieu_ban_do = "thanh_pho"


## Dựng cảnh: trời, mặt đất, cảnh vật, ảnh nền bản đồ.
func _dung_canh() -> void:
	_moi_truong()
	_mat_dat()
	_vat_can()
	var t_anh := Time.get_ticks_msec()
	anh_ban_do = AnhBanDo.tao(self)
	print("[ban_do] ve anh ban do trong %d ms" % (Time.get_ticks_msec() - t_anh))


## Độ cao mặt đất ở (x, z).
func chieu_cao(x: float, z: float) -> float:
	return dia_hinh.chieu_cao(x, z) if dia_hinh else 0.0


## Mecha người chơi (trang bị đang chọn), camera và bộ điều khiển.
func _tao_nguoi_choi(vi_tri: Vector3, huong := 0.0) -> void:
	TienTrinh.sua_trang_bi()
	var tb: Dictionary = TienTrinh.trang_bi
	nguoi_choi = _tao_mecha(0, tr("Bạn"), tb["loai"], {"phai": tb["phai"], "trai": tb["trai"]},
		{"trai": tb["tay_phu_trai"], "phai": tb["tay_phu_phai"]}, tb["can_chien"], vi_tri)
	nguoi_choi.nut_nang_cap = [TienTrinh.so_nut(tb["loai"], 0), TienTrinh.so_nut(tb["loai"], 1), TienTrinh.so_nut(tb["loai"], 2)]
	nguoi_choi.rotation.y = huong
	nguoi_choi.dk_huong = huong
	var dk := DieuKhienNguoiChoi.new()
	nguoi_choi.dieu_khien = dk
	nguoi_choi.lay_da_lao = CanBang.CAN_CHIEN["lao_chem"]["lay_da_nguoi"]
	nguoi_choi.toc_lao_chem_goc = CanBang.CAN_CHIEN["lao_chem"]["toc"]
	add_child(dk)
	add_child(nguoi_choi)
	cam = CameraRig.new()
	cam.muc_tieu = nguoi_choi
	add_child(cam)
	dk.cam = cam
	dk.ban_do = self
	nguoi_choi.bi_ha.connect(_khi_bi_ha)


## HUD, bản đồ nhỏ, bản đồ M, bảng trang bị, menu tạm dừng.
func _dung_giao_dien() -> void:
	var lop := CanvasLayer.new()
	add_child(lop)
	hud = HUD.new()
	hud.nguoi_choi = nguoi_choi
	hud.cam = cam
	hud.ho_tro = ho_tro
	hud.ban_do = self
	lop.add_child(hud)
	var nho := BanDoNho.new()
	nho.ban_do = self
	lop.add_child(nho)
	var lop_menu := CanvasLayer.new()
	lop_menu.layer = 5
	lop_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lop_menu)
	if che_do == "cu_diem":
		menu = MenuCuDiem.new()
		lop_menu.add_child(menu)
	ban_do_mat = BanDoMat.new()
	ban_do_mat.ban_do = self
	lop_menu.add_child(ban_do_mat)
	bang_trang_bi = BangTrangBi.new()
	bang_trang_bi.ban_do = self
	lop_menu.add_child(bang_trang_bi)
	var lop_dung := CanvasLayer.new()
	lop_dung.layer = 8
	lop_dung.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lop_dung)
	tam_dung = ManTamDung.new()
	tam_dung.ban_do = self
	lop_dung.add_child(tam_dung)


## Chế độ chiếm cứ điểm: tàu sân bay, 5 cứ điểm, người chơi, bot hai phe.
func _bat_dau() -> void:
	_tau_tren_troi()
	for ten in VI_TRI_CU_DIEM:
		var cd := CuDiem.new()
		cd.ten = ten
		cd.ban_do = self
		add_child(cd)
		cd.global_position = VI_TRI_CU_DIEM[ten]
		cd.da_chiem.connect(_khi_chiem)
		cd.mat.connect(func(x: CuDiem, phe_cu: int) -> void: bao(tr("%s đã mất cứ điểm %s — công trình bị phá sạch") % [tr(CuDiem.TEN_PHE[phe_cu]), x.ten]))
		cu_diem.append(cd)
	_tao_nguoi_choi(CAN_CU[0], 0.0)                 # nhìn về phía bắc (về phía địch)
	ho_tro = HoTro.new()
	ho_tro.ban_do = self
	add_child(ho_tro)
	(nguoi_choi.dieu_khien as DieuKhienNguoiChoi).ho_tro = ho_tro

	# phe địch: loại mecha theo quân số và độ khó. Luôn có 1 mecha Cơ động bắn tỉa (chiếu laser đỏ báo trước).
	var loai_dich: Array = ["co_ban", "co_ban", "co_dong"]
	if do_kho == "kho":
		loai_dich = ["hang_nang", "co_ban", "co_dong"]
	if quan_so >= 6:
		loai_dich = ["co_ban", "hang_nang", "co_dong", "ho_tro", "co_ban", "hang_nang"]
	var kho: Dictionary = CanBang.DO_KHO[do_kho]
	for i in loai_dich.size():
		var loai: String = loai_dich[i]
		var b := _tao_bot_loai(1, loai, "%s %d · %s" % [tr("Đế Chế"), i + 1, tr(CanBang.LOAI_MECHA[loai]["ten"])], CAN_CU[1] + Vector3((i % 3 - 1) * 40.0, 0, -30.0 * (i / 3)))
		b.rotation.y = PI
		b.dk_huong = PI
		b.he_so_sat_thuong = float(kho["he_so_bot"]) * float(b.cs["he_so_hoa_luc"])
		b.he_so_can_chien = CanBang.BOT["he_so_can_chien"]
		var bk := b.dieu_khien as DieuKhienBot
		bk.p_ne /= float(kho["phan_xa"])
		bk.p_do /= float(kho["phan_xa"])
		bots.append(b)
	# phe ta: đồng đội bot (loại chọn ở menu, "ngẫu nhiên" thì máy chọn)
	var ngau := ["co_ban", "hang_nang", "ho_tro", "co_dong"]
	for i in quan_so - 1:
		var loai: String = TienTrinh.dong_doi[i] if i < TienTrinh.dong_doi.size() else "ngau_nhien"
		if loai == "ngau_nhien":
			loai = "co_ban" if _tu_kiem_tra else ngau.pick_random()
		var b := _tao_bot_loai(0, loai, "%s %d" % [tr("Đồng đội"), i + 1], CAN_CU[0] + Vector3((i % 2 * 2 - 1) * 40.0 * (1 + i / 2), 0, 20))
		b.he_so_sat_thuong = CanBang.HE_SO_SAT_THUONG_TIEP_VIEN * float(b.cs["he_so_hoa_luc"])
		dong_doi.append(b)
	_dung_giao_dien()
	AmThanh.nhac("tran")
	if "--thu_vao_tran" in " ".join(OS.get_cmdline_user_args()):
		_thu_vao_tran()

	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			cho_ket_thuc = false
			var tk := TuKiemTra.new()
			tk.ban_do = self
			tk.thu_muc = a.get_slice("=", 1) if "=" in a else "user://anh_thu"
			for b in OS.get_cmdline_user_args():
				if b.begins_with("--quansat="):
					tk.quan_sat = float(b.get_slice("=", 1))
			add_child(tk)


func _tao_mecha(phe: int, ten: String, loai: String, vk: Dictionary, tay_phu: Dictionary, cc: String, vi_tri: Vector3) -> Mecha:
	var m := Mecha.new()
	m.phe = phe
	m.ten = ten
	m.loai = loai
	m.vk = vk.duplicate()
	m.tay_phu = tay_phu.duplicate()
	m.can_chien = cc
	m.position = vi_tri
	m.set_meta("diem_xuat_phat", vi_tri)
	return m


## Bot theo loại mecha: trang bị lấy từ BOT_TRANG_BI (phe địch dùng bản "_dich" có laser báo trước nếu có).
func _tao_bot_loai(phe: int, loai: String, ten: String, vi_tri: Vector3) -> Mecha:
	var tb: Dictionary = CanBang.BOT_TRANG_BI[loai]
	var vk := {}
	for tay in ["phai", "trai"]:
		var x: String = tb["vk"][tay]
		if phe == 1 and CanBang.VU_KHI.has(x + "_dich"):
			x += "_dich"
		vk[tay] = x
	var b := _tao_mecha(phe, ten, loai, vk, tb["tay_phu"], tb["can_chien"], vi_tri)
	b.nut_nang_cap = [TienTrinh.so_nut_phe(phe, loai, 0), TienTrinh.so_nut_phe(phe, loai, 1), TienTrinh.so_nut_phe(phe, loai, 2)]
	var bk := DieuKhienBot.new()
	bk.ban_do = self
	bk.ban_tia = bool(tb.get("ban_tia", false))
	b.dieu_khien = bk
	b.lay_da_lao = CanBang.CAN_CHIEN["lao_chem"]["lay_da_may"]
	b.toc_lao_chem_goc = CanBang.CAN_CHIEN["lao_chem"]["toc_may"]
	b.he_so_sat_thuong = CanBang.HE_SO_SAT_THUONG_BOT
	add_child(bk)
	add_child(b)
	b.bi_ha.connect(_khi_bi_ha)
	return b


## Mecha tiếp viện phe ta: rơi từ tàu sân bay xuống cạnh người chơi rồi tự chiến đấu.
func tao_tiep_vien(vi_tri: Vector3) -> Mecha:
	_so_tiep_vien += 1
	var tb: Dictionary = CanBang.BOT_TRANG_BI["co_ban"]
	var m := _tao_mecha(0, "%s %d" % [tr("Tiếp viện"), _so_tiep_vien], "co_ban", tb["vk"], tb["tay_phu"], tb["can_chien"], vi_tri)
	var bk := DieuKhienBot.new()
	bk.ban_do = self
	bk.hay_lao_chem = 0.7
	m.dieu_khien = bk
	m.lay_da_lao = CanBang.CAN_CHIEN["lao_chem"]["lay_da_may"]
	m.toc_lao_chem_goc = CanBang.CAN_CHIEN["lao_chem"]["toc_may"]
	m.he_so_sat_thuong = CanBang.HE_SO_SAT_THUONG_TIEP_VIEN
	add_child(bk)
	add_child(m)
	m.hoi_sinh(vi_tri)
	m.set_meta("tiep_vien", true)
	m.bi_ha.connect(_khi_bi_ha)
	return m


func _khi_bi_ha(m: Mecha) -> void:
	if m.phe != nguoi_choi.phe:
		hud.bao_ha()
		if m.ke_tan_cong == nguoi_choi or (m.ke_tan_cong is UMinigun and (m.ke_tan_cong as UMinigun).chu == nguoi_choi):
			so_ha += 1
			ho_tro.them_dch(CanBang.DIEM_CHI_HUY["ha"], tr("Hạ %s") % m.ten)
	if m.has_meta("tiep_vien"):
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(m):
			m.queue_free()
		return
	if m == nguoi_choi:
		# người chơi: hiện màn hình chọn điểm hồi sinh trong lúc đếm ngược
		hoi_sinh_con = maxf(1.5, CanBang.HOI_SINH - 0.6 * TienTrinh.so_nut("san_bay", 1))
		if DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		while hoi_sinh_con > 0.0:
			await get_tree().process_frame
			if not get_tree().paused:
				hoi_sinh_con -= get_process_delta_time()
		hoi_sinh_con = 0.0
		var chon := _vi_tri_hoi_sinh(m.phe, hoi_sinh_chon)
		hoi_sinh_chon = chon[0]
		m.hoi_sinh(chon[1])
		if DisplayServer.get_name() != "headless" and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	await get_tree().create_timer(CanBang.HOI_SINH, false).timeout
	if is_instance_valid(m):
		# bot: hồi sinh ở cứ điểm phe mình gần cứ điểm nó đang nhắm nhất, không có thì về căn cứ
		var muc: CuDiem = (m.dieu_khien as DieuKhienBot).cu_diem_muc if m.dieu_khien is DieuKhienBot else null
		var tot := "Căn cứ"
		var kc_tot := INF
		for d in diem_hoi_sinh(m.phe):
			if muc and d[0] != "Căn cứ":
				var kc: float = (d[1] as Vector3).distance_to(muc.global_position)
				if kc < kc_tot:
					kc_tot = kc
					tot = d[0]
		m.hoi_sinh(_vi_tri_hoi_sinh(m.phe, tot)[1])


## Các điểm hồi sinh của một phe: căn cứ + cứ điểm phe đó đang giữ và không có địch trong vòng.
func diem_hoi_sinh(phe: int) -> Array:
	var ds: Array = [["Căn cứ", CAN_CU[phe]]]
	for cd in cu_diem:
		if cd.chu == phe and cd.co_mat[1 - phe] == 0:
			ds.append(["Cứ điểm " + cd.ten, cd.global_position])
	return ds


## [tên, vị trí chạm đất] của điểm hồi sinh tên 	en (không còn hợp lệ thì về căn cứ), lệch ngẫu nhiên một chút.
func _vi_tri_hoi_sinh(phe: int, ten: String) -> Array:
	var ds := diem_hoi_sinh(phe)
	var chon: Array = ds[0]
	for d in ds:
		if d[0] == ten:
			chon = d
	return [chon[0], _cho_dap_trong(chon[1])]


## Tìm chỗ đáp trống quanh `tam`: mặt đất bằng (không phải nóc phế tích), không có ụ súng, máy bay,
## mecha hay phế tích trong vòng 8 m. Thử vài vòng xa dần; không có chỗ nào thì đáp chỗ thoáng nhất đã thử.
func _cho_dap_trong(tam: Vector3) -> Vector3:
	var kg := get_world_3d().direct_space_state
	var cau := SphereShape3D.new()
	cau.radius = 8.0
	var hoi := PhysicsShapeQueryParameters3D.new()
	hoi.shape = cau
	hoi.collision_mask = 2 | 16                      # mecha / ụ súng / máy bay + phế tích, đá, nhà
	var tot := tam
	var it_nhat := 999
	for lan in 30:
		var goc := randf() * TAU
		var r := randf_range(12.0, 30.0 + lan * 1.5)
		var p := tam + Vector3(cos(goc), 0.0, sin(goc)) * r
		var tia := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 400.0, p + Vector3.DOWN * 200.0, 1)
		var trung := kg.intersect_ray(tia)
		if trung.is_empty():
			continue
		var vat = trung["collider"]
		if (vat is CollisionObject3D and ((vat as CollisionObject3D).collision_layer & 16) != 0) or (trung["normal"] as Vector3).y < 0.85:
			continue                                     # nóc phế tích / sườn dốc
		p = trung["position"]
		hoi.transform = Transform3D(Basis(), p + Vector3.UP * 6.0)
		var so := kg.intersect_shape(hoi, 8).size()
		if so == 0:
			return p
		if so < it_nhat:
			it_nhat = so
			tot = p
	return tot


func _process(dt: float) -> void:
	_t += dt
	if _thoi_tiet:
		var c := get_viewport().get_camera_3d()
		if c:
			_thoi_tiet.global_position = c.global_position
	# số liệu tàu sân bay cho các phần cũ (HUD, AI chọn loại cứ điểm, máy bay chở quân)
	for phe in 2:
		var s := tran_troi.san_bay(phe)
		mau_tau[phe] = (s.giap + s.khien) if (s and s.song) else 0.0
	var sb := tran_troi.san_bay(0)
	tau_san_bay = sb if (sb and sb.song) else _moc_tau[0]
	if da_ket_thuc or get_tree().paused:
		return
	thoi_gian_con = maxf(0.0, thoi_gian_con - dt)
	# nhạc căng hơn khi một tàu sân bay dưới 30%
	if minf(tran_troi.ti_le_san_bay(0), tran_troi.ti_le_san_bay(1)) < 0.3:
		AmThanh.nhac("cang")
	if cho_ket_thuc and thoi_gian_con <= 0.0:
		var a := tran_troi.ti_le_san_bay(0)
		var b := tran_troi.ti_le_san_bay(1)
		var kq := 0 if absf(a - b) < 0.005 else (1 if a > b else -1)
		ket_thuc(kq, tr("Hết giờ — tàu sân bay ta còn %d%%, tàu sân bay địch còn %d%%") % [int(a * 100), int(b * 100)])


func _khi_san_bay_bi_ha(phe: int) -> void:
	if not cho_ket_thuc or da_ket_thuc:
		bao(tr("TÀU SÂN BAY %s ĐÃ BỊ HẠ") % tr(CuDiem.TEN_PHE[phe]).to_upper())
		return
	if phe == 1:
		ket_thuc(1, tr("Tàu sân bay địch đã bị hạ!"))
	else:
		ket_thuc(-1, tr("Tàu sân bay phe ta đã bị hạ."))


## Kết thúc trận: tính điểm công trạng, hiện màn kết quả.
func ket_thuc(thang: int, ly_do: String) -> void:
	if da_ket_thuc:
		return
	da_ket_thuc = true
	var diem := TienTrinh.ghi_ket_qua(thang, so_ha, so_cu_diem)
	TienTrinh.ket_qua = {"thang": thang, "ly_do": ly_do, "thoi_gian": CanBang.THOI_GIAN_TRAN - thoi_gian_con,
		"so_ha": so_ha, "cu_diem": so_cu_diem, "thuong": diem,
		"ta": tran_troi.ti_le_san_bay(0), "dich": tran_troi.ti_le_san_bay(1)}
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


func ve_menu() -> void:
	get_tree().paused = false
	AmThanh.dung_nhac()
	get_tree().change_scene_to_file("res://scenes/menu_chinh.tscn")


## Có bảng nào đang mở che màn hình (menu tạm dừng, bảng trang bị, bản đồ chiến hạm, bảng chọn cứ điểm)?
func dang_mo_bang() -> bool:
	return (tam_dung and tam_dung.visible) or (bang_trang_bi and bang_trang_bi.visible) \
		or (ban_do_mat and ban_do_mat.visible) \
		or (menu and menu.visible) or da_ket_thuc or hoi_sinh_con > 0.0


# ---------------------------------------------------------------- cứ điểm, tàu

func bao(s: String) -> void:
	if hud:
		hud.thong_bao(s)


func kich_thuoc() -> float:
	return KICH_THUOC


func can_cu(phe: int) -> Vector3:
	return CAN_CU[phe]


func tau_san_bay_cua(phe: int) -> Node3D:
	var s := tran_troi.san_bay(phe)
	return s if (s and s.song) else _moc_tau[phe]


func sat_thuong_tau(phe: int, luong: float) -> void:
	tran_troi.sat_thuong_san_bay(phe, luong)
	HieuUng.vu_no(self, tau_san_bay_cua(phe).global_position + Vector3(randf_range(-40, 40), 10, randf_range(-60, 60)), 30.0, Color(1.0, 0.6, 0.2))


func sua_tau(phe: int, luong: float) -> void:
	var s := tran_troi.san_bay(phe)
	if s and s.song:
		tran_troi.sua_san_bay(phe, luong)
		bao(tr("Máy bay hậu cần đã sửa tàu sân bay %s (+%d)") % [tr(CuDiem.TEN_PHE[phe]), int(luong)])


## Bảng trang bị (B): chế độ cứ điểm chỉ mở được ở căn cứ hoặc trạm hậu cần phe ta.
func mo_trang_bi() -> void:
	if not co_the_doi_sung(nguoi_choi):
		bao(tr("Chỉ đổi trang bị được ở căn cứ hoặc trong trạm hậu cần phe ta"))
		return
	if bang_trang_bi and not dang_mo_bang() and Time.get_ticks_msec() - bang_trang_bi.t_dong > 300:
		bang_trang_bi.mo()


## Đổi trang bị được ở gần căn cứ phe mình hoặc trong trạm hậu cần phe mình.
func co_the_doi_sung(m: Mecha) -> bool:
	if m.global_position.distance_to(CAN_CU[m.phe]) < 180.0:
		return true
	for cd in cu_diem:
		if cd.chu == m.phe and cd.loai == "hau_can" and cd.trong_vong(m.global_position):
			return true
	return false


## Bật / tắt luật chiếm cứ điểm (tự kiểm tra tắt đi khi thử các phần khác).
func dat_cu_diem(bat: bool) -> void:
	for cd in cu_diem:
		cd.tat = not bat


func _khi_chiem(cd: CuDiem, phe: int) -> void:
	bao(tr("%s đã chiếm cứ điểm %s") % [tr(CuDiem.TEN_PHE[phe]).capitalize(), cd.ten])
	AmThanh.phat("chiem_cu_diem" if phe == nguoi_choi.phe else "mat_cu_diem")
	if phe == nguoi_choi.phe:
		so_cu_diem += 1
		ho_tro.them_dch(CanBang.DIEM_CHI_HUY["chiem"], tr("Chiếm cứ điểm %s") % cd.ten)
		menu.hoi(cd)                     # phe người chơi: tạm dừng để người chơi chọn
	else:
		cd.chon_loai(_ai_chon_loai(cd, phe))


## AI phe máy chọn loại cứ điểm theo bảng ưu tiên đơn giản.
func _ai_chon_loai(cd: CuDiem, phe: int) -> String:
	var dem := {"phao_dai": 0, "ten_lua": 0, "hau_can": 0}
	for x in cu_diem:
		if x.chu == phe and x.loai != "":
			dem[x.loai] += 1
	if tran_troi.ti_le_san_bay(phe) < 0.6 and dem["hau_can"] == 0:
		return "hau_can"                 # tàu sân bay phe mình yếu: cần sửa
	if cd.ten == "C":
		return "phao_dai"                # cứ điểm giữa bản đồ hay bị tranh chấp: xây pháo đài
	if dem["ten_lua"] < 2:
		return "ten_lua"                 # đủ 2 trạm tên lửa để ép tàu sân bay đối phương
	return "phao_dai"

# ---------------------------------------------------------------- dựng cảnh

func _moi_truong() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var hdr := "res://assets_ngoai/troi/kloofendal_48d_partly_cloudy_puresky_2k.hdr"
	if kieu_ban_do == "thanh_pho":
		# thành phố đổ nát: trời âm u, chân trời vàng đục khói bụi
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color(0.34, 0.38, 0.44)
		sm.sky_horizon_color = Color(0.64, 0.59, 0.52)
		sm.ground_bottom_color = Color(0.24, 0.23, 0.22)
		sm.ground_horizon_color = Color(0.62, 0.57, 0.5)
		sm.sun_angle_max = 25.0
		sky.sky_material = sm
	elif ResourceLoader.exists(hdr):
		var pm := PanoramaSkyMaterial.new()
		pm.panorama = load(hdr)
		pm.energy_multiplier = 1.0
		sky.sky_material = pm
	else:
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color(0.3, 0.48, 0.72)
		sm.sky_horizon_color = Color(0.86, 0.78, 0.66)
		sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	var sun := DirectionalLight3D.new()
	var kieu := {}                    # chỉnh màu + sương thể tích riêng từng bản đồ (DoHoa)
	sun.shadow_enabled = bool(TienTrinh.cai_dat.get("bong", true))
	sun.directional_shadow_max_distance = 900.0
	match kieu_ban_do:
		"thanh_pho":
			# thành phố đổ nát: khói bụi xám vàng, nắng vàng nhạt chiếu xiên, tro bay lơ lửng
			env.fog_light_color = Color(0.52, 0.49, 0.45)
			env.fog_density = 0.00055
			env.fog_sky_affect = 0.6
			env.ambient_light_energy = 0.8
			sun.rotation_degrees = Vector3(-38, 25, 0)
			sun.light_color = Color(1.0, 0.87, 0.72)
			sun.light_energy = 1.3
			kieu = {"suong": 0.0025, "mau_suong": Color(0.7, 0.65, 0.58), "bao_hoa": 1.0, "tuong_phan": 1.06}
			_thoi_tiet = _hat_bay(500, Color(0.32, 0.3, 0.28), 0.2, Vector3(0.3, -0.5, 0.2), 0.8)
		"bai_tap":
			# bãi tập: trời trong, nắng sáng, sương rất mỏng
			env.fog_light_color = Color(0.7, 0.76, 0.84)
			env.fog_density = 0.0003
			env.fog_sky_affect = 0.3
			sun.rotation_degrees = Vector3(-46, 30, 0)
			sun.light_color = Color(1.0, 0.95, 0.86)
			sun.light_energy = 1.25
			kieu = {"suong": 0.0, "mau_suong": Color(0.75, 0.82, 0.92), "bao_hoa": 1.02}
		"dong_que":
			# đồng quê: trời trong cao, nắng trưa, tầm nhìn xa
			env.fog_light_color = Color(0.68, 0.76, 0.86)
			env.fog_density = 0.00025
			env.fog_sky_affect = 0.35
			env.ambient_light_energy = 0.85
			sun.rotation_degrees = Vector3(-44, 40, 0)
			sun.light_color = Color(1.0, 0.95, 0.85)
			sun.light_energy = 1.2
			kieu = {"suong": 0.0, "mau_suong": Color(0.8, 0.86, 0.95), "bao_hoa": 0.98, "tuong_phan": 1.03}
			_thoi_tiet = _hat_bay(400, Color(1.0, 0.95, 0.75), 0.1, Vector3(0.2, 0.1, 0.1), 0.5)
		_:
			# ngoại ô: trời trong, nắng chiều vàng ấm, sương mỏng xanh ở xa
			env.fog_light_color = Color(0.62, 0.7, 0.8)
			env.fog_density = 0.00035
			env.fog_sky_affect = 0.4
			env.ambient_light_energy = 0.85
			sun.rotation_degrees = Vector3(-34, 60, 0)
			sun.light_color = Color(1.0, 0.9, 0.76)
			sun.light_energy = 1.35
			kieu = {"suong": 0.0, "mau_suong": Color(0.86, 0.8, 0.7), "bao_hoa": 1.03}
	we.environment = env
	add_child(we)
	add_child(sun)
	DoHoa.ap_moi_truong(we, sun, kieu, TienTrinh.cai_dat["do_hoa"])


## Hạt bay quanh camera (tuyết rơi / bụi phấn): một khối 140 × 70 × 140 m đi theo camera, hạt rơi theo thế giới.
func _hat_bay(so: int, mau: Color, co: float, trong_luc: Vector3, lac: float) -> GPUParticles3D:
	var h := GPUParticles3D.new()
	h.amount = so
	h.lifetime = 9.0
	h.preprocess = 9.0
	h.local_coords = false
	h.visibility_aabb = AABB(Vector3(-90, -50, -90), Vector3(180, 100, 180))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(70, 35, 70)
	pm.gravity = trong_luc
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = lac
	pm.direction = Vector3(0.4, 0, 0.2)
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 6.0
	h.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(co, co)
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/hat_bay.gdshader")
	m.set_shader_parameter("mau", Color(mau.r, mau.g, mau.b, 0.9))
	q.material = m
	h.draw_pass_1 = q
	h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(h)
	return h


## Mặt đất: địa hình theo kiểu bản đồ, có khối va chạm theo độ cao, san phẳng quanh căn cứ, cứ điểm, đường.
func _mat_dat() -> void:
	match kieu_ban_do:
		"thanh_pho":
			_dung_ban_do = DungThanhPho.new()
		"ngoai_o":
			_dung_ban_do = DungNgoaiO.new()
		"dong_que":
			_dung_ban_do = DungDongQue.new()
		"bai_tap":
			_dung_ban_do = DungBaiTap.new()
		_:
			_dung_ban_do = DungThanhPho.new()
	_dung_ban_do.tinh_duong(self)
	dia_hinh = DiaHinh.new()
	dia_hinh.kieu = kieu_ban_do
	for cc in CAN_CU:
		dia_hinh.vung_phang.append([Vector2(cc.x, cc.z), 290.0, 430.0])
	for ten in VI_TRI_CU_DIEM:
		dia_hinh.vung_phang.append([Vector2(VI_TRI_CU_DIEM[ten].x, VI_TRI_CU_DIEM[ten].z), 140.0, 300.0])
	dia_hinh.duong_phang = _dung_ban_do.duong
	var mat := ShaderMaterial.new()
	mat.shader = load({"ngoai_o": "res://scripts/mat_ngoai_o.gdshader", "dong_que": "res://scripts/mat_dong_que.gdshader",
		"bai_tap": "res://scripts/mat_bai_tap.gdshader"}.get(kieu_ban_do, "res://scripts/mat_thanh_pho.gdshader"))
	mat.set_shader_parameter("tex_bt", load("res://assets_ngoai/mat_dat/concrete_floor_worn_001_diff_2k.jpg"))
	var ds_duong: Array[Vector4] = []
	for d in _dung_ban_do.duong:
		ds_duong.append(Vector4(d[0].x, d[0].y, d[1].x, d[1].y))
	while ds_duong.size() < 12:
		ds_duong.append(Vector4.ZERO)
	mat.set_shader_parameter("duong", ds_duong)
	var vung: Array[Vector4] = []
	for cc in CAN_CU:
		vung.append(Vector4(cc.x, cc.z, 240.0, 0.0))
	for ten in VI_TRI_CU_DIEM:
		vung.append(Vector4(VI_TRI_CU_DIEM[ten].x, VI_TRI_CU_DIEM[ten].z, 115.0, 0.0))
	while vung.size() < 8:
		vung.append(Vector4.ZERO)
	mat.set_shader_parameter("vung", vung)
	if _dung_ban_do.has_method("cai_mat_dat"):
		_dung_ban_do.call("cai_mat_dat", mat)
	add_child(dia_hinh)
	dia_hinh.dung(mat)


## Cảnh vật, căn cứ (xem dung_thanh_pho.gd, dung_ngoai_o.gd, dung_dong_que.gd, dung_bai_tap.gd).
func _vat_can() -> void:
	var t0 := Time.get_ticks_msec()
	add_child(_dung_ban_do)
	_dung_ban_do.dung(self, dia_hinh)
	var cay_n: Variant = _dung_ban_do.get("cay")
	var them := ", %d cay, %d bui" % [cay_n.so_cay, cay_n.so_bui] if cay_n is TrongCay else ""
	print("[ban_do] %s: %d nha (%d do nat), %d da%s, dung trong %d ms" % [kieu_ban_do, _dung_ban_do.so_nha, _dung_ban_do.so_nha_do, _dung_ban_do.so_da, them, Time.get_ticks_msec() - t0])


func _tau_tren_troi() -> void:
	tran_troi = TranTrenTroi.new()
	tran_troi.ban_do = self
	add_child(tran_troi)
	tran_troi.dung()
	tran_troi.san_bay_bi_ha.connect(_khi_san_bay_bi_ha)
	for phe in 2:
		var moc := Node3D.new()
		add_child(moc)
		moc.global_position = tran_troi.san_bay(phe).global_position
		_moc_tau.append(moc)
	tau_san_bay = tran_troi.san_bay(0)


## Phép thử đi trọn vòng (--thu_vao_tran): vào trận từ menu, chụp ảnh, kết thúc trận, về menu.
func _thu_vao_tran() -> void:
	await get_tree().create_timer(8.0).timeout
	print("[thu_menu] trong tran: %d mecha phe ta, %d mecha dich, %d tau tren troi, FPS %d" % [dong_doi.size() + 1, bots.size(), tran_troi.tau.size(), Engine.get_frames_per_second()])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--thu_menu="):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.get_slice("=", 1).path_join("m11_trong_tran_6v6.png"))
	ket_thuc(1, tr("Phép thử: kết thúc trận"))
	await get_tree().create_timer(2.0).timeout
	ve_menu()
