class_name CuDiem
extends Node3D
## Một cứ điểm. Lúc đầu trận để trống.
## Chiếm: mecha đứng trong vòng. Chỉ một phe có mặt thì thanh chiếm chạy (nhiều mecha nhanh hơn, tối đa x2);
## hai phe cùng có mặt thì đứng yên. Cứ điểm của địch phải kéo thanh về 0 trước — lúc đó mọi công trình,
## ụ súng, quân đồn trú bị PHÁ SẠCH — rồi mới chiếm sang phe mình.
## Chiếm xong: chọn loại (phe người chơi: game tạm dừng để chọn; phe máy: tự chọn).
## Sau đó máy bay chở quân từ tàu sân bay xuống, quân đồn trú tới và ụ súng được xây dần từng cái.

signal da_chiem(cu_diem: CuDiem, phe: int)
signal mat(cu_diem: CuDiem, phe_cu: int)
signal xay_xong(cu_diem: CuDiem)

const MAU_PHE := [Color(0.35, 0.7, 1.0), Color(1.0, 0.3, 0.25)]
const MAU_TRUNG_LAP := Color(0.75, 0.75, 0.75)
const TEN_PHE := ["Liên Hiệp", "Đế Chế"]     # phe ta (mecha xanh) / phe địch (mecha đỏ)

var ten := "A"
var ban_do: Node                   # BanDoThu
var chu := -1                      # -1: trống, 0: Trắng, 1: Đen
var thanh := 0.0                   # -1..1: +1 = Trắng giữ hẳn, -1 = Đen giữ hẳn
var loai := ""                     # "", "phao_dai", "ten_lua", "hau_can"
var dang_xay := false
var co_mat := [0, 0]               # số mecha mỗi phe đang đứng trong vòng
var suc_chiem := [0.0, 0.0]        # tổng sức chiếm (mecha Cơ động chiếm nhanh hơn, Hạng nặng chậm hơn)
var _hen_emp := 0.0                # trạm tên lửa hướng EMP: đếm tới lần phóng EMP kế tiếp
var he_so_toc_do := 1.0            # để tự kiểm tra chạy nhanh
var chu_ky := 30.0
var u_sung: Array[USung] = []
var quan: Array[Node3D] = []
var tat := false                   # tắt luật chiếm (tự kiểm tra)

var _ban_kinh: float
var _mat_vong: StandardMaterial3D
var _mat_co: StandardMaterial3D
var _den: OmniLight3D
var _hen_gio := 0.0
var _phien := 0                    # tăng mỗi lần mất cứ điểm, để huỷ việc xây đang dở


func _ready() -> void:
	add_to_group("cu_diem")
	_ban_kinh = CanBang.CU_DIEM["ban_kinh"]
	chu_ky = CanBang.CU_DIEM["chu_ky"]
	# bệ tròn thấp (đi lên được) + vòng chiếm trên mặt đất + cột cờ phát sáng
	var be := StaticBody3D.new()
	be.collision_layer = 1
	var hinh := CollisionShape3D.new()
	var tru := CylinderShape3D.new()
	tru.radius = 26.0
	tru.height = 0.35                     # thấp để mecha lướt lên được (thân mecha bo tròn trượt qua mép)
	hinh.shape = tru
	hinh.position.y = 0.175
	be.add_child(hinh)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 26.0
	cm.bottom_radius = 27.0
	cm.height = 0.35
	cm.radial_segments = 48
	var mat_be := StandardMaterial3D.new()
	mat_be.albedo_color = Color(0.42, 0.43, 0.42)
	mat_be.roughness = 0.9
	cm.material = mat_be
	mi.mesh = cm
	mi.position.y = 0.175
	be.add_child(mi)
	add_child(be)
	var vong := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = _ban_kinh - 1.5
	tm.outer_radius = _ban_kinh
	tm.rings = 96
	_mat_vong = StandardMaterial3D.new()
	_mat_vong.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_vong.albedo_color = MAU_TRUNG_LAP
	tm.material = _mat_vong
	vong.mesh = tm
	vong.scale = Vector3(1, 0.2, 1)
	vong.position.y = 0.2
	vong.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(vong)
	var cot := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.6
	cc.bottom_radius = 1.2
	cc.height = 32.0
	var mat_cot := StandardMaterial3D.new()
	mat_cot.albedo_color = Color(0.3, 0.3, 0.32)
	mat_cot.metallic = 0.5
	cc.material = mat_cot
	cot.mesh = cc
	cot.position.y = 16.8
	add_child(cot)
	var co := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 4.0, 7.0)
	_mat_co = StandardMaterial3D.new()
	_mat_co.albedo_color = MAU_TRUNG_LAP
	_mat_co.emission_enabled = true
	_mat_co.emission = MAU_TRUNG_LAP
	_mat_co.emission_energy_multiplier = 1.2
	bm.material = _mat_co
	co.mesh = bm
	co.position = Vector3(0, 30.0, 3.6)
	add_child(co)
	_den = OmniLight3D.new()
	_den.light_color = MAU_TRUNG_LAP
	_den.light_energy = 3.0
	_den.omni_range = 45.0
	_den.position.y = 34.0
	add_child(_den)
	_to_mau()


func _to_mau() -> void:
	var mau: Color = MAU_TRUNG_LAP if chu < 0 else MAU_PHE[chu]
	_mat_vong.albedo_color = mau
	_mat_co.albedo_color = mau
	_mat_co.emission = mau
	_den.light_color = mau


func ten_loai() -> String:
	return tr(CanBang.LOAI_CU_DIEM[loai]["ten"]) if loai != "" else (tr("đang chọn loại") if chu >= 0 else tr("trống"))


func trong_vong(p: Vector3) -> bool:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length() <= _ban_kinh


# ---------------------------------------------------------------- chiếm

func _physics_process(dt: float) -> void:
	co_mat = [0, 0]
	suc_chiem = [0.0, 0.0]
	for n in get_tree().get_nodes_in_group("mecha"):
		var m := n as Mecha
		if m and m.song and trong_vong(m.global_position):
			co_mat[m.phe] += 1
			suc_chiem[m.phe] += float(m.cs.get("he_so_chiem", 1.0))
	if tat:
		return
	var toc := 1.0 / float(CanBang.CU_DIEM["thoi_gian_chiem"]) * he_so_toc_do
	var cu := thanh
	if co_mat[0] > 0 and co_mat[1] == 0:
		thanh = minf(1.0, thanh + toc * _he_so(0) * dt)
	elif co_mat[1] > 0 and co_mat[0] == 0:
		thanh = maxf(-1.0, thanh - toc * _he_so(1) * dt)
	elif co_mat[0] == 0 and co_mat[1] == 0:
		var ve := 0.0 if chu < 0 else (1.0 if chu == 0 else -1.0)
		thanh = move_toward(thanh, ve, float(CanBang.CU_DIEM["hoi_phuc"]) * dt)
	# mất cứ điểm khi thanh về 0 (hoặc đổi dấu)
	if chu == 0 and thanh <= 0.0 and cu > 0.0:
		_mat_chu()
	elif chu == 1 and thanh >= 0.0 and cu < 0.0:
		_mat_chu()
	# chiếm xong
	if chu < 0 and absf(thanh) >= 1.0:
		_duoc_chiem(0 if thanh > 0.0 else 1)
	_hieu_qua(dt)


func _he_so(phe_chiem: int) -> float:
	var s: float = suc_chiem[phe_chiem]
	var k := clampf(0.5 + 0.5 * s, 0.5, 2.0)          # 1 mecha thường x1, 2 mecha x1,5, 3+ mecha x2
	if chu >= 0 and chu != phe_chiem and loai == "phao_dai":
		k *= float(CanBang.LOAI_CU_DIEM["phao_dai"]["he_so_bi_chiem"]) * (1.0 - 0.12 * _nut("phao_dai", 2))
	return k


func _nut(muc: String, huong: int) -> int:
	return TienTrinh.so_nut_phe(maxi(chu, 0), muc, huong)


func _duoc_chiem(phe: int) -> void:
	chu = phe
	loai = ""
	_to_mau()
	da_chiem.emit(self, phe)


func _mat_chu() -> void:
	var cu := chu
	chu = -1
	loai = ""
	dang_xay = false
	_phien += 1
	for u in u_sung:
		if is_instance_valid(u):
			u.pha()
	u_sung.clear()
	for q in quan:
		if is_instance_valid(q):
			q.queue_free()
	quan.clear()
	_to_mau()
	mat.emit(self, cu)


# ---------------------------------------------------------------- xây dựng

## Gọi sau khi phe chủ chọn loại. Máy bay chở quân bay xuống, quân đồn trú tới, ụ súng xây dần.
func chon_loai(l: String) -> void:
	if chu < 0:
		return
	loai = l
	dang_xay = true
	_hen_gio = chu_ky
	var phien := _phien
	var phe := chu
	var cfg: Dictionary = CanBang.LOAI_CU_DIEM[l]
	ban_do.bao(tr("%s chọn %s tại cứ điểm %s") % [tr(TEN_PHE[phe]).capitalize(), tr(cfg["ten"]), ten])
	# máy bay chở quân từ tàu sân bay xuống
	var tau: Node3D = ban_do.tau_san_bay_cua(phe)
	var mb := MayBay.new()
	mb.phe = phe
	var day := global_position + Vector3(0, 2.0, 0)
	var tren := global_position + Vector3(0, 60.0, 0)
	var toc: float = float(CanBang.CU_DIEM["may_bay_toc_do"]) * he_so_toc_do
	if ban_do.mau_tau[phe] <= 0.0:
		toc *= 0.5                                         # mất tàu sân bay: tiếp viện chậm hẳn
	mb.duong = [[tren, toc], [day, 12.0 * he_so_toc_do]]
	_noi_bi_ban_roi(mb)
	ban_do.add_child(mb)
	mb.global_position = tau.global_position + Vector3(0, -30, 0)
	await mb.toi_noi
	if phien != _phien or not is_instance_valid(mb):
		if is_instance_valid(mb):
			mb.queue_free()
		return
	# quân đồn trú xuống máy bay
	var so_quan: int = int(CanBang.CU_DIEM["quan_don_tru"]) + int(cfg.get("quan_them", 0)) + _nut("san_bay", 0)
	if l == "phao_dai":
		so_quan += 2 * _nut("phao_dai", 1)
	for k in so_quan:
		_tao_linh(phe, k, so_quan)
	# máy bay quay về
	mb.toi_noi.connect(mb.queue_free, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	mb.bay([[tren, 12.0], [tau.global_position + Vector3(0, -30, 0), toc]])
	# xây ụ súng: 2 ụ súng máy cơ bản + ụ theo loại
	var ds: Array = ["sung_may", "sung_may"] + (cfg["u"] as Array)
	if l == "phao_dai":
		if _nut("phao_dai", 1) >= 2:
			ds.append("sung_may_doi")
		if _nut("phao_dai", 1) >= 4:
			ds.append("phao")
	var thoi_gian: float = CanBang.CU_DIEM["xay_moi_u"] / he_so_toc_do / (1.0 + 0.15 * _nut("san_bay", 0))
	for k in ds.size():
		if phien != _phien:
			return
		var u := USung.new()
		u.loai = ds[k]
		u.phe = phe
		if l == "phao_dai":
			u.he_so_mau = 1.0 + 0.12 * _nut("phao_dai", 0)
		var goc := TAU * k / ds.size() + 0.4
		var r := 20.0 if k < 2 else (36.0 if k < 6 else 44.0)
		ban_do.add_child(u)
		u.global_position = global_position + Vector3(cos(goc), 0.0, sin(goc)) * r + Vector3(0, 0.35 if r < 26.0 else 0.0, 0)
		u.rotation.y = goc + PI * 0.5
		u_sung.append(u)
		u.bi_pha.connect(func(x: USung) -> void: u_sung.erase(x))
		u.xay(thoi_gian * 0.8)
		await get_tree().create_timer(thoi_gian, false).timeout
	if phien == _phien:
		dang_xay = false
		xay_xong.emit(self)


func _tao_linh(phe: int, k: int, tong: int) -> void:
	var goc := TAU * k / tong
	var linh := Node3D.new()
	var than := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.77, 0.8) if phe == 0 else Color(0.2, 0.2, 0.22)
	cap.material = mat
	than.mesh = cap
	than.position.y = 0.9
	linh.add_child(than)
	var mu := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.5
	var mat_mu := StandardMaterial3D.new()
	mat_mu.albedo_color = MAU_PHE[phe]
	sm.material = mat_mu
	mu.mesh = sm
	mu.position.y = 1.85
	linh.add_child(mu)
	ban_do.add_child(linh)
	linh.global_position = global_position + Vector3(cos(goc), 0.0, sin(goc)) * randf_range(6.0, 14.0) + Vector3(0, 0.35, 0)
	quan.append(linh)


# ---------------------------------------------------------------- hiệu quả theo loại

func _hieu_qua(dt: float) -> void:
	if chu < 0 or loai == "":
		return
	if loai == "hau_can":
		# sửa giáp mecha phe ta đứng trong vòng
		var sua: float = float(CanBang.LOAI_CU_DIEM["hau_can"]["sua_mecha"]) * (1.0 + 0.15 * _nut("hau_can", 1))
		for n in get_tree().get_nodes_in_group("mecha"):
			var m := n as Mecha
			if m and m.song and m.phe == chu and trong_vong(m.global_position):
				m.mau = minf(float(m.cs["mau"]), m.mau + sua * dt)
	if dang_xay:
		return
	# trạm tên lửa hướng EMP: thêm 1 tên lửa EMP theo nhịp riêng
	if loai == "ten_lua" and _nut("ten_lua", 2) >= 1:
		_hen_emp -= dt
		if _hen_emp <= 0.0:
			_hen_emp = float(CanBang.TRAN_TROI["emp_chu_ky"]) - 10.0 * (_nut("ten_lua", 2) - 1)
			for u in u_sung:
				if is_instance_valid(u) and u.loai == "ten_lua" and u.xong:
					ban_do.tran_troi.phong_tu_dat(chu, u.global_position + Vector3.UP * 7.0, 400.0, true)
					AmThanh.phat("ten_lua_phong", u.global_position)
					break
	_hen_gio -= dt
	if _hen_gio > 0.0:
		return
	_hen_gio = chu_ky
	if loai == "ten_lua":
		_hen_gio = chu_ky * (1.0 - 0.08 * _nut("ten_lua", 1))
	match loai:
		"ten_lua":
			for u in u_sung:
				if is_instance_valid(u) and u.loai == "ten_lua" and u.xong:
					_phong_chong_tau(u)
		"hau_can":
			_gui_hau_can()


## Tên lửa từ ụ tên lửa bay lên trời, vào tàu địch mà phe này đang ưu tiên (mặc định tàu sân bay).
## Tàu phòng không địch bắn hạ được giữa đường.
func _phong_chong_tau(u: USung) -> void:
	var dmg: float = float(CanBang.LOAI_CU_DIEM["ten_lua"]["sat_thuong_tau"]) * (1.0 + 0.12 * _nut("ten_lua", 0))
	ban_do.tran_troi.phong_tu_dat(chu, u.global_position + Vector3.UP * 7.0, dmg, false)
	AmThanh.phat("ten_lua_phong", u.global_position)


func _gui_hau_can() -> void:
	var phe := chu
	var tau: Node3D = ban_do.tau_san_bay_cua(phe)
	var mb := MayBay.new()
	mb.phe = phe
	# cất cánh chậm (dễ bị bắn rơi) rồi mới bay nhanh lên tàu
	var nhanh := 1.0 + 0.15 * _nut("hau_can", 2)
	mb.duong = [[global_position + Vector3(0, 120.0, 0), 14.0 * nhanh], [tau.global_position + Vector3(0, -30, 0), float(CanBang.CU_DIEM["may_bay_toc_do"]) * nhanh]]
	mb.mau *= 1.0 + 0.2 * _nut("hau_can", 2)
	_noi_bi_ban_roi(mb)
	ban_do.add_child(mb)
	mb.global_position = global_position + Vector3(0, 3.0, 0)
	var hp: float = float(CanBang.LOAI_CU_DIEM["hau_can"]["sua_tau"]) * (1.0 + 0.15 * _nut("hau_can", 0))
	mb.toi_noi.connect(func() -> void:
		ban_do.sua_tau(phe, hp)
		mb.queue_free())
	mb.bi_ban_roi.connect(func() -> void: ban_do.bao(tr("Máy bay hậu cần %s bị bắn rơi tại %s!") % [tr(TEN_PHE[phe]), ten]))


## Máy bay địch bị bắn rơi: phe người chơi được Điểm Chỉ Huy.
func _noi_bi_ban_roi(mb: MayBay) -> void:
	var phe_mb := mb.phe
	mb.bi_ban_roi.connect(func() -> void:
		if phe_mb != ban_do.nguoi_choi.phe and ban_do.ho_tro:
			ban_do.ho_tro.them_dch(CanBang.DIEM_CHI_HUY["may_bay"], tr("Bắn rơi máy bay địch")))
