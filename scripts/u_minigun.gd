class_name UMinigun
extends StaticBody3D
## Ụ minigun của mecha Hỗ trợ (kỹ năng E). Chỉ bắn mecha địch ĐANG BAY NHANH trong tầm:
## khóa mục tiêu 1 giây (còi báo cho mục tiêu biết) rồi xả đạn. Tắt bay kịp thì thoát.
## Độ bền thấp, địch đi bộ tới là phá được dễ dàng.
## Mô hình: ụ súng máy đôi của người làm game (models/u_sung/u_sung_may_doi.glb), thu nhỏ còn 80%.

const MO_HINH := "res://models/u_sung/u_sung_may_doi.glb"
const TI_LE := 0.8

var phe := 0
var chu: Mecha
var mau := 700.0
var song := true
var muc: Mecha = null              # mecha đang bị khóa
var khoa_con := 0.0                # đã khóa được bao lâu (>= bao_truoc thì bắn)
var _hoi := 0.0
var _dau: Node3D
var _cs: Dictionary


func _ready() -> void:
	_cs = CanBang.U_MINIGUN
	mau = _cs["mau"]
	add_to_group("cong_trinh")
	add_to_group("u_minigun")
	collision_layer = 2
	collision_mask = 0
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(4.3, 4.4, 5.0)
	hinh.shape = hop
	hinh.position.y = 2.2
	add_child(hinh)
	if ResourceLoader.exists(MO_HINH):
		_dau = (load(MO_HINH) as PackedScene).instantiate() as Node3D
		_dau.scale = Vector3.ONE * TI_LE
	else:
		_dau = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3, 2, 4)
		(_dau as MeshInstance3D).mesh = bm
		_dau.position.y = 2.0
	add_child(_dau)
	var den := OmniLight3D.new()
	den.light_color = CuDiem.MAU_PHE[phe]
	den.light_energy = 1.5
	den.omni_range = 10.0
	den.position.y = 4.0
	add_child(den)


func tam_than() -> Vector3:
	return global_position + Vector3.UP * 2.5


func _physics_process(dt: float) -> void:
	if not song:
		return
	_hoi = maxf(0.0, _hoi - dt)
	if muc and (not is_instance_valid(muc) or not muc.song or not muc.dang_bay or not _thay(muc)):
		muc = null
		khoa_con = 0.0
	if muc == null:
		muc = _tim()
		khoa_con = 0.0
		return
	var d := global_basis.inverse() * (muc.tam_than() - tam_than())    # hướng tới mục tiêu trong hệ toạ độ của ụ
	_dau.rotation.y = lerp_angle(_dau.rotation.y, atan2(d.x, d.z), 1.0 - exp(-dt * 8.0))   # mô hình nhìn về +Z
	khoa_con += dt
	if khoa_con >= float(_cs["bao_truoc"]) and _hoi <= 0.0:
		_hoi = _cs["nhip"]
		_ban()


func _thay(m: Mecha) -> bool:
	if m.global_position.distance_to(global_position) > float(_cs["tam"]):
		return false
	var q := PhysicsRayQueryParameters3D.create(tam_than(), m.tam_than(), 1)
	return not get_world_3d().direct_space_state.intersect_ray(q)


func _tim() -> Mecha:
	var tot: Mecha = null
	var kc_tot := INF
	for n in get_tree().get_nodes_in_group("mecha"):
		var m := n as Mecha
		if m and m.song and m.phe != phe and m.dang_bay and _thay(m):
			var kc := m.global_position.distance_to(global_position)
			if kc < kc_tot:
				tot = m
				kc_tot = kc
	return tot


func _ban() -> void:
	var tu := global_position + Vector3.UP * 3.4 + _dau.global_basis.z.normalized() * 3.0
	var huong := (muc.tam_than() + muc.velocity * 0.05 - tu).normalized()
	huong = huong.rotated(Vector3.UP, deg_to_rad(randf_range(-1, 1) * float(_cs["lech"])))
	var q := PhysicsRayQueryParameters3D.create(tu, tu + huong * float(_cs["tam"]) * 1.2, 1 | 2, [get_rid()])
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	var cuoi := tu + huong * float(_cs["tam"])
	if kq:
		cuoi = kq["position"]
		var m := kq["collider"] as Mecha
		if m and m.phe != phe:
			m.nhan_sat_thuong(float(_cs["sat_thuong"]), self)
	HieuUng.vet_dan(get_parent(), tu, cuoi, Color(1.6, 1.0, 0.4))
	AmThanh.phat("sung_may", tu)
	if kq:
		AmThanh.phat("trung_dan" if kq["collider"] is Mecha else "dan_cham_dat", cuoi)


func nhan_sat_thuong(luong: float, _tu: Node = null) -> void:
	if not song:
		return
	mau -= luong
	if mau <= 0.0:
		song = false
		HieuUng.vu_no(get_parent(), tam_than(), 9.0, Color(1.0, 0.6, 0.2))
		queue_free()
