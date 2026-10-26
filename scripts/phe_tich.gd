class_name PheTich
extends RefCounted
## Tạo lưới 3D bằng code cho khối bê tông, cột gãy, tường xếp khối đổ nát (dùng ở 3 bản đồ và bãi tập).
## Mọi hàm trả về ArrayMesh; chất liệu gán ở nơi dùng (vân chiếu theo toạ độ thế giới nên không cần UV).
## (26/10: bỏ cổng vòm, kim tự tháp bậc, tháp nhọn, cột đổ của bản đồ sa mạc cũ — không còn ai dùng.)


## Thêm một khối hộp (đã biến đổi) vào SurfaceTool, pháp tuyến phẳng từng mặt.
static func them_hop(st: SurfaceTool, t: Transform3D, kich: Vector3) -> void:
	var h := kich * 0.5
	var mat := [
		[Vector3.RIGHT, Vector3.UP, Vector3.FORWARD], [Vector3.LEFT, Vector3.UP, Vector3.BACK],
		[Vector3.UP, Vector3.FORWARD, Vector3.RIGHT], [Vector3.DOWN, Vector3.BACK, Vector3.RIGHT],
		[Vector3.BACK, Vector3.UP, Vector3.RIGHT], [Vector3.FORWARD, Vector3.UP, Vector3.LEFT],
	]
	for m in mat:
		var n: Vector3 = m[0]
		var u: Vector3 = m[1]
		var v: Vector3 = m[2]
		var c := Vector3(n.x * h.x, n.y * h.y, n.z * h.z)
		var du := Vector3(u.x * h.x, u.y * h.y, u.z * h.z)
		var dv := Vector3(v.x * h.x, v.y * h.y, v.z * h.z)
		var g := [c - du - dv, c + du - dv, c + du + dv, c - du + dv]
		var nn := (t.basis * n).normalized()
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nn)
			st.add_vertex(t * (g[k] as Vector3))


## Thân trụ (cột): bán kính dưới / trên, cao h, có rãnh dọc; gay > 0 thì ngọn gãy lởm chởm (độ sâu tương đối).
static func them_tru(st: SurfaceTool, t: Transform3D, r_duoi: float, r_tren: float, h: float, so_canh: int,
		so_ranh: int, gay: float, rng: RandomNumberGenerator) -> void:
	var ngon: Array[float] = []
	for i in so_canh:
		var lom := 0.0
		if gay > 0.0:
			lom = h * gay * (0.3 + 0.7 * rng.randf()) * (0.6 + 0.4 * sin(i * 0.9 + rng.randf()))
		ngon.append(h - maxf(lom, 0.0))
	var diem_duoi: Array[Vector3] = []
	var diem_tren: Array[Vector3] = []
	var phap: Array[Vector3] = []
	for i in so_canh:
		var a := TAU * i / so_canh
		var rr := 1.0 + (0.045 * cos(a * so_ranh) if so_ranh > 0 else 0.0)
		var huong := Vector3(cos(a), 0.0, sin(a))
		var ty := ngon[i] / h
		var r_ngon := lerpf(r_duoi, r_tren, ty)
		diem_duoi.append(huong * r_duoi * rr)
		diem_tren.append(huong * r_ngon * rr + Vector3.UP * ngon[i])
		phap.append(huong)
	for i in so_canh:
		var j := (i + 1) % so_canh
		var bo := [[diem_duoi[i], phap[i]], [diem_duoi[j], phap[j]], [diem_tren[j], phap[j]],
			[diem_duoi[i], phap[i]], [diem_tren[j], phap[j]], [diem_tren[i], phap[i]]]
		for x in bo:
			st.set_normal((t.basis * (x[1] as Vector3)).normalized())
			st.add_vertex(t * (x[0] as Vector3))
	# mặt trên (gãy: lởm chởm)
	var tam := Vector3.UP * (h * (1.0 - gay * 0.5) if gay > 0.0 else h)
	for i in so_canh:
		var j := (i + 1) % so_canh
		var n := (diem_tren[j] - tam).cross(diem_tren[i] - tam).normalized()
		if n.y < 0.0:
			n = -n
		for x in [tam, diem_tren[i], diem_tren[j]]:
			st.set_normal((t.basis * n).normalized())
			st.add_vertex(t * (x as Vector3))


static func _xong(st: SurfaceTool) -> ArrayMesh:
	return st.commit()


## Cột cổ: bệ vuông + thân có rãnh + đầu cột (nếu còn nguyên). gay: 0 = nguyên, 0.1–0.5 = gãy ngọn.
static func cot(h: float, r: float, gay: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	them_hop(st, Transform3D(Basis(), Vector3(0, r * 0.45, 0)), Vector3(r * 2.7, r * 0.9, r * 2.7))
	them_hop(st, Transform3D(Basis(), Vector3(0, r * 1.05, 0)), Vector3(r * 2.4, r * 0.3, r * 2.4))
	var than := h - r * 1.2 - (r * 1.1 if gay <= 0.0 else 0.0)
	them_tru(st, Transform3D(Basis(), Vector3(0, r * 1.2, 0)), r, r * 0.86, than, 40, 20, gay, rng)
	if gay <= 0.0:
		them_hop(st, Transform3D(Basis(), Vector3(0, r * 1.2 + than + r * 0.25, 0)), Vector3(r * 2.0, r * 0.5, r * 2.0))
		them_hop(st, Transform3D(Basis(), Vector3(0, r * 1.2 + than + r * 0.8, 0)), Vector3(r * 2.8, r * 0.6, r * 2.8))
	return _xong(st)


## Tường xếp khối đổ nát: dài × cao × dày; đỉnh lởm chởm, có lỗ hổng. Trả về [lưới, danh sách cột (x, cao)] để dựng va chạm.
static func tuong(dai: float, cao: float, day: float, rng: RandomNumberGenerator) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var khoi_dai := 4.0
	var khoi_cao := 2.4
	var so_cot := maxi(2, int(dai / khoi_dai))
	var so_hang := maxi(1, int(cao / khoi_cao))
	var cot_cao: Array = []
	var pha := rng.randf() * 10.0
	for c in so_cot:
		var dinh := float(so_hang) * (0.45 + 0.55 * absf(sin(c * 0.37 + pha)) * (0.6 + 0.4 * rng.randf()))
		if rng.randf() < 0.12:
			dinh *= 0.3                                         # chỗ sụp
		var n := maxi(1, int(dinh))
		cot_cao.append([(c + 0.5 - so_cot * 0.5) * khoi_dai, n * khoi_cao])
		for hng in n:
			var lo := hng >= 2 and hng < n - 1 and rng.randf() < 0.07  # lỗ hổng
			if lo:
				continue
			var x := (c + 0.5 - so_cot * 0.5) * khoi_dai
			var kich := Vector3(khoi_dai * rng.randf_range(0.93, 0.99), khoi_cao * rng.randf_range(0.94, 0.99), day * rng.randf_range(0.92, 1.0))
			var xoay := Basis(Vector3.UP, rng.randf_range(-0.03, 0.03))
			var p := Vector3(x + rng.randf_range(-0.15, 0.15), hng * khoi_cao + khoi_cao * 0.5, rng.randf_range(-0.2, 0.2))
			them_hop(st, Transform3D(xoay, p), kich)
	return [_xong(st), cot_cao]
