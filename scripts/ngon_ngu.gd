extends Node
## Ngôn ngữ (autoload "NgonNgu"): tiếng Anh (mặc định lần đầu), tiếng Nhật, tiếng Việt.
## Bảng dịch: res://ngon_ngu/dich.csv (mở được bằng Excel), mỗi dòng một câu: vi,en,ja.
## Cột "vi" là câu gốc tiếng Việt viết trong code (khóa dịch); "\n" trong ô là xuống dòng.
## Ô tiếng Anh / Nhật để trống thì hiện câu tiếng Việt.
## Chọn ngôn ngữ lưu ở user://cai_dat.cfg (mục cai_dat, khóa "ngon_ngu"), dùng chung mọi bản lưu.

signal da_doi

const DUONG_BANG := "res://ngon_ngu/dich.csv"
const DUONG_CAI_DAT := "user://cai_dat.cfg"
const DS := [["en", "English"], ["ja", "日本語"], ["vi", "Tiếng Việt"]]

var ngon_ngu := "en"
var so_cau := 0                    # số câu trong bảng dịch
var thieu := {"en": 0, "ja": 0}   # số câu còn thiếu bản dịch


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_nap_bang()
	var c := ConfigFile.new()
	if not _tu_kiem_tra() and c.load(DUONG_CAI_DAT) == OK:      # tự kiểm tra: như lần đầu mở game (tiếng Anh)
		ngon_ngu = String(c.get_value("cai_dat", "ngon_ngu", "en"))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ngon_ngu="):
			ngon_ngu = a.get_slice("=", 1)
	if not _co(ngon_ngu):
		ngon_ngu = "en"
	TranslationServer.set_locale(ngon_ngu)


static func _tu_kiem_tra() -> bool:
	var tham := " ".join(OS.get_cmdline_user_args())
	return "--thu_menu" in tham or "--autotest" in tham or "--thu_chien_dich" in tham or "--chup_huong_dan" in tham


func _co(ma: String) -> bool:
	for d in DS:
		if d[0] == ma:
			return true
	return false


func _nap_bang() -> void:
	var f := FileAccess.open(DUONG_BANG, FileAccess.READ)
	if f == null:
		push_warning("Không mở được bảng dịch " + DUONG_BANG)
		return
	var dau := f.get_csv_line()
	var cot := {}
	for i in dau.size():
		cot[dau[i].strip_edges()] = i
	var bang := {}
	for ma in ["en", "ja", "vi"]:
		var t := Translation.new()
		t.locale = ma
		bang[ma] = t
	while not f.eof_reached():
		var dong := f.get_csv_line()
		if dong.size() < 2 or dong[0].strip_edges() == "":
			continue
		var khoa := dong[cot.get("vi", 0)].c_unescape()
		so_cau += 1
		(bang["vi"] as Translation).add_message(khoa, khoa)      # tiếng Việt: chính câu gốc (không thì Godot lấy tiếng Anh thay)
		for ma in ["en", "ja"]:
			var i: int = cot.get(ma, -1)
			var dich := dong[i].c_unescape() if i >= 0 and i < dong.size() else ""
			if dich.strip_edges() == "":
				thieu[ma] += 1
				continue
			(bang[ma] as Translation).add_message(khoa, dich)
	for ma in bang:
		TranslationServer.add_translation(bang[ma])


## Đổi ngôn ngữ, lưu lại, báo cho các màn dựng lại chữ.
func dat(ma: String) -> void:
	if not _co(ma):
		return
	ngon_ngu = ma
	TranslationServer.set_locale(ma)
	if _tu_kiem_tra():
		da_doi.emit()                      # tự kiểm tra: không ghi đè cài đặt thật
		return
	var c := ConfigFile.new()
	c.load(DUONG_CAI_DAT)
	c.set_value("cai_dat", "ngon_ngu", ma)
	c.save(DUONG_CAI_DAT)
	da_doi.emit()


func ten_hien(ma := "") -> String:
	if ma == "":
		ma = ngon_ngu
	for d in DS:
		if d[0] == ma:
			return d[1]
	return ma
