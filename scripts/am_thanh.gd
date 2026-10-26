extends Node
## Âm thanh chung: hiệu ứng 2D / 3D theo vị trí, âm thanh lặp gắn vào vật (động cơ), nhạc chuyển mượt.
## Ba kênh âm lượng: Master (tổng), Nhac, HieuUng (chỉnh trong Cài đặt).
## Chế độ tự kiểm tra: tắt tiếng kênh tổng nhưng vẫn ghi nhật ký để kiểm tra.

## Kho âm thanh: tên -> [danh sách file (chọn ngẫu nhiên), âm lượng dB, cao độ, độ lệch cao độ, khoảng cách nghe rõ (m)].
## Tiếng tự tạo bằng audio-studio (Stable Audio 3), file ở res://am_thanh/ (mono 44,1 kHz). Tiếng hay lặp lại
## (súng máy, trúng đạn, nổ…) có 2–3 bản để chọn ngẫu nhiên cho đỡ nhàm. Tên nào chưa có trong kho thì im lặng.
## Vòng lặp động cơ (mecha.gd LOP_DONG_CO) cùng mức RMS −18 dBFS, nên số dB ở đây là độ to tương đối giữa các lớp.
const KHO := {
	# --- động cơ: vòng lặp, hòa theo trạng thái ---
	"dong_co_cho": [["res://am_thanh/dong_co_cho.ogg"], -14.0, 1.0, 0.0, 30.0],
	"luot_lap": [["res://am_thanh/luot_lap.ogg"], -8.0, 1.0, 0.0, 40.0],
	"luot_nhanh_lap": [["res://am_thanh/luot_nhanh_lap.ogg"], -5.0, 1.0, 0.0, 50.0],
	"bay_lap": [["res://am_thanh/bay_lap.ogg"], -5.0, 1.0, 0.0, 50.0],
	"lo_lung_lap": [["res://am_thanh/lo_lung_lap.ogg"], -9.0, 1.0, 0.0, 35.0],
	"gio_roi": [["res://am_thanh/gio_roi.ogg"], -8.0, 1.0, 0.0, 40.0],
	# --- động cơ: một lần ---
	"khoi_dong": [["res://am_thanh/khoi_dong.ogg"], -6.0, 1.0, 0.03, 35.0],
	"bat_bay": [["res://am_thanh/bat_bay.ogg"], -3.0, 1.0, 0.05, 50.0],
	"qua_nhiet": [["res://am_thanh/qua_nhiet.ogg"], -3.0, 1.0, 0.0, 40.0],
	"ne": [["res://am_thanh/lao_phan_luc.ogg"], -4.0, 1.1, 0.05, 50.0],             # lao ngang
	"lao_phan_luc": [["res://am_thanh/lao_phan_luc.ogg"], -2.0, 1.0, 0.04, 50.0],   # F lao chém
	# --- chân ---
	"buoc_chan": [["res://am_thanh/buoc_chan.ogg"], -6.0, 1.0, 0.06, 40.0],
	"cham_dat": [["res://am_thanh/cham_dat_1.ogg", "res://am_thanh/cham_dat_2.ogg"], -4.0, 1.0, 0.05, 45.0],
	"ha_canh": [["res://am_thanh/ha_canh.ogg"], 0.0, 1.0, 0.0, 60.0],
	# --- vũ khí ---
	"sung_truong": [["res://am_thanh/sung_truong.ogg"], -10.0, 1.0, 0.06, 60.0],
	"sung_may": [["res://am_thanh/sung_may_1.ogg", "res://am_thanh/sung_may_2.ogg"], -12.0, 1.0, 0.08, 55.0],
	"sung_ban_tia": [["res://am_thanh/sung_ban_tia.ogg"], -4.0, 1.0, 0.03, 90.0],
	"tia_nang_luong": [["res://am_thanh/tia_nang_luong.ogg"], -6.0, 1.0, 0.05, 50.0],
	"phao_plasma": [["res://am_thanh/phao_plasma.ogg"], -6.0, 1.0, 0.06, 60.0],
	"emp": [["res://am_thanh/emp.ogg"], -5.0, 1.0, 0.05, 50.0],
	"phao_nhiet": [["res://am_thanh/phao_nhiet.ogg"], -6.0, 1.0, 0.05, 40.0],
	"phao_tau": [["res://am_thanh/phao_tau.ogg"], 0.0, 1.0, 0.08, 200.0],
	"ten_lua_phong": [["res://am_thanh/ten_lua_phong.ogg"], -5.0, 1.0, 0.08, 60.0],
	"ten_lua_bay": [["res://am_thanh/ten_lua_bay.ogg"], -12.0, 1.0, 0.0, 25.0],     # lặp, gắn vào tên lửa
	# --- trúng / nổ ---
	"trung_dan": [["res://am_thanh/trung_dan_1.ogg", "res://am_thanh/trung_dan_2.ogg", "res://am_thanh/trung_dan_3.ogg"], -10.0, 1.0, 0.1, 35.0],
	"dan_cham_dat": [["res://am_thanh/dan_cham_dat_1.ogg", "res://am_thanh/dan_cham_dat_2.ogg", "res://am_thanh/dan_cham_dat_3.ogg"], -14.0, 1.0, 0.1, 30.0],
	"bi_trung": [["res://am_thanh/bi_trung_1.ogg", "res://am_thanh/bi_trung_2.ogg"], -6.0, 1.0, 0.08, 0.0],   # 2D: mình bị trúng
	"trung_xac_nhan": [["res://am_thanh/trung_xac_nhan.ogg"], -14.0, 1.0, 0.04, 0.0],                       # 2D: mình bắn trúng
	"khien_trung": [["res://am_thanh/khien_trung.ogg"], -6.0, 1.0, 0.08, 40.0],
	"chem_vut": [["res://am_thanh/chem_vut.ogg"], -3.0, 1.0, 0.06, 40.0],
	"chem_trung": [["res://am_thanh/chem_trung_1.ogg", "res://am_thanh/chem_trung_2.ogg"], -2.0, 1.0, 0.06, 45.0],
	"do_don": [["res://am_thanh/do_don.ogg"], -2.0, 1.0, 0.05, 50.0],
	"no_nho": [["res://am_thanh/no_nho_1.ogg", "res://am_thanh/no_nho_2.ogg", "res://am_thanh/no_nho_3.ogg"], -4.0, 1.0, 0.08, 70.0],
	"no_lon": [["res://am_thanh/no_lon_1.ogg", "res://am_thanh/no_lon_2.ogg"], 0.0, 1.0, 0.06, 120.0],
	# --- cảnh báo (2D) ---
	"khoa_muc_tieu": [["res://am_thanh/khoa_muc_tieu.ogg"], -10.0, 1.0, 0.0, 0.0],  # mình khóa được địch
	"khoa_bip": [["res://am_thanh/khoa_bip.ogg"], -10.0, 1.0, 0.0, 0.0],            # mình đang bị khóa
	"canh_bao": [["res://am_thanh/canh_bao.ogg"], -8.0, 1.0, 0.0, 0.0],             # tên lửa tới: hud chỉnh nhịp theo khoảng cách
	"canh_bao_chem": [["res://am_thanh/canh_bao_chem.ogg"], -4.0, 1.0, 0.0, 0.0],   # địch đang lao chém tới
	"canh_bao_minigun": [["res://am_thanh/canh_bao_minigun.ogg"], -12.0, 1.0, 0.0, 0.0],
	"chiem_cu_diem": [["res://am_thanh/chiem_cu_diem.ogg"], -6.0, 1.0, 0.0, 0.0],
	"mat_cu_diem": [["res://am_thanh/mat_cu_diem.ogg"], -6.0, 1.0, 0.0, 0.0],
	# --- giao diện (2D) ---
	"ui_bam": [["res://am_thanh/ui_bam.ogg"], -12.0, 1.0, 0.03, 0.0],
	"ui_luot": [["res://am_thanh/ui_luot.ogg"], -18.0, 1.0, 0.05, 0.0],
	"ui_mo": [["res://am_thanh/ui_mo.ogg"], -10.0, 1.0, 0.0, 0.0],
	"ui_dong": [["res://am_thanh/ui_dong.ogg"], -12.0, 1.0, 0.0, 0.0],
	"ui_mua": [["res://am_thanh/ui_mua.ogg"], -8.0, 1.0, 0.0, 0.0],
	"ui_loi": [["res://am_thanh/ui_loi.ogg"], -10.0, 1.0, 0.0, 0.0],
	"ui_mo_khoa": [["res://am_thanh/ui_mo_khoa.ogg"], -6.0, 1.0, 0.0, 0.0],
}
## Nhạc: tên -> file. Các tên đang được gọi: menu, tran, cang, thang, thua. Không có file thì im lặng.
const NHAC := {}

var nhat_ky := {}                  # tên -> số lần phát (để tự kiểm tra)
var thieu: Array[String] = []      # file không nạp được
var dang_nhac := ""
var _cache := {}
var _cho_2d: Array[AudioStreamPlayer] = []
var _cho_3d: Array[AudioStreamPlayer3D] = []
var _lan_cuoi := {}                # tên -> thời điểm phát gần nhất (chống dồn tiếng súng máy)
var _nhac: Array[AudioStreamPlayer] = []
var _nhac_i := 0
var _tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Nhac"
		add_child(p)
		_nhac.append(p)
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "HieuUng"
		add_child(p)
		_cho_2d.append(p)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest") or a.begins_with("--thu_menu") or a.begins_with("--thu_troi"):
			AudioServer.set_bus_mute(0, true)        # tự kiểm tra: không phát tiếng ra loa


func _nap(duong: String) -> AudioStream:
	if _cache.has(duong):
		return _cache[duong]
	var s: AudioStream = null
	if ResourceLoader.exists(duong):
		s = load(duong) as AudioStream
	if s == null and not thieu.has(duong):
		thieu.append(duong)
		push_warning("Thiếu âm thanh: " + duong)
	_cache[duong] = s
	return s


func _chon(ten: String) -> Array:
	if not KHO.has(ten):
		return []
	var k: Array = KHO[ten]
	var s := _nap((k[0] as Array).pick_random())
	if s == null:
		return []
	return [s, k[1], float(k[2]) + randf_range(-float(k[3]), float(k[3])), k[4]]


## Phát một hiệu ứng. vi_tri = Vector3: âm thanh 3D tại chỗ đó; null: 2D (giao diện, cảnh báo).
func phat(ten: String, vi_tri: Variant = null, them_db := 0.0) -> void:
	var bay_gio := Time.get_ticks_msec() / 1000.0
	if bay_gio - float(_lan_cuoi.get(ten, -1.0)) < 0.045:
		return
	_lan_cuoi[ten] = bay_gio
	var c := _chon(ten)
	if c.is_empty():
		return
	nhat_ky[ten] = int(nhat_ky.get(ten, 0)) + 1
	if vi_tri is Vector3 and is_inside_tree():
		var p := _lay_3d()
		if p == null:
			return
		p.stream = c[0]
		p.volume_db = float(c[1]) + them_db
		p.pitch_scale = c[2]
		p.unit_size = maxf(float(c[3]), 5.0)
		p.max_distance = maxf(float(c[3]) * 12.0, 400.0)
		p.global_position = vi_tri
		p.play()
	else:
		var p2 := _lay_2d()
		p2.stream = c[0]
		p2.volume_db = float(c[1]) + them_db
		p2.pitch_scale = c[2]
		p2.play()


func ui(ten: String) -> void:
	phat("ui_" + ten)


func _lay_2d() -> AudioStreamPlayer:
	for p in _cho_2d:
		if not p.playing:
			return p
	return _cho_2d[0]


func _lay_3d() -> AudioStreamPlayer3D:
	var canh := get_tree().current_scene
	if canh == null or not canh is Node3D:
		return null
	_cho_3d.assign(_cho_3d.filter(func(x) -> bool: return is_instance_valid(x)))
	for p in _cho_3d:
		if not p.playing and p.get_parent() == canh:
			return p
	if _cho_3d.size() >= 40:
		return _cho_3d[0]
	var moi := AudioStreamPlayer3D.new()
	moi.bus = "HieuUng"
	moi.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	moi.process_mode = Node.PROCESS_MODE_PAUSABLE
	canh.add_child(moi)
	_cho_3d.append(moi)
	return moi


## Âm thanh lặp gắn vào một vật (động cơ mecha, máy bay). Trả về player để bật / tắt / chỉnh âm lượng.
func vong_lap(ten: String, vat: Node3D) -> AudioStreamPlayer3D:
	var c := _chon(ten)
	var p := AudioStreamPlayer3D.new()
	p.bus = "HieuUng"
	if not c.is_empty():
		var s: AudioStream = (c[0] as AudioStream).duplicate()
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		p.stream = s
		p.volume_db = c[1]
		p.unit_size = maxf(float(c[3]), 5.0)
		p.max_distance = maxf(float(c[3]) * 12.0, 400.0)
	vat.add_child(p)
	return p


## Chuyển nhạc (mờ dần bài cũ, lên dần bài mới).
func nhac(ten: String, lap := true) -> void:
	if ten == dang_nhac:
		return
	dang_nhac = ten
	var s: AudioStream = null
	if NHAC.has(ten):
		s = _nap(NHAC[ten])
	var cu := _nhac[_nhac_i]
	_nhac_i = 1 - _nhac_i
	var moi := _nhac[_nhac_i]
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(cu, "volume_db", -40.0, 1.5)
	_tw.chain().tween_callback(cu.stop)
	if s:
		s = s.duplicate()
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = lap
		elif s is AudioStreamWAV:
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if lap else AudioStreamWAV.LOOP_DISABLED
			if lap and (s as AudioStreamWAV).loop_end <= 0:
				(s as AudioStreamWAV).loop_end = int((s as AudioStreamWAV).get_length() * (s as AudioStreamWAV).mix_rate)
		moi.stream = s
		moi.volume_db = -40.0
		moi.play()
		var tw2 := create_tween()
		tw2.tween_property(moi, "volume_db", 0.0, 1.5)


func dung_nhac() -> void:
	nhac("")
