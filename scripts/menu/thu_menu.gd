class_name ThuMenu
extends Node
## Tự kiểm tra các màn menu (tham số --thu_menu=<thư mục>): bấm qua từng màn, chụp ảnh ở cả 3 ngôn ngữ,
## thử bảng trang bị (mở khóa, lắp), đổi phím (kể cả hoán đổi), lưu / tải ô lưu, độ khó chiến dịch, Esc lùi một bước,
## cuối cùng in tổng kết.
## Gắn vào gốc cây (không phải vào menu) để còn sống khi menu được dựng lại sau khi đổi ngôn ngữ.
## Thêm --thu_vao_tran: sau cùng vào trận 6v6.

static var da_tao := false
var thu_muc := "user://anh_thu_menu"
var _ket_qua: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(thu_muc)
	_chay()


var menu: MenuChinh:
	get:
		return get_tree().current_scene as MenuChinh


func _gio(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _chup(ten: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(thu_muc.path_join(ten + ".png"))
	print("[thu_menu] chup ", ten)


func _ghi(ten: String, dat: bool, chi_tiet := "") -> void:
	_ket_qua.append([ten, dat])
	print("[kiem] %s %s — %s" % ["DAT" if dat else "KHONG DAT", ten, chi_tiet])


func _nut(goc: Node, ten: String) -> Button:
	return goc.find_child(ten, true, false) as Button


func _bam(goc: Node, ten: String) -> bool:
	var b := _nut(goc, ten)
	if b == null:
		print("[thu_menu] KHONG THAY NUT ", ten)
		return false
	if b.disabled:
		print("[thu_menu] nut bi khoa ", ten)
		return false
	b.pressed.emit()
	return true


## Bấm Esc như người chơi (qua hàng sự kiện nhập), chờ vài khung hình cho menu xử lý.
func _bam_esc() -> void:
	for nhan in [true, false]:
		var e := InputEventKey.new()
		e.keycode = KEY_ESCAPE
		e.physical_keycode = KEY_ESCAPE
		e.pressed = nhan
		Input.parse_input_event(e)
		await get_tree().process_frame
		await get_tree().process_frame


## Đổi ngôn ngữ rồi chờ menu dựng lại.
func _doi_ngon_ngu(ma: String) -> void:
	GiaoDien.doi_ngon_ngu(ma)
	await _gio(1.2)


func _chay() -> void:
	await _gio(1.8)
	_ghi("Lần đầu mở game là tiếng Anh", NgonNgu.ngon_ngu == "en" and tr("CHIẾN DỊCH") == "CAMPAIGN", NgonNgu.ngon_ngu)
	await _chup("m01_man_chinh_en")
	TienTrinh.cong_trang += 3000
	menu.cap_nhat_cong_trang()
	# ---- chiến dịch
	menu.mo("chien_dich")
	await _gio(0.5)
	_ghi("Màn Chiến dịch: nhiệm vụ 1 mở, nhiệm vụ 2 khóa", not _nut(menu.man["chien_dich"], "nv_0").disabled and _nut(menu.man["chien_dich"], "nv_1").disabled)
	_bam(menu.man["chien_dich"], "kho_kho")
	await _gio(0.2)
	_ghi("Chọn độ khó chiến dịch (Khó: 3 địch tấn công cùng lúc)", TienTrinh.cau_hinh_tran["do_kho"] == "kho" and _nut(menu.man["chien_dich"], "kho_kho") != null)
	_bam(menu.man["chien_dich"], "kho_thuong")
	await _gio(0.2)
	await _chup("m02_chien_dich_en")
	# ---- mecha & vũ khí (bảng trang bị dùng chung)
	menu.mo("mecha")
	await _gio(0.5)
	var mm: ManMecha = menu.man["mecha"]
	_bam(mm, "nut_loai_hang_nang")
	await _gio(0.4)
	var bang: BangTrangBi = mm.find_child("bang_trang_bi", true, false)
	bang.o_chon = "trai"
	var mo := bang.chon_mon("trai", "sung_phao")          # khóa: ở menu thì mở bằng điểm công trạng
	_ghi("Mở khóa + lắp súng pháo ở menu", mo and TienTrinh.da_mo("sung_phao") and TienTrinh.trang_bi["trai"] == "sung_phao", "điểm còn %d" % TienTrinh.cong_trang)
	bang.o_chon = "e"
	bang.chon_mon("e", "khien")
	await _gio(0.8)
	await _chup("m03_mecha_en")
	_bam(mm, "nut_loai_co_ban")
	await _gio(0.3)
	# ---- nâng cấp
	menu.mo("nang_cap")
	await _gio(0.5)
	await _chup("m04_nang_cap_en")
	# ---- đổi phím
	menu.mo("cai_dat")
	await _gio(0.4)
	var cd: ManCaiDat = menu.man["cai_dat"]
	var mp := cd.mo_phim()
	await _gio(0.4)
	mp.doi_phim("tay_phu_trai", ["k", KEY_G])
	var ev_g := false
	for e in InputMap.action_get_events("tay_phu_trai"):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_G:
			ev_g = true
	_ghi("Đổi phím tay phụ trái sang G", Phim.ten("tay_phu_trai") == "G" and ev_g)
	var bi := mp.doi_phim("tay_phu_phai", ["k", KEY_G])
	_ghi("Phím trùng thì hoán đổi", bi == "tay_phu_trai" and Phim.ten("tay_phu_trai") == "E" and Phim.ten("tay_phu_phai") == "G")
	mp.doi_phim("ban_trai", ["k", KEY_V])
	await _gio(0.3)
	await _chup("m05_doi_phim_en")
	# biểu tượng nút trên bảng trang bị đổi theo phím mới
	mp.queue_free()
	menu.mo("mecha")
	await _gio(0.5)
	await _chup("m06_bang_trang_bi_phim_moi")
	Phim.mac_dinh_tat_ca()
	_ghi("Khôi phục phím mặc định", Phim.ten("tay_phu_trai") == "Q" and Phim.nut_chuot("ban_trai") == MOUSE_BUTTON_RIGHT)
	# ---- lưu / tải
	TienTrinh.cong_trang = 1234
	TienTrinh.chien_dich["mo"] = 3
	TienTrinh.luu_o(2)
	TienTrinh.cong_trang = 5
	TienTrinh.chien_dich["mo"] = 1
	var tai := TienTrinh.tai_o(2)
	_ghi("Lưu vào ô 2 rồi tải lại", tai and TienTrinh.cong_trang == 1234 and int(TienTrinh.chien_dich["mo"]) == 3, "điểm %d, mở %d nhiệm vụ" % [TienTrinh.cong_trang, int(TienTrinh.chien_dich["mo"])])
	menu.mo("chinh")
	await _gio(0.3)
	var lt := ManLuuTai.new()
	menu.giao_dien.add_child(lt)
	await _gio(0.5)
	await _chup("m07_luu_tai_en")
	lt.queue_free()
	# ---- tiếng Nhật
	await _doi_ngon_ngu("ja")
	_ghi("Đổi sang tiếng Nhật", tr("CHIẾN DỊCH") == "キャンペーン" and menu.dang_mo == "chinh")
	await _chup("m08_man_chinh_ja")
	menu.mo("chien_dich")
	await _gio(0.5)
	await _chup("m09_chien_dich_ja")
	menu.mo("mecha")
	await _gio(0.6)
	await _chup("m10_mecha_ja")
	menu.mo("cai_dat")
	await _gio(0.4)
	await _chup("m11_cai_dat_ja")
	# ---- tiếng Việt
	await _doi_ngon_ngu("vi")
	_ghi("Đổi sang tiếng Việt (màn đang mở giữ nguyên)", tr("CHIẾN DỊCH") == "CHIẾN DỊCH" and menu.dang_mo == "cai_dat")
	await _chup("m12_cai_dat_vi")
	menu.mo("mecha")
	await _gio(0.6)
	await _chup("m13_mecha_vi")
	menu.mo("chuan_bi")
	await _gio(0.5)
	await _chup("m14_chuan_bi_vi")
	await _doi_ngon_ngu("en")
	menu.mo("ghi_cong")
	await _gio(0.5)
	await _chup("m15_ghi_cong_en")
	menu.mo("chuan_bi")
	await _gio(0.3)
	var cb: ManChuanBi = menu.man["chuan_bi"]
	_bam(cb, "quan_6")
	await _gio(0.3)
	# ---- chất lượng đồ họa: đổi ở Cài đặt là áp ngay cho môi trường đang có
	menu.mo("cai_dat")
	await _gio(0.3)
	var env_menu: Environment = (get_tree().get_nodes_in_group("moi_truong")[0] as WorldEnvironment).environment
	_bam(menu.man["cai_dat"], "do_hoa_thap")
	await _gio(0.3)
	var thap_ok: bool = TienTrinh.cai_dat["do_hoa"] == "thap" and not env_menu.ssao_enabled and not env_menu.sdfgi_enabled
	_bam(menu.man["cai_dat"], "do_hoa_cao")
	await _gio(0.3)
	var cao_ok: bool = TienTrinh.cai_dat["do_hoa"] == "cao" and env_menu.ssao_enabled and env_menu.sdfgi_enabled
	await _chup("m17_cai_dat_do_hoa")
	_bam(menu.man["cai_dat"], "do_hoa_vua")
	await _gio(0.3)
	_ghi("Chất lượng đồ họa Thấp / Cao áp ngay", thap_ok and cao_ok, "thấp %s · cao %s" % [thap_ok, cao_ok])
	menu.mo("chinh")
	await _gio(0.3)
	# ---- Esc lùi một bước: màn con → màn chính; màn đổi phím → Cài đặt → màn chính; màn chính → hỏi thoát game
	menu.mo("nang_cap")
	await _gio(0.3)
	await _bam_esc()
	var esc_lui := menu.dang_mo == "chinh"
	menu.mo("cai_dat")
	await _gio(0.3)
	var mp2 := (menu.man["cai_dat"] as ManCaiDat).mo_phim()
	await _gio(0.3)
	await _bam_esc()
	var esc_phim := not is_instance_valid(mp2) and menu.dang_mo == "cai_dat"
	await _bam_esc()
	esc_phim = esc_phim and menu.dang_mo == "chinh"
	await _bam_esc()
	var esc_hoi := menu.man["chinh"].find_child("hoi_thoat", true, false) != null
	await _chup("m16_hoi_thoat_en")
	await _bam_esc()
	esc_hoi = esc_hoi and menu.man["chinh"].find_child("hoi_thoat", true, false) == null and menu.dang_mo == "chinh"
	_ghi("Esc ở màn con: quay lại màn chính", esc_lui)
	_ghi("Esc ở màn đổi phím: về Cài đặt, Esc nữa: về màn chính", esc_phim)
	_ghi("Esc ở màn chính: hỏi thoát game, Esc nữa: đóng hộp hỏi", esc_hoi)
	menu.mo("chuan_bi")
	await _gio(0.3)
	var dat := _ket_qua.filter(func(k): return k[1]).size()
	print("[kiem] TONG: %d / %d dat" % [dat, _ket_qua.size()])
	print("[thu_menu] XONG MENU")
	if "--thu_vao_tran" in " ".join(OS.get_cmdline_user_args()):
		print("[thu_menu] bam BAT DAU TRAN (6v6)")
		_bam(cb, "nut_bat_dau")
		return
	get_tree().quit()
