class_name MayBay
extends StaticBody3D
## Máy bay vận tải cỡ trực thăng (mẫu tàu đổ bộ của người dùng, dài 26 m, mỗi phe một mẫu):
## chở quân từ tàu sân bay xuống cứ điểm, hoặc chở hàng hậu cần từ cứ điểm lên tàu sân bay.
## Bay theo danh sách điểm; lúc lên / xuống gần mặt đất thì bay chậm nên mecha bắn rơi được.
## Khóa mục tiêu được như mecha (có song, ten, mau, cs, velocity, tam_than()).

signal toi_noi
signal bi_ban_roi

var phe := 0
var mau := 700.0
var song := true
var ten := "Máy bay tiếp vận"
var cs := {"mau": 700.0}
var velocity := Vector3.ZERO
var duong: Array = []              # [[điểm, tốc độ m/s], ...]
var _i := 0
var _xong := false
var _model: Node3D
var _t := 0.0

const MODEL := ["res://models/may_bay/may_bay_trang.glb", "res://models/may_bay/may_bay_den.glb"]


func tam_than() -> Vector3:
	return global_position


func _ready() -> void:
	cs = {"mau": mau}
	add_to_group("cong_trinh")
	add_to_group("may_bay")
	collision_layer = 2
	collision_mask = 0
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(15, 7, 24)
	hinh.shape = hop
	hinh.position.y = 2.5
	add_child(hinh)
	var mau_soc: Color = CuDiem.MAU_PHE[phe]
	# mẫu có mũi hướng +Z, còn máy bay bay về phía -Z của nó nên xoay 180 độ; nâng lên để bụng chạm đất lúc đáp
	_model = (load(MODEL[phe]) as PackedScene).instantiate() as Node3D
	_model.rotation.y = PI
	_model.position.y = 2.5
	add_child(_model)
	var den := OmniLight3D.new()
	den.light_color = mau_soc
	den.light_energy = 2.0
	den.omni_range = 14.0
	den.position = Vector3(0, -2.5, 0)
	add_child(den)


## Bay tiếp theo một đường mới.
func bay(duong_moi: Array) -> void:
	duong = duong_moi
	_i = 0
	_xong = false


func _physics_process(dt: float) -> void:
	_t += dt
	# lơ lửng nhẹ và nghiêng theo hướng bay cho đỡ cứng
	_model.position.y = 2.5 + sin(_t * 1.7) * 0.25
	_model.rotation.x = lerpf(_model.rotation.x, clampf(-velocity.y * 0.004, -0.25, 0.25), 1.0 - exp(-dt * 2.0))
	if _xong or _i >= duong.size():
		velocity = Vector3.ZERO
		return
	var dich: Vector3 = duong[_i][0]
	var toc: float = duong[_i][1]
	var d := dich - global_position
	var buoc := toc * dt
	velocity = d.normalized() * toc if d.length() > 0.01 else Vector3.ZERO
	if d.length() <= buoc:
		global_position = dich
		_i += 1
		if _i >= duong.size():
			_xong = true
			toi_noi.emit()
		return
	global_position += d.normalized() * buoc
	var ngang := Vector3(d.x, 0.0, d.z)
	if ngang.length() > 1.0:
		rotation.y = lerp_angle(rotation.y, atan2(-ngang.x, -ngang.z), 1.0 - exp(-dt * 3.0))


func nhan_sat_thuong(luong: float, _tu: Node = null) -> void:
	if mau <= 0.0:
		return
	mau -= luong
	if mau <= 0.0:
		song = false
		HieuUng.vu_no(get_parent(), global_position, 14.0, Color(1.0, 0.6, 0.2))
		bi_ban_roi.emit()
		queue_free()
