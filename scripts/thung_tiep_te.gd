class_name ThungTiepTe
extends Node3D
## Hòm tiếp tế rơi từ tàu sân bay. Nằm trên mặt đất một thời gian (mặc định 60 giây);
## mecha phe ta lại gần thì tự nhặt: hồi giáp và đầy năng lượng, rồi hòm biến mất.
## Có cột sáng xanh để thấy từ xa; 10 giây cuối cột sáng nhấp nháy.
## Mô hình: "Sci-Fi Shipping Crate" của David W CG (CC BY 4.0, xem GHI_CONG.md). Không có file thì dùng khối hộp.

signal da_nhat(boi: Mecha)

const MODEL := "res://assets_ngoai/hom_tiep_te/shipping_crate.glb"
const KICH_THUOC := 6.0          # cạnh lớn nhất của hòm (m)

var phe := 0
var hoi_mau := 1800.0
var ton_tai := 60.0
var ban_kinh_nhat := 10.0
var con := 0.0                   # giây còn lại
var da_dap := false              # đã chạm đất chưa
var _cot: MeshInstance3D
var _mat_cot: StandardMaterial3D
var _den: OmniLight3D


func _ready() -> void:
	add_to_group("thung_tiep_te")
	con = ton_tai
	var hinh: Node3D
	if ResourceLoader.exists(MODEL):
		hinh = (load(MODEL) as PackedScene).instantiate()
		add_child(hinh)
		_vua_kich_thuoc(hinh)
	else:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(KICH_THUOC, KICH_THUOC * 0.75, KICH_THUOC)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.8, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.9, 0.4)
		mat.emission_energy_multiplier = 0.6
		bm.material = mat
		mi.mesh = bm
		mi.position.y = KICH_THUOC * 0.375
		add_child(mi)
	# cột sáng xanh
	_cot = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.9
	cm.height = 120.0
	cm.radial_segments = 12
	_mat_cot = StandardMaterial3D.new()
	_mat_cot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_cot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cot.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_cot.albedo_color = Color(0.3, 1.4, 0.6, 0.55)
	cm.material = _mat_cot
	_cot.mesh = cm
	_cot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cot.position.y = 60.0
	_cot.visible = false
	add_child(_cot)
	_den = OmniLight3D.new()
	_den.light_color = Color(0.3, 1.0, 0.5)
	_den.light_energy = 2.5
	_den.omni_range = 18.0
	_den.position.y = 4.0
	add_child(_den)


## Thu nhỏ / phóng to mô hình cho vừa KICH_THUOC và đặt đáy chạm đất.
func _vua_kich_thuoc(hinh: Node3D) -> void:
	var hop := AABB()
	var dau := true
	for mi in hinh.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var b := (global_transform.affine_inverse() * m3.global_transform) * m3.get_aabb()
		hop = b if dau else hop.merge(b)
		dau = false
	if dau:
		return
	var lon := maxf(hop.size.x, maxf(hop.size.y, hop.size.z))
	var s := KICH_THUOC / maxf(lon, 0.001)
	hinh.scale = Vector3.ONE * s
	hinh.position = -Vector3(hop.get_center().x, hop.position.y, hop.get_center().z) * s


## Thả từ độ cao `tu_cao` xuống điểm `dich` (đã dò mặt đất).
func tha(tu: Vector3, dich: Vector3, thoi_gian := 2.2) -> void:
	global_position = tu
	var tw := create_tween()
	tw.tween_property(self, "global_position", dich, thoi_gian).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	da_dap = true
	_cot.visible = true
	HieuUng.vu_no(get_parent(), dich + Vector3.UP * 2.0, 9.0, Color(0.3, 1.0, 0.5), false)
	AmThanh.phat("cham_dat", dich)


func _process(dt: float) -> void:
	if not da_dap:
		return
	con -= dt
	if con <= 10.0:
		_mat_cot.albedo_color.a = 0.55 if fmod(con, 0.5) > 0.25 else 0.1
	if con <= 0.0:
		queue_free()
		return
	for n in get_tree().get_nodes_in_group("mecha"):
		var e := n as Mecha
		if e and e.song and e.phe == phe:
			var d := e.global_position - global_position
			if Vector2(d.x, d.z).length() <= ban_kinh_nhat:
				e.hoi_mau(hoi_mau)
				HieuUng.vu_no(get_parent(), global_position + Vector3.UP * 3.0, 8.0, Color(0.3, 1.0, 0.5), false)
				AmThanh.phat("ui_mua", global_position)
				da_nhat.emit(e)
				queue_free()
				return
