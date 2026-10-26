class_name USung
extends StaticBody3D
## Ụ súng của cứ điểm: tự xoay về mecha địch gần nhất trong tầm (không bị nhà che) rồi bắn.
## Bắn hỏng được (súng, pháo, tên lửa, pháo kích đều trúng). Lúc mới xây thì mọc dần lên từ mặt đất.
## Ụ tên lửa không bắn mecha: cứ điểm dùng nó để phóng tên lửa vào tàu sân bay địch.

signal bi_pha(u: USung)

var loai := "sung_may"
var phe := 0
var cs: Dictionary
var mau := 1000.0
var xong := false                 # đã xây xong chưa
var ten := "Ụ súng"
var he_so_mau := 1.0              # nâng cấp pháo đài: ụ bền hơn
var song := true
var mau_toi_da := 1000.0
var ten_hien := "Ụ súng"          # tên hiện ở khung khóa (khóa dịch)
var tam_phat_hien := -1.0         # chiến dịch: >0 thì chỉ bắn mecha trong tầm này (mặc định = tầm bắn)
var he_so_sat_thuong := 1.0       # chiến dịch: ụ địch bắn nhẹ hơn (như mecha địch)
var _model: Node3D
var _hoi := 0.0
var _muc: Mecha = null
var _tim_lai := 0.0


func _ready() -> void:
	add_to_group("cong_trinh")
	cs = CanBang.U_SUNG[loai]
	mau = float(cs["mau"]) * he_so_mau
	mau_toi_da = mau
	ten = cs["ten"]
	ten_hien = cs["ten"]
	collision_layer = 2
	collision_mask = 0
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(6, 6, 6)
	hinh.shape = hop
	hinh.position.y = 3.0
	add_child(hinh)
	_model = (load(cs["model"]) as PackedScene).instantiate()
	add_child(_model)
	_model.position.y = -6.0                 # nằm dưới đất, xây xong mới trồi lên
	# vòng màu phe dưới chân
	var vong := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.6
	tm.outer_radius = 4.2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = CuDiem.MAU_PHE[phe]
	tm.material = mat
	vong.mesh = tm
	vong.scale = Vector3(1, 0.3, 1)
	vong.position.y = 0.15
	add_child(vong)


## Xây: trồi lên trong `thoi_gian` giây, có bụi và tia lửa hàn.
func xay(thoi_gian: float) -> void:
	var tw := create_tween()
	tw.tween_property(_model, "position:y", 0.0, thoi_gian).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	HieuUng.tia_lua(get_parent(), global_position + Vector3.UP * 2.0, Vector3.UP, Color(1.8, 1.2, 0.5), 24)
	await tw.finished
	if is_instance_valid(self):
		xong = true


func tam_than() -> Vector3:
	return global_position + Vector3.UP * 3.5


func nhan_sat_thuong(luong: float, _tu: Node = null) -> void:
	if mau <= 0.0:
		return
	mau -= luong
	if mau <= 0.0:
		pha()


func pha() -> void:
	mau = 0.0
	song = false
	HieuUng.vu_no(get_parent(), global_position + Vector3.UP * 3.0, 12.0, Color(1.0, 0.6, 0.2))
	bi_pha.emit(self)
	queue_free()


func _physics_process(dt: float) -> void:
	if not xong:
		return
	_hoi = maxf(0.0, _hoi - dt)
	_tim_lai -= dt
	if _tim_lai <= 0.0:
		_tim_lai = 0.4
		_muc = _tim_muc_tieu()
	if _muc == null or not is_instance_valid(_muc) or not _muc.song:
		return
	var d := global_basis.inverse() * (_muc.tam_than() - global_position)   # hướng tới mục tiêu, tính trong hệ toạ độ của ụ
	var goc_muon := atan2(d.x, d.z)                  # mô hình nhìn về +Z
	_model.rotation.y = rotate_toward(_model.rotation.y, goc_muon, float(cs["quay"]) * dt)
	if absf(angle_difference(_model.rotation.y, goc_muon)) < 0.15 and _hoi <= 0.0:
		_ban()


func _diem_nong() -> Vector3:
	var toi := _model.global_basis.z.normalized()
	return global_position + Vector3.UP * 3.6 + toi * 4.0


func _tim_muc_tieu() -> Mecha:
	var tot: Mecha = null
	var kc_tot: float = cs["tam"] if tam_phat_hien <= 0.0 else minf(float(cs["tam"]), tam_phat_hien)
	var kg := get_world_3d().direct_space_state
	for n in get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e == null or not e.song or e.phe == phe or e.dang_roi:
			continue
		var kc := e.global_position.distance_to(global_position)
		if kc >= kc_tot:
			continue
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 4.0, e.tam_than(), 1)
		if not kg.intersect_ray(q).is_empty():
			continue
		tot = e
		kc_tot = kc
	return tot


func _ban() -> void:
	_hoi = cs["nhip"]
	var nong := _diem_nong()
	var dich := _muc.tam_than()
	AmThanh.phat({"ten_lua": "ten_lua_phong", "dan_cham": "phao_plasma"}.get(cs["kieu"], "sung_truong"), nong)
	if cs["kieu"] == "ten_lua":
		# loạt tên lửa đuổi theo mecha địch (bắn hạ được bằng súng tay)
		for k in int(cs["so_qua"]):
			var tl := TenLua.new()
			tl.phe = phe
			tl.muc_tieu = _muc
			tl.toc_do = cs["toc_do_dan"]
			tl.quay = cs["quay_dan"]
			tl.sat_thuong = float(cs["sat_thuong"]) * he_so_sat_thuong
			tl.ban_kinh_no = cs["no"]
			tl.mau = Color(1.8, 0.5, 0.3) if phe == 1 else Color(0.6, 0.9, 1.8)
			tl.huong = (Vector3.UP + _model.global_basis.z * 0.6 + _model.global_basis.x * (k - 0.5) * 0.4).normalized()
			get_parent().add_child(tl)
			tl.global_position = global_position + Vector3.UP * 7.0 + _model.global_basis.x * (k - 0.5) * 2.5
		return
	if cs["kieu"] == "dan_cham":
		dich += _muc.velocity * (nong.distance_to(dich) / float(cs["toc_do_dan"]))
		var dan := DanPlasma.new()
		dan.phe = phe
		dan.van_toc = (dich - nong).normalized() * float(cs["toc_do_dan"])
		dan.sat_thuong = float(cs["sat_thuong"]) * he_so_sat_thuong
		dan.ban_kinh_no = cs["no"]
		dan.mau = Color(1.6, 0.6, 0.2) if phe == 1 else Color(0.5, 0.9, 1.6)
		get_parent().add_child(dan)
		dan.global_position = nong
		return
	var huong := (dich - nong).normalized()
	var lech := deg_to_rad(float(cs["lech"]))
	huong = huong.rotated(Vector3.UP, randf_range(-lech, lech)).rotated(huong.cross(Vector3.UP).normalized(), randf_range(-lech, lech) * 0.5)
	var q := PhysicsRayQueryParameters3D.create(nong, nong + huong * float(cs["tam"]) * 1.1, 1 | 2, [get_rid()])
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	var cuoi := nong + huong * float(cs["tam"])
	if kq:
		cuoi = kq["position"]
		var m := kq["collider"] as Mecha
		if m and m.phe != phe:
			m.nhan_sat_thuong(float(cs["sat_thuong"]) * he_so_sat_thuong, self)
		AmThanh.phat("trung_dan" if m else "dan_cham_dat", cuoi)
	HieuUng.vet_dan(get_parent(), nong, cuoi, Color(1.6, 0.9, 0.4))
