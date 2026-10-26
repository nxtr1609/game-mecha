class_name MauNha
extends RefCounted
## Mẫu nhà của bạn (models/nha/<tên>.glb), đã đổi sang mét bằng Blender: mỗi file có 3 bản
## "nguyen" (nguyên vẹn), "do_1", "do_2" (đổ nát: cụt phần trên, gạch vụn, ám khói bằng màu đỉnh).
## <tên>.json: chiều cao và hộp va chạm từng bản ({"tam": [x, y, z], "kich": [x, y, z]}, trục Godot).

## Nội thành (tòa cao) và ngoại thành (nhà thấp). Cao (m) ghi trong json.
const NOI_THANH := ["toa_tron", "toa_khoi", "toa_phien", "toa_cao_1", "toa_cao_2", "thap_cong_nghiep", "thap_tron"]
const NGOAI_THANH := ["nha_vuon", "nha_hien_dai", "nha_kinh", "nha_kinh_lon", "khu_thap", "thap_ang_ten"]
const BAN := ["nguyen", "do_1", "do_2"]

static var _luoi := {}
static var _tt := {}


## Lưới của một bản (dùng chung cho mọi nơi đặt nhà này). Vật liệu bật màu đỉnh để thấy vết ám khói.
static func luoi(ten: String, ban := "nguyen") -> Mesh:
	var khoa := ten + "/" + ban
	if _luoi.has(khoa):
		return _luoi[khoa]
	var sc := (load("res://models/nha/%s.glb" % ten) as PackedScene).instantiate()
	for b in BAN:
		var mi := sc.find_child(b, true, false) as MeshInstance3D
		if mi == null:
			continue
		var m := mi.mesh.duplicate() as ArrayMesh
		for s in m.get_surface_count():
			var vl := m.surface_get_material(s)
			if vl is StandardMaterial3D:
				var v2 := (vl as StandardMaterial3D).duplicate() as StandardMaterial3D
				v2.vertex_color_use_as_albedo = true
				v2.roughness = 0.9
				v2.metallic = 0.0
				m.surface_set_material(s, v2)
		_luoi[ten + "/" + b] = m
	sc.free()
	return _luoi.get(khoa)


static func thong_tin(ten: String) -> Dictionary:
	if not _tt.has(ten):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://models/nha/%s.json" % ten))
		_tt[ten] = d if d is Dictionary else {}
	return _tt[ten]


## Hộp va chạm của một bản: [tâm, kích thước] (trục Godot, gốc ở giữa chân nhà).
static func hop(ten: String, ban := "nguyen") -> Array:
	var h: Dictionary = thong_tin(ten).get(ban, {})
	var t: Array = h.get("tam", [0, 5, 0])
	var k: Array = h.get("kich", [10, 10, 10])
	return [Vector3(t[0], t[1], t[2]), Vector3(k[0], k[1], k[2])]


static func cao(ten: String, ban := "nguyen") -> float:
	return (hop(ten, ban)[1] as Vector3).y
