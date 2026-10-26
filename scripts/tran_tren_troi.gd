class_name TranTrenTroi
extends Node3D
## Trên trời: hai tàu sân bay (mỗi phe một chiếc) đứng yên phía trên hai căn cứ, bắn nhau làm nền với sát thương
## ngang nhau — tự nó không phân thắng thua. Người chơi giúp tàu ta bằng cứ điểm: trạm tên lửa bắn tàu địch
## (có tên lửa EMP làm tàu tê liệt, ngừng bắn), trạm hậu cần sửa tàu ta. Tàu sân bay bị hạ là thua.
## (26/10/2026: bỏ hẳn chế độ hạm đội — bàn cờ xếp tàu, hộ tống, pháo kích, phòng không, tường chắn;
## code cũ ở _ban_luu/2026-10-26_truoc_nang_do_hoa/.)

signal san_bay_bi_ha(phe: int)

var ban_do: Node = null
var tau: Array[TauChien] = []              # [tàu sân bay phe 0, tàu sân bay phe 1]
var ten_lua: Array = []                    # tên lửa từ trạm dưới đất đang bay
var dan_san_bay: Array = []                # đạn pháo chính của tàu sân bay đang bay
var thong_ke := {"dan_ban": 0, "dan_trung_tau": 0, "ten_lua_phong": 0, "ten_lua_trung": 0, "emp_trung": 0}
var _cs: Dictionary
var _hen_ban := [3.0, 7.0]                 # đếm tới loạt kế tiếp của mỗi tàu (lệch nhịp cho đỡ đồng loạt)


func _ready() -> void:
	_cs = CanBang.TRAN_TROI


## Dựng hai tàu sân bay.
func dung() -> void:
	var cfg: Dictionary = CanBang.TAU_SAN_BAY
	var vt: Vector3 = _cs["vi_tri"]
	for phe in 2:
		var t := TauChien.new()
		t.phe = phe
		t.giap_max = cfg["giap"]
		t.khien_max = cfg["khien"]
		t.giap = t.giap_max
		t.khien = t.khien_max
		add_child(t)
		t.global_position = vt if phe == 0 else Vector3(-vt.x, vt.y, -vt.z)
		t.y0 = t.position.y
		t.rotation.y = PI if phe == 0 else 0.0          # mũi tàu (+Z của mô hình) hướng về phía địch
		t.bi_ha.connect(_khi_tau_bi_ha)
		tau.append(t)


func san_bay(phe: int) -> TauChien:
	for t in tau:
		if is_instance_valid(t) and t.phe == phe:
			return t
	return null


func ti_le_san_bay(phe: int) -> float:
	var s := san_bay(phe)
	return s.ti_le_mau() if s else 0.0


## Tàu sân bay địch của phe `phe` nếu còn sống.
func muc_tieu(phe: int) -> TauChien:
	var s := san_bay(1 - phe)
	return s if s and s.song else null


# ---------------------------------------------------------------- vòng lặp

func _physics_process(dt: float) -> void:
	for t in tau:
		if is_instance_valid(t):
			t.dem_gio(dt)
	tau.assign(tau.filter(func(x) -> bool: return is_instance_valid(x)))
	_ban_nhau(dt)
	_bay_ten_lua(dt)


## Mỗi tàu bắn một loạt 3 viên pháo chính vào tàu kia theo nhịp như nhau (bị EMP thì ngừng bắn).
func _ban_nhau(dt: float) -> void:
	var cfg: Dictionary = _cs["san_bay_ban"]
	for phe in 2:
		var s := san_bay(phe)
		var d := san_bay(1 - phe)
		if s == null or d == null or not s.song or not d.song or s.te_liet_con > 0.0:
			continue
		_hen_ban[phe] -= dt
		if _hen_ban[phe] > 0.0:
			continue
		_hen_ban[phe] = float(cfg["chu_ky"])
		for k in 3:
			var tu := s.global_position + Vector3(randf_range(-55, 55), randf_range(15, 30), 0)
			var toi := d.global_position + Vector3(randf_range(-50, 50), randf_range(-10, 15), 0)
			var v := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.0, 3.0, 34.0)
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(2.2, 1.6, 0.7) if phe == 0 else Color(2.4, 0.7, 0.45)
			bm.material = mat
			v.mesh = bm
			v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(v)
			v.global_position = tu
			v.look_at(toi, Vector3.UP)
			dan_san_bay.append({"tu": tu, "toi": toi, "t": -k * 0.35, "tg": tu.distance_to(toi) / float(_cs["toc_dan"]),
				"dmg": float(cfg["sat_thuong"]) / 3.0, "muc": d, "node": v})
		thong_ke["dan_ban"] += 1
		AmThanh.phat("phao_tau", s.global_position, 4.0)
	var con: Array = []
	for x in dan_san_bay:
		var v: MeshInstance3D = x["node"]
		if not is_instance_valid(v):
			continue
		x["t"] += dt
		var k := clampf(float(x["t"]) / float(x["tg"]), 0.0, 1.0)
		v.global_position = (x["tu"] as Vector3).lerp(x["toi"], k)
		v.visible = float(x["t"]) >= 0.0
		if k < 1.0:
			con.append(x)
			continue
		var muc = x["muc"]
		if is_instance_valid(muc) and (muc as TauChien).song:
			(muc as TauChien).nhan_sat_thuong(float(x["dmg"]))
			thong_ke["dan_trung_tau"] += 1
		HieuUng.vu_no(self, x["toi"], 18.0, Color(1.0, 0.7, 0.3))
		v.queue_free()
	dan_san_bay = con


## Tên lửa phóng từ trạm tên lửa dưới đất (vị trí cứ điểm) lên tàu sân bay địch. emp: làm tàu tê liệt.
func phong_tu_dat(phe: int, vi_tri: Vector3, dmg: float, emp := false) -> void:
	if muc_tieu(phe) == null:
		return
	var n := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 1.4
	cm.height = 9.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.6, 2.0) if emp else (Color(1.8, 0.9, 0.4) if phe == 0 else Color(2.0, 0.5, 0.3))
	cm.material = mat
	n.mesh = cm
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n)
	n.global_position = vi_tri
	n.add_child(HieuUng.vet_khoi(Color(0.75, 0.72, 0.7) if not emp else Color(0.7, 0.6, 1.0)))
	ten_lua.append({"phe": phe, "node": n, "v": Vector3.UP * 60.0, "dmg": dmg, "emp": emp, "t": 0.0})
	thong_ke["ten_lua_phong"] += 1


func _bay_ten_lua(dt: float) -> void:
	var con: Array = []
	for d in ten_lua:
		var n: MeshInstance3D = d["node"]
		if not is_instance_valid(n):
			continue
		var muc := muc_tieu(int(d["phe"]))
		if muc == null:
			HieuUng.vu_no(self, n.global_position, 6.0, Color(1, 0.6, 0.3))
			n.queue_free()
			continue
		d["t"] += dt
		var dich := muc.global_position
		var muon := (dich - n.global_position).normalized() * float(_cs["toc_ten_lua"])
		var v: Vector3 = d["v"]
		v = v.lerp(muon, clampf(dt * (0.6 + float(d["t"]) * 0.5), 0.0, 1.0))
		d["v"] = v
		var buoc := v * dt
		if n.global_position.distance_to(dich) <= buoc.length() + 35.0:
			if d["emp"]:
				muc.te_liet_con = _cs["emp_te_liet"]
				muc.nhan_sat_thuong(float(d["dmg"]) * 0.15)
				thong_ke["emp_trung"] += 1
				HieuUng.vu_no(self, n.global_position, 30.0, Color(0.6, 0.5, 1.8))
				if ban_do and ban_do.has_method("bao"):
					ban_do.bao(tr("Tên lửa EMP trúng %s %s — tê liệt %d giây") % [tr("tàu sân bay"), tr(CuDiem.TEN_PHE[muc.phe]), int(_cs["emp_te_liet"])])
			else:
				muc.nhan_sat_thuong(float(d["dmg"]))
				HieuUng.vu_no(self, n.global_position, 22.0, Color(1.0, 0.6, 0.25))
			thong_ke["ten_lua_trung"] += 1
			n.queue_free()
			continue
		n.global_position += buoc
		if v.length() > 1.0:
			n.look_at(n.global_position + v, Vector3.UP if absf(v.normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)
			n.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		con.append(d)
	ten_lua = con


func _khi_tau_bi_ha(t: TauChien) -> void:
	if ban_do and ban_do.has_method("bao"):
		ban_do.bao(tr("%s %s đã bị hạ!") % [tr("Tàu sân bay"), tr(CuDiem.TEN_PHE[t.phe])])
	san_bay_bi_ha.emit(t.phe)


# ---------------------------------------------------------------- dùng với mặt đất

## Sát thương trực tiếp lên tàu sân bay.
func sat_thuong_san_bay(phe: int, luong: float) -> void:
	var s := san_bay(phe)
	if s:
		s.nhan_sat_thuong(luong)


## Máy bay hậu cần sửa tàu sân bay (giáp thân).
func sua_san_bay(phe: int, luong: float) -> void:
	var s := san_bay(phe)
	if s and s.song:
		s.giap = minf(s.giap_max, s.giap + luong)
