class_name CayRung
extends RefCounted
## Tạo lưới cây rừng bằng code (không dùng mẫu tải về), theo thước mecha cao 10 m:
## - co_thu: cây cổ thụ cao 45–80 m, thân to 3,6–6 m, rễ bạnh vè cao 6–10 m, cành tỏa, tán lá ở 35–80 m.
## - cay_vua: cây tầng giữa cao 26–40 m, thân 2–3 m.
## - cay_co: cây cọ cao 18–28 m, thân cong, tàu lá dài 8–11 m rủ xuống.
## - duong_xi: bụi dương xỉ cao 3–4,5 m (tới ngực mecha). bui: bụi lá rộng cao 3–5 m.
## - cay_do: thân cây đổ (dài 1, bán kính 1 — phóng theo kích thước khi đặt).
## Mỗi cây trả về [ArrayMesh, bán kính gốc thân, chiều cao thân]. Mặt 0 là vỏ cây, mặt 1 là lá (tấm phẳng, lá vẽ
## trong la_cay.gdshader). Bụi chỉ có một mặt lá.


## Đoạn thân trụ thon từ a tới b (bán kính ra -> rb), n cạnh, pháp tuyến hướng ra ngoài.
static func _doan(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, n: int) -> void:
	var truc := (b - a).normalized()
	var u := truc.cross(Vector3.FORWARD if absf(truc.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var v := truc.cross(u).normalized()
	for i in n:
		var a1 := TAU * i / n
		var a2 := TAU * (i + 1) / n
		var d1 := u * cos(a1) + v * sin(a1)
		var d2 := u * cos(a2) + v * sin(a2)
		var p := [a + d1 * ra, a + d2 * ra, b + d2 * rb, b + d1 * rb]
		var nn := [d1, d2, d2, d1]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nn[k])
			st.add_vertex(p[k])


## Thân cây gồm nhiều đoạn, cong nhẹ. Trả về danh sách điểm tâm thân theo chiều cao.
static func _than(st: SurfaceTool, r0: float, r1: float, h: float, so_doan: int, cong: float, rng: RandomNumberGenerator, n := 10) -> Array[Vector3]:
	var diem: Array[Vector3] = []
	var huong := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
	var pha := rng.randf() * TAU
	for i in so_doan + 1:
		var t := float(i) / so_doan
		var lech := huong * cong * t * t + Vector2(sin(t * 5.0 + pha), cos(t * 4.0 + pha)) * cong * 0.15
		diem.append(Vector3(lech.x, -1.5 + (h + 1.5) * t, lech.y))
	for i in so_doan:
		var t1 := float(i) / so_doan
		var t2 := float(i + 1) / so_doan
		_doan(st, diem[i], diem[i + 1], lerpf(r0, r1, t1), lerpf(r0, r1, t2), n)
	return diem


## Rễ bạnh vè: tấm vè mỏng hình tam giác chạy từ thân xuống đất.
static func _re_banh(st: SurfaceTool, r0: float, so: int, rng: RandomNumberGenerator) -> void:
	var a0 := rng.randf() * TAU
	for i in so:
		var a := a0 + TAU * i / so + rng.randf_range(-0.25, 0.25)
		var d := Vector3(cos(a), 0, sin(a))
		var ngang := Vector3(-d.z, 0, d.x) * rng.randf_range(0.5, 0.75) * r0 / 2.4
		var cao := rng.randf_range(4.0, 7.0) * r0 / 2.4
		var xa := r0 + rng.randf_range(3.5, 6.5) * r0 / 2.4
		var tren := d * r0 * 0.85 + Vector3.UP * cao
		var goc_trong := d * r0 * 0.8 + Vector3.DOWN * 1.5
		var chan := d * xa + Vector3.DOWN * 1.5
		var giua := d * (r0 + (xa - r0) * 0.35) + Vector3.UP * cao * 0.35
		for s: float in [-1.0, 1.0]:
			var lech: Vector3 = ngang * s
			var n := (d.cross(Vector3.UP) * s).normalized()
			for v in [tren + lech * 0.4, giua + lech, chan + lech * 0.6, tren + lech * 0.4, chan + lech * 0.6, goc_trong + lech]:
				st.set_normal((n + d * 0.3).normalized())
				st.add_vertex(v)
		# sống vè (mặt trên)
		for v in [tren - ngang * 0.4, tren + ngang * 0.4, giua + ngang, tren - ngang * 0.4, giua + ngang, giua - ngang,
				giua - ngang, giua + ngang, chan + ngang * 0.6, giua - ngang, chan + ngang * 0.6, chan - ngang * 0.6]:
			st.set_normal((d + Vector3.UP).normalized())
			st.add_vertex(v)


## Một tấm lá vuông cạnh k tại tam, xoay theo b (tấm nằm trong mặt phẳng x-z của b). n_ra: pháp tuyến (hướng ra ngoài tán).
static func _tam_la(st: SurfaceTool, tam: Vector3, k: float, b: Basis, n_ra: Vector3) -> void:
	var x := b.x * k * 0.5
	var z := b.z * k * 0.5
	var g := [tam - x - z, tam + x - z, tam + x + z, tam - x + z]
	var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n_ra)
		st.set_uv(uv[i])
		st.add_vertex(g[i])


## Chùm lá quanh tâm c: so tấm cỡ k rải trong khối elip bán kính r (dẹt theo chiều đứng).
static func _chum_la(st: SurfaceTool, c: Vector3, so: int, k: float, r: float, tam_tan: Vector3, rng: RandomNumberGenerator) -> void:
	for i in so:
		var q := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.6), rng.randf_range(-1, 1)) * r
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.6, 0.6)) * Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4))
		var n_ra := ((c + q - tam_tan).normalized() + Vector3.UP * 0.8).normalized()
		_tam_la(st, c + q, k * rng.randf_range(0.8, 1.2), b, n_ra)


## Tàu lá cong (dương xỉ, cọ): dải gồm so_doan đoạn, bắt đầu từ goc theo hướng ngang huong, ngóc lên rồi rủ xuống.
static func _la_cong(st: SurfaceTool, goc: Vector3, huong: Vector3, dai: float, rong: float, ngoc: float, ru: float, so_doan: int) -> void:
	var ngang := huong.cross(Vector3.UP).normalized() * rong * 0.5
	var truoc_l := Vector3.ZERO
	var truoc_r := Vector3.ZERO
	for i in so_doan + 1:
		var t := float(i) / so_doan
		var p := goc + huong * dai * t + Vector3.UP * (ngoc * t - ru * t * t) * dai
		var l := p - ngang
		var r := p + ngang
		if i > 0:
			var t0 := float(i - 1) / so_doan
			var n := (ngang.cross(p - (truoc_l + truoc_r) * 0.5)).normalized()
			if n.y < 0.0:
				n = -n
			var g := [truoc_l, truoc_r, r, l]
			var uv := [Vector2(0, t0), Vector2(1, t0), Vector2(1, t), Vector2(0, t)]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(n)
				st.set_uv(uv[k])
				st.add_vertex(g[k])
		truoc_l = l
		truoc_r = r


static func _xong(st_vo: SurfaceTool, st_la: SurfaceTool) -> ArrayMesh:
	var m := ArrayMesh.new()
	if st_vo:
		st_vo.commit(m)
	st_la.commit(m)
	return m


## Cây cổ thụ tầng vượt tán.
static func co_thu(rng: RandomNumberGenerator) -> Array:
	var vo := SurfaceTool.new()
	vo.begin(Mesh.PRIMITIVE_TRIANGLES)
	var la := SurfaceTool.new()
	la.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := rng.randf_range(45.0, 80.0)
	var r0 := rng.randf_range(1.8, 3.0)
	var h_tan := h * rng.randf_range(0.66, 0.76)
	var tam := _than(vo, r0, r0 * 0.5, h_tan, 6, rng.randf_range(1.0, 3.5), rng)
	_re_banh(vo, r0, rng.randi_range(4, 6), rng)
	var dinh: Vector3 = tam[tam.size() - 1]
	var tam_tan := dinh + Vector3.UP * h * 0.1
	var so_canh := rng.randi_range(5, 7)
	var a0 := rng.randf() * TAU
	for i in so_canh:
		var a := a0 + TAU * i / so_canh + rng.randf_range(-0.3, 0.3)
		var goc := tam[rng.randi_range(4, 6)]
		var dau := goc + Vector3(cos(a), 0, sin(a)) * rng.randf_range(9.0, 15.0) * (h / 60.0) + Vector3.UP * rng.randf_range(5.0, 10.0)
		_doan(vo, goc, dau, r0 * 0.38, r0 * 0.14, 6)
		_chum_la(la, dau + Vector3.UP * 2.5, 16, rng.randf_range(9.0, 12.0), 7.0, tam_tan, rng)
		_chum_la(la, goc.lerp(dau, 0.55) + Vector3.UP * 3.0, 6, rng.randf_range(8.0, 10.0), 4.0, tam_tan, rng)
	_chum_la(la, dinh + Vector3.UP * 6.0, 22, rng.randf_range(10.0, 13.0), 9.0, tam_tan, rng)
	return [_xong(vo, la), r0, h_tan]


## Cây tầng giữa.
static func cay_vua(rng: RandomNumberGenerator) -> Array:
	var vo := SurfaceTool.new()
	vo.begin(Mesh.PRIMITIVE_TRIANGLES)
	var la := SurfaceTool.new()
	la.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := rng.randf_range(26.0, 40.0)
	var r0 := rng.randf_range(1.0, 1.5)
	var h_tan := h * 0.72
	var tam := _than(vo, r0, r0 * 0.55, h_tan, 5, rng.randf_range(0.8, 2.5), rng, 8)
	var dinh: Vector3 = tam[tam.size() - 1]
	var tam_tan := dinh + Vector3.UP * 4.0
	for i in 4:
		var a := TAU * i / 4.0 + rng.randf_range(-0.4, 0.4)
		var goc: Vector3 = tam[rng.randi_range(3, 4)]
		var dau := goc + Vector3(cos(a), 0, sin(a)) * rng.randf_range(4.0, 7.0) + Vector3.UP * rng.randf_range(3.0, 6.0)
		_doan(vo, goc, dau, r0 * 0.35, r0 * 0.15, 5)
		_chum_la(la, dau + Vector3.UP * 1.0, 12, rng.randf_range(7.0, 9.0), 5.0, tam_tan, rng)
	_chum_la(la, dinh + Vector3.UP * 5.0, 16, rng.randf_range(7.5, 9.5), 6.5, tam_tan, rng)
	_chum_la(la, dinh + Vector3.DOWN * 2.0, 8, rng.randf_range(7.0, 9.0), 6.0, tam_tan, rng)
	return [_xong(vo, la), r0, h_tan]


## Cây cọ: thân mảnh cong, đốt ngang, tàu lá dài rủ xuống.
static func cay_co(rng: RandomNumberGenerator) -> Array:
	var vo := SurfaceTool.new()
	vo.begin(Mesh.PRIMITIVE_TRIANGLES)
	var la := SurfaceTool.new()
	la.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := rng.randf_range(18.0, 28.0)
	var r0 := rng.randf_range(0.55, 0.8)
	var tam := _than(vo, r0, r0 * 0.75, h, 7, rng.randf_range(2.0, 4.5), rng, 7)
	var dinh: Vector3 = tam[tam.size() - 1]
	var so := rng.randi_range(10, 13)
	var a0 := rng.randf() * TAU
	for i in so:
		var a := a0 + TAU * i / so + rng.randf_range(-0.15, 0.15)
		var huong := Vector3(cos(a), 0, sin(a))
		_la_cong(la, dinh, huong, rng.randf_range(8.0, 11.0), rng.randf_range(2.2, 2.8), rng.randf_range(0.35, 0.7), rng.randf_range(0.8, 1.2), 4)
	for i in 3:
		var a := rng.randf() * TAU
		_la_cong(la, dinh, Vector3(cos(a), 0, sin(a)), rng.randf_range(5.0, 7.0), 1.8, 1.4, 0.6, 3)
	return [_xong(vo, la), r0, h]


## Bụi dương xỉ: tàu lá mọc từ gốc tỏa vòng, ngóc lên rồi rủ (cao 3–4,5 m, rộng 8–11 m).
static func duong_xi(rng: RandomNumberGenerator) -> Array:
	var la := SurfaceTool.new()
	la.begin(Mesh.PRIMITIVE_TRIANGLES)
	var so := rng.randi_range(9, 13)
	var a0 := rng.randf() * TAU
	for i in so:
		var a := a0 + TAU * i / so + rng.randf_range(-0.2, 0.2)
		_la_cong(la, Vector3(0, 0.2, 0), Vector3(cos(a), 0, sin(a)), rng.randf_range(4.5, 6.0), rng.randf_range(1.5, 1.9),
			rng.randf_range(1.0, 1.5), rng.randf_range(0.8, 1.2), 3)
	return [_xong(null, la), 0.0, 4.0]


## Bụi lá rộng: chùm tấm lá dạng vòm (cao 3–5 m, rộng 7–9 m).
static func bui(rng: RandomNumberGenerator) -> Array:
	var la := SurfaceTool.new()
	la.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cao := rng.randf_range(2.5, 4.0)
	_chum_la(la, Vector3(0, cao, 0), rng.randi_range(10, 14), rng.randf_range(4.0, 5.5), 3.5, Vector3(0, -1, 0), rng)
	return [_xong(null, la), 0.0, cao]


## Thân cây đổ: trụ thon dọc trục x từ 0 tới 1, bán kính 1 ở gốc (phóng to khi đặt), hai đầu gãy lởm chởm.
static func cay_do(rng: RandomNumberGenerator) -> ArrayMesh:
	var vo := SurfaceTool.new()
	vo.begin(Mesh.PRIMITIVE_TRIANGLES)
	_doan(vo, Vector3(0, 0, 0), Vector3(0.5, 0, 0), 1.0, 0.85, 9)
	_doan(vo, Vector3(0.5, 0, 0), Vector3(1.0, 0, 0), 0.85, 0.7, 9)
	# đầu gãy: hình nón lởm chởm
	for dau in [[Vector3.ZERO, 1.0, -1.0], [Vector3(1, 0, 0), 0.7, 1.0]]:
		var c: Vector3 = dau[0]
		var r: float = dau[1]
		var s: float = dau[2]
		for i in 9:
			var a1 := TAU * i / 9.0
			var a2 := TAU * (i + 1) / 9.0
			var p1 := c + Vector3(0, cos(a1), sin(a1)) * r
			var p2 := c + Vector3(0, cos(a2), sin(a2)) * r
			var nhon := c + Vector3(s * rng.randf_range(0.02, 0.06), rng.randf_range(-0.3, 0.3) * r, rng.randf_range(-0.3, 0.3) * r)
			for v in [p1, p2, nhon]:
				vo.set_normal(Vector3(s, 0, 0))
				vo.add_vertex(v)
	var m := ArrayMesh.new()
	vo.commit(m)
	return m
