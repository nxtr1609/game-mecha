extends Node
## Phím điều khiển (autoload "Phim"). Mỗi hành động gán đúng một phím hoặc một nút chuột.
## Người chơi đổi phím ở Cài đặt → Điều khiển; phím đã đổi lưu ở user://cai_dat.cfg (mục "phim"),
## dùng chung mọi bản lưu. Cận chiến khi mecha địch đang khóa trong tầm = lao chém.

const DUONG_CAI_DAT := "user://cai_dat.cfg"

## Phím mặc định: [loại, mã]. loại "k" = bàn phím (physical keycode), "m" = nút chuột.
const MAC_DINH := {
	"di_toi": ["k", KEY_W],
	"di_lui": ["k", KEY_S],
	"di_trai": ["k", KEY_A],
	"di_phai": ["k", KEY_D],
	"lao": ["k", KEY_SHIFT],             # bấm: bật lao theo hướng đang đi; giữ: lướt nhanh liên tục (đều tốn nhiệt); bị lao chém: bấm đúng lúc để né
	"bay": ["k", KEY_SPACE],             # giữ: bay lên (tốn nhiệt)
	"doi_che_do": ["k", KEY_CTRL],       # dưới đất: lướt / chạy bộ; đang bay: giữ độ cao
	"roi_nhanh": ["k", KEY_T],           # đang bay: rơi nhanh xuống
	"ban_phai": ["m", MOUSE_BUTTON_LEFT],    # vũ khí tay phải
	"ban_trai": ["m", MOUSE_BUTTON_RIGHT],   # vũ khí tay trái
	"tay_phu_trai": ["k", KEY_Q],
	"tay_phu_phai": ["k", KEY_E],
	"phao_nhiet": ["k", KEY_X],
	"can_chien": ["k", KEY_F],           # chém; địch đang khóa trong tầm: lao chém; bị lao chém: bấm đúng lúc để đỡ
	"trang_bi": ["k", KEY_B],            # bảng trang bị
	"ban_do": ["k", KEY_M],              # bản đồ chiến trường
	"ho_tro_1": ["k", KEY_1],            # gọi pháo kích (chế độ cứ điểm)
	"ho_tro_2": ["k", KEY_2],            # thả tiếp tế
	"ho_tro_3": ["k", KEY_3],            # quét radar
	"ho_tro_4": ["k", KEY_4],            # thả mecha tiếp viện
}
## Thứ tự và tên hiện ở màn đổi phím (tên là khóa dịch).
const DANH_SACH := [
	["di_toi", "Đi tới"], ["di_lui", "Đi lùi"], ["di_trai", "Sang trái"], ["di_phai", "Sang phải"],
	["lao", "Bật lao (giữ: lướt nhanh) / né đòn"], ["bay", "Bay lên (giữ)"], ["doi_che_do", "Giữ độ cao / chạy bộ"], ["roi_nhanh", "Rơi nhanh"],
	["ban_phai", "Vũ khí phải"], ["ban_trai", "Vũ khí trái"], ["tay_phu_trai", "Tay phụ trái"], ["tay_phu_phai", "Tay phụ phải"],
	["phao_nhiet", "Pháo nhiệt"], ["can_chien", "Cận chiến / lao chém / đỡ đòn"], ["trang_bi", "Bảng trang bị"], ["ban_do", "Bản đồ"],
	["ho_tro_1", "Hỗ trợ 1: pháo kích"], ["ho_tro_2", "Hỗ trợ 2: tiếp tế"], ["ho_tro_3", "Hỗ trợ 3: radar"], ["ho_tro_4", "Hỗ trợ 4: tiếp viện"],
]

var gan := {}                  # hành động -> [loại, mã] đang dùng


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("tha_chuot"):
		InputMap.add_action("tha_chuot")
		var esc := InputEventKey.new()
		esc.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("tha_chuot", esc)
	doc()


## Đọc phím đã đổi (nếu có) rồi gán vào InputMap.
func doc() -> void:
	gan = {}
	for a in MAC_DINH:
		gan[a] = (MAC_DINH[a] as Array).duplicate()
	if not _tu_kiem_tra():
		var c := ConfigFile.new()
		if c.load(DUONG_CAI_DAT) == OK and c.has_section("phim"):
			for a in c.get_section_keys("phim"):
				var v: Variant = c.get_value("phim", a)
				if gan.has(a) and v is Array and (v as Array).size() == 2:
					gan[a] = [String(v[0]), int(v[1])]
	ap_dung()


func luu() -> void:
	if _tu_kiem_tra():
		return
	var c := ConfigFile.new()
	c.load(DUONG_CAI_DAT)
	if c.has_section("phim"):
		c.erase_section("phim")
	for a in gan:
		if gan[a] != MAC_DINH[a]:
			c.set_value("phim", a, gan[a])
	c.save(DUONG_CAI_DAT)


func _tu_kiem_tra() -> bool:
	var s := " ".join(OS.get_cmdline_user_args())
	return "--autotest" in s or "--thu_menu" in s or "--thu_chien_dich" in s or "--chup_huong_dan" in s


func ap_dung() -> void:
	for a in gan:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
		else:
			InputMap.add_action(a)
		InputMap.action_add_event(a, _su_kien(gan[a]))


static func _su_kien(g: Array) -> InputEvent:
	if g[0] == "m":
		var mb := InputEventMouseButton.new()
		mb.button_index = int(g[1]) as MouseButton
		return mb
	var ev := InputEventKey.new()
	ev.physical_keycode = int(g[1]) as Key
	return ev


## Đổi phím cho một hành động. Phím đó đang thuộc hành động khác thì hai bên hoán đổi.
## Trả về tên hành động bị hoán đổi ("" nếu không có).
func doi(hanh_dong: String, g: Array) -> String:
	var cu: Array = gan[hanh_dong]
	var bi_doi := ""
	for a in gan:
		if a != hanh_dong and gan[a][0] == g[0] and int(gan[a][1]) == int(g[1]):
			gan[a] = cu.duplicate()
			bi_doi = a
	gan[hanh_dong] = g.duplicate()
	ap_dung()
	luu()
	return bi_doi


func mac_dinh_tat_ca() -> void:
	for a in MAC_DINH:
		gan[a] = (MAC_DINH[a] as Array).duplicate()
	ap_dung()
	luu()


## Biến một sự kiện bấm phím / chuột thành [loại, mã] (null nếu không gán được).
static func tu_su_kien(e: InputEvent) -> Variant:
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		var k := (e as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or k == KEY_NONE:
			return null
		return ["k", int(k)]
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		var b := (e as InputEventMouseButton).button_index
		if b in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
			return ["m", int(b)]
	return null


## Nút chuột của hành động (MOUSE_BUTTON_LEFT / RIGHT / ...), 0 nếu là phím.
func nut_chuot(hanh_dong: String) -> int:
	var g: Array = gan.get(hanh_dong, ["k", 0])
	return int(g[1]) if g[0] == "m" else 0


## Tên ngắn để hiện (đã dịch): "Q", "Shift", "Chuột trái"...
func ten(hanh_dong: String) -> String:
	return ten_gan(gan.get(hanh_dong, ["k", 0]))


static func ten_gan(g: Array) -> String:
	if g[0] == "m":
		match int(g[1]):
			MOUSE_BUTTON_LEFT:
				return String(TranslationServer.translate("Chuột trái"))
			MOUSE_BUTTON_RIGHT:
				return String(TranslationServer.translate("Chuột phải"))
			MOUSE_BUTTON_MIDDLE:
				return String(TranslationServer.translate("Chuột giữa"))
			_:
				return String(TranslationServer.translate("Chuột %d")) % int(g[1])
	var k := int(g[1])
	match k:
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_SPACE:
			return "Space"
		KEY_ALT:
			return "Alt"
		KEY_TAB:
			return "Tab"
	return OS.get_keycode_string(k)

