class_name Bia
extends AnimatableBody3D
## Bia tập ở bãi huấn luyện, làm bằng code. Nhận đạn như ụ súng (nhom "cong_trinh", phe địch) nên khóa mục tiêu,
## tên lửa, cung máu trên vòng ngắm đều chạy như với địch thật.
## kieu: "dung" — bảng tròn đỏ trắng trên cột (cao ~8 m, hợp mecha 10 m);
##       "chay" — bảng chạy qua lại trên ray ngang (bien_do mét);
##       "bay"  — drone nhỏ bay vòng tròn (ban_kinh_vong mét, cao do_cao mét quanh tam_vong).
## Trúng hết máu thì vỡ (nổ nhỏ) rồi biến mất.

signal bi_pha(b: Bia)

var kieu := "dung"
var phe := 1
var mau := 150.0
var mau_toi_da := 150.0
var song := true
var ten_hien := "Bia tập"
var huong_nhin := Vector3(0, 0, 1)     # bia đứng / chạy: mặt bảng quay về phía này
var bien_do := 45.0
var toc_do := 14.0                     # bia chạy: m/s; bia bay: m/s theo vòng
var tam_vong := Vector3.ZERO
var ban_kinh_vong := 110.0
var do_cao := 45.0
var pha := 0.0
var _goc := Vector3.ZERO
var _t := 0.0

static var _vl_bang: ShaderMaterial
static var _vl_khung: StandardMaterial3D


func _ready() -> void:
	add_to_group("cong_trinh")
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	mau_toi_da = mau
	ten_hien = "Bia bay" if kieu == "bay" else ("Bia chạy" if kieu == "chay" else "Bia tập")
	_goc = global_position
	_t = pha
	if _vl_bang == null:
		_vl_bang = ShaderMaterial.new()
		_vl_bang.shader = load("res://scripts/bia.gdshader")
		_vl_khung = StandardMaterial3D.new()
		_vl_khung.albedo_color = Color(0.32, 0.33, 0.35)
		_vl_khung.roughness = 0.6
		_vl_khung.metallic = 0.5
	if kieu == "bay":
		_dung_drone()
	else:
		_dung_bang()


func _dung_bang() -> void:
	var cot := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.45
	cm.height = 5.0
	cm.material = _vl_khung
	cot.mesh = cm
	cot.position.y = 2.5
	add_child(cot)
	var de := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.0, 0.6, 2.4)
	bm.material = _vl_khung
	de.mesh = bm
	de.position.y = 0.3
	add_child(de)
	var bang := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(7.0, 7.0)
	qm.material = _vl_bang
	bang.mesh = qm
	bang.position.y = 7.5
	bang.name = "bang"
	add_child(bang)
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(6.6, 6.6, 0.8)
	hinh.shape = hop
	hinh.position.y = 7.5
	add_child(hinh)
	var h2 := CollisionShape3D.new()
	var tru := BoxShape3D.new()
	tru.size = Vector3(1.0, 5.0, 1.0)
	h2.shape = tru
	h2.position.y = 2.5
	add_child(h2)
	look_at(global_position - Vector3(huong_nhin.x, 0, huong_nhin.z), Vector3.UP)


func _dung_drone() -> void:
	var than := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 1.0, 3.2)
	bm.material = _vl_khung
	than.mesh = bm
	add_child(than)
	for g in 4:
		var a := TAU * g / 4.0 + PI * 0.25
		var canh := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.3
		cm.bottom_radius = 1.3
		cm.height = 0.12
		cm.material = _vl_bang
		canh.mesh = cm
		canh.position = Vector3(cos(a), 0.35, sin(a)) * Vector3(2.6, 1.0, 2.6)
		add_child(canh)
	var den := OmniLight3D.new()
	den.light_color = Color(1.0, 0.35, 0.2)
	den.light_energy = 2.0
	den.omni_range = 8.0
	den.position.y = -0.8
	add_child(den)
	var hinh := CollisionShape3D.new()
	var cau := SphereShape3D.new()
	cau.radius = 3.4
	hinh.shape = cau
	add_child(hinh)


func tam_than() -> Vector3:
	return global_position + (Vector3.UP * 7.5 if kieu != "bay" else Vector3.ZERO)


func _physics_process(dt: float) -> void:
	if not song:
		return
	_t += dt
	match kieu:
		"chay":
			var ngang := Vector3(-huong_nhin.z, 0, huong_nhin.x).normalized()
			global_position = _goc + ngang * sin(_t * toc_do / maxf(1.0, bien_do)) * bien_do
		"bay":
			var g := _t * toc_do / ban_kinh_vong
			global_position = tam_vong + Vector3(cos(g) * ban_kinh_vong, do_cao + sin(_t * 0.9) * 4.0, sin(g) * ban_kinh_vong)
			rotation.y = -g


func nhan_sat_thuong(luong: float, _tu: Node = null, _xuyen := false) -> void:
	if not song:
		return
	mau -= luong
	if mau <= 0.0:
		mau = 0.0
		song = false
		HieuUng.vu_no(get_tree().current_scene, tam_than(), 6.0, Color(1.0, 0.6, 0.25))
		bi_pha.emit(self)
		queue_free()
