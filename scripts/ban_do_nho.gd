class_name BanDoNho
extends Control
## Bản đồ nhỏ góc trên bên phải: bạn luôn ở giữa, bắc ở trên (phía địch), thấy khoảng 650 m quanh bạn.
## Cùng ảnh nền và ký hiệu với bản đồ lớn (BanDoMat.ve). Ẩn khi đang mở bản đồ lớn hoặc đang chọn điểm hồi sinh.

const CANH := 230.0
const TAM_NHIN := 650.0          # mét từ tâm tới mép bản đồ nhỏ

var ban_do: Node
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size = Vector2(CANH, CANH)
	_font = GiaoDien.font()


func _process(_dt: float) -> void:
	position = Vector2(get_viewport_rect().size.x - CANH - 24.0, 110.0)   # dưới thanh máu tàu sân bay địch
	size = Vector2(CANH, CANH)
	visible = ban_do != null and is_instance_valid(ban_do.nguoi_choi) and ban_do.anh_ban_do != null \
		and not (ban_do.ban_do_mat and ban_do.ban_do_mat.visible) and ban_do.hoi_sinh_con <= 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var m: Mecha = ban_do.nguoi_choi
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.05, 0.8))
	BanDoMat.ve(self, ban_do, Rect2(Vector2.ZERO, size), Vector2(m.global_position.x, m.global_position.z), CANH * 0.5 / TAM_NHIN, false, _font)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.65, 0.85, 0.9), false, 2.0)
	BanDoMat._chu(self, _font, Vector2(CANH * 0.5, 14), tr("▲ địch"), 11, Color(1, 0.6, 0.5), true)
	var wp := VeBieuTuong.rong_nut(_font, "ban_do", 0.42)
	VeBieuTuong.nut(self, _font, "ban_do", Vector2(8 + wp * 0.5, CANH - 13), 0.42)
	BanDoMat._chu(self, _font, Vector2(14 + wp, CANH - 8), tr("Bản đồ"), 12, Color(1, 1, 1, 0.75))
