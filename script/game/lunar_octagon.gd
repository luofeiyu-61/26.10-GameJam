@tool
extends Node2D
## 月历里的「正八边形框」：外八边形 + 内八边形 + 对应顶点之间的连线。
##
## 几何全在 _draw() 里算，尺寸用「边到中心的距离」表示：
##   · outer_apothem = 10  → 每条边离中心 10 个单位
##   · inner_apothem = 7.5 → 内圈每条边离中心 7.5 个单位
## 1 个单位 = unit_px 像素（默认 18 → 外圈边长到中心 180px，整宽 360px）。
##
## 顶点从 start_angle_deg 开始（默认 -90 = 正上方），共 vertices 个，默认 8。
## 挂点建议放在父节点（那一层 ColorRect）的中点，脚本不会自己改 position。

@export var outer_apothem: float = 10.0:
	set(v):
		outer_apothem = v
		queue_redraw()
@export var inner_apothem: float = 7.5:
	set(v):
		inner_apothem = v
		queue_redraw()
@export var unit_px: float = 18.0:
	set(v):
		unit_px = v
		queue_redraw()
@export_range(3, 32, 1) var vertices: int = 8:
	set(v):
		vertices = maxi(v, 3)
		queue_redraw()
@export var start_angle_deg: float = -90.0:
	set(v):
		start_angle_deg = v
		queue_redraw()
@export var line_color: Color = Color(0.95, 0.89, 0.7, 0.9):
	set(v):
		line_color = v
		queue_redraw()
@export var line_width: float = 2.0:
	set(v):
		line_width = v
		queue_redraw()
@export var show_outer: bool = true:
	set(v):
		show_outer = v
		queue_redraw()
@export var show_inner: bool = true:
	set(v):
		show_inner = v
		queue_redraw()
@export var show_spokes: bool = true:
	set(v):
		show_spokes = v
		queue_redraw()
@export var antialiased: bool = true:
	set(v):
		antialiased = v
		queue_redraw()


func _draw() -> void:
	var n: int = maxi(vertices, 3)
	var outer: PackedVector2Array = _ringPoints(outer_apothem, n)
	var inner: PackedVector2Array = _ringPoints(inner_apothem, n)

	if show_outer and outer.size() > 0:
		draw_polyline(_closed(outer), line_color, line_width, antialiased)
	if show_inner and inner.size() > 0:
		draw_polyline(_closed(inner), line_color, line_width, antialiased)
	if show_spokes and outer.size() == inner.size():
		for i in n:
			draw_line(inner[i], outer[i], line_color, line_width, antialiased)


#「边到中心 = apothem」的正 n 边形顶点：外接半径 = apothem / cos(pi/n)
func _ringPoints(apothem: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if apothem <= 0.0:
		return pts
	var radius: float = apothem * unit_px / cos(PI / float(n))
	for i in n:
		var a: float = deg_to_rad(start_angle_deg) + TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


#首点补到末尾，draw_polyline 才会闭合成一圈
func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out
