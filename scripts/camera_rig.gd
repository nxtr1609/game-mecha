class_name CameraRig
extends Node3D
## Camera góc nhìn thứ ba, đặt sau vai phải mecha. Chuột xoay camera, mecha xoay thân theo camera.

var muc_tieu: Mecha
var yaw := 0.0
var pitch := -0.12
var do_nhay := 0.0024
var cam: Camera3D
var _tay: SpringArm3D
var _cao := 11.0
var _chuot_nghi := 1.0     # giây kể từ lần cuối di chuột
var _rung := 0.0           # độ rung camera còn lại (vụ nổ lớn)
var _tre := 0.0            # vừa bật lao: camera bám chậm lại, mecha văng ra mép màn hình (học từ Iron Valiant)
var _fov_them := 0.0


func _ready() -> void:
	add_to_group("camera_rig")
	_tay = SpringArm3D.new()
	_tay.spring_length = 26.0
	_tay.collision_mask = 1
	_tay.margin = 0.6
	_tay.position = Vector3(8.5, 0.0, 0.0)
	add_child(_tay)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.far = 6000.0
	cam.near = 0.3
	_tay.add_child(cam)
	cam.current = true
	if muc_tieu:
		yaw = muc_tieu.rotation.y
		global_position = muc_tieu.global_position + Vector3.UP * _cao
		muc_tieu.su_kien.connect(_khi_su_kien)
	_bat_chuot(true)


func _khi_su_kien(loai: String) -> void:
	match loai:
		"lao":
			_tre = 0.9
			_fov_them = 9.0
			rung(0.45)
		"lao_chem":
			_tre = 0.6
			_fov_them = 8.0
		"dap":
			rung(0.6)
		"bi_chem", "bi_do":
			rung(0.8)
		"trung":
			rung(0.25)


func _bat_chuot(bat: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if bat else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := e as InputEventMouseMotion
		var nhay := do_nhay * float(TienTrinh.cai_dat.get("do_nhay_chuot", 1.0))
		yaw -= mm.relative.x * nhay
		_chuot_nghi = 0.0
		pitch = clampf(pitch - mm.relative.y * nhay, -1.25, 0.9)
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		var canh := get_tree().current_scene
		if not (canh and canh.has_method("dang_mo_bang") and canh.dang_mo_bang()):
			_bat_chuot(true)


func _process(dt: float) -> void:
	if not is_instance_valid(muc_tieu):
		return
	var dich := muc_tieu.global_position + Vector3.UP * _cao * muc_tieu.ty_le
	_tre = maxf(0.0, _tre - dt)
	global_position = global_position.lerp(dich, 1.0 - exp(-dt * lerpf(18.0, 2.2, _tre / 0.9)))
	# bám mục tiêu đang khóa (như Armored Core): khi không di chuột, camera tự xoay dần về phía mục tiêu
	_chuot_nghi += dt
	var k = muc_tieu.khoa
	if CanBang.CAMERA_BAM_KHOA > 0.0 and is_instance_valid(k) and k.get("song") != false and _chuot_nghi > 0.12:
		var d: Vector3 = k.tam_than() - cam.global_position
		var a := 1.0 - exp(-dt * CanBang.CAMERA_BAM_KHOA)
		yaw = lerp_angle(yaw, atan2(-d.x, -d.z), a)
		pitch = lerpf(pitch, clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.25, 0.9), a)
	basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	if _rung > 0.001:
		_rung = maxf(0.0, _rung - dt * 2.5)
		var r := _rung * _rung * 0.03
		basis = basis * Basis(Vector3.RIGHT, randf_range(-r, r)) * Basis(Vector3.UP, randf_range(-r, r))
	_fov_them = lerpf(_fov_them, 0.0, 1.0 - exp(-dt * 3.0))
	cam.fov = lerpf(cam.fov, 70.0 + _fov_them, 1.0 - exp(-dt * 12.0))


func huong_nhin() -> Vector3:
	return -cam.global_basis.z


## Điểm ở giữa màn hình mà tâm ngắm đang chỉ vào.
func diem_ngam(bo_qua: Array[RID]) -> Vector3:
	var tu := cam.global_position
	var toi := tu + huong_nhin() * 2500.0
	var q := PhysicsRayQueryParameters3D.create(tu, toi, 1 | 2, bo_qua)
	var kq := get_world_3d().direct_space_state.intersect_ray(q)
	if kq:
		return kq["position"]
	return toi


## Rung camera (0..1.5) khi có vụ nổ lớn gần.
func rung(manh: float) -> void:
	_rung = clampf(maxf(_rung, manh), 0.0, 1.5)
