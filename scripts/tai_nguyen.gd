class_name TaiNguyen
extends RefCounted
## Nạp mẫu 3D tải về (Kenney...) và căn lại tâm: gốc toạ độ nằm ở giữa đáy mẫu.
## (Nhiều mẫu Kenney có gốc lệch về một góc, đặt thẳng vào sẽ bị trượt chỗ.)
## Ghi nhớ khung bao (AABB) của từng mẫu để dựng khối va chạm và xếp nhà cho khỏi chồng nhau.

static var _khung := {}           # đường dẫn -> AABB (theo toạ độ gốc của mẫu, chưa căn tâm)
static var _vat_lieu := {}        # màu chỉnh -> vật liệu dùng chung


## Khung bao của mẫu sau khi căn tâm (đáy ở y = 0, giữa ở x = z = 0), chưa nhân tỉ lệ.
static func khung(duong: String) -> AABB:
	if not _khung.has(duong):
		var n := (load(duong) as PackedScene).instantiate() as Node3D
		_khung[duong] = _do_khung(n)
		n.free()
	var a: AABB = _khung[duong]
	return AABB(Vector3(-a.size.x * 0.5, 0.0, -a.size.z * 0.5), a.size)


static func _do_khung(goc: Node3D) -> AABB:
	var hop := AABB()
	var dau := true
	for mi in goc.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var t := Transform3D()
		var n: Node = m3
		while n != goc and n is Node3D:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var b := t * m3.get_aabb()
		hop = b if dau else hop.merge(b)
		dau = false
	return hop


## Tạo mẫu đã căn tâm. ti_le: nhân kích thước. mau: nếu khác trắng thì nhân màu (làm mẫu tươi thành xám bê tông).
static func tao(duong: String, ti_le := 1.0, mau := Color.WHITE) -> Node3D:
	var vo := Node3D.new()
	var n := (load(duong) as PackedScene).instantiate() as Node3D
	if not _khung.has(duong):
		_khung[duong] = _do_khung(n)
	var a: AABB = _khung[duong]
	n.position = -Vector3(a.position.x + a.size.x * 0.5, a.position.y, a.position.z + a.size.z * 0.5)
	vo.add_child(n)
	vo.scale = Vector3.ONE * ti_le
	if mau != Color.WHITE:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			for s in m3.get_surface_override_material_count():
				var goc_mat := m3.mesh.surface_get_material(s)
				if goc_mat is StandardMaterial3D:
					m3.set_surface_override_material(s, _mau_chinh(goc_mat as StandardMaterial3D, mau))
	return vo


static func _mau_chinh(goc: StandardMaterial3D, mau: Color) -> StandardMaterial3D:
	var khoa := "%d_%s" % [goc.get_instance_id(), mau.to_html()]
	if not _vat_lieu.has(khoa):
		var m := goc.duplicate() as StandardMaterial3D
		m.albedo_color = goc.albedo_color * mau
		m.roughness = maxf(goc.roughness, 0.75)
		_vat_lieu[khoa] = m
	return _vat_lieu[khoa]
