class_name AnhBanDo
extends RefCounted
## Vẽ ảnh nền bản đồ chiến trường (nhìn từ trên xuống, bắc ở trên = phía căn cứ địch) một lần lúc vào trận:
## màu đất theo kiểu bản đồ, đổ bóng đồi theo độ cao thật của địa hình, nước / hồ băng, đường, vật cản lớn
## (phế tích, cụm tảng băng, đá), cây rừng. Bản đồ lớn (phím M) và bản đồ nhỏ góc màn hình dùng chung ảnh này.

const N := 480                    # cạnh ảnh (px) cho cả vùng chơi 3200 m: 6,7 m mỗi px
const RONG := 3200.0


## Toạ độ ảnh (px) của một điểm (x, z) trên mặt đất.
static func diem_anh(x: float, z: float) -> Vector2:
	return Vector2((x + RONG * 0.5) / RONG * N, (z + RONG * 0.5) / RONG * N)


static func tao(bd: Node) -> ImageTexture:
	var dh: DiaHinh = bd.dia_hinh
	var kieu := dh.kieu
	var thap := Color(0.7, 0.55, 0.36)
	var cao := Color(0.88, 0.74, 0.52)
	var mau_vat := Color(0.5, 0.4, 0.28)
	var mau_duong := Color(0.64, 0.56, 0.45)
	var mau_nuoc := Color(0.45, 0.65, 0.82)
	match kieu:
		"bai_tap":
			thap = Color(0.42, 0.42, 0.43)
			cao = Color(0.36, 0.42, 0.24)
			mau_vat = Color(0.6, 0.6, 0.62)
		"dong_que":
			thap = Color(0.36, 0.4, 0.2)
			cao = Color(0.5, 0.52, 0.28)
			mau_vat = Color(0.5, 0.48, 0.45)
			mau_duong = Color(0.5, 0.41, 0.29)
			mau_nuoc = Color(0.2, 0.36, 0.42)
		"ngoai_o":
			thap = Color(0.24, 0.34, 0.15)
			cao = Color(0.4, 0.48, 0.24)
			mau_vat = Color(0.55, 0.53, 0.5)
			mau_duong = Color(0.22, 0.22, 0.24)
		"thanh_pho":
			thap = Color(0.34, 0.34, 0.35)
			cao = Color(0.34, 0.34, 0.35)
			mau_vat = Color(0.55, 0.53, 0.5)
			mau_duong = Color(0.2, 0.2, 0.22)
	# 1) nền theo lưới độ cao của địa hình (mỗi đỉnh lưới 20 m), đổ bóng đồi ánh sáng từ tây bắc
	var n := dh.so_o
	var o := DiaHinh.O
	var goc := -DiaHinh.KICH * 0.5
	var i0 := int((-RONG * 0.5 - goc) / o)
	var so := int(RONG / o)
	var nho := Image.create(so, so, false, Image.FORMAT_RGB8)
	for iz in so:
		for ix in so:
			var gx := clampi(i0 + ix, 1, n - 1)
			var gz := clampi(i0 + iz, 1, n - 1)
			var h: float = dh.cao_luoi[gz * (n + 1) + gx]
			var dx: float = dh.cao_luoi[gz * (n + 1) + gx - 1] - dh.cao_luoi[gz * (n + 1) + gx + 1]
			var dz: float = dh.cao_luoi[(gz - 1) * (n + 1) + gx] - dh.cao_luoi[(gz + 1) * (n + 1) + gx]
			var bong := clampf(1.0 + (dx + dz) * 0.018, 0.78, 1.18)
			var c := thap.lerp(cao, clampf(h / 50.0, 0.0, 1.0)) * bong
			if kieu == "dong_que" and h < DiaHinh.MUC_NUOC + 0.4:
				c = mau_nuoc
			nho.set_pixel(ix, iz, Color(c.r, c.g, c.b))
	nho.resize(N, N, Image.INTERPOLATE_BILINEAR)
	var img := nho
	# 2) đường (thành phố: thêm lưới phố ô bàn cờ)
	var bdd: DungBanDo = bd._dung_ban_do
	if bdd is DungThanhPho:
		var w_pho := maxi(2, int(DungThanhPho.RONG_PHO / RONG * N))
		for i in range(-10, 11):
			var c := diem_anh(i * DungThanhPho.O_PHO, i * DungThanhPho.O_PHO)
			img.fill_rect(Rect2i(int(c.x) - w_pho / 2, 0, w_pho, N), mau_duong)
			img.fill_rect(Rect2i(0, int(c.y) - w_pho / 2, N, w_pho), mau_duong)
	if bdd is DungDongQue:
		var mau_cay2 := Color(0.12, 0.22, 0.07)
		for q2 in (bdd as DungDongQue).cay.vi_tri:
			var q := diem_anh(q2.x, q2.y)
			img.fill_rect(Rect2i(int(q.x), int(q.y), 2, 2), mau_cay2)
	if bdd is DungNgoaiO:
		# phố cong đông–tây và phố nối bắc–nam
		for k in range(-6, 7):
			for xi in range(-1600, 1600, 6):
				var q := diem_anh(xi, DungNgoaiO.z_pho(xi, k))
				img.fill_rect(Rect2i(int(q.x) - 1, int(q.y) - 1, 2, 2), mau_duong)
		for j in range(-4, 5):
			for zi in range(-1600, 1600, 6):
				var q := diem_anh(DungNgoaiO.x_noi(zi, j), zi)
				img.fill_rect(Rect2i(int(q.x) - 1, int(q.y) - 1, 2, 2), mau_duong)
		var mau_cay := Color(0.1, 0.2, 0.06)
		for q2 in (bdd as DungNgoaiO).cay.vi_tri:
			var q := diem_anh(q2.x, q2.y)
			img.fill_rect(Rect2i(int(q.x), int(q.y), 2, 2), mau_cay)
	var w_d := maxi(3, int(bdd.rong_duong / RONG * N))
	for d in bdd.duong:
		var a: Vector2 = diem_anh(d[0].x, d[0].y)
		var b: Vector2 = diem_anh(d[1].x, d[1].y)
		var buoc := int(a.distance_to(b))
		for k in buoc + 1:
			var p := a.lerp(b, float(k) / maxf(1.0, buoc))
			img.fill_rect(Rect2i(int(p.x) - w_d / 2, int(p.y) - w_d / 2, w_d, w_d), mau_duong)
	# nhà: khối sáng (còn nguyên) / khối nâu xám (đổ nát)
	for h in bdd.ds_hop_nha:
		var q := diem_anh((h[0] as Vector2).x, (h[0] as Vector2).y)
		var k := (h[1] as Vector2) / RONG * N
		var mau_nha := Color(0.5, 0.46, 0.42) if h[2] else Color(0.78, 0.78, 0.8)
		img.fill_rect(Rect2i(int(q.x - k.x * 0.5), int(q.y - k.y * 0.5), maxi(1, int(k.x)), maxi(1, int(k.y))), mau_nha)
	# 3) vật cản tròn (tường đổ, đá)
	for x in bd._dung_ban_do.ds_ban_do():
		var q := diem_anh(x[0].x, x[0].y)
		var r := maxf(1.0, float(x[1]) / RONG * N * 0.75)
		for yy in range(int(q.y - r), int(q.y + r) + 1):
			for xx in range(int(q.x - r), int(q.x + r) + 1):
				if xx >= 0 and yy >= 0 and xx < N and yy < N and Vector2(xx, yy).distance_to(q) <= r:
					img.set_pixel(xx, yy, mau_vat)
	return ImageTexture.create_from_image(img)
