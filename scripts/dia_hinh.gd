class_name DiaHinh
extends StaticBody3D
## Địa hình bản đồ, có khối va chạm theo đúng độ cao (HeightMapShape3D). Các kiểu (kieu):
## - "thanh_pho": mặt đất phẳng (thành phố đổ nát; rìa bản đồ là dãy nhà cao).
## - "ngoai_o": đồi thoải cao tới ~24 m.
## - "dong_que": đồi lượn cao tới ~38 m, hai con sông uốn lượn chắn ngang (đối xứng hai phe), nước sâu ~3 m.
## - "bai_tap": sân phẳng ±590 m, đồi đất bao quanh (bãi huấn luyện).
## Quanh căn cứ, cứ điểm và dọc các đại lộ được san phẳng (độ cao 0) để mecha và bot đi lại dễ.
## Ngoài rìa bản đồ địa hình cao dần lên, che đường chân trời.
## chieu_cao(x, z) dùng chung cho lưới hiển thị, khối va chạm và việc đặt cảnh vật.

const O := 20.0                 # cỡ một ô lưới (m)
const KICH := 4800.0            # cả vùng địa hình (rộng hơn bản đồ 3,2 km để che chân trời)
const BIEN := 1500.0            # quá vùng này địa hình cao dần lên
const MUC_NUOC := -1.8          # đồng quê: mặt nước sông
const SONG_RONG := 20.0         # đồng quê: nửa bề rộng lòng sông

var kieu := "thanh_pho"
var cao_luoi := PackedFloat32Array()   # độ cao tại các đỉnh lưới (giữ lại để vẽ bản đồ), (so_o + 1)² giá trị
var so_o := 0
var vung_phang: Array = []      # [Vector2 tâm, bán kính phẳng, bán kính chuyển]
var duong_phang: Array = []     # [Vector2 a, Vector2 b] các đại lộ (phẳng 35 m mỗi bên)
var _n1 := FastNoiseLite.new()
var _n2 := FastNoiseLite.new()
var _n3 := FastNoiseLite.new()


func _init() -> void:
	_n1.seed = 1601
	_n1.frequency = 0.0016
	_n2.seed = 7302
	_n2.frequency = 0.005
	_n3.seed = 4419
	_n3.frequency = 0.02


func _kc_toi_doan(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Độ cao mặt đất tại (x, z).
func chieu_cao(x: float, z: float) -> float:
	if kieu == "thanh_pho":
		return 0.0                    # thành phố: mặt đất phẳng (rìa bản đồ là dãy nhà cao, không cần đồi)
	if kieu == "bai_tap":
		# bãi tập: sân phẳng ±590 m, đồi đất bao quanh
		var r := maxf(absf(x), absf(z))
		return smoothstep(590.0, 780.0, r) * (40.0 + 14.0 * _n2.get_noise_2d(x, z))
	var p := Vector2(x, z)
	var h := 0.0
	match kieu:
		"dong_que":
			h = _cao_dong_que(x, z)
		_:
			h = _cao_ngoai_o(x, z)
	# phẳng quanh căn cứ, cứ điểm, đại lộ
	var phang := 1.0
	for v in vung_phang:
		var d := p.distance_to(v[0])
		phang = minf(phang, smoothstep(float(v[1]), float(v[2]), d))
	for d2 in duong_phang:
		var kc := _kc_toi_doan(p, d2[0], d2[1])
		phang = minf(phang, smoothstep(35.0, 120.0, kc))
	h *= phang
	# đồng quê: lòng sông khoét xuống (chỗ đường cắt qua có cầu)
	if kieu == "dong_que":
		var ks := kc_suoi(x, z)
		h = lerpf(MUC_NUOC - 3.2, h, smoothstep(SONG_RONG * 0.6, SONG_RONG + 30.0, ks))
	# ngoài rìa: địa hình cao dần
	var ria := maxf(absf(x), absf(z)) - BIEN
	if ria > 0.0:
		var cao_ria := 70.0 + 50.0 * (_n2.get_noise_2d(x * 1.7, z * 1.7) * 0.5 + 0.5)
		h += smoothstep(0.0, 500.0, ria) * cao_ria
	return h


## Ngoại ô: đồi thoải cao tới ~24 m (dốc nhẹ, nhà đặt được), mấp mô nhỏ.
func _cao_ngoai_o(x: float, z: float) -> float:
	var n := _n1.get_noise_2d(x * 1.1, z * 1.1) * 0.5 + 0.5
	return pow(clampf(n, 0.0, 1.0), 1.3) * 24.0 + _n2.get_noise_2d(x, z) * 2.5


## Đồng quê: đồi lượn rộng cao tới ~38 m, mặt ruộng gần như phẳng.
func _cao_dong_que(x: float, z: float) -> float:
	var n := _n1.get_noise_2d(x * 0.8, z * 0.8) * 0.5 + 0.5
	return pow(clampf(n, 0.0, 1.0), 1.2) * 38.0 + _n2.get_noise_2d(x * 0.7, z * 0.7) * 2.5


## Đồng quê: dòng chảy của hai con sông (đối xứng qua trục x: một sông mỗi bên, giữa cứ điểm và C).
func z_suoi(x: float, phia: float) -> float:
	return phia * (430.0 + 95.0 * sin(x / 300.0 + 0.7) + 45.0 * sin(x / 137.0 + 2.1))


## Khoảng cách (gần đúng) tới lòng sông gần nhất.
func kc_suoi(x: float, z: float) -> float:
	var tot := INF
	for phia: float in [1.0, -1.0]:
		var zs := z_suoi(x, phia)
		var dz := phia * (95.0 / 300.0 * cos(x / 300.0 + 0.7) + 45.0 / 137.0 * cos(x / 137.0 + 2.1))
		tot = minf(tot, absf(z - zs) / sqrt(1.0 + dz * dz))
	return tot


## Chỗ này là mặt nước (không đặt cảnh vật lên).
func la_nuoc(x: float, z: float, them := 0.0) -> bool:
	if kieu == "dong_que":
		return kc_suoi(x, z) < SONG_RONG + 12.0 + them
	return false


## Pháp tuyến (để đặt vật nghiêng theo mặt đất).
func phap_tuyen(x: float, z: float) -> Vector3:
	var e := 3.0
	var hx := chieu_cao(x + e, z) - chieu_cao(x - e, z)
	var hz := chieu_cao(x, z + e) - chieu_cao(x, z - e)
	return Vector3(-hx, 2.0 * e, -hz).normalized()


## Dựng lưới hiển thị và khối va chạm. Gọi sau khi đã gán kieu / vung_phang / duong_phang.
func dung(vat_lieu: Material) -> void:
	collision_layer = 1
	collision_mask = 0
	var n := int(KICH / O)
	var goc := -KICH * 0.5
	var cao := PackedFloat32Array()
	cao.resize((n + 1) * (n + 1))
	for iz in n + 1:
		for ix in n + 1:
			cao[iz * (n + 1) + ix] = chieu_cao(goc + ix * O, goc + iz * O)
	cao_luoi = cao
	so_o = n
	# lưới hiển thị
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in n + 1:
		for ix in n + 1:
			var h: float = cao[iz * (n + 1) + ix]
			var hx_t: float = cao[iz * (n + 1) + maxi(ix - 1, 0)]
			var hx_s: float = cao[iz * (n + 1) + mini(ix + 1, n)]
			var hz_t: float = cao[maxi(iz - 1, 0) * (n + 1) + ix]
			var hz_s: float = cao[mini(iz + 1, n) * (n + 1) + ix]
			st.set_normal(Vector3(hx_t - hx_s, 2.0 * O, hz_t - hz_s).normalized())
			st.add_vertex(Vector3(goc + ix * O, h, goc + iz * O))
	for iz in n:
		for ix in n:
			var a := iz * (n + 1) + ix
			var b := a + 1
			var c := a + (n + 1)
			var d := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = vat_lieu
	add_child(mi)
	# khối va chạm: lưới độ cao, mỗi ô 1 đơn vị rồi phóng to đều O lần
	var hm := HeightMapShape3D.new()
	hm.map_width = n + 1
	hm.map_depth = n + 1
	var du_lieu := PackedFloat32Array()
	du_lieu.resize(cao.size())
	for i in cao.size():
		du_lieu[i] = cao[i] / O
	hm.map_data = du_lieu
	var hinh := CollisionShape3D.new()
	hinh.shape = hm
	hinh.scale = Vector3.ONE * O
	add_child(hinh)
	# thống kê độ dốc trong vùng chơi (để chỉnh cho mecha vẫn lướt lên được)
	var doc := 0
	var tong := 0
	for iz in range(1, n):
		for ix in range(1, n):
			var x := goc + ix * O
			var z := goc + iz * O
			if absf(x) > 1450.0 or absf(z) > 1450.0:
				continue
			tong += 1
			var dx: float = cao[iz * (n + 1) + ix + 1] - cao[iz * (n + 1) + ix - 1]
			var dz: float = cao[(iz + 1) * (n + 1) + ix] - cao[(iz - 1) * (n + 1) + ix]
			if Vector2(dx, dz).length() / (2.0 * O) > tan(deg_to_rad(38.0)):
				doc += 1
	print("[dia_hinh] %s: %.1f%% o luoi trong vung choi doc hon 38 do" % [kieu, 100.0 * doc / maxf(1.0, tong)])
