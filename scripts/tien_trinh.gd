extends Node
## Tiến trình người chơi (lưu vào user://tien_trinh.json) và cài đặt (user://cai_dat.cfg).
## Cũng giữ cấu hình trận đang chọn (cau_hinh_tran) và kết quả trận vừa đánh (ket_qua) để chuyển giữa menu và trận.

const DUONG_LUU := "user://tien_trinh.json"
const DUONG_LUU_THU := "user://tien_trinh_thu.json"   # chế độ tự kiểm tra: không đụng vào bản lưu thật
const DUONG_CAI_DAT := "user://cai_dat.cfg"
const THU_MUC_O := "user://ban_luu"
const THU_MUC_O_THU := "user://ban_luu_thu"       # chế độ tự kiểm tra
const SO_O := 3

var cong_trang := 0
var cap := {}                    # mục cây kỹ năng -> cấp (1..5)
var nut := {}                    # mục -> [số nút hướng 1, 2, 3]
var mo_khoa: Array = []          # vũ khí / cận chiến đã mở
var trang_bi := {}               # loai, phai, trai, tay_phu_trai, tay_phu_phai, can_chien
var dong_doi: Array = []         # loại mecha của đồng đội bot ("ngau_nhien" = để máy chọn)
var so_tran := 0
var so_thang := 0
var chien_dich := {"mo": 1, "xong": []}     # chiến dịch: số nhiệm vụ đã mở, id các nhiệm vụ đã hoàn thành
var nhiem_vu := 0                            # nhiệm vụ đang chọn / đang chơi (chỉ số trong CanBang.CHIEN_DICH)
var dang_nhiem_vu := -1                      # đang ở giữa nhiệm vụ nào (lưu giữa nhiệm vụ: tải lại thì chơi lại từ đầu)
var gio_choi := 0.0                          # tổng thời gian chơi (giây)

var cai_dat := {
	"am_luong_tong": 0.8, "am_luong_nhac": 0.6, "am_luong_hieu_ung": 0.8,
	"do_nhay_chuot": 1.0, "toan_man_hinh": false, "bong": true, "do_hoa": "cao",
}
var cau_hinh_tran := {"do_kho": "thuong", "quan_so": 3, "ban_do": "thanh_pho"}
var ket_qua := {}                # trận vừa xong: thang (-1/0/1), thoi_gian, so_ha, cu_diem, thuong

var _duong := DUONG_LUU


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--kiem_ma" in OS.get_cmdline_user_args():
		_kiem_ma.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest") or a.begins_with("--thu_menu") or a.begins_with("--thu_troi") or a.begins_with("--thu_chien_dich") or a.begins_with("--chup_huong_dan"):
			_duong = DUONG_LUU_THU
			if FileAccess.file_exists(_duong):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(_duong))
	_mac_dinh()
	doc()
	doc_cai_dat()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--quanso="):
			cau_hinh_tran["quan_so"] = int(a.get_slice("=", 1))
		elif a.begins_with("--dokho="):
			cau_hinh_tran["do_kho"] = a.get_slice("=", 1)
		elif a.begins_with("--ban_do="):
			cau_hinh_tran["ban_do"] = a.get_slice("=", 1)
		elif a.begins_with("--do_hoa="):
			cai_dat["do_hoa"] = a.get_slice("=", 1)          # thử một mức chất lượng đồ họa (không lưu)
			DoHoa.cu = cai_dat["do_hoa"] == "cu"
	if "--autotest" in " ".join(OS.get_cmdline_user_args()):
		# tự kiểm tra trận: mở sẵn mọi vũ khí
		mo_khoa = CanBang.GIA_MO_KHOA.keys()


func _mac_dinh() -> void:
	cong_trang = CanBang.CONG_TRANG_BAN_DAU
	cap = {}
	nut = {}
	for k in CanBang.CAY_KY_NANG:
		cap[k] = 1
		nut[k] = [0, 0, 0]
	mo_khoa = []
	trang_bi = {"loai": "co_ban", "phai": "sung_may", "trai": "sung_truong", "tay_phu_trai": "ten_lua",
		"tay_phu_phai": "ten_lua", "can_chien": "kiem"}
	dong_doi = ["ngau_nhien", "ngau_nhien", "ngau_nhien", "ngau_nhien", "ngau_nhien"]
	so_tran = 0
	so_thang = 0
	chien_dich = {"mo": 1, "xong": []}
	nhiem_vu = 0
	dang_nhiem_vu = -1
	gio_choi = 0.0


# ---------------------------------------------------------------- lưu / đọc

## Toàn bộ tiến trình dưới dạng Dictionary (để ghi ra file / ô lưu).
func du_lieu() -> Dictionary:
	return {
		"cong_trang": cong_trang, "cap": cap, "nut": nut, "mo_khoa": mo_khoa,
		"trang_bi": trang_bi, "dong_doi": dong_doi, "so_tran": so_tran, "so_thang": so_thang,
		"cau_hinh_tran": cau_hinh_tran, "chien_dich": chien_dich, "nhiem_vu": nhiem_vu,
		"gio_choi": gio_choi, "dang_nhiem_vu": dang_nhiem_vu, "luc_luu": Time.get_datetime_string_from_system(false, true),
	}


## Tự động lưu (user://tien_trinh.json) — gọi sau mỗi thay đổi, sau mỗi nhiệm vụ / trận, khi thoát game.
func luu() -> void:
	var f := FileAccess.open(_duong, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(du_lieu(), "	"))


func doc() -> void:
	var d: Variant = _doc_json(_duong)
	if d is Dictionary:
		ap_du_lieu(d)


static func _doc_json(duong: String) -> Variant:
	if not FileAccess.file_exists(duong):
		return null
	var f := FileAccess.open(duong, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


## Đọc tiến trình từ Dictionary (thiếu mục nào thì giữ mặc định).
func ap_du_lieu(d: Dictionary) -> void:
	cong_trang = int(d.get("cong_trang", cong_trang))
	for k in CanBang.CAY_KY_NANG:
		if d.get("cap", {}).has(k):
			cap[k] = clampi(int(d["cap"][k]), 1, CanBang.CAP_TOI_DA)
		if d.get("nut", {}).has(k):
			var a: Array = d["nut"][k]
			nut[k] = [int(a[0]), int(a[1]), int(a[2])]
	mo_khoa = (d.get("mo_khoa", []) as Array).duplicate()
	if d.get("trang_bi") is Dictionary:
		for k in d["trang_bi"]:
			trang_bi[k] = d["trang_bi"][k]
	if d.get("dong_doi") is Array:
		dong_doi = (d["dong_doi"] as Array).duplicate()
	so_tran = int(d.get("so_tran", 0))
	so_thang = int(d.get("so_thang", 0))
	if d.get("chien_dich") is Dictionary:
		chien_dich = {"mo": clampi(int(d["chien_dich"].get("mo", 1)), 1, CanBang.CHIEN_DICH.size()),
			"xong": (d["chien_dich"].get("xong", []) as Array).duplicate()}
	nhiem_vu = clampi(int(d.get("nhiem_vu", 0)), 0, CanBang.CHIEN_DICH.size() - 1)
	gio_choi = float(d.get("gio_choi", 0.0))
	dang_nhiem_vu = int(d.get("dang_nhiem_vu", -1))
	if d.get("cau_hinh_tran") is Dictionary:
		cau_hinh_tran["do_kho"] = d["cau_hinh_tran"].get("do_kho", "thuong")
		cau_hinh_tran["quan_so"] = int(d["cau_hinh_tran"].get("quan_so", 3))
		var bd: String = d["cau_hinh_tran"].get("ban_do", "thanh_pho")
		cau_hinh_tran["ban_do"] = bd if CanBang.BAN_DO.has(bd) else "thanh_pho"
	sua_trang_bi()


# ---------------------------------------------------------------- ô lưu (3 ô người chơi tự lưu + ô tự động lưu)

func duong_o(i: int) -> String:
	return (THU_MUC_O_THU if _duong == DUONG_LUU_THU else THU_MUC_O).path_join("o_%d.json" % i)


## Lưu tiến trình hiện tại vào ô i (1..SO_O).
func luu_o(i: int) -> bool:
	luu()
	DirAccess.make_dir_recursive_absolute(duong_o(i).get_base_dir())
	var f := FileAccess.open(duong_o(i), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(du_lieu(), "	"))
	return true


## Tải ô i: tiến trình hiện tại được thay bằng nội dung ô (rồi tự động lưu). Trả về false nếu ô trống / hỏng.
func tai_o(i: int) -> bool:
	var d: Variant = _doc_json(duong_o(i))
	if not d is Dictionary:
		return false
	_mac_dinh()
	ap_du_lieu(d)
	luu()
	return true


func xoa_o(i: int) -> void:
	if FileAccess.file_exists(duong_o(i)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(duong_o(i)))


## Thông tin một ô để hiện (rỗng nếu ô trống). i = 0: ô tự động lưu (tiến trình đang chơi).
func thong_tin_o(i: int) -> Dictionary:
	var d: Variant = du_lieu() if i == 0 else _doc_json(duong_o(i))
	if not d is Dictionary:
		return {}
	var cd: Dictionary = d.get("chien_dich", {"mo": 1, "xong": []})
	return {"luc_luu": String(d.get("luc_luu", "")), "gio_choi": float(d.get("gio_choi", 0.0)),
		"nhiem_vu_xong": (cd.get("xong", []) as Array).size(), "nhiem_vu_mo": int(cd.get("mo", 1)),
		"cong_trang": int(d.get("cong_trang", 0)), "loai": String((d.get("trang_bi", {}) as Dictionary).get("loai", "co_ban")),
		"dang_nhiem_vu": int(d.get("dang_nhiem_vu", -1)), "so_tran": int(d.get("so_tran", 0))}


## Đã chơi gì chưa (để hiện nút Tiếp tục).
func da_choi() -> bool:
	return so_tran > 0 or not (chien_dich["xong"] as Array).is_empty() or gio_choi > 60.0 or dang_nhiem_vu >= 0


func _process(dt: float) -> void:
	gio_choi += dt


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		luu()


func luu_cai_dat() -> void:
	var c := ConfigFile.new()
	c.load(DUONG_CAI_DAT)                    # giữ các mục khác (phím, ngôn ngữ)
	for k in cai_dat:
		c.set_value("cai_dat", k, cai_dat[k])
	c.save(DUONG_CAI_DAT)
	ap_dung_cai_dat()


func doc_cai_dat() -> void:
	var c := ConfigFile.new()
	if c.load(DUONG_CAI_DAT) == OK:
		for k in cai_dat:
			cai_dat[k] = c.get_value("cai_dat", k, cai_dat[k])
	ap_dung_cai_dat()


func ap_dung_cai_dat() -> void:
	for ten in ["Master", "Nhac", "HieuUng"]:
		var i := AudioServer.get_bus_index(ten)
		if i < 0:
			continue
		var k: String = {"Master": "am_luong_tong", "Nhac": "am_luong_nhac", "HieuUng": "am_luong_hieu_ung"}[ten]
		var v: float = cai_dat[k]
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)
	if DisplayServer.get_name() != "headless":
		var muon := DisplayServer.WINDOW_MODE_FULLSCREEN if cai_dat["toan_man_hinh"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != muon:
			DisplayServer.window_set_mode(muon)
	if not DoHoa.MUC.has(cai_dat["do_hoa"]):
		cai_dat["do_hoa"] = "cao"
	DoHoa.ap_lai(get_tree(), cai_dat["do_hoa"])


# ---------------------------------------------------------------- cây kỹ năng

func diem_ky_nang(muc: String) -> int:
	return int(cap.get(muc, 1)) * CanBang.DIEM_MOI_CAP


func diem_da_dung(muc: String) -> int:
	var a: Array = nut.get(muc, [0, 0, 0])
	return int(a[0]) + int(a[1]) + int(a[2])


func diem_con(muc: String) -> int:
	return diem_ky_nang(muc) - diem_da_dung(muc)


## Số nút người chơi đã mở ở một hướng (0..4).
func so_nut(muc: String, huong: int) -> int:
	return int((nut.get(muc, [0, 0, 0]) as Array)[huong])


## Số nút của một phe: phe 0 theo người chơi, phe 1 (máy) theo độ khó.
func so_nut_phe(phe: int, muc: String, huong: int) -> int:
	if phe == 0:
		return so_nut(muc, huong)
	return int(CanBang.DO_KHO[cau_hinh_tran.get("do_kho", "thuong")]["nut_dich"])


func gia_len_cap(muc: String) -> int:
	return CanBang.GIA_LEN_CAP * int(cap.get(muc, 1))


func len_cap(muc: String) -> bool:
	var c: int = cap.get(muc, 1)
	if c >= CanBang.CAP_TOI_DA or cong_trang < gia_len_cap(muc):
		return false
	cong_trang -= gia_len_cap(muc)
	cap[muc] = c + 1
	luu()
	return true


func them_nut(muc: String, huong: int) -> bool:
	if diem_con(muc) <= 0 or so_nut(muc, huong) >= CanBang.NUT_MOI_HUONG:
		return false
	(nut[muc] as Array)[huong] = so_nut(muc, huong) + 1
	luu()
	return true


func chia_lai(muc: String) -> void:
	nut[muc] = [0, 0, 0]
	luu()


# ---------------------------------------------------------------- vũ khí

func da_mo(id: String) -> bool:
	return id == "" or not CanBang.GIA_MO_KHOA.has(id) or mo_khoa.has(id)


func mo_khoa_vk(id: String) -> bool:
	if da_mo(id):
		return true
	var gia: int = CanBang.GIA_MO_KHOA[id]
	if cong_trang < gia:
		return false
	cong_trang -= gia
	mo_khoa.append(id)
	luu()
	return true


## Trang bị hợp lệ: món không có trong bảng hoặc chưa mở khóa thì đổi về món mặc định.
func sua_trang_bi() -> void:
	if not CanBang.LOAI_MECHA.has(trang_bi.get("loai", "")):
		trang_bi["loai"] = "co_ban"
	for o in ["phai", "trai"]:
		var x: String = trang_bi.get(o, "")
		if not CanBang.DS_VU_KHI.has(x) or not da_mo(x):
			trang_bi[o] = "sung_may" if o == "phai" else "sung_truong"
	for o in ["tay_phu_trai", "tay_phu_phai"]:
		var x: String = trang_bi.get(o, "")
		if not CanBang.TAY_PHU.has(x) or not da_mo(x):
			trang_bi[o] = "ten_lua"
	if not CanBang.KIEU_CAN_CHIEN.has(trang_bi.get("can_chien", "")) or not da_mo(trang_bi["can_chien"]):
		trang_bi["can_chien"] = "kiem"
	trang_bi.erase("vai")
	trang_bi.erase("ky_nang")


# ---------------------------------------------------------------- chiến dịch

func nhiem_vu_mo(i: int) -> bool:
	return i < int(chien_dich["mo"])


func nhiem_vu_xong(i: int) -> bool:
	return (chien_dich["xong"] as Array).has(CanBang.CHIEN_DICH[i]["id"])


## Ghi kết quả một nhiệm vụ. Thắng: cộng điểm (lần đầu đủ, chơi lại ít hơn), mở nhiệm vụ kế. Trả về điểm được cộng.
func ghi_ket_qua_chien_dich(i: int, thang: bool) -> int:
	var diem := 0
	dang_nhiem_vu = -1
	if thang:
		var nv: Dictionary = CanBang.CHIEN_DICH[i]
		diem = int(nv["thuong"]) if not nhiem_vu_xong(i) else int(float(nv["thuong"]) * CanBang.CHIEN_DICH_CHOI_LAI)
		if not nhiem_vu_xong(i):
			(chien_dich["xong"] as Array).append(nv["id"])
		chien_dich["mo"] = clampi(maxi(int(chien_dich["mo"]), i + 2), 1, CanBang.CHIEN_DICH.size())
		cong_trang += diem
	luu()
	return diem


# ---------------------------------------------------------------- sau trận

## Cộng điểm công trạng theo kết quả trận, trả về số điểm được cộng.
func ghi_ket_qua(thang: int, so_ha: int, so_cu_diem: int) -> int:
	var th: Dictionary = CanBang.THUONG
	var diem: int = th["thang"] if thang > 0 else (th["hoa"] if thang == 0 else th["thua"])
	diem += so_ha * int(th["moi_ha"]) + so_cu_diem * int(th["moi_cu_diem"])
	cong_trang += diem
	so_tran += 1
	if thang > 0:
		so_thang += 1
	luu()
	return diem


## Công cụ cho người làm game (--kiem_ma): nạp mọi file .gd để bắt lỗi biên dịch rồi thoát.
func _kiem_ma() -> void:
	var ds: Array = []
	var cho := ["res://scripts"]
	while not cho.is_empty():
		var d: String = cho.pop_back()
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				ds.append(d.path_join(f))
		for sub in DirAccess.get_directories_at(d):
			cho.append(d.path_join(sub))
	var loi := 0
	for p in ds:
		var s := load(p) as GDScript
		if s == null or not s.can_instantiate():
			print("[kiem_ma] LOI: ", p)
			loi += 1
	print("[kiem_ma] da kiem %d file, %d loi" % [ds.size(), loi])
	var nn: Node = get_tree().root.get_node_or_null("NgonNgu")
	if nn:
		print("[kiem_ma] bang dich: %d cau, thieu en %d, ja %d" % [nn.so_cau, nn.thieu["en"], nn.thieu["ja"]])
		for ma in ["en", "ja"]:
			TranslationServer.set_locale(ma)
			print("[kiem_ma] %s: %s | %s" % [ma, tr("CHIẾN DỊCH"), tr("Mecha: %s
Vũ khí phải: %s · Vũ khí trái: %s
Tay phụ: %s / %s · Cận chiến: %s").replace("
", " / ")])
	get_tree().quit()
