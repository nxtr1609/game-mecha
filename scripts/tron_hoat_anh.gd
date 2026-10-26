class_name TronHoatAnh
extends RefCounted
## Bộ trộn hoạt ảnh tự viết (thay AnimationTree) cho dễ chia lớp:
## - mau(ten, t): lấy tư thế của một clip ở thời điểm t: {xương: Quaternion} + vị trí hông.
## - phu(goc, tren, w, mat_na): phủ tư thế "tren" lên "goc" với trọng số w, chỉ ở các xương trong mặt nạ.
## - ap(tt): đặt tư thế vào Skeleton3D.
## Xương nào clip không có (vd. dáng đi không có tay) thì giữ nguyên tư thế bên dưới.

const THAN_DUOI := ["Hips", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes", "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToes"]
const COT_SONG := ["Spine", "Chest", "UpperChest", "Neck", "Head"]
const TAY_TRAI := ["LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand"]
const TAY_PHAI := ["RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand"]

var sk: Skeleton3D
var lib: AnimationLibrary
var _tr := {}            # clip -> {xương: chỉ số track xoay, "_p": chỉ số track vị trí hông}
var _xuong := {}         # tên -> chỉ số xương


func _init(skel: Skeleton3D, thu_vien: AnimationLibrary) -> void:
	sk = skel
	lib = thu_vien
	for i in sk.get_bone_count():
		_xuong[sk.get_bone_name(i)] = i
	for ten in lib.get_animation_list():
		var a := lib.get_animation(ten)
		var m := {}
		for k in a.get_track_count():
			var xuong := String(a.track_get_path(k)).get_slice(":", 1)
			if a.track_get_type(k) == Animation.TYPE_ROTATION_3D:
				m[xuong] = k
			elif a.track_get_type(k) == Animation.TYPE_POSITION_3D and xuong == "Hips":
				m["_p"] = k
		_tr[ten] = m


func co(ten: String) -> bool:
	return lib.has_animation(ten)


func dai(ten: String) -> float:
	return lib.get_animation(ten).length


func lap(ten: String) -> bool:
	return lib.get_animation(ten).loop_mode != Animation.LOOP_NONE


func meta(ten: String, khoa: String, mac_dinh: Variant) -> Variant:
	var a := lib.get_animation(ten)
	return a.get_meta(khoa, mac_dinh)


## Tư thế của clip ở thời điểm t (clip lặp thì quấn vòng, không lặp thì dừng ở cuối).
func mau(ten: String, t: float) -> Dictionary:
	var a := lib.get_animation(ten)
	t = fposmod(t, a.length) if a.loop_mode != Animation.LOOP_NONE else clampf(t, 0.0, a.length)
	var q := {}
	var m: Dictionary = _tr[ten]
	for x in m:
		if x == "_p":
			continue
		q[x] = a.rotation_track_interpolate(m[x], t)
	var tt := {"q": q}
	if m.has("_p"):
		tt["p"] = a.position_track_interpolate(m["_p"], t)
	return tt


## Phủ "tren" lên "goc" (trọng số w) ở các xương trong mat_na (rỗng = mọi xương). Trả về tư thế mới.
func phu(goc: Dictionary, tren: Dictionary, w: float, mat_na: Array = [], co_hong := true) -> Dictionary:
	if w <= 0.001:
		return goc
	var q: Dictionary = (goc["q"] as Dictionary).duplicate()
	var qt: Dictionary = tren["q"]
	for x in qt:
		if not mat_na.is_empty() and not mat_na.has(x):
			continue
		q[x] = (q[x] as Quaternion).slerp(qt[x], w) if q.has(x) else qt[x]
	var kq := {"q": q}
	var p0: Variant = goc.get("p")
	var p1: Variant = tren.get("p")
	if co_hong and p1 != null and (mat_na.is_empty() or mat_na.has("Hips")):
		kq["p"] = (p0 as Vector3).lerp(p1, w) if p0 != null else p1
	else:
		kq["p"] = p0
	return kq


func ap(tt: Dictionary) -> void:
	var q: Dictionary = tt["q"]
	for x in q:
		var i: int = _xuong.get(x, -1)
		if i >= 0:
			sk.set_bone_pose_rotation(i, q[x])
	if tt.get("p") != null:
		sk.set_bone_pose_position(_xuong["Hips"], tt["p"])
