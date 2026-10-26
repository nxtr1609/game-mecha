class_name DanPlasma
extends Node3D
## Viên đạn plasma bay chậm, nổ lan khi chạm địa hình hoặc mecha.
## Bay xa hơn tầm tối ưu thì sát thương giảm dần (còn `dmg_xa` ở tầm tối đa).
## Vụ nổ lớn (pháo kích) làm rung camera.

var chu: Mecha
var phe := 0
var van_toc := Vector3.ZERO
var sat_thuong := 0.0
var ban_kinh_no := 10.0
var mau := Color(0.5, 0.8, 1.0)
var thoi_gian := 6.0
var kich_thuoc := 1.0
var tam_toi_uu := 1e9
var tam_toi_da := 1e9
var dmg_xa := 1.0
var nhiet_them := 0.0              # đạn EMP: trúng thì động cơ mecha địch nóng thêm bấy nhiêu
var _da_bay := 0.0


func _ready() -> void:
	add_to_group("dan")
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.1 * kich_thuoc
	sm.height = 2.2 * kich_thuoc
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = mau
	sm.material = mat
	mi.mesh = sm
	add_child(mi)
	var den := OmniLight3D.new()
	den.light_color = mau
	den.light_energy = 3.0
	den.omni_range = 18.0
	add_child(den)


func _physics_process(dt: float) -> void:
	thoi_gian -= dt
	if thoi_gian <= 0.0:
		queue_free()
		return
	var tu := global_position
	var toi := tu + van_toc * dt
	var ex: Array[RID] = []
	if is_instance_valid(chu):
		ex.append(chu.get_rid())
	var q := PhysicsRayQueryParameters3D.create(tu, toi, 1 | 2, ex)
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	if kq:
		_no(kq["position"])
		return
	_da_bay += tu.distance_to(toi)
	global_position = toi


func _no(p: Vector3) -> void:
	var he_so := 1.0
	if _da_bay > tam_toi_uu:
		he_so = lerpf(1.0, dmg_xa, clampf((_da_bay - tam_toi_uu) / maxf(tam_toi_da - tam_toi_uu, 1.0), 0.0, 1.0))
	for n in get_tree().get_nodes_in_group("mecha"):
		var m := n as Mecha
		if m and m.song and m.phe != phe:
			var d := m.tam_than().distance_to(p)
			var tam := ban_kinh_no + 4.0
			if d < tam:
				var dmg := sat_thuong * he_so * (1.0 - 0.5 * d / tam)
				m.nhan_sat_thuong(dmg, chu)
				if nhiet_them > 0.0:
					m.them_nhiet(nhiet_them * (1.0 - 0.5 * d / tam))
				if is_instance_valid(chu):
					chu.ban_trung.emit(m, dmg)
	no_cong_trinh(get_tree(), p, ban_kinh_no, sat_thuong * he_so, phe)
	HieuUng.vu_no(get_parent(), p, ban_kinh_no, mau)
	if ban_kinh_no < 8.0:                                  # đạn nhỏ: vu_no không kêu, nổ lép bép nhỏ
		AmThanh.phat("no_nho", p, -8.0)
	if ban_kinh_no >= 15.0:
		for c in get_tree().get_nodes_in_group("camera_rig"):
			var kc := (c as Node3D).global_position.distance_to(p)
			c.rung(clampf(ban_kinh_no / 30.0, 0.3, 1.5) * clampf(1.0 - kc / 300.0, 0.0, 1.0))
	queue_free()

## Gây sát thương nổ lan lên công trình địch (ụ súng, máy bay) quanh điểm p.
static func no_cong_trinh(cay: SceneTree, p: Vector3, ban_kinh: float, sat_thuong: float, phe: int) -> void:
	for n in cay.get_nodes_in_group("cong_trinh"):
		var ct := n as Node3D
		if ct and ct.get("phe") != phe:
			var d := (ct.global_position + Vector3.UP * 3.0).distance_to(p)
			if d < ban_kinh + 5.0:
				ct.nhan_sat_thuong(sat_thuong * (1.0 - 0.5 * d / (ban_kinh + 5.0)))
