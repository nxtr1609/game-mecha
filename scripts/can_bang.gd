extends Node
## Bảng cân bằng: mọi con số chỉnh độ khó / cảm giác chơi nằm ở đây.
## Đơn vị: mét, giây, máu (điểm). Mecha cao 10 m.
## Cơ chế điều khiển ghép từ game thử "Thử Gameplay Mecha" (học từ Iron Valiant, không chép):
## thanh nhiệt thay năng lượng, Ctrl giữ độ cao, T rơi nhanh, tay phụ Q / E, pháo nhiệt X,
## F chém / F lao chém (địch trong tầm) có né / đỡ đúng lúc, giữ Shift lướt nhanh, bảng trang bị B.

# =====================================================================  MECHA

## THANH NHIỆT: bật lao, bay lên, giữ độ cao làm nóng động cơ. Đầy = QUÁ NHIỆT: chỉ chạy bộ được,
## không bay / bật lao / lướt; đang bay thì rơi; chờ nguội hết mới dùng lại.
const NHIET := {
	"toi_da": 100.0,
	"lao": 13.0,              # mỗi lần bật lao (20/10: 21 → 13, bật lao liền ~7 lần mới quá nhiệt)
	"bay": 8.0,               # mỗi giây khi giữ Space bay lên (20/10: 15 → 8, bay liên tục ~12,5 giây)
	"giu_do_cao": 2.5,        # mỗi giây khi giữ độ cao (Ctrl lúc đang bay) (20/10: 6 → 2,5, lơ lửng ~40 giây)
	"giu_lao": 8.0,           # mỗi giây khi GIỮ Shift lướt nhanh (~11 giây liên tục thì quá nhiệt)
	"cho_nguoi": 0.5,         # thôi dùng động cơ bấy nhiêu giây thì bắt đầu nguội
	"nguoi": 32.0,            # nguội mỗi giây
	"nguoi_qua_nhiet": 34.0,  # lúc quá nhiệt: nguội từ đầy về 0 mất ~3 giây
}

## Mecha loại Cơ bản. Các loại khác chỉ ghi chỗ khác trong LOAI_MECHA[...]["chi_so"].
const MECHA := {
	"mau": 4000.0,
	"trong_luc": 34.0,
	"toc_luot": 50.0,         # lướt sát mặt đất
	"toc_luot_nhanh": 85.0,   # GIỮ Shift: lướt nhanh liên tục (trên đất lẫn trên không), tốn nhiệt NHIET["giu_lao"]
	"toc_lao": 130.0,         # bật lao (bấm Shift): vọt rất nhanh rồi giảm dần về tốc độ lướt
	"thoi_lao": 0.32,
	"hoi_lao": 0.45,
	"cao_bay": 70.0,          # bay lên tối đa bấy nhiêu mét so với mặt đất bên dưới
	"toc_len": 26.0,
	"gia_chay": 40.0,         # gia tốc khi chạy bộ (Ctrl dưới đất / quá nhiệt); tốc độ chạy lấy từ dáng chạy: tới 20, ngang 13, lùi 12 m/s
	"toc_roi": 110.0,         # T: rơi nhanh khi đang bay (m/s)
	"he_so_toc": 1.0,         # nhân mọi tốc độ (loại mecha, nâng cấp)
	# --- hồi sinh: rơi từ tàu sân bay xuống (rất nhanh, chỉ hãm lại ở ~25 m cuối, tổng chừng 1,7 giây)
	"roi_cao": 220.0,
	"roi_toc_do": 160.0,
}

## 4 loại mecha. "than": mẫu thân dùng ("to" / "thon", mỗi mẫu có màu phe ta xanh và màu địch đỏ).
## "ty_le": to / nhỏ hơn mẫu gốc. "thang": thang 1–5 [tốc độ, giáp, hỏa lực, chiếm cứ điểm].
## "kha_nang": khả năng tự có (xem KHA_NANG). "chi_so": chỗ khác loại Cơ bản.
const LOAI_MECHA := {
	"co_ban": {"ten": "Cơ bản", "than": "thon", "ty_le": 1.0, "kha_nang": "",
		"mo_ta": "Cân bằng mọi mặt.",
		"thang": [3, 3, 3, 3],
		"chi_so": {}},
	"co_dong": {"ten": "Cơ động", "than": "thon", "ty_le": 0.95, "kha_nang": "luot_kep",
		"mo_ta": "Nhanh nhất, chiếm cứ điểm nhanh nhất, giáp mỏng.",
		"thang": [5, 1, 3, 5],
		"chi_so": {"mau": 3000.0, "he_so_toc": 1.15, "nhiet_toi_da": 120.0, "he_so_chiem": 1.8}},
	"hang_nang": {"ten": "Hạng nặng", "than": "to", "ty_le": 1.1, "kha_nang": "khien_day",
		"mo_ta": "Giáp dày, hỏa lực mạnh, chậm, nóng máy nhanh.",
		"thang": [1, 5, 5, 2],
		"chi_so": {"mau": 5800.0, "he_so_toc": 0.85, "nhiet_toi_da": 90.0, "he_so_chiem": 0.7, "he_so_hoa_luc": 1.2}},
	"ho_tro": {"ten": "Hỗ trợ", "than": "to", "ty_le": 1.0, "kha_nang": "ky_su",
		"mo_ta": "Giỏi dùng tay phụ: đặt nhiều ụ minigun hơn, tay phụ hồi nhanh hơn. Tự đánh yếu hơn.",
		"thang": [3, 3, 2, 3],
		"chi_so": {"he_so_hoa_luc": 0.85, "he_so_hoi_tay_phu": 0.8, "so_u_minigun": 2}},
}
## Khả năng tự có của từng loại (trước đây là kỹ năng phím E).
const KHA_NANG := {
	"luot_kep": {"ten": "Lướt kép", "mo_ta": "Bật lao lần hai ngay sau lần đầu (trong 0,8 giây) không tốn nhiệt.", "cua_so": 0.8},
	"khien_day": {"ten": "Khiên dày", "mo_ta": "Khiên năng lượng (tay phụ) chặn hết đạn phía trước; loại khác chặn 75%."},
	"ky_su": {"ten": "Kỹ sư", "mo_ta": "Đặt được 2 ụ minigun (loại khác 1), tay phụ hồi nhanh hơn 20%."},
}
## Mẫu 3D theo thân và phe: [phe ta (xanh), địch (đỏ)]. Mẫu Tripo gắn xương sẵn, mỗi mẫu có 3 đế phụ sau lưng:
## trái, phải mang ổ tên lửa (mặc định), giữa lưng trống — sau này thay ổ tên lửa bằng vũ khí khác.
const MAU_THAN := {
	"to": ["mecha_xanh_1", "mecha_do_2"],
	"thon": ["mecha_xanh_2", "mecha_do_1"],
}

# =====================================================================  VŨ KHÍ

## Vũ khí tay (chuột trái = tay phải, chuột phải = tay trái). Hai tay lắp tự do món nào cũng được.
## "kieu": "tia" bắn tức thì, "dan_cham" đạn bay thấy được. Mỗi vũ khí có TẦM TỐI ƯU và TẦM TỐI ĐA:
## bắn xa hơn tầm tối ưu thì đạn tỏa rộng dần (tới "lech_xa" lần) và sát thương giảm dần (còn "dmg_xa" ở tầm tối đa).
## "tam_khoa": cầm vũ khí này ở tay phải thì khóa mục tiêu xa bao nhiêu.
## "chan_ten_lua": đạn bắn rơi được tên lửa địch — CHỈ súng máy; súng bắn chậm / bắn tỉa thì đạn đi xuyên qua tên lửa.
## "nhiet_them": trúng thì làm nóng động cơ địch thêm bấy nhiêu (đầy là quá nhiệt).
## "laser": giây chiếu laser báo trước khi bắn (chỉ bản của máy địch, tên có đuôi "_dich").
const VU_KHI := {
	"sung_may": {
		"ten": "Súng máy xoay nòng", "model": "res://models/sung_mecha/minigun.glb", "dai": 6.0, "kieu": "tia",
		"nhip": 0.07, "sat_thuong": 14.0, "tam_toi_uu": 260.0, "tam": 520.0, "tam_khoa": 520.0,
		"do_lech": 1.3, "lech_xa": 2.5, "dmg_xa": 0.5, "chan_ten_lua": true, "giat": 2.0, "mau": Color(1.0, 0.8, 0.4),
	},
	"sung_truong": {
		"ten": "Súng trường", "model": "res://models/sung_mecha/mecha_sung_truong.glb", "dai": 6.0, "kieu": "tia",
		"nhip": 0.55, "sat_thuong": 120.0, "tam_toi_uu": 450.0, "tam": 760.0, "tam_khoa": 700.0,
		"do_lech": 0.35, "lech_xa": 2.0, "dmg_xa": 0.6, "giat": 9.0, "mau": Color(1.0, 0.9, 0.55),
	},
	"sung_ban_tia": {
		"ten": "Súng bắn tỉa", "model": "res://models/sung_mecha/ban_tia_moi.glb", "dai": 8.5, "kieu": "tia",
		"nhip": 1.6, "sat_thuong": 520.0, "tam_toi_uu": 800.0, "tam": 1300.0, "tam_khoa": 1200.0,
		"do_lech": 0.04, "lech_xa": 2.0, "dmg_xa": 0.6, "giat": 22.0, "mau": Color(0.6, 0.9, 1.6),
	},
	"sung_ban_tia_dich": {           # máy địch bắn tỉa: chiếu tia laser đỏ báo trước, né được bằng bật lao / nấp
		"ten": "Súng bắn tỉa", "model": "res://models/sung_mecha/ban_tia_moi.glb", "dai": 8.5, "kieu": "tia", "an": true,
		"nhip": 4.5, "sat_thuong": 900.0, "tam_toi_uu": 800.0, "tam": 1300.0, "tam_khoa": 1200.0,
		"do_lech": 0.0, "lech_xa": 2.0, "dmg_xa": 0.6, "giat": 22.0, "laser": 1.1, "mau": Color(1.8, 0.4, 0.3),
	},
	"sung_phao": {
		"ten": "Súng pháo", "model": "res://models/sung_mecha/sung_phao.glb", "dai": 7.0, "kieu": "tia",
		"nhip": 2.0, "sat_thuong": 380.0, "tam_toi_uu": 500.0, "tam": 900.0, "tam_khoa": 800.0,
		"do_lech": 0.25, "lech_xa": 2.0, "dmg_xa": 0.6, "no_lan": 10.0, "sat_thuong_lan": 260.0,   # nổ lan: bán kính, sát thương ở tâm
		"giat": 28.0, "mau": Color(1.0, 0.6, 0.3),
	},
	"phao_plasma": {
		"ten": "Pháo plasma", "model": "res://models/sung_mecha/mecha_phao_plasma_a.glb", "dai": 6.0, "kieu": "dan_cham",
		"nhip": 1.8, "sat_thuong": 420.0, "toc_do_dan": 170.0, "tam_toi_uu": 300.0, "tam": 900.0,
		"dmg_xa": 0.6, "no": 12.0, "do_lech": 0.0, "giat": 22.0, "mau": Color(0.45, 0.8, 1.0),
	},
	"phao_plasma_dich": {
		"ten": "Pháo plasma", "model": "res://models/sung_mecha/mecha_phao_plasma_b.glb", "dai": 6.0, "kieu": "dan_cham", "an": true,
		"nhip": 3.0, "sat_thuong": 380.0, "toc_do_dan": 110.0, "tam_toi_uu": 300.0, "tam": 900.0,
		"dmg_xa": 0.6, "no": 10.0, "do_lech": 0.0, "giat": 22.0, "laser": 0.6, "mau": Color(1.0, 0.45, 0.2),
	},
	"sung_tia_nang_luong": {
		"ten": "Súng tia năng lượng", "model": "res://models/sung_mecha/mecha_sung_tia_nang_luong.glb", "dai": 7.0, "kieu": "tia",
		"nhip": 0.85, "sat_thuong": 300.0, "tam_toi_uu": 420.0, "tam": 900.0, "tam_khoa": 800.0,
		"do_lech": 0.1, "lech_xa": 2.0, "dmg_xa": 0.6, "nhiet_them": 12.0, "tia_to": true, "giat": 14.0,
		"mau": Color(0.6, 1.4, 1.8),
	},
	"sung_emp": {
		"ten": "Súng EMP", "model": "res://models/sung_mecha/mecha_sung_emp.glb", "dai": 6.0, "kieu": "dan_cham",
		"nhip": 2.4, "sat_thuong": 120.0, "toc_do_dan": 150.0, "tam_toi_uu": 280.0, "tam": 700.0,
		"dmg_xa": 0.7, "no": 9.0, "nhiet_them": 40.0, "do_lech": 0.0, "giat": 16.0, "mau": Color(0.7, 0.5, 1.8),
	},
}
## Thứ tự hiện trong bảng trang bị.
const DS_VU_KHI := ["sung_may", "sung_truong", "sung_ban_tia", "sung_phao", "phao_plasma", "sung_tia_nang_luong", "sung_emp"]

## Tay phụ (Q = trái, E = phải) — hai ổ trên tay máy sau lưng. Mỗi bên chọn một món, hồi riêng.
const TAY_PHU := {
	"ten_lua": {"ten": "Tên lửa (2 quả)", "mo_ta": "Cần khóa mục tiêu. 2 quả bám đuổi, 170 sát thương mỗi quả.",
		"hoi": 3.5, "so_qua": 2, "sat_thuong": 170.0, "quay": 1.7, "toc_max": 120.0, "no": 7.0},
	"ten_lua_loat": {"ten": "Tên lửa loạt (6 quả nhỏ)", "mo_ta": "Cần khóa. 6 quả nhỏ, quay gắt hơn, 60 sát thương mỗi quả — khó bắn rơi hết.",
		"hoi": 7.0, "so_qua": 6, "sat_thuong": 60.0, "quay": 2.4, "toc_max": 105.0, "no": 5.0},
	"sung_may_vai": {"ten": "Súng máy vai", "mo_ta": "Bật 5 giây: tự bắn rơi tên lửa địch bay tới trong 150 m.",
		"hoi": 12.0, "thoi_gian": 5.0, "tam": 150.0, "nhip": 0.2},
	"khien": {"ten": "Khiên năng lượng", "mo_ta": "Bật 4 giây: sát thương đến từ phía trước (70°) chỉ còn 25% (Hạng nặng: chặn hết).",
		"hoi": 14.0, "thoi_gian": 4.0, "con_lai": 0.25, "goc": 70.0},
	"u_minigun": {"ten": "Ụ minigun", "mo_ta": "Đặt ụ minigun tại chỗ. Ụ chỉ bắn mecha địch đang bay, có còi báo 1 giây trước khi bắn.",
		"hoi": 12.0},
}
const DS_TAY_PHU := ["ten_lua", "ten_lua_loat", "sung_may_vai", "khien", "u_minigun"]
const U_MINIGUN := {"ten": "Ụ minigun", "mau": 700.0, "tam": 320.0, "bao_truoc": 1.0,
	"sat_thuong": 14.0, "nhip": 0.05, "lech": 1.2}

## Tên lửa bay: tăng tốc dần, bẻ lái có giới hạn — bật lao ngang đúng lúc là né được
## (lệch quá "bo_bam_goc" so với mục tiêu thì thôi bám). Pháo nhiệt kéo nó đi chỗ khác. Súng máy bắn rơi được.
const TEN_LUA := {
	"toc_dau": 45.0,
	"gia_toc": 110.0,
	"song": 7.0,
	"kich_no": 4.5,           # tới gần mục tiêu bấy nhiêu mét thì nổ
	"ban_kinh_trung": 1.8,    # đạn súng máy cách tên lửa bấy nhiêu mét là bắn rơi
	"tam_khoa": 750.0,        # tay phụ tên lửa chỉ phóng khi mục tiêu đang khóa trong tầm này
	"bo_bam_goc": 100.0,
}

## Pháo nhiệt: mecha nào cũng có (X). Tên lửa đang khóa mình và còn xa hơn "gan_qua" mét thì mất khóa, lao theo pháo.
const PHAO_NHIET := {"so_luot": 2, "hoi": 15.0, "chay": 3.0, "gan_qua": 25.0}

## Cận chiến. F: chém nhanh trước mặt; mecha địch đang khóa trong "tam_danh_dau" mét (chữ F hiện cạnh nó) thì F = LAO CHÉM:
## tự lao cực nhanh tới chém. Bị địch lao chém thì có vòng báo động quanh thân nó: bấm Shift đúng lúc (còn ≤ cửa sổ né
## giây trước cú chém) là né, bấm F đúng lúc (≤ cửa sổ đỡ) là ĐỠ — kẻ lao tới bị choáng. Bấm sớm quá thì coi như đã
## phản ứng sai, vẫn bị chém (mỗi cú lao chỉ được phản ứng một lần). Đỡ rất khó (cửa sổ hẹp).
## NÂNG CẤP: hướng "Cơ động" của cây kỹ năng mecha nới cửa sổ né / đỡ ("nang_cap_ne", "nang_cap_do" mỗi nút) và lao chém
## nhanh hơn ("nang_cap_toc" mỗi nút). Lao càng nhanh thì máy càng khó né / đỡ (xác suất chia theo tỉ lệ "toc" / tốc độ lao).
const CAN_CHIEN := {
	"chem": {"sat_thuong": 320.0, "tam": 18.0, "hoi": 0.9, "lao_nhe": 40.0},
	"lao_chem": {"sat_thuong": 750.0, "tam_danh_dau": 120.0, "toc": 220.0, "toc_may": 160.0, "nang_cap_toc": 0.08,
		"trung_cach": 14.0, "hoi": 3.0, "nhiet": 20.0,
		"lay_da_nguoi": 0.08, "lay_da_may": 0.3},      # lấy đà trước khi lao (20/10: người 0,15 → 0,08, máy 0,55 → 0,3 — báo động ngắn hơn)
	"cua_so_ne": 0.35,
	"cua_so_do": 0.15,
	"nang_cap_ne": 0.03,
	"nang_cap_do": 0.015,
	"choang_bi_do": 2.2,      # bị đỡ đòn: choáng bấy nhiêu giây (không làm gì được)
	"choang_bi_chem": 0.5,    # bị lao chém trúng: khựng
}
## Kiểu cận chiến (ô F của bảng trang bị). "he_so": nhân sát thương chém, "tam_them": tầm chém thêm (m),
## "goc_dot": cung trúng (càng lớn càng hẹp), "choang": địch khựng thêm bao lâu, "nhiet_them": địch nóng thêm,
## "luoi": kích thước lưỡi năng lượng ở cẳng tay trái (rộng, dày, dài).
const KIEU_CAN_CHIEN := {
	"kiem": {"ten": "Kiếm plasma", "mo_ta": "Chém ngang, trúng rộng, dễ dùng.",
		"he_so": 1.0, "tam_them": 0.0, "goc_dot": 0.2, "choang": 0.0, "nhiet_them": 0.0, "xuyen_khien": false,
		"mau": Color(0.5, 1.6, 2.4), "luoi": Vector3(0.25, 0.9, 9.0)},
	"thuong": {"ten": "Thương xuyên", "mo_ta": "Đâm thẳng, sát thương cao nhất, xuyên khiên năng lượng. Trúng hẹp.",
		"he_so": 1.4, "tam_them": 4.0, "goc_dot": 0.7, "choang": 0.0, "nhiet_them": 0.0, "xuyen_khien": true,
		"mau": Color(2.0, 1.3, 0.5), "luoi": Vector3(0.35, 0.35, 13.0)},
	"dam_emp": {"ten": "Đấm EMP", "mo_ta": "Sát thương thấp, địch choáng 1,5 giây và nóng máy thêm 40.",
		"he_so": 0.5, "tam_them": -4.0, "goc_dot": 0.3, "choang": 1.5, "nhiet_them": 40.0, "xuyen_khien": false,
		"mau": Color(1.2, 0.8, 2.6), "luoi": Vector3(1.8, 1.8, 2.4)},
}

## Giá mở khóa (điểm công trạng). Thứ không có trong bảng thì có sẵn từ đầu.
const GIA_MO_KHOA := {
	"sung_phao": 250, "sung_tia_nang_luong": 300, "sung_emp": 250,
	"ten_lua_loat": 300, "sung_may_vai": 250,
	"thuong": 200, "dam_emp": 200,
}
## Trang bị của bot theo loại mecha. Máy địch dùng bản "_dich" (có laser báo trước) nếu có.
const BOT_TRANG_BI := {
	"co_ban": {"vk": {"phai": "sung_truong", "trai": "phao_plasma"}, "tay_phu": {"trai": "ten_lua", "phai": "ten_lua"}, "can_chien": "kiem"},
	"co_dong": {"vk": {"phai": "sung_ban_tia", "trai": "sung_may"}, "tay_phu": {"trai": "ten_lua", "phai": "khien"}, "can_chien": "kiem", "ban_tia": true},
	"hang_nang": {"vk": {"phai": "sung_may", "trai": "sung_phao"}, "tay_phu": {"trai": "ten_lua_loat", "phai": "khien"}, "can_chien": "thuong"},
	"ho_tro": {"vk": {"phai": "sung_truong", "trai": "sung_emp"}, "tay_phu": {"trai": "u_minigun", "phai": "sung_may_vai"}, "can_chien": "dam_emp"},
}
## Máy (bot): phản xạ, nhịp dùng tên lửa / lao chém, né / đỡ cú lao chém của đối thủ.
const BOT := {
	"phan_xa_phao_nhiet": 0.45,  # giây từ lúc thấy tên lửa tới lúc phóng pháo nhiệt
	"ty_le_phao_nhiet": 0.7,     # bao nhiêu phần lần có tên lửa thì bot dùng pháo nhiệt
	"hoi_ten_lua": [6.0, 10.0],
	"he_so_can_chien": 0.8,      # cận chiến của máy địch
	"hoi_lao_chem": [7.0, 12.0], # máy lao chém cứ mỗi bấy nhiêu giây (khi đủ gần)
	"ne_lao_chem": 0.35,         # máy né được cú lao chém bao nhiêu phần lần
	"do_lao_chem": 0.10,         # ... đỡ được (kẻ lao tới bị choáng) bao nhiêu phần lần — hiếm
}

## Hỗ trợ gọi từ chiến hạm phe ta. Thả tiếp tế và radar miễn phí (chỉ có thời gian hồi);
## pháo kích và tiếp viện tốn thêm "dch" Điểm Chỉ Huy kiếm trong trận.
const HO_TRO := {
	# Pháo kích vào vùng cố định (chỗ mục tiêu khóa đứng lúc gọi, hoặc điểm ngắm).
	# "vung": bán kính vùng đạn rơi (= vòng đỏ). "no": bán kính nổ mỗi quả. "sat_thuong": mỗi quả ở tâm nổ.
	"phao_kich": {"ten": "Pháo kích", "tau": "Tàu pháo kích", "hoi": 20.0, "dch": 60,
		"tre": 2.5, "so_dan": 14, "vung": 45.0, "sat_thuong": 900.0, "no": 32.0},
	# Hòm tiếp tế rơi cách mecha "cach" m về phía trước, nằm "ton_tai" giây, lại gần trong "nhat" m để nhặt.
	"tiep_te": {"ten": "Thả tiếp tế", "tau": "Tàu sân bay", "hoi": 30.0,
		"hoi_mau": 1800.0, "ton_tai": 60.0, "nhat": 10.0, "cach": 22.0},
	"radar": {"ten": "Quét radar", "tau": "Tàu sân bay", "hoi": 25.0, "thoi_gian": 10.0},
	"tiep_vien": {"ten": "Thả mecha tiếp viện", "tau": "Tàu sân bay", "hoi": 45.0, "toi_da": 2, "dch": 80},
}

const CAMERA_BAM_KHOA := 3.0   # camera tự xoay về mục tiêu đang khóa (0 = tắt). Lớn = bám chặt hơn
const HOI_SINH := 5.0   # giây chờ hồi sinh
const HE_SO_SAT_THUONG_BOT := 0.45        # bot địch gây sát thương bằng 45% người chơi
const HE_SO_SAT_THUONG_TIEP_VIEN := 0.7   # mecha tiếp viện phe ta

# =====================================================================  CỨ ĐIỂM

## Luật chiếm: mecha đứng trong vòng. Chỉ một phe có mặt thì thanh chiếm chạy; hai phe cùng có mặt thì đứng yên (tranh chấp).
## Cứ điểm đang thuộc địch: phải kéo thanh về 0 trước (lúc đó mọi công trình bị PHÁ SẠCH), rồi mới chiếm sang phe mình.
const CU_DIEM := {
	"ban_kinh": 55.0,            # bán kính vòng chiếm (m)
	"thoi_gian_chiem": 12.0,     # 1 mecha chiếm cứ điểm trống mất bao nhiêu giây (nhiều mecha nhanh hơn, tối đa x2)
	"hoi_phuc": 0.05,            # không ai tranh chấp: thanh chiếm tự hồi về phía chủ bao nhiêu mỗi giây
	"may_bay_toc_do": 90.0,      # máy bay chở quân / hậu cần (m/s)
	"xay_moi_u": 3.0,            # giây xây một ụ súng sau khi quân tới
	"quan_don_tru": 6,           # số lính đồn trú cơ bản
	"chu_ky": 30.0,              # trạm tên lửa / hậu cần làm việc mỗi bao nhiêu giây
}

## Ba loại cứ điểm. "u": danh sách ụ súng xây thêm (ngoài 2 ụ súng máy cơ bản của mọi cứ điểm).
const LOAI_CU_DIEM := {
	"phao_dai": {
		"ten": "PHÁO ĐÀI",
		"mo_ta": "Thêm 2 ụ súng máy đôi + 2 ụ pháo.\nQuân đồn trú đông gấp đôi.\nĐịch chiếm lại chậm gấp đôi.\nKhông hỗ trợ tàu.",
		"u": ["sung_may_doi", "sung_may_doi", "phao", "phao"],
		"quan_them": 6,
		"he_so_bi_chiem": 0.5,
	},
	"ten_lua": {
		"ten": "TRẠM TÊN LỬA",
		"mo_ta": "Xây 2 ụ tên lửa.\nMỗi 30 giây, mỗi ụ phóng 1 tên lửa\nlên tàu địch (550 sát thương / quả).\nỤ tên lửa cũng bắn mecha địch đến gần.",
		"u": ["ten_lua", "ten_lua"],
		"sat_thuong_tau": 550.0,
	},
	"hau_can": {
		"ten": "TRẠM HẬU CẦN",
		"mo_ta": "Mỗi 30 giây gửi máy bay hậu cần\nsửa tàu sân bay phe ta (+700).\nMecha phe ta trong vòng được sửa giáp\n(+60/giây) và đổi trang bị (B).",
		"u": [],
		"sua_tau": 700.0,
		"sua_mecha": 60.0,
	},
}

## Ụ súng. "tam": tầm bắn, "nhip": giây giữa 2 phát, "lech": độ tỏa (độ).
const U_SUNG := {
	"sung_may": {"ten": "Ụ súng máy", "model": "res://models/u_sung/u_sung_may.glb", "mau": 1800.0,
		"kieu": "tia", "sat_thuong": 9.0, "nhip": 0.12, "tam": 360.0, "lech": 1.4, "quay": 2.5},
	"sung_may_doi": {"ten": "Ụ súng máy đôi", "model": "res://models/u_sung/u_sung_may_doi.glb", "mau": 2200.0,
		"kieu": "tia", "sat_thuong": 9.0, "nhip": 0.07, "tam": 380.0, "lech": 1.6, "quay": 2.2},
	"phao": {"ten": "Ụ pháo", "model": "res://models/u_sung/u_phao.glb", "mau": 2600.0,
		"kieu": "dan_cham", "sat_thuong": 240.0, "nhip": 3.5, "tam": 550.0, "toc_do_dan": 160.0, "no": 9.0, "quay": 1.2},
	# ụ tên lửa: phóng tên lửa vào tàu sân bay địch (trạm tên lửa) VÀ bắn tên lửa đuổi mecha địch đến gần
	"ten_lua": {"ten": "Ụ tên lửa", "model": "res://models/u_sung/u_ten_lua.glb", "mau": 2400.0,
		"kieu": "ten_lua", "sat_thuong": 220.0, "nhip": 6.0, "so_qua": 2, "tam": 520.0,
		"toc_do_dan": 85.0, "quay_dan": 1.7, "no": 7.0, "quay": 1.0},
}

## Trên trời: mỗi phe một tàu sân bay đứng yên phía trên căn cứ, hai tàu bắn nhau ngang sức làm nền.
## Người chơi giúp tàu ta bằng cứ điểm: trạm tên lửa (bắn tàu địch) và trạm hậu cần (sửa tàu ta).
## (26/10/2026 bỏ hẳn chế độ hạm đội — bàn cờ xếp tàu, hộ tống, pháo kích, phòng không; code cũ ở _ban_luu.)
## "model": mẫu 3D [phe ta, phe địch]; "ti_le": phóng to mẫu (mẫu gốc dài 240 m); "co_khien": cỡ quả cầu khiên (m).
const TAU_SAN_BAY := {
	"ten": "Tàu sân bay", "giap": 45000.0, "khien": 15000.0,
	"model": ["res://models/tau/tau_trang_san_bay.glb", "res://models/tau/tau_den_san_bay.glb"], "ti_le": 1.05,
	"co_khien": Vector3(225.0, 70.0, 276.0),
}
## Tàu sân bay hai phe: tổng giáp + khiên.
const MAU_TAU_SAN_BAY := 60000.0
const TRAN_TROI := {
	"vi_tri": Vector3(-30.0, 620.0, 1290.0),   # tàu sân bay phe ta (phe địch đối xứng qua tâm bản đồ)
	"khien_tre_hoi": 10.0,     # không bị bắn bao lâu thì khiên bắt đầu hồi
	"khien_hoi": 0.002,        # mỗi giây hồi bao nhiêu phần khiên tối đa
	"toc_dan": 700.0,          # đạn pháo chính của tàu sân bay
	"toc_ten_lua": 230.0,      # tên lửa từ trạm tên lửa dưới đất
	"emp_te_liet": 10.0,
	"emp_chu_ky": 70.0,        # trạm tên lửa có hướng EMP: thêm 1 tên lửa EMP mỗi bao nhiêu giây (giảm theo nâng cấp)
	"san_bay_ban": {"sat_thuong": 60.0, "chu_ky": 8.0},   # mỗi loạt (chia 3 viên), hai bên như nhau
}

# =====================================================================  NÂNG CẤP, TIẾN TRÌNH

## Cây kỹ năng: mỗi mục có 3 hướng, mỗi hướng 4 nút mở lần lượt. Mỗi nút cho cùng một hiệu quả ("moi_nut").
## Mỗi cấp của mục cho 2 điểm kỹ năng (cấp 1–5 → tối đa 10 điểm cho 12 nút: phải chọn hướng).
const CAY_KY_NANG := {
	"san_bay": {"nhom": "san_bay", "ten": "Tàu sân bay", "huong": [
		["Tiếp viện cứ điểm", "Ụ súng xây nhanh hơn 15%, thêm 1 lính đồn trú"],
		["Mecha", "Hồi sinh nhanh hơn 0,6 giây, thả tiếp viện rẻ hơn 10 Điểm Chỉ Huy"],
		["Hỗ trợ trực tiếp", "Thả tiếp tế và quét radar hồi nhanh hơn 10%"]]},
	"co_ban": {"nhom": "mecha", "ten": "Mecha Cơ bản", "huong": [
		["Giáp", "+6% giáp"], ["Cơ động", "+4% tốc độ, +8% thanh nhiệt và tốc độ nguội, cửa sổ né +0,03 giây, đỡ +0,015 giây, lao chém nhanh hơn 8%"], ["Hỏa lực", "+5% sát thương"]]},
	"co_dong": {"nhom": "mecha", "ten": "Mecha Cơ động", "huong": [
		["Giáp", "+6% giáp"], ["Cơ động", "+4% tốc độ, +8% thanh nhiệt và tốc độ nguội, cửa sổ né +0,03 giây, đỡ +0,015 giây, lao chém nhanh hơn 8%"], ["Hỏa lực", "+5% sát thương"]]},
	"hang_nang": {"nhom": "mecha", "ten": "Mecha Hạng nặng", "huong": [
		["Giáp", "+6% giáp"], ["Cơ động", "+4% tốc độ, +8% thanh nhiệt và tốc độ nguội, cửa sổ né +0,03 giây, đỡ +0,015 giây, lao chém nhanh hơn 8%"], ["Hỏa lực", "+5% sát thương"]]},
	"ho_tro": {"nhom": "mecha", "ten": "Mecha Hỗ trợ", "huong": [
		["Giáp", "+6% giáp"], ["Cơ động", "+4% tốc độ, +8% thanh nhiệt và tốc độ nguội, cửa sổ né +0,03 giây, đỡ +0,015 giây, lao chém nhanh hơn 8%"], ["Hỏa lực", "+5% sát thương"]]},
	"phao_dai": {"nhom": "cu_diem", "ten": "Pháo đài", "huong": [
		["Ụ súng bền", "+12% máu ụ súng"],
		["Thêm ụ và lính", "+2 lính; nút 2: thêm 1 ụ súng máy đôi; nút 4: thêm 1 ụ pháo"],
		["Khó chiếm lại", "Địch chiếm lại chậm thêm 12%"]]},
	"ten_lua": {"nhom": "cu_diem", "ten": "Trạm tên lửa", "huong": [
		["Sát thương", "+12% sát thương tên lửa lên tàu"],
		["Nhịp phóng", "Phóng nhanh hơn 8%"],
		["EMP", "Phóng thêm tên lửa EMP làm tê liệt tàu 10 giây; mỗi nút phóng EMP thường hơn"]]},
	"hau_can": {"nhom": "cu_diem", "ten": "Trạm hậu cần", "huong": [
		["Sửa tàu", "+15% lượng sửa tàu sân bay"],
		["Sửa mecha", "+15% tốc độ sửa giáp mecha"],
		["Máy bay nhanh", "Máy bay hậu cần nhanh hơn 15%, bền hơn 20%"]]},
}
const CAP_TOI_DA := 5
const DIEM_MOI_CAP := 2
const NUT_MOI_HUONG := 4
## Giá lên cấp: từ cấp c lên c+1 tốn GIA_LEN_CAP * c điểm công trạng.
const GIA_LEN_CAP := 150
const CONG_TRANG_BAN_DAU := 300
## Điểm công trạng sau trận.
const THUONG := {"thang": 400, "hoa": 220, "thua": 150, "moi_ha": 15, "moi_cu_diem": 30}

## Độ khó: hạm đội địch, sát thương bot địch, số nút nâng cấp địch có ở mỗi hướng,
## số mecha địch được tấn công cùng lúc trong chiến dịch (con khác đã phát hiện thì đứng xa chờ lượt).
const DO_KHO := {
	"de": {"ten": "Dễ", "he_so_bot": 0.35, "nut_dich": 0, "phan_xa": 1.3, "tan_cong_cung_luc": 1},
	"thuong": {"ten": "Thường", "he_so_bot": 0.45, "nut_dich": 1, "phan_xa": 1.0, "tan_cong_cung_luc": 2},
	"kho": {"ten": "Khó", "he_so_bot": 0.6, "nut_dich": 2, "phan_xa": 0.75, "tan_cong_cung_luc": 3},
}

## Bản đồ chọn ở màn Vào trận. Cả ba dùng chung vị trí căn cứ và 5 cứ điểm, chỉ khác địa hình và cảnh vật.
## Mecha cao 10 m nên cảnh vật làm theo thước đó: tòa nhà nội thành 40–90 m, nhà vườn 12–16 m, cây 12–24 m.
const BAN_DO := {
	"thanh_pho": {"ten": "Thành phố đổ nát",
		"mo_ta": "Phố ô bàn cờ giữa hàng trăm tòa nhà cao bị chiến tranh tàn phá, đại lộ chéo rộng nối các cứ điểm. Nhà che tầm bắn: đánh gần, nấp sau tòa nhà, bay lên mái để bắn xa."},
	"ngoai_o": {"ten": "Ngoại ô",
		"mo_ta": "Đồi thoải, phố cong hai bên là nhà vườn, nhà kính, hàng rào cây xanh; khu thấp cạnh mỗi cứ điểm, tháp ăng-ten trên đỉnh đồi. Đánh tầm trung, nấp sau nhà và đồi."},
	"dong_que": {"ten": "Đồng quê",
		"mo_ta": "Đồi lượn giữa ruộng lúa, bờ cây, trang trại và hai con sông có cầu. Tầm nhìn xa, ít chỗ nấp: hợp súng bắn tỉa và tên lửa; nấp sau đồi, mỏm đá, làng nhỏ quanh cứ điểm."},
}

## Trận đấu: giới hạn thời gian. Hết giờ thì phe có tàu sân bay còn nhiều % (giáp + khiên) hơn thắng.
const THOI_GIAN_TRAN := 900.0
## Điểm Chỉ Huy trong trận: kiếm được khi...
const DIEM_CHI_HUY := {"ha": 20, "chiem": 40, "may_bay": 15}


# =====================================================================  CHIẾN DỊCH

## Chiến dịch: đi một mình trên bản đồ rộng, đánh mecha địch kiểu Iron Valiant. 5 nhiệm vụ mở lần lượt.
## "ban_do": "bai_tap" (bãi huấn luyện, cảnh riêng "canh") hoặc một trong BAN_DO (3,2 km). Toạ độ [x, z] (m), phía nam (z dương)
## là phía ta. Địch / ụ đặt ở quảng trường cứ điểm hoặc trên đại lộ — những chỗ bản đồ luôn để trống.
## "dich": [loại mecha, x, z, kiểu] — kiểu: "tuan_tra" (đứng canh, đánh khi thấy người chơi đủ gần hoặc bị bắn),
##   "san" (đội săn: đi tuần khắp vùng, phát hiện người chơi thì lao vào), "dot2" (đợt hai: rơi từ trên trời xuống khi
##   đợt một bị hạ hết, rồi đi tuần như đội săn),
##   "phuc_kich" (nấp, chỉ đánh khi người chơi tới rất gần), "chi_huy" (mecha chỉ huy: máu ×3, né / đỡ giỏi hơn).
## Thêm "_ban_tia" vào kiểu để mecha đó đứng xa bắn tỉa (laser báo trước).
## "u": ụ súng địch [loại ụ (U_SUNG), x, z].
## "muc_tieu": "ha_het" (hạ hết địch), "pha_u" (phá hết ụ), "chi_huy" (hạ mecha chỉ huy).
## "diem_den": các điểm phải đi qua lần lượt (nhiệm vụ phục kích). "thuong": điểm công trạng lần đầu hoàn thành.
const CHIEN_DICH := [
	{"id": "huan_luyen", "ten": "Huấn luyện", "ban_do": "bai_tap", "canh": "res://scenes/huan_luyen.tscn", "bat_dau": [0, 420], "thuong": 0, "muc_tieu": "ha_het",
		"mo_ta": "Bãi tập bắn bia. 6 bài: di chuyển và nhiệt, nhắm bắn, khóa mục tiêu và tên lửa, pháo nhiệt, né và đỡ đòn, cận chiến. Trước mỗi bài có bảng hướng dẫn. Cuối cùng là bài thi: hạ 2 mecha và 2 ụ tên lửa.",
		"mau_dich": 0.5, "sat_thuong_dich": 0.35,
		"dich": [], "u": []},
	{"id": "tram_ten_lua", "ten": "Trạm tên lửa", "ban_do": "dong_que", "bat_dau": [0, 1150], "thuong": 300, "muc_tieu": "pha_u",
		"mo_ta": "Đế Chế dựng 3 trạm tên lửa ở các làng giữa đồng quê. Phá cả 6 ụ tên lửa. Mỗi trạm có một mecha canh gác, trạm giữa có xạ thủ bắn tỉa.",
		"mau_dich": 0.6, "sat_thuong_dich": 0.4,
		"dich": [["co_ban", -720, -780, "tuan_tra"], ["co_dong", 30, 40, "tuan_tra_ban_tia"], ["hang_nang", 720, -780, "tuan_tra"]],
		"u": [["ten_lua", -780, -820], ["ten_lua", -720, -860], ["ten_lua", -40, -30], ["ten_lua", 40, -30], ["ten_lua", 780, -820], ["ten_lua", 720, -860]]},
	{"id": "doi_san", "ten": "Đội săn", "ban_do": "ngoai_o", "bat_dau": [0, 1150], "thuong": 350, "muc_tieu": "ha_het",
		"mo_ta": "Một đội săn Đế Chế đang đi tuần giữa vùng ngoại ô: 3 mecha (có một xạ thủ bắn tỉa chiếu laser) — bị chúng phát hiện là chúng lao vào. 2 mecha nữa rơi xuống khi đợt đầu bị hạ.",
		"mau_dich": 0.7, "sat_thuong_dich": 0.42,
		"dich": [["co_ban", -300, 330, "san"], ["co_ban", 300, 330, "san"], ["co_dong", 0, 0, "san_ban_tia"],
			["hang_nang", 0, 0, "dot2"], ["co_ban", 0, 0, "dot2"]]},
	{"id": "phuc_kich", "ten": "Phục kích", "ban_do": "thanh_pho", "bat_dau": [0, 1150], "thuong": 400, "muc_tieu": "ha_het",
		"mo_ta": "Trinh sát qua thành phố đổ nát, lần lượt tới 3 quảng trường. Mỗi nơi có 2 mecha Đế Chế nấp sau các tòa nhà — chúng chỉ ra tay khi bạn tới gần.",
		"mau_dich": 0.7, "sat_thuong_dich": 0.45,
		"diem_den": [[-750, 820], [0, 0], [750, -820]],
		"dich": [["co_ban", -700, 760, "phuc_kich"], ["co_dong", -800, 780, "phuc_kich"],
			["co_ban", -50, -40, "phuc_kich"], ["ho_tro", 50, -40, "phuc_kich"],
			["hang_nang", 700, -780, "phuc_kich"], ["co_ban", 800, -790, "phuc_kich"]]},
	{"id": "chi_huy", "ten": "Chỉ huy", "ban_do": "thanh_pho", "bat_dau": [0, 650], "thuong": 500, "muc_tieu": "chi_huy",
		"mo_ta": "Mecha chỉ huy Đế Chế đóng ở quảng trường giữa thành phố đổ nát, có 3 hộ vệ và ụ súng canh. Hạ mecha chỉ huy để kết thúc chiến dịch.",
		"mau_dich": 0.75, "sat_thuong_dich": 0.32,
		"dich": [["hang_nang", 0, -40, "chi_huy"], ["co_ban", -70, 40, "tuan_tra"], ["ho_tro", 70, 40, "tuan_tra"], ["co_dong", 150, -150, "tuan_tra_ban_tia"]],
		"u": [["sung_may_doi", -90, 70], ["phao", 85, -70]]},      # quảng trường thành phố trống trải: 2 ụ (sa mạc cũ có 4)
]
const CHIEN_DICH_HOI_SINH := 2          # số lần hồi sinh mỗi nhiệm vụ (hết lượt là thất bại)
const CHIEN_DICH_CHOI_LAI := 0.4        # chơi lại nhiệm vụ đã xong: được bấy nhiêu phần điểm thưởng
## Tầm phát hiện (m) theo kiểu địch; phải nhìn thấy người chơi (không bị nhà che) mới tính là phát hiện.
const CHIEN_DICH_PHAT_HIEN := {"tuan_tra": 380.0, "phuc_kich": 170.0, "san": 450.0}
const CHIEN_DICH_CHI_HUY := {"he_so_mau": 2.5, "p_ne": 0.55, "p_do": 0.3, "hay_lao_chem": 1.6}


## Chỉ số một mecha: loại Cơ bản + chỗ khác của loại + nâng cấp. nut = số nút đã mở ở 3 hướng [giáp, cơ động, hỏa lực].
func chi_so_mecha(loai: String, nut: Array = [0, 0, 0]) -> Dictionary:
	var cs: Dictionary = MECHA.duplicate()
	var lm: Dictionary = LOAI_MECHA.get(loai, LOAI_MECHA["co_ban"])
	cs["he_so_chiem"] = 1.0
	cs["he_so_hoa_luc"] = 1.0
	cs["nhiet_toi_da"] = NHIET["toi_da"]
	cs["he_so_nguoi"] = 1.0
	cs["he_so_hoi_tay_phu"] = 1.0
	cs["so_u_minigun"] = 1
	for k in lm["chi_so"]:
		cs[k] = lm["chi_so"][k]
	cs["mau"] = float(cs["mau"]) * (1.0 + 0.06 * int(nut[0]))
	cs["he_so_toc"] = float(cs["he_so_toc"]) * (1.0 + 0.04 * int(nut[1]))
	cs["nhiet_toi_da"] = float(cs["nhiet_toi_da"]) * (1.0 + 0.08 * int(nut[1]))
	cs["he_so_nguoi"] = float(cs["he_so_nguoi"]) * (1.0 + 0.08 * int(nut[1]))
	cs["cua_so_ne"] = float(CAN_CHIEN["cua_so_ne"]) + float(CAN_CHIEN["nang_cap_ne"]) * int(nut[1])
	cs["cua_so_do"] = float(CAN_CHIEN["cua_so_do"]) + float(CAN_CHIEN["nang_cap_do"]) * int(nut[1])
	cs["he_so_lao_chem"] = 1.0 + float(CAN_CHIEN["lao_chem"]["nang_cap_toc"]) * int(nut[1])
	cs["he_so_hoa_luc"] = float(cs["he_so_hoa_luc"]) * (1.0 + 0.05 * int(nut[2]))
	cs["ty_le"] = lm["ty_le"]
	cs["than"] = lm["than"]
	cs["kha_nang"] = lm["kha_nang"]
	return cs


## Tên mẫu 3D (không đuôi) của một loại mecha theo phe: phe 0 màu xanh, phe 1 màu đỏ.
func ten_mau(loai: String, phe: int) -> String:
	return MAU_THAN[LOAI_MECHA.get(loai, LOAI_MECHA["co_ban"])["than"]][clampi(phe, 0, 1)]

