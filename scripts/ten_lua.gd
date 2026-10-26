class_name TenLua
extends Area3D
## Tên lửa đuổi theo mục tiêu. Tăng tốc dần, bẻ lái có giới hạn: bật lao ngang đúng lúc là né được
## (lệch quá "bo_bam_goc" so với mục tiêu thì thôi bám, bay thẳng tới hết giờ). Pháo nhiệt kéo nó đi chỗ khác.
## Chỉ đạn súng máy bắn rơi được (xem tren_duong_dan) — bị bắn rơi thì nổ giữa đường, không gây sát thương.
## Tên lửa chống tàu (trạm tên lửa): bay lên tàu sân bay địch (tau_dich).

signal bi_ban_ha(boi: Node)

var chu: Node
var phe := 0
var muc_tieu: Node3D               # Mecha, máy bay, pháo nhiệt
var diem_dich := Vector3.ZERO      # không có mục tiêu thì bay về điểm này
var tau_dich: Node3D = null        # tên lửa chống tàu: bay lên tàu sân bay địch
var khi_toi_tau: Callable          # gọi khi trúng tàu
var toc_do := 95.0                 # tốc độ tối đa
var quay := 2.4                    # bẻ lái (rad/s)
var sat_thuong := 280.0
var ban_kinh_no := 7.0
var mau := Color(1.6, 0.8, 0.4)
var co := 1.0                      # to / nhỏ (tên lửa loạt nhỏ hơn)
var thoi_gian := -1.0              # -1: lấy CanBang.TEN_LUA["song"]
var huong := Vector3.FORWARD
var _toc := 0.0
var _song := 0.0
var _bam := true
var _da_no := false


func _ready() -> void:
	add_to_group("ten_lua")
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	if thoi_gian < 0.0:
		thoi_gian = CanBang.TEN_LUA["song"]
	_toc = minf(float(CanBang.TEN_LUA["toc_dau"]), toc_do)
	scale = Vector3.ONE * co
	var hinh := CollisionShape3D.new()
	var cau := SphereShape3D.new()
	cau.radius = 2.2
	hinh.shape = cau
	add_child(hinh)
	var than := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.28
	cm.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	mat.metallic = 0.5
	cm.material = mat
	than.mesh = cm
	than.rotation.x = -PI * 0.5      # trục dài theo -Z (hướng bay)
	add_child(than)
	var lua := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.3
	lm.bottom_radius = 0.0
	lm.height = 2.4
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	lmat.albedo_color = mau
	lm.material = lmat
	lua.mesh = lm
	lua.rotation.x = -PI * 0.5
	lua.position.z = 2.2
	add_child(lua)
	var den := OmniLight3D.new()
	den.light_color = mau
	den.light_energy = 2.0
	den.omni_range = 10.0
	add_child(den)
	# vệt khói
	var vet := HieuUng.vet_khoi()
	vet.position = Vector3(0, 0, 1.2)
	add_child(vet)
	var am := AmThanh.vong_lap("ten_lua_bay", self)      # tiếng động cơ bay theo tên lửa, mất khi nổ
	if am.stream:
		am.play()


func diem_ngam_vao() -> Vector3:
	return global_position


func _physics_process(dt: float) -> void:
	if _da_no:
		return
	_song += dt
	if _song >= thoi_gian:
		_no(global_position, true)
		return
	_toc = minf(_toc + float(CanBang.TEN_LUA["gia_toc"]) * dt, toc_do)
	var dich := diem_dich
	var co_dich := diem_dich != Vector3.ZERO
	if is_instance_valid(tau_dich):
		dich = tau_dich.global_position
		co_dich = true
		if global_position.distance_to(dich) < 45.0:
			if khi_toi_tau.is_valid():
				khi_toi_tau.call()
			_da_no = true
			HieuUng.vu_no(get_parent(), global_position, 22.0, mau)
			queue_free()
			return
	elif _bam and is_instance_valid(muc_tieu) and muc_tieu.get("song") != false:
		dich = Mecha.diem_cua(muc_tieu)
		co_dich = true
		if global_position.distance_to(dich) < float(CanBang.TEN_LUA["kich_no"]) * maxf(co, 0.8):
			_no(global_position, not (muc_tieu is PhaoNhiet))     # tới pháo nhiệt thì nổ vô hại
			return
	if co_dich and _song > 0.25:
		var muon := (dich - global_position).normalized()
		var goc := huong.angle_to(muon)
		if tau_dich == null and is_instance_valid(muc_tieu) and rad_to_deg(goc) > float(CanBang.TEN_LUA["bo_bam_goc"]):
			_bam = false                                           # đã bị né: thôi bám, bay thẳng
		elif goc > 0.0001:
			huong = huong.slerp(muon, minf(1.0, quay * dt / goc)).normalized()
	var tu := global_position
	var toi := tu + huong * _toc * dt
	var ex: Array[RID] = []
	if is_instance_valid(chu) and chu is CollisionObject3D:
		ex.append((chu as CollisionObject3D).get_rid())
	var q := PhysicsRayQueryParameters3D.create(tu, toi, 1 | 2, ex)
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	if kq and not (kq["collider"] is Mecha and (kq["collider"] as Mecha).phe == phe):
		_no(kq["position"], true)
		return
	global_position = toi
	if absf(huong.dot(Vector3.UP)) < 0.99:
		look_at(toi + huong, Vector3.UP)


## Bị đạn súng máy bắn trúng giữa đường.
func bi_ban(boi: Node = null) -> void:
	if _da_no:
		return
	bi_ban_ha.emit(boi)
	_no(global_position, false)


func _no(p: Vector3, gay_sat_thuong: bool) -> void:
	_da_no = true
	if gay_sat_thuong:
		for n in get_tree().get_nodes_in_group("mecha"):
			var m := n as Mecha
			if m and m.song and m.phe != phe:
				var d := m.tam_than().distance_to(p)
				var tam := ban_kinh_no + 4.0
				if d < tam:
					var dmg := sat_thuong * (1.0 - 0.5 * d / tam)
					m.nhan_sat_thuong(dmg, chu if is_instance_valid(chu) else null)
					m.trung_ten_lua()
					if is_instance_valid(chu) and chu.has_signal("ban_trung"):
						chu.ban_trung.emit(m, dmg)
		DanPlasma.no_cong_trinh(get_tree(), p, ban_kinh_no, sat_thuong, phe)
	HieuUng.vu_no(get_parent(), p, ban_kinh_no * co if gay_sat_thuong else 4.0, mau)
	queue_free()


## Tên lửa (của phe khác) gần đường đạn a→b nhất trong bán kính trúng, gần a nhất; không có thì null.
static func tren_duong_dan(tree: SceneTree, a: Vector3, b: Vector3, phe_ban: int) -> TenLua:
	var tot: TenLua = null
	var t_tot := INF
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.01:
		return null
	var r: float = CanBang.TEN_LUA["ban_kinh_trung"]
	for n in tree.get_nodes_in_group("ten_lua"):
		var tl := n as TenLua
		if tl == null or tl.phe == phe_ban or tl.is_queued_for_deletion() or tl._da_no:
			continue
		var t := clampf((tl.global_position - a).dot(ab) / l2, 0.0, 1.0)
		if (a + ab * t).distance_to(tl.global_position) < r * maxf(tl.co, 0.7) and t < t_tot:
			t_tot = t
			tot = tl
	return tot
