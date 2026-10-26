class_name TrongCay
extends RefCounted
## Trồng cây bằng code (CayRung, không dùng mẫu tải về) cho bản đồ ngoại ô / đồng quê, theo thước mecha cao 10 m:
## cây lá rộng thu nhỏ còn 12–24 m (thân 1–1,5 m), bụi 3–6 m làm hàng rào cây xanh.
## Cây cùng biến thể gom vào MultiMesh theo ô 640 m (ít lệnh vẽ); thân cây có va chạm (gom theo ô), bụi đi xuyên được.

const O_CAY := 640.0

var cha: Node3D
var bien_the: Array = []          # [mesh, r gốc, cao thân, loại]
var _mm := {}                     # "biến thể:ô x:ô z" -> Array[Transform3D]
var _than_o := {}                 # "ô x:ô z" -> StaticBody3D
var vi_tri := PackedVector2Array()   # để vẽ bản đồ
var so_cay := 0
var so_bui := 0


## mau_la: [màu tối, màu sáng] của tán lá; them_mau_thu: thêm vài biến thể lá vàng / cam (mùa thu).
func _init(n: Node3D, rng: RandomNumberGenerator, mau_la: Array, them_mau_thu := true) -> void:
	cha = n
	var vo := ShaderMaterial.new()
	vo.shader = load("res://scripts/vo_cay.gdshader")
	var la := _vat_lieu_la(0, mau_la[0], mau_la[1], 0.08)
	var la_thu := _vat_lieu_la(0, Color(0.32, 0.2, 0.05), Color(0.7, 0.45, 0.12), 0.08)
	var la_bui := _vat_lieu_la(0, Color(mau_la[0].r * 1.2, mau_la[0].g * 1.15, mau_la[0].b), Color(mau_la[1].r, mau_la[1].g * 1.05, mau_la[1].b), 0.2)
	for k in 5:
		var kq := CayRung.cay_vua(rng)
		var m: ArrayMesh = kq[0]
		m.surface_set_material(0, vo)
		m.surface_set_material(1, la_thu if (them_mau_thu and k == 4) else la)
		bien_the.append([m, kq[1], kq[2], "cay"])
	for k in 3:
		var kq := CayRung.bui(rng)
		var m: ArrayMesh = kq[0]
		m.surface_set_material(0, la_bui)
		bien_the.append([m, kq[1], kq[2], "bui"])


static func _vat_lieu_la(kieu: int, a: Color, b: Color, gio: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/la_cay.gdshader")
	m.set_shader_parameter("kieu", kieu)
	m.set_shader_parameter("mau_a", a)
	m.set_shader_parameter("mau_b", b)
	m.set_shader_parameter("gio", gio)
	return m


func cac_bien_the(loai: String) -> Array:
	var ds := []
	for i in bien_the.size():
		if bien_the[i][3] == loai:
			ds.append(i)
	return ds


## Trồng một cây (cao_m: chiều cao mong muốn, theo đó thu nhỏ mẫu cây 26–40 m). Trả về bán kính thân.
func cay(i: int, p: Vector3, goc: float, cao_m: float, va_cham := true) -> float:
	var bt: Array = bien_the[i]
	var ti := cao_m / maxf(1.0, float(bt[2]) * 1.15)
	var t := Transform3D(Basis(Vector3.UP, goc).scaled(Vector3.ONE * ti), p)
	_them(i, t)
	var r := float(bt[1]) * ti
	if va_cham:
		_va_cham_than(p, r * 1.05, float(bt[2]) * ti)
	vi_tri.append(Vector2(p.x, p.z))
	so_cay += 1
	return r


## Bụi (không va chạm). ti: phóng to (bụi gốc cao 3–5 m).
func bui(i: int, p: Vector3, goc: float, ti: float) -> void:
	_them(i, Transform3D(Basis(Vector3.UP, goc).scaled(Vector3(ti, ti * 0.9, ti)), p))
	so_bui += 1


func _them(i: int, t: Transform3D) -> void:
	var k := "%d:%d:%d" % [i, floori(t.origin.x / O_CAY), floori(t.origin.z / O_CAY)]
	if not _mm.has(k):
		_mm[k] = []
	_mm[k].append(t)


func _va_cham_than(p: Vector3, r: float, cao: float) -> void:
	var k := "%d:%d" % [floori(p.x / O_CAY), floori(p.z / O_CAY)]
	if not _than_o.has(k):
		var than := StaticBody3D.new()
		than.collision_layer = DungBanDo.LOP_VAT_CAN
		than.collision_mask = 0
		cha.add_child(than)
		_than_o[k] = than
	var hinh := CollisionShape3D.new()
	var tru := CylinderShape3D.new()
	tru.radius = maxf(r, 0.6)
	tru.height = cao
	hinh.shape = tru
	hinh.position = p + Vector3.UP * cao * 0.5
	(_than_o[k] as StaticBody3D).add_child(hinh)


## Gom các vị trí thành MultiMesh theo ô (gọi một lần sau khi trồng xong).
func xong() -> void:
	for k in _mm:
		var phan: PackedStringArray = (k as String).split(":")
		var bt: Array = bien_the[int(phan[0])]
		var ds: Array = _mm[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = bt[0]
		mm.instance_count = ds.size()
		for j in ds.size():
			mm.set_instance_transform(j, ds[j])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if bt[3] == "bui":
			mmi.visibility_range_end = 900.0
			mmi.visibility_range_end_margin = 80.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cha.add_child(mmi)
