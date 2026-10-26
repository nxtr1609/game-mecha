class_name DieuKhienBot
extends Node
## Bot mecha (phe địch, đồng đội, tiếp viện, địch trong chiến dịch). Bấm "phím" qua các lệnh dk_* như người chơi.
## - Chế độ cứ điểm: không có địch gần thì đi chiếm cứ điểm (ưu tiên cứ điểm trống / của địch gần nhất, giữ
##   cứ điểm phe mình đang bị chiếm; các bot cùng phe chia nhau ra). Tránh nhà bằng tia dò phía trước.
## - Chiến dịch: tuần tra quanh chỗ đứng ("tuan_tra", "lang_thang" thì đi tuần khắp vùng), chỉ đánh và bám theo khi đã
##   PHÁT HIỆN đối thủ (trong "tam_phat_hien" mét và nhìn thấy, không bị nhà che) hoặc bị bắn trúng; mất dấu lâu thì về tuần.
##   Số địch tấn công cùng lúc do dieu_phoi (LuotTanCong) quyết theo độ khó: chưa tới lượt thì đứng xa chờ, không bắn;
##   bị đối thủ bắn trúng thì đánh trả ngay.
## - Gặp địch: lượn ngang, giữ cự ly theo súng, bật lao né, thỉnh thoảng bay lên; bắn khi thấy;
##   phóng tên lửa / dùng tay phụ theo nhịp; tên lửa lao tới thì phóng pháo nhiệt (có phản xạ, không phải lần nào
##   cũng kịp) hoặc lấy súng máy bắn rơi; gần thì chém, trong tầm thì thỉnh thoảng lao chém.
## - Bị lao chém: quyết một lần (né / đỡ / chịu) theo xác suất rồi bấm đúng lúc như người chơi.
## - Đứng trong vùng pháo kích của địch: sau một lúc phản ứng thì lao ra ngoài.

var ban_do: Node                  # để biết các cứ điểm (chế độ cứ điểm); null trong chiến dịch
var ban_tia := false             # kiểu bắn tỉa: giữ khoảng cách xa, ít lao chém
var tam_giao_tranh := 380.0      # địch gần hơn mức này (và nhìn thấy) thì đánh, không thì đi chiếm cứ điểm / tuần tra
var tuan_tra := false            # chiến dịch: đứng canh quanh diem_canh, chỉ đánh khi phát hiện địch
var lang_thang := false          # chiến dịch: đi tuần qua các điểm ngẫu nhiên quanh diem_canh (đội săn)
var diem_canh := Vector3.ZERO
var tam_phat_hien := 380.0
var dieu_phoi: LuotTanCong = null   # chiến dịch: giới hạn số địch tấn công cùng lúc
var san_lung := false            # luôn đi tìm địch gần nhất (máy lái thay người chơi khi tự kiểm tra)
var danh_cong_trinh := false     # hết mecha địch thì đánh công trình địch (ụ súng) — chiến dịch
var p_ne := 0.35                 # xác suất né cú lao chém
var p_do := 0.10                 # xác suất đỡ
var hay_lao_chem := 1.0          # nhân tần suất lao chém
var cu_diem_muc: CuDiem = null   # cứ điểm đang nhắm tới
var muc_tieu: Node3D
var so_lan_ket := 0

var _chon_lai := 0.0
var _lech_dung := Vector3.ZERO   # mỗi bot đứng một chỗ hơi khác trong vòng
var _chieu := 1.0
var _doi_chieu := 2.0
var _hoi_lao := 2.0
var _hoi_bay := 6.0
var _bay_con := 0.0
var _hoi_tp := {"trai": 4.0, "phai": 7.0}
var _thay_tl := -1.0
var _se_phao := false
var _giu_tran := 0.0
var _ket := 0.0
var _hoi_lc := 4.0
var _hoi_chem := 0.0
var _quyet := {}                 # id kẻ đang lao chém mình -> "ne" / "do" / "" (quyết một lần mỗi cú)
var _vung_thay := {}             # vùng pháo kích đã thấy -> [giây đã thấy, giây phản ứng]
var _ket_t := 0.0
var _thoat_t := 0.0
var _thoat_huong := 0.0
var _noi_su_kien := false
var _bi_ban_t := 0.0             # vừa bị đối thủ bắn trúng: đánh trả ngay (vượt giới hạn số địch tấn công)
var _diem_tuan := Vector3.ZERO   # lang thang: điểm đang đi tới
var _doi_diem_tuan := 0.0

const NHO_DAU := 10.0            # phát hiện rồi thì nhớ đối thủ bấy nhiêu giây sau lần cuối nhìn thấy
const CACH_CHO := 380.0          # chưa tới lượt tấn công: đứng cách đối thủ chừng này

func _ready() -> void:
	p_ne = CanBang.BOT["ne_lao_chem"]
	p_do = CanBang.BOT["do_lao_chem"]
	_hoi_tp = {"trai": randf_range(3.0, 7.0), "phai": randf_range(5.0, 10.0)}
	_hoi_lc = randf_range(3.0, 7.0)


func dieu_khien(m: Mecha, dt: float) -> void:
	if not _noi_su_kien:
		_noi_su_kien = true
		m.bi_trung.connect(func(tu: Node, _luong: float) -> void:
			if tu != null and is_instance_valid(tu) and tu.get("phe") != null and tu.get("phe") != m.phe:
				_giu_tran = maxf(_giu_tran, NHO_DAU)
				_bi_ban_t = 8.0)
	m.dk_ban["phai"] = false
	m.dk_ban["trai"] = false
	m.dk_bay = false
	m.muc_tieu_ban = null
	_phong_thu(m)
	muc_tieu = _chon_muc_tieu(m)
	var kc := INF
	var thay := false
	if muc_tieu:
		kc = muc_tieu.global_position.distance_to(m.global_position)
		thay = _thay(m, muc_tieu)
	_giu_tran -= dt
	_bi_ban_t -= dt
	# phát hiện: đối thủ trong tầm phát hiện VÀ nhìn thấy (hoặc vừa bị bắn); đã phát hiện thì bám theo khi còn thấy
	if tuan_tra and muc_tieu and thay and (kc < tam_phat_hien or (_giu_tran > 0.0 and kc < tam_phat_hien * 2.5)):
		_giu_tran = maxf(_giu_tran, NHO_DAU)
	var phat_hien := not tuan_tra or san_lung or _giu_tran > 0.0
	# chỉ khóa (và bắn) khi nhìn thấy mục tiêu, không bị nhà che
	m.khoa = muc_tieu if (muc_tieu and phat_hien and thay and kc < maxf(float(m.vk_chinh().get("tam_khoa", 650.0)), 650.0)) else null
	if ban_do and ban_do.get("cu_diem") != null:
		_chon_lai -= dt
		if _chon_lai <= 0.0:
			_chon_lai = randf_range(2.5, 4.0)
			cu_diem_muc = _chon_cu_diem(m)
			_lech_dung = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * 25.0
	var giao_tranh := muc_tieu != null and phat_hien and (thay or san_lung or tuan_tra) \
		and kc < tam_giao_tranh * (2.2 if ban_tia else 1.0) * (3.0 if (san_lung or tuan_tra) else 1.0)
	if giao_tranh:
		_giu_tran = maxf(_giu_tran, 0.5)
	_doi_chieu -= dt
	if _doi_chieu <= 0.0:
		_doi_chieu = randf_range(1.8, 4.0)
		_chieu = -_chieu if randf() < 0.7 else _chieu

	if giao_tranh and dieu_phoi and not san_lung and not dieu_phoi.duoc_tan_cong(m, _bi_ban_t > 0.0):
		m.khoa = null
		_cho_luot(m, thay)
	elif giao_tranh:
		_danh(m, dt, kc, thay)
	elif tuan_tra and not san_lung:
		_canh(m)
	else:
		_di_toi_cu_diem(m)
		if muc_tieu:
			m.dk_ngam = Mecha.diem_cua(muc_tieu)
		_thoat_ket(m, dt)

	# đứng trong vùng pháo kích của địch: sau một lúc phản ứng thì lao ra khỏi vòng đỏ
	var thoat := _huong_thoat_vung(m, dt)
	if thoat != Vector3.ZERO:
		var toi_b := -m.global_basis.z
		m.dk_di = Vector2(thoat.dot(m.global_basis.x), thoat.dot(toi_b)).normalized()
		if m.nhiet < m.nhiet_toi_da() * 0.6 and _hoi_lao <= 0.0:
			m.dk_lao = true
			_hoi_lao = 1.0
	_tranh_ten_lua(m, dt)
	_bay_con -= dt
	if _bay_con > 0.0 and not m.qua_nhiet:
		m.dk_bay = true


## Đánh nhau: mặt hướng về địch, giữ cự ly, lượn ngang, bật lao, bay, bắn, tay phụ, cận chiến.
func _danh(m: Mecha, dt: float, kc: float, thay: bool) -> void:
	var dv := muc_tieu.global_position - m.global_position
	var d := Vector2(dv.x, dv.z).length()
	m.dk_huong = atan2(-dv.x, -dv.z)
	m.dk_ngam = Mecha.diem_cua(muc_tieu)
	var xa_nhat := 800.0 if ban_tia else 280.0
	var gan_nhat := 450.0 if ban_tia else 150.0
	if m.vk["phai"] == "sung_may" and not ban_tia:
		xa_nhat = 220.0
		gan_nhat = 80.0
	var tien := 0.0
	if d > xa_nhat or (not thay and d > 60.0):
		tien = 1.0
	elif d < gan_nhat and thay:
		tien = -1.0
	m.dk_di = Vector2(_chieu * (1.0 if thay else 0.4), tien).normalized()
	# đang ở cứ điểm cần giữ / chiếm mà bị kéo ra ngoài vòng: lượn dần về lại vòng
	if cu_diem_muc and not ban_tia and not cu_diem_muc.trong_vong(m.global_position) \
			and cu_diem_muc.global_position.distance_to(m.global_position) < 250.0:
		var ve := (cu_diem_muc.global_position - m.global_position)
		ve.y = 0.0
		ve = ve.normalized()
		m.dk_di = (m.dk_di + Vector2(ve.dot(m.global_basis.x), ve.dot(-m.global_basis.z))).limit_length(1.0)
	# mục tiêu trên cao (ụ trên mái nhà): bay lên ngang tầm mới bắn trúng
	if dv.y > 8.0 and d < 350.0 and m.is_on_floor() and _bay_con <= 0.0 and m.nhiet < m.nhiet_toi_da() * 0.5:
		_bay_con = clampf(dv.y / 20.0, 0.8, 2.2)
	# vướng tường: đổi chiều lướt, bay vượt lên
	if m.is_on_wall():
		_ket += dt
	else:
		_ket = maxf(0.0, _ket - dt * 0.5)
	if _ket > 0.5 and not m.qua_nhiet:
		_ket = 0.0
		_chieu = -_chieu
		_bay_con = 2.2
	# bật lao né, thỉnh thoảng bay lên (giữ nhiệt: không lao bừa khi sắp quá nhiệt)
	var nmax := m.nhiet_toi_da()
	_hoi_lao -= dt
	if _hoi_lao <= 0.0 and m.nhiet < nmax * 0.55:
		_hoi_lao = randf_range(2.2, 4.5)
		m.dk_lao = true
	_hoi_bay -= dt
	if _hoi_bay <= 0.0 and m.nhiet < nmax * 0.35:
		_hoi_bay = randf_range(8.0, 15.0)
		_bay_con = maxf(_bay_con, randf_range(0.8, 1.8))
	if not m.khoa:
		return
	# cận chiến: gần thì chém; trong tầm đánh dấu thì thỉnh thoảng lao chém
	_hoi_lc -= dt
	_hoi_chem -= dt
	if muc_tieu is Mecha and not m.dang_bi_choang():
		if d < 18.0 and _hoi_chem <= 0.0:
			_hoi_chem = randf_range(1.2, 2.0)
			m.dk_chem = true
		elif not ban_tia and d <= float(CanBang.CAN_CHIEN["lao_chem"]["tam_danh_dau"]) * 0.9 and _hoi_lc <= 0.0 and m.co_the_lao_chem():
			var H2: Array = CanBang.BOT["hoi_lao_chem"]
			_hoi_lc = randf_range(H2[0], H2[1]) / maxf(hay_lao_chem, 0.1)
			m.dk_lao_chem = true
	elif d < 18.0 and _hoi_chem <= 0.0:
		_hoi_chem = randf_range(1.2, 2.0)
		m.dk_chem = true
	# tay phụ Q / E theo nhịp
	for ben in ["trai", "phai"]:
		_hoi_tp[ben] -= dt
		if _hoi_tp[ben] > 0.0 or m.hoi_tay_phu[ben] > 0.0:
			continue
		var tp: String = m.tay_phu[ben]
		var dung := false
		match tp:
			"ten_lua", "ten_lua_loat":
				dung = d < float(CanBang.TEN_LUA["tam_khoa"])
			"khien":
				dung = d < 500.0
			"u_minigun":
				dung = d < 400.0 and m.is_on_floor()
			"sung_may_vai":
				dung = false                              # bật khi có tên lửa bay tới (xem _tranh_ten_lua)
		if dung:
			var H: Array = CanBang.BOT["hoi_ten_lua"]
			_hoi_tp[ben] = randf_range(H[0], H[1])
			m.dk_tay_phu[ben] = true
	# bắn
	for tay in ["phai", "trai"]:
		var vk: Dictionary = CanBang.VU_KHI[m.vk[tay]]
		var ban_tl: bool = m.muc_tieu_ban != null and vk.get("chan_ten_lua", false)
		m.dk_ban[tay] = ban_tl or (thay and kc < float(vk["tam"]))


## Đã phát hiện đối thủ nhưng chưa tới lượt tấn công: quay mặt về nó, giữ khoảng cách CACH_CHO, lượn ngang, không bắn.
func _cho_luot(m: Mecha, thay: bool) -> void:
	var dv := muc_tieu.global_position - m.global_position
	var d := Vector2(dv.x, dv.z).length()
	m.dk_huong = atan2(-dv.x, -dv.z)
	m.dk_ngam = Mecha.diem_cua(muc_tieu)
	var tien := 0.0
	if d > CACH_CHO + 80.0 or (not thay and d > CACH_CHO * 0.5):
		tien = 1.0
	elif d < CACH_CHO - 60.0:
		tien = -1.0
	m.dk_di = Vector2(_chieu * 0.5, tien).limit_length(1.0)
	if m.di_bo and m.is_on_floor():
		m.dk_ctrl = true


## Chiến dịch: chưa phát hiện địch thì đứng canh, lượn chậm quanh chỗ canh (lang_thang: đi tuần qua các điểm ngẫu nhiên).
func _canh(m: Mecha) -> void:
	var dich := diem_canh
	if lang_thang:
		_doi_diem_tuan -= get_physics_process_delta_time()
		var toi_noi := Vector2(_diem_tuan.x - m.global_position.x, _diem_tuan.z - m.global_position.z).length() < 40.0
		if _diem_tuan == Vector3.ZERO or _doi_diem_tuan <= 0.0 or toi_noi:
			_doi_diem_tuan = randf_range(14.0, 24.0)
			var g := randf() * TAU
			_diem_tuan = diem_canh + Vector3(cos(g), 0.0, sin(g)) * randf_range(80.0, 420.0)
		dich = _diem_tuan
	var d := dich - m.global_position
	d.y = 0.0
	if d.length() > 40.0:
		var huong := _tranh_vat_can(m, d.normalized())
		m.dk_huong = atan2(-huong.x, -huong.z)
		m.dk_di = Vector2(0.0, 0.6)
		if not m.di_bo and m.is_on_floor():
			m.dk_ctrl = true                             # đi tuần thì chạy bộ
	else:
		m.dk_di = Vector2.ZERO
	m.dk_ngam = Vector3.ZERO


## Tên lửa đang lao vào mình: pháo nhiệt (sau phản xạ), súng máy vai, hoặc súng máy tay bắn rơi.
func _tranh_ten_lua(m: Mecha, dt: float) -> void:
	var tl_gan: TenLua = null
	var d_tl := INF
	for n in m.get_tree().get_nodes_in_group("ten_lua"):
		var tl := n as TenLua
		if tl and tl.muc_tieu == m:
			var k := tl.global_position.distance_to(m.global_position)
			if k < d_tl:
				d_tl = k
				tl_gan = tl
	if tl_gan == null:
		_thay_tl = -1.0
		return
	var B: Dictionary = CanBang.BOT
	if _thay_tl < 0.0:
		_thay_tl = 0.0
		_se_phao = randf() < float(B["ty_le_phao_nhiet"])
		for ben in ["trai", "phai"]:
			if m.tay_phu[ben] == "sung_may_vai" and m.hoi_tay_phu[ben] <= 0.0:
				m.dk_tay_phu[ben] = true
	_thay_tl += dt
	if _se_phao and _thay_tl > float(B["phan_xa_phao_nhiet"]) and m.phao_nhiet > 0 and d_tl > float(CanBang.PHAO_NHIET["gan_qua"]) + 5.0:
		m.dk_phao_nhiet = true
		_se_phao = false
	if d_tl < 170.0:
		for tay in ["phai", "trai"]:
			if CanBang.VU_KHI[m.vk[tay]].get("chan_ten_lua", false):
				m.muc_tieu_ban = tl_gan
				m.dk_ban[tay] = true


## Bị lao chém: quyết một lần (né / đỡ / chịu), rồi bấm đúng lúc như người chơi.
func _phong_thu(m: Mecha) -> void:
	for n in m.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or e == m or e.phe == m.phe or not e.dang_lao_chem_vao(m):
			continue
		var id := e.get_instance_id()
		if not _quyet.has(id):
			# lao càng nhanh càng khó né / đỡ
			var kho := minf(1.0, float(CanBang.CAN_CHIEN["lao_chem"]["toc"]) / maxf(e.toc_lao_chem(), 1.0))
			var r := randf()
			_quyet[id] = "do" if r < p_do * kho else ("ne" if r < (p_do + p_ne) * kho else "")
		var con := e.t_toi_va_cham()
		if _quyet[id] == "ne" and con <= minf(0.22, float(m.cs["cua_so_ne"]) * 0.8):
			m.dk_di = Vector2(_chieu, 0.0)
			m.dk_lao = true
			_quyet[id] = "xong"
		elif _quyet[id] == "do" and con <= minf(0.08, float(m.cs["cua_so_do"]) * 0.7):
			m.dk_chem = true
			_quyet[id] = "xong"
	if _quyet.size() > 8:
		_quyet.clear()


func _chon_muc_tieu(m: Mecha) -> Node3D:
	var tot: Node3D = null
	var kc_tot := 1e9 if (san_lung or tuan_tra) else 900.0
	for n in m.get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or not e.song or e.phe == m.phe or e.dang_roi:
			continue
		var kc := e.global_position.distance_to(m.global_position)
		if kc < kc_tot:
			tot = e
			kc_tot = kc
	if tot == null and danh_cong_trinh:
		for n in m.get_tree().get_nodes_in_group("cong_trinh"):
			var c := n as Node3D
			if c == null or c.get("song") == false or c.get("phe") == m.phe or c.get("phe") == null:
				continue
			var kc := c.global_position.distance_to(m.global_position)
			if kc < kc_tot:
				tot = c
				kc_tot = kc
	return tot


func _thay(m: Mecha, e: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(m.tam_than() + Vector3.UP * 2.0, Mecha.diem_cua(e), 1)
	return m.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Hướng (thế giới, nằm ngang) để chạy ra khỏi vùng pháo kích của địch; Vector3.ZERO nếu không cần.
func _huong_thoat_vung(m: Mecha, dt: float) -> Vector3:
	for n in m.get_tree().get_nodes_in_group("vung_nguy_hiem"):
		var v := n as Node3D
		if v == null or int(v.get_meta("phe", -1)) == m.phe:
			continue
		var d := m.global_position - v.global_position
		d.y = 0.0
		var r: float = v.get_meta("ban_kinh", 30.0)
		if d.length() > r + 10.0:
			continue
		var id := v.get_instance_id()
		if not _vung_thay.has(id):
			_vung_thay[id] = [0.0, randf_range(0.5, 1.4)]
		_vung_thay[id][0] += dt
		if _vung_thay[id][0] >= _vung_thay[id][1]:
			return d.normalized() if d.length() > 0.5 else m.global_basis.x
	return Vector3.ZERO


## Chọn cứ điểm để đi: cứ điểm trống / của địch gần nhất, cứ điểm phe mình đang bị địch chiếm thì ưu tiên giữ.
## Bot cùng phe đã nhắm cứ điểm nào thì cứ điểm đó bị cộng thêm "khoảng cách", để chia nhau ra.
func _chon_cu_diem(m: Mecha) -> CuDiem:
	if ban_do == null:
		return null
	var tot: CuDiem = null
	var diem_tot := INF
	var dich := 1 - m.phe
	for cd in ban_do.cu_diem as Array:
		var c := cd as CuDiem
		var kc := c.global_position.distance_to(m.global_position)
		var diem := kc
		if c.chu == m.phe:
			if c.co_mat[dich] == 0 and absf(c.thanh) > 0.95:
				continue                                  # của mình và yên ổn: khỏi đi
			diem -= 400.0                                 # đang bị chiếm: đi giữ
		elif c.chu == dich:
			diem += 250.0 if c.loai == "phao_dai" else 120.0
		for n in m.get_tree().get_nodes_in_group("mecha"):
			var b := n as Mecha
			if b and b != m and b.song and b.phe == m.phe and b.dieu_khien is DieuKhienBot \
					and (b.dieu_khien as DieuKhienBot).cu_diem_muc == c:
				diem += 500.0
		if diem < diem_tot:
			diem_tot = diem
			tot = c
	return tot


## Đi tới cứ điểm đang nhắm (bật lao nếu còn xa), tới nơi thì lượn trong vòng để chiếm / giữ.
## Không có cứ điểm (chiến dịch, săn lùng): đi thẳng tới mục tiêu.
func _di_toi_cu_diem(m: Mecha) -> void:
	if m.di_bo and m.is_on_floor():
		m.dk_ctrl = true                                  # đi đường thì lướt
	var dich := Vector3.ZERO
	if cu_diem_muc:
		dich = cu_diem_muc.global_position + _lech_dung
		if ban_tia:
			# bắn tỉa đứng xa canh chừng: dừng cách cứ điểm khoảng 300 m về phía căn cứ mình
			var ve_nha: Vector3 = (ban_do.can_cu(m.phe) - cu_diem_muc.global_position).normalized()
			dich = cu_diem_muc.global_position + ve_nha * 300.0
	elif muc_tieu:
		dich = muc_tieu.global_position
	else:
		m.dk_di = Vector2.ZERO
		return
	var d := dich - m.global_position
	d.y = 0.0
	if d.length() < 18.0 or (cu_diem_muc and not ban_tia and cu_diem_muc.trong_vong(m.global_position) and d.length() < 30.0):
		m.dk_di = Vector2(_chieu * 0.5, 0.0)            # tới nơi: lượn nhẹ trong vòng
		return
	var huong := _tranh_vat_can(m, d.normalized())
	m.dk_huong = atan2(-huong.x, -huong.z)
	m.dk_di = Vector2(0.0, 1.0)
	_hoi_lao -= get_physics_process_delta_time()
	if d.length() > 220.0 and m.nhiet < m.nhiet_toi_da() * 0.3 and _hoi_lao <= 0.0:
		_hoi_lao = randf_range(1.2, 2.5)
		m.dk_lao = true


## Bị nhà chặn (muốn đi mà gần như đứng yên): quay ngang rồi lướt đi một đoạn;
## kẹt nhiều lần liền thì bay vọt qua.
func _thoat_ket(m: Mecha, dt: float) -> void:
	var toc := Vector2(m.velocity.x, m.velocity.z).length()
	if _thoat_t > 0.0:
		_thoat_t -= dt
		m.dk_huong = _thoat_huong
		m.dk_di = Vector2(0.0, 1.0)
		if so_lan_ket >= 3 and m.nhiet < m.nhiet_toi_da() * 0.5:
			_bay_con = maxf(_bay_con, 0.3)
		return
	if m.dk_di.length() > 0.5 and toc < 4.0 and m.is_on_floor():
		_ket_t += dt
	else:
		_ket_t = maxf(0.0, _ket_t - dt * 0.5)
		if toc > 15.0:
			so_lan_ket = maxi(0, so_lan_ket - 1) if randf() < dt * 0.2 else so_lan_ket
	if _ket_t > 1.6:
		_ket_t = 0.0
		so_lan_ket += 1
		_thoat_t = 1.5
		_thoat_huong = m.rotation.y + (PI * 0.5 if randf() < 0.5 else -PI * 0.5) + randf_range(-0.4, 0.4)


## Dò phía trước: hướng thẳng bị nhà chắn thì thử lệch dần sang hai bên.
func _tranh_vat_can(m: Mecha, huong: Vector3) -> Vector3:
	var kg := m.get_world_3d().direct_space_state
	var goc := m.global_position + Vector3.UP * 5.0
	for lech in [0.0, 0.6, -0.6, 1.1, -1.1, 1.6, -1.6]:
		var h := huong.rotated(Vector3.UP, lech)
		var q := PhysicsRayQueryParameters3D.create(goc, goc + h * 55.0, 16)   # lớp 16: vật cản (không tính đồi cát)
		if kg.intersect_ray(q).is_empty():
			return h
	return huong.rotated(Vector3.UP, 2.2)
