class_name DieuKhienNguoiChoi
extends Node
## Đọc bàn phím / chuột (theo bảng phím Phim, đổi được ở Cài đặt), khóa mục tiêu nằm trong vòng ngắm,
## rồi ra lệnh cho mecha của người chơi.

var cam: CameraRig
var ho_tro: HoTro
var ban_do: Node
const GIU_KHOA := 1.3       # đã khóa rồi thì giữ tới khi ra ngoài vòng ngắm lớn hơn chừng này lần


func dieu_khien(m: Mecha, _dt: float) -> void:
	var bang_che: bool = ban_do != null and ban_do.has_method("dang_mo_bang") and ban_do.dang_mo_bang()
	m.dk_di = Vector2(Input.get_axis("di_trai", "di_phai"), Input.get_axis("di_lui", "di_toi"))
	m.dk_huong = cam.yaw
	var khoa_cu := m.khoa
	m.khoa = _tim_khoa(m)
	if m.khoa != null and m.khoa != khoa_cu:
		AmThanh.phat("khoa_muc_tieu")
	if m.khoa is Mecha:
		(m.khoa as Mecha).da_bi_khoa = true
	var bo_qua: Array[RID] = [m.get_rid()]
	m.dk_ngam = cam.diem_ngam(bo_qua)
	m.dk_ban["phai"] = Input.is_action_pressed("ban_phai") and not bang_che
	m.dk_ban["trai"] = Input.is_action_pressed("ban_trai") and not bang_che
	m.dk_bay = Input.is_action_pressed("bay")
	m.dk_giu_lao = Input.is_action_pressed("lao") and not bang_che
	if bang_che:
		return
	if Input.is_action_just_pressed("lao"):
		m.dk_lao = true
	if Input.is_action_just_pressed("doi_che_do"):
		m.dk_ctrl = true
	if Input.is_action_just_pressed("roi_nhanh"):
		m.dk_roi = true
	if Input.is_action_just_pressed("tay_phu_trai"):
		m.dk_tay_phu["trai"] = true
	if Input.is_action_just_pressed("tay_phu_phai"):
		m.dk_tay_phu["phai"] = true
	if Input.is_action_just_pressed("phao_nhiet"):
		m.dk_phao_nhiet = true
	if Input.is_action_just_pressed("can_chien"):
		# F: mecha địch đang khóa trong tầm (chữ F hiện cạnh nó) thì lao chém, không thì chém thường;
		# đang bị lao chém thì F là đỡ (Mecha tự xét)
		if m.co_the_lao_chem() and m.ke_dang_lao_toi() == null:
			m.dk_lao_chem = true
		else:
			m.dk_chem = true
	m.muc_tieu_ban = _ten_lua_gan_tam(m)
	if Input.is_action_just_pressed("trang_bi") and ban_do and ban_do.has_method("mo_trang_bi"):
		ban_do.mo_trang_bi()
	if ho_tro:
		for k in 4:
			if Input.is_action_just_pressed("ho_tro_%d" % (k + 1)):
				ho_tro.goi(k)


## Khóa mục tiêu địch (mecha, máy bay, ụ súng) nằm trong vòng ngắm, gần tâm nhất, nhìn thấy được, trong tầm khóa.
func _tim_khoa(m: Mecha) -> Node3D:
	var goc_cam := cam.cam.global_position
	var tam_khoa := maxf(float(m.vk_chinh().get("tam_khoa", 650.0)), float(CanBang.TEN_LUA["tam_khoa"]))
	var tot: Node3D = null
	var diem_tot := INF
	var ds := m.get_tree().get_nodes_in_group("mecha") + m.get_tree().get_nodes_in_group("may_bay") \
		+ m.get_tree().get_nodes_in_group("cong_trinh")
	for n in ds:
		var e := n as Node3D
		if e == null or e == m or e.get("song") == false or e.get("phe") == m.phe or e.get("phe") == null:
			continue
		if e is Mecha and (e as Mecha).dang_roi:
			continue
		var p := Mecha.diem_cua(e)
		var d: Vector3 = p - goc_cam
		if d.length() > tam_khoa:
			continue
		var cach := HUD.cach_tam(cam.cam, p)
		if cach > HUD.R * (GIU_KHOA if e == m.khoa else 1.0):
			continue
		var diem := cach * (0.6 if e is Mecha else 1.0)     # ưu tiên mecha hơn công trình
		if diem >= diem_tot:
			continue
		var q := PhysicsRayQueryParameters3D.create(goc_cam, p, 1)
		if m.get_world_3d().direct_space_state.intersect_ray(q):
			continue                      # bị vật cản che
		tot = e
		diem_tot = diem
	return tot


## Súng máy chặn tên lửa: đang bắn súng máy mà có tên lửa địch trong vòng ngắm, cách mình ≤ 170 m
## (HUD đánh dấu bằng tam giác rỗng) thì đạn ngắm vào quả gần tâm nhất.
func _ten_lua_gan_tam(m: Mecha) -> Node3D:
	var co_may := false
	for tay in ["phai", "trai"]:
		if m.dk_ban[tay] and CanBang.VU_KHI[m.vk[tay]].get("chan_ten_lua", false):
			co_may = true
	if not co_may:
		return null
	var tot: TenLua = null
	var cach_tot := HUD.R
	for n in m.get_tree().get_nodes_in_group("ten_lua"):
		var tl := n as TenLua
		if tl == null or tl.phe == m.phe or tl.global_position.distance_to(m.global_position) > 170.0:
			continue
		var cach := HUD.cach_tam(cam.cam, tl.global_position)
		if cach <= cach_tot:
			cach_tot = cach
			tot = tl
	return tot
