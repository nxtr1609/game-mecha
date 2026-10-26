class_name LuotTanCong
extends RefCounted
## Giới hạn số mecha địch tấn công cùng lúc (chiến dịch, theo độ khó CanBang.DO_KHO[..]["tan_cong_cung_luc"]).
## Bot đã phát hiện người chơi thì mỗi khung hình xin lượt (duoc_tan_cong); đủ số rồi thì con khác đứng xa chờ.
## Vừa bị người chơi bắn trúng (ep) thì luôn được đánh trả. Con nào thôi xin lượt quá 1 giây (mất dấu, bị hạ) thì nhường chỗ.

var so_toi_da := 2
var _dang := {}                    # mecha đang tấn công -> lúc xin lượt gần nhất


func duoc_tan_cong(m: Mecha, ep: bool) -> bool:
	var bay := Mecha.gio()
	for k in _dang.keys():
		if not is_instance_valid(k) or not (k as Mecha).song or bay - float(_dang[k]) > 1.0:
			_dang.erase(k)
	if _dang.has(m) or ep or _dang.size() < so_toi_da:
		_dang[m] = bay
		return true
	return false
