class_name HoTro
extends Node
## Gọi hỗ trợ từ chiến hạm phe ta (bản thử: chỉ có thời gian hồi).
##   1. Pháo kích (tàu pháo kích; khi tắt chế độ hạm đội thì bắn từ tàu sân bay — người dùng chốt giữ): đánh dấu một vùng cố định (chỗ mục tiêu khóa đang đứng, hoặc điểm ngắm),
##      sau vài giây một loạt đạn pháo hạng nặng rơi rải khắp vùng, nổ lan rộng.
##   2. Thả tiếp tế (tàu sân bay): hòm rơi xuống phía trước mecha, nằm đó 60 giây, lại gần để nhặt.
##   3. Quét radar (tàu sân bay): thấy vị trí mọi mecha địch, kể cả sau nhà, trong vài giây.
##   4. Thả mecha tiếp viện (tàu sân bay): một mecha phe ta rơi xuống và cùng chiến đấu.

const THU_TU := ["phao_kich", "tiep_te", "radar", "tiep_vien"]

var ban_do: Node                  # BanDoThu: có nguoi_choi, tau_san_bay, tao_tiep_vien()
var hoi: Array[float] = [0.0, 0.0, 0.0, 0.0]
var radar_con := 0.0
var thong_bao := ""
var thong_bao_con := 0.0
var tiep_vien: Array[Mecha] = []
var dch := 0                         # Điểm Chỉ Huy kiếm trong trận (hạ mecha, chiếm cứ điểm, bắn rơi máy bay)


func _process(dt: float) -> void:
	for i in hoi.size():
		hoi[i] = maxf(0.0, hoi[i] - dt)
	radar_con = maxf(0.0, radar_con - dt)
	thong_bao_con = maxf(0.0, thong_bao_con - dt)
	tiep_vien.assign(tiep_vien.filter(func(x) -> bool: return is_instance_valid(x) and x.song))


func _bao(s: String) -> void:
	thong_bao = s
	thong_bao_con = 2.5


func them_dch(n: int, ly_do: String) -> void:
	dch += n
	_bao(tr("+%d Điểm Chỉ Huy — %s") % [n, ly_do])


## Giá Điểm Chỉ Huy của một hỗ trợ (0 = miễn phí).
func gia(id: String) -> int:
	var g: int = int(CanBang.HO_TRO[id].get("dch", 0))
	if id == "tiep_vien":
		g = maxi(0, g - 10 * TienTrinh.so_nut("san_bay", 1))
	return g


## Lý do hỗ trợ chưa gọi được vì tàu ("" = gọi được).
func ly_do_khong_goi(id: String) -> String:
	var tr: TranTrenTroi = ban_do.tran_troi
	var sb := tr.san_bay(0)
	if sb == null or not sb.song:
		return tr("Tàu sân bay đã bị hạ")
	match id:
		"tiep_vien":
			if sb.te_liet_con > 0.0:
				return tr("Tàu sân bay đang bị EMP")
	return ""


func goi(i: int) -> void:
	var m: Mecha = ban_do.nguoi_choi
	if not m.song:
		return
	var id: String = THU_TU[i]
	var cfg: Dictionary = CanBang.HO_TRO[id]
	if hoi[i] > 0.0:
		_bao(tr("%s chưa sẵn sàng (%.0f s)") % [cfg["ten"], hoi[i]])
		return
	var ly_do := ly_do_khong_goi(id)
	if ly_do != "":
		_bao("%s: %s" % [tr(cfg["ten"]), ly_do])
		AmThanh.ui("loi")
		return
	if dch < gia(id):
		_bao(tr("%s cần %d Điểm Chỉ Huy (đang có %d)") % [cfg["ten"], gia(id), dch])
		AmThanh.ui("loi")
		return
	dch -= gia(id)
	match id:
		"phao_kich":
			_phao_kich(m, cfg)
		"tiep_te":
			_tiep_te(m, cfg)
		"radar":
			radar_con = cfg["thoi_gian"]
		"tiep_vien":
			if tiep_vien.size() >= int(cfg["toi_da"]):
				_bao(tr("Đã có đủ %d mecha tiếp viện") % int(cfg["toi_da"]))
				return
			var vi_tri := m.global_position + m.global_basis.x * 30.0 - m.global_basis.z * 10.0
			tiep_vien.append(ban_do.tao_tiep_vien(vi_tri))
	var he_hoi := 1.0
	if id == "tiep_te" or id == "radar":
		he_hoi = 1.0 - 0.1 * TienTrinh.so_nut("san_bay", 2)
	elif id == "phao_kich":
		he_hoi = 1.0 - 0.08 * TienTrinh.so_nut("phao_kich", 0)
	hoi[i] = float(cfg["hoi"]) * he_hoi
	_bao("%s: %s" % [tr(cfg["tau"]), tr(cfg["ten"])])
	AmThanh.ui("mo")


# ---------------------------------------------------------------- pháo kích

func _mat_dat(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 50.0, p + Vector3.DOWN * 300.0, 1)
	var kq := get_viewport().world_3d.direct_space_state.intersect_ray(q)
	return kq["position"] if kq else Vector3(p.x, 0.0, p.z)


## Pháo kích vào một VÙNG CỐ ĐỊNH: chỗ mục tiêu đang khóa đứng lúc gọi, hoặc điểm đang ngắm.
## Vòng đỏ hiện đúng vùng sát thương; địch kịp chạy ra khỏi vòng thì thoát.
func _phao_kich(m: Mecha, cfg: Dictionary) -> void:
	var goc: Vector3 = m.khoa.global_position if (is_instance_valid(m.khoa) and m.khoa.get("song") != false) else m.dk_ngam
	var diem := _mat_dat(goc)
	var vung: float = cfg["vung"]
	var dau := _vong_danh_dau(diem, vung)
	dau.add_to_group("vung_nguy_hiem")          # bot địch thấy vòng đỏ sẽ tìm cách chạy ra
	dau.set_meta("ban_kinh", vung)
	dau.set_meta("phe", m.phe)
	await get_tree().create_timer(cfg["tre"]).timeout
	var tau: Node3D = ban_do.tau_san_bay
	var toc_dan := 520.0
	var so: int = cfg["so_dan"]
	for k in so:
		# đạn rơi gần thẳng đứng từ trên cao (lệch nhẹ về phía tàu) để không vướng nhà
		var ve_tau := Vector3(tau.global_position.x - diem.x, 0.0, tau.global_position.z - diem.z).normalized()
		var tu := diem + ve_tau * 120.0 + Vector3(randf_range(-30, 30), 520.0, randf_range(-30, 30))
		# rải đều khắp vùng: quả đầu rơi giữa, các quả sau xoay vòng ra mép
		var goc_r := TAU * k / 5.0 + randf_range(-0.4, 0.4)
		var r := 0.0 if k == 0 else vung * sqrt(float(k) / so) * randf_range(0.75, 1.0)
		var dich := diem + Vector3(cos(goc_r), 0.0, sin(goc_r)) * r
		var dan := DanPlasma.new()
		dan.chu = ban_do.nguoi_choi
		dan.phe = 0
		dan.van_toc = (dich - tu).normalized() * toc_dan
		dan.sat_thuong = float(cfg["sat_thuong"]) * (1.0 + 0.1 * TienTrinh.so_nut("phao_kich", 0))
		dan.ban_kinh_no = cfg["no"]
		dan.mau = Color(1.6, 0.7, 0.2)
		dan.kich_thuoc = 3.0
		ban_do.add_child(dan)
		dan.global_position = tu
		dan.thoi_gian = 4.0
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(dau):
		dau.queue_free()

func _vong_danh_dau(diem: Vector3, ban_kinh: float) -> Node3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = ban_kinh - 2.5
	tm.outer_radius = ban_kinh
	tm.rings = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.8, 0.4, 0.2)
	tm.material = mat
	mi.mesh = tm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ban_do.add_child(mi)
	mi.global_position = diem + Vector3.UP * 0.4
	mi.scale = Vector3(1.0, 0.6, 1.0)
	var cot := MeshInstance3D.new()   # cột sáng đánh dấu từ xa
	var cm := CylinderMesh.new()
	cm.top_radius = 0.8
	cm.bottom_radius = 0.8
	cm.height = 160.0
	cm.material = mat
	cot.mesh = cm
	cot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.add_child(cot)
	cot.position = Vector3(0, 80.0 / 0.6, 0)
	cot.scale = Vector3(1.0, 1.0 / 0.6, 1.0)
	var tw := mi.create_tween().set_loops()
	tw.tween_property(mat, "albedo_color", Color(0.6, 0.1, 0.05), 0.3)
	tw.tween_property(mat, "albedo_color", Color(1.8, 0.4, 0.2), 0.3)
	return mi


# ---------------------------------------------------------------- tiếp tế

func _tiep_te(m: Mecha, cfg: Dictionary) -> void:
	var dich := _mat_dat(m.global_position - m.global_basis.z * float(cfg["cach"]))
	var thung := ThungTiepTe.new()
	thung.phe = m.phe
	thung.hoi_mau = cfg["hoi_mau"]
	thung.ton_tai = cfg["ton_tai"]
	thung.ban_kinh_nhat = cfg["nhat"]
	ban_do.add_child(thung)
	thung.da_nhat.connect(func(boi: Mecha) -> void:
		if boi == ban_do.nguoi_choi:
			_bao(tr("Đã nhặt tiếp tế: +%d giáp, đầy năng lượng") % int(cfg["hoi_mau"]))
		else:
			_bao(tr("%s đã nhặt tiếp tế") % boi.ten))
	var tau: Node3D = ban_do.tau_san_bay
	thung.tha(Vector3(dich.x, tau.global_position.y - 30.0, dich.z), dich)