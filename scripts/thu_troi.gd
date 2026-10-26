class_name ThuTroi
extends Node3D
## Mô phỏng nhanh trận trên trời (tham số --thu_troi): hai tàu sân bay với vài cách giữ trạm tên lửa / hậu cần,
## chạy ở tốc độ x20, in thời gian hạ tàu sân bay (hoặc % còn lại sau 15 phút) để chỉnh độ dài trận.

## [tên, -, độ khó, trạm tên lửa ta, trạm tên lửa địch, hậu cần ta, hậu cần địch]
const KICH_BAN := [
	["Chi 2 tau san bay, khong tram", "", "thuong", 0, 0, 0, 0],
	["Ta giu 1 tram ten lua", "", "thuong", 1, 0, 0, 0],
	["Ta giu 2 tram ten lua", "", "thuong", 2, 0, 0, 0],
	["Ta 2 tram, dich 1 tram", "", "thuong", 2, 1, 0, 0],
	["Ta 2 tram, dich 1 hau can", "", "thuong", 2, 0, 0, 1],
	["Ta 3 tram", "", "thuong", 3, 0, 0, 0],
]


func _ready() -> void:
	_chay()


func _chay() -> void:
	Engine.time_scale = 20.0
	Engine.max_physics_steps_per_frame = 40
	for kb in KICH_BAN:
		await _mot_tran(kb)
	Engine.time_scale = 1.0
	print("[thu_troi] XONG")
	get_tree().quit()


func _mot_tran(kb: Array) -> void:
	TienTrinh.cau_hinh_tran["do_kho"] = kb[2]
	var tr := TranTrenTroi.new()
	add_child(tr)
	tr.dung()
	var t := 0.0
	var hen := [0.0, 0.0]
	var hen_hc := [5.0, 5.0]
	var ha_mang := [-1]                  # lambda bắt biến theo giá trị: dùng mảng để ghi được
	tr.san_bay_bi_ha.connect(func(phe: int) -> void:
		if ha_mang[0] < 0:
			ha_mang[0] = phe)
	while t < CanBang.THOI_GIAN_TRAN and ha_mang[0] < 0:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		for phe in 2:
			var so_hc: int = (kb[5] if phe == 0 else kb[6]) if kb.size() > 6 else 0
			if so_hc > 0:
				hen_hc[phe] -= dt
				if hen_hc[phe] <= 0.0:
					hen_hc[phe] = CanBang.CU_DIEM["chu_ky"]
					tr.sua_san_bay(phe, float(CanBang.LOAI_CU_DIEM["hau_can"]["sua_tau"]) * so_hc)
			var so_tram: int = kb[3] if phe == 0 else kb[4]
			if so_tram <= 0:
				continue
			hen[phe] -= dt
			if hen[phe] <= 0.0:
				hen[phe] = CanBang.CU_DIEM["chu_ky"]
				for k in so_tram * 2:   # mỗi trạm 2 ụ tên lửa
					var goc := Vector3(-750 + k * 300, 0, 820 if phe == 0 else -820)
					tr.phong_tu_dat(phe, goc, CanBang.LOAI_CU_DIEM["ten_lua"]["sat_thuong_tau"])
	var ha: int = ha_mang[0]
	var s := "thua (tau ta bi ha)" if ha == 0 else ("THANG (tau dich bi ha)" if ha == 1 else "het gio")
	print("[thu_troi] %s: %s sau %d:%02d | san bay ta %d%%, dich %d%% | %s" % [
		kb[0], s, int(t) / 60, int(t) % 60, int(tr.ti_le_san_bay(0) * 100), int(tr.ti_le_san_bay(1) * 100), str(tr.thong_ke)])
	tr.queue_free()
	await get_tree().physics_frame

