class_name PhaoNhiet
extends Node3D
## Một quả pháo nhiệt: bay ra, rơi chậm, cháy sáng rồi tắt. Tên lửa bị kéo theo thì nổ vô hại khi tới gần.

var van_toc := Vector3.ZERO
var song := true
var _con := 3.0


func _ready() -> void:
	add_to_group("phao_nhiet")
	_con = CanBang.PHAO_NHIET["chay"]
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(2.4, 1.9, 1.2)
	sm.material = m
	mi.mesh = sm
	add_child(mi)
	var den := OmniLight3D.new()
	den.light_color = Color(1.0, 0.85, 0.6)
	den.omni_range = 16.0
	den.light_energy = 3.0
	add_child(den)
	var vet := CPUParticles3D.new()
	vet.amount = 30
	vet.lifetime = 0.8
	vet.local_coords = false
	vet.direction = Vector3.UP
	vet.spread = 30.0
	vet.initial_velocity_min = 0.5
	vet.initial_velocity_max = 1.5
	vet.gravity = Vector3(0, 0.5, 0)
	vet.scale_amount_min = 0.6
	vet.scale_amount_max = 1.2
	var qm := QuadMesh.new()
	var mk := StandardMaterial3D.new()
	mk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mk.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mk.albedo_color = Color(0.95, 0.9, 0.85, 0.4)
	mk.albedo_texture = HieuUng.tron_mem()
	qm.material = mk
	vet.mesh = qm
	add_child(vet)


func diem_ngam_vao() -> Vector3:
	return global_position


func tam_than() -> Vector3:
	return global_position


func _physics_process(dt: float) -> void:
	_con -= dt
	if _con <= 0.0:
		queue_free()
		return
	van_toc = van_toc.lerp(Vector3(0, -4.0, 0), 1.0 - exp(-dt * 1.5))   # cản gió: chậm dần rồi rơi chậm
	global_position += van_toc * dt
