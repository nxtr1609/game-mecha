class_name TauChien
extends Node3D
## Tàu sân bay trên trời (mỗi phe một chiếc). Đứng yên, dập dềnh nhẹ. Có giáp thân + khiên riêng: khiên tự hồi khi
## không bị bắn một lúc, lóe sáng khi trúng đạn. Trúng EMP thì tê liệt (ngừng bắn, khiên không hồi).
## Logic bắn nằm ở TranTrenTroi; tàu chỉ giữ số liệu, hình ảnh và nhận sát thương.

signal bi_ha(tau: TauChien)

var phe := 0
var giap := 0.0
var giap_max := 0.0
var khien := 0.0
var khien_max := 0.0
var te_liet_con := 0.0             # trúng EMP
var song := true
var khong_bi_ban := 99.0
var y0 := 0.0

var _mat_khien: StandardMaterial3D
var _t := 0.0


func _ready() -> void:
	add_to_group("tau_chien")
	var cfg: Dictionary = CanBang.TAU_SAN_BAY
	var duong: String = cfg["model"][phe]
	if ResourceLoader.exists(duong):
		var model := (load(duong) as PackedScene).instantiate() as Node3D
		model.scale = Vector3.ONE * float(cfg["ti_le"])
		DoHoa.chinh_vat_lieu(model, 0.5, 0.45, true)
		add_child(model)
	# khiên: quả cầu dẹt bao quanh tàu, chỉ lóe lên khi trúng đạn
	var khien_mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 24
	sm.rings = 12
	_mat_khien = StandardMaterial3D.new()
	_mat_khien.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_khien.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_khien.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_khien.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_khien.albedo_color = Color(0.3, 0.6, 1.2, 0.0) if phe == 0 else Color(1.2, 0.4, 0.3, 0.0)
	sm.material = _mat_khien
	khien_mi.mesh = sm
	khien_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	khien_mi.scale = cfg["co_khien"]
	add_child(khien_mi)


func ti_le_mau() -> float:
	return (giap + khien) / maxf(1.0, giap_max + khien_max)


func dem_gio(dt: float) -> void:
	_t += dt
	khong_bi_ban += dt
	te_liet_con = maxf(0.0, te_liet_con - dt)
	if not song:
		return
	var cs: Dictionary = CanBang.TRAN_TROI
	if khong_bi_ban > float(cs["khien_tre_hoi"]) and te_liet_con <= 0.0:
		khien = minf(khien_max, khien + khien_max * float(cs["khien_hoi"]) * dt)
	# hình ảnh: dập dềnh nhẹ, khiên mờ dần
	position.y = y0 + sin(_t * 0.25 + phe * 3.0) * 5.0
	_mat_khien.albedo_color.a = maxf(0.0, _mat_khien.albedo_color.a - dt * 1.5)


func nhan_sat_thuong(dmg: float) -> void:
	if not song:
		return
	khong_bi_ban = 0.0
	if khien > 0.0:
		_mat_khien.albedo_color.a = 0.45
		if dmg <= khien:
			khien -= dmg
			return
		dmg -= khien
		khien = 0.0
	giap -= dmg
	if giap <= 0.0:
		giap = 0.0
		_bi_ha()


func _bi_ha() -> void:
	song = false
	khien = 0.0
	for k in 5:
		var p := global_position + Vector3(randf_range(-60, 60), randf_range(-15, 15), randf_range(-90, 90))
		HieuUng.vu_no(get_parent(), p, 40.0, Color(1.0, 0.55, 0.2))
	bi_ha.emit(self)
	# xác tàu nghiêng dần, chìm xuống rồi biến mất
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 420.0, 14.0).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation:z", randf_range(-0.5, 0.5), 14.0)
	tw.chain().tween_callback(queue_free)
