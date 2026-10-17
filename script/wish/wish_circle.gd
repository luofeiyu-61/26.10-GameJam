extends Node2D
class_name WishCircle

#============================================================
# 祈愿环：太极（中心） + 四象（内环） + 八卦（外环）
#
# 摆位原理：每个 AnimatedSprite2D 用 offset = (0, -r) 把自己摆到圆周上，
#          于是它自身的 rotation 就决定它在圆上的角度（相对各自父节点）。
#          父节点 SiXiang / BaGua 只负责整体缓慢自转（idleRotating）。
#
# 选中表现（已砍掉「聚拢」那套）：
#          xiang_selected / gua_selected 只表示「选中了哪个」；
#          circle_xiang / circle_gua 两个高亮圆用指数插值平滑贴到选中的象 / 卦上，
#          line_taiji_xiang / line_xiang_gua 把线两端掐在圆的边上连起来。
#          具体见文件末尾的「连线」region。
#============================================================

@onready var taiji: AnimatedSprite2D = $taiji

@onready var si_xiang: Node2D = $SiXiang

@onready var xiang11: AnimatedSprite2D = $"SiXiang/11"
@onready var xiang10: AnimatedSprite2D = $"SiXiang/10"
@onready var xiang00: AnimatedSprite2D = $"SiXiang/00"
@onready var xiang01: AnimatedSprite2D = $"SiXiang/01"

@onready var ba_gua: Node2D = $BaGua

@onready var gua111: AnimatedSprite2D = $"BaGua/111"
@onready var gua011: AnimatedSprite2D = $"BaGua/011"
@onready var gua010: AnimatedSprite2D = $"BaGua/010"
@onready var gua001: AnimatedSprite2D = $"BaGua/001"
@onready var gua000: AnimatedSprite2D = $"BaGua/000"
@onready var gua100: AnimatedSprite2D = $"BaGua/100"
@onready var gua101: AnimatedSprite2D = $"BaGua/101"
@onready var gua110: AnimatedSprite2D = $"BaGua/110"





var time:float

@export var w0:float = -0.2
@export var w1:float = 0.1
@export var w2:float = -0.02


#环上元素，顺序 = 圆周上的角度顺序（0°,90°,180°,270° / 0°,45°,…,315°）
#必须在 _ready 里赋值：@onready 变量要等节点就绪后才有值
var xiang :Array[AnimatedSprite2D] = []
var gua :Array[AnimatedSprite2D] = []


var xiang_selected:int=-1
var gua_selected:int=-1


func idleRotating(delta:float):
	taiji.rotate(delta*w0)
	si_xiang.rotate(delta*w1)
	ba_gua.rotate(delta*w2)


#============================================================
# 对外接口：只记「选中了哪个」，具体表现交给末尾的「连线」region
#============================================================

#选中第 index 个卦（0~7）；传 -1 或越界等于取消选中
func selectGua(index:int) -> void:
	gua_selected = index if index >= 0 and index < gua.size() else -1

#取消选中
func clearGua() -> void:
	gua_selected = -1

#选中第 index 个象（0~3）；传 -1 或越界等于取消选中
func selectXiang(index:int) -> void:
	xiang_selected = index if index >= 0 and index < xiang.size() else -1

#取消选中
func clearXiang() -> void:
	xiang_selected = -1


#============================================================

func _ready() -> void:
	xiang.assign([xiang11, xiang10, xiang00, xiang01])
	gua.assign([gua111, gua011, gua010, gua001, gua000, gua100, gua101, gua110])

	updateSprites()


func _process(delta: float) -> void:
	idleRotating(delta)
	_refreshLines(delta)
		



#region 爻搓卦判断
var yaos:=[]
var yaos2gua:=[]

func addYao(index:int,yy:bool):
	if yaos.size()<3:
		yaos.append(index)
		yaos2gua.append(1 if yy else 0)
		updateSprites()
	

func delYao(index:int):
	if index in yaos:
		yaos2gua.remove_at(yaos.find(index))
		yaos.erase(index)
		updateSprites()

func clearYao():
	yaos2gua.clear()
	yaos.clear()
	updateSprites()


signal nao_gua_sprite_change(gua_:ENUMS.Gua)

func getPatternsFromYaos()->Array[int]:
	#gua111, gua011, gua010, gua001, gua000, gua100, gua101, gua110
	#[xiang11, xiang10, xiang00, xiang01]
	var result :Array[int]=[-1,-1,-1]
	if yaos2gua.size()>=1:
		result[0]= yaos2gua[0]
	if yaos2gua.size()>=2:
		match str(yaos2gua[0])+str(yaos2gua[1]):
			"11":result[1]=0
			"10":result[1]=1
			"00":result[1]=2
			"01":result[1]=3
	if yaos2gua.size()==3:
		var gua___:ENUMS.Gua
		match str(yaos2gua[0])+str(yaos2gua[1])+str(yaos2gua[2]):
			"111":
				result[2]=0
				gua___=ENUMS.Gua.Qian
			"011":
				result[2]=1
				gua___=ENUMS.Gua.Xun
			"010":
				result[2]=2
				gua___=ENUMS.Gua.Kan
			"001":
				result[2]=3
				gua___=ENUMS.Gua.Gen
			"000":
				result[2]=4
				gua___=ENUMS.Gua.Kun
			"100":
				result[2]=5
				gua___=ENUMS.Gua.Zhen
			"101":
				result[2]=6
				gua___=ENUMS.Gua.Li
			"110":
				result[2]=7
				gua___=ENUMS.Gua.Dui
				
		nao_gua_sprite_change.emit(gua___)
	else:
		nao_gua_sprite_change.emit(ENUMS.Gua.NONE)
	
	return result

func updateSprites():
	#图案阶段
	var stage := yaos.size()
	
	var statue := getPatternsFromYaos()
	xiang_selected=statue[1]
	gua_selected = statue[2]
	match stage:
		0:
			taiji.modulate=Color(1.0, 1.0, 1.0, 0.6)
			ba_gua.modulate=Color(1.0, 1.0, 1.0, 0.6)
			si_xiang.modulate=Color(1.0, 1.0, 1.0, 0.6)
			
		1:
			taiji.modulate=Color(1.0, 1.0, 1.0, 1)
			si_xiang.modulate=Color(1.0, 1.0, 1.0, 0.6)
			
		2:
			si_xiang.modulate=Color(1.0, 1.0, 1.0, 1)
			ba_gua.modulate=Color(1.0, 1.0, 1.0, 0.6)
			
		3:
			ba_gua.modulate=Color(1.0, 1.0, 1.0, 1)
			







	

#endregion


#region 连线：太极 → 选中的象 → 选中的卦
#circle_xiang 贴到选中的象、circle_gua 贴到选中的卦。
#选中时圆出现并从太极平滑滑出；取消选中时不马上消失，而是**平滑缩回太极**，
#回到太极之后才隐藏（见下面 _refreshLines 的出场/退场逻辑）。
#line_taiji_xiang 连 太极 → circle_xiang；line_xiang_gua 连 circle_xiang → circle_gua，
#两条线的两端都掐在圆的「边上」，而不是连到圆心。
#两条线的显隐**只按几何**（两个圆心离得比半径之和大才画），不跟随「选中与否」的开关，
#所以退场过程中线会跟着圆一起收，不会突然消失。
const LINE_WIDTH := 6.0
const LINE_COLOR := Color(0.917647, 0.850980, 0.627451, 0.5)   #纸黄色，alpha 0.5

#圆的跟随速度：越大越快。用指数插值 1-exp(-speed*dt)，与帧率无关
@export var follow_speed: float = 12.0
#退场（缩回太极）时的速度。比 follow_speed 慢，好让「缩回去」的过程看得清；
#太快的话 500→0 只要几帧，看起来就跟直接消失一样。想更慢/更快直接调这个值
#（比如 2.0 = 更慢更明显，8.0 = 更干脆）。
@export var return_speed: float = 16.0

#归位判定：离太极这么近就算「已经回到太极」，这时才把圆隐藏
const RETURN_HIDE_EPS := 1.0

@onready var line_taiji_xiang: Line2D = _ensureLine("line_taiji_xiang")
@onready var line_xiang_gua: Line2D = _ensureLine("line_xiang_gua")

#端点的高亮圆：和线同色，排在线的后面 → 画在线之上、在卦/象图案之下
@onready var circle_xiang: Polygon2D = _ensureCircle("circle_xiang")
@onready var circle_gua: Polygon2D = _ensureCircle("circle_gua")


#取 sprite「画出来的位置」。
#注意：这些 sprite 是靠自身 offset 摆到圆周上的（position 一直是 0），
#所以不能用 global_position，必须把 offset 用它的全局变换换算出去。
func _spriteVisualPos(s:AnimatedSprite2D) -> Vector2:
	return s.get_global_transform() * s.offset


#场景里没有这根线就现场补一个（防呆）。补出来的会排在最后，所以用 z_index 压到最底。
func _ensureLine(node_name:String) -> Line2D:
	var l := get_node_or_null(node_name) as Line2D
	if l != null:
		return l
	l = Line2D.new()
	l.name = node_name
	l.width = LINE_WIDTH
	l.default_color = LINE_COLOR
	l.antialiased = true
	l.z_index = -1
	add_child(l)
	return l


#端点圆的半径（本地单位）。卦/象的 sprite 是 7*10=70 本地宽，半径 35 就是正好一样大。
const CIRCLE_RADIUS := 40.0


#场景里没有这个圆就现场补一个（防呆）。多边形按 CIRCLE_RADIUS 生成。
func _ensureCircle(node_name:String) -> Polygon2D:
	var c := get_node_or_null(node_name) as Polygon2D
	if c == null:
		c = Polygon2D.new()
		c.name = node_name
		c.z_index = -1
		c.color = LINE_COLOR
		add_child(c)
	if c.polygon.is_empty():
		var pts := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			pts.append(Vector2(cos(a), sin(a)) * CIRCLE_RADIUS)
		c.polygon = pts
	return c


var _style_synced := false

#让圆跟着各自那条线走（颜色 + 层级同源，改线的颜色就会一起改）
func _syncStyleOnce() -> void:
	if _style_synced:
		return
	_style_synced = true
	if line_taiji_xiang != null and circle_xiang != null:
		circle_xiang.color = line_taiji_xiang.default_color
		circle_xiang.z_index = line_taiji_xiang.z_index
	if line_xiang_gua != null and circle_gua != null:
		circle_gua.color = line_xiang_gua.default_color
		circle_gua.z_index = line_xiang_gua.z_index


#每帧刷新：两个圆平滑贴到目标位置，两条线把两端掐在圆的边上
func _refreshLines(delta: float) -> void:
	if line_taiji_xiang == null or line_xiang_gua == null:
		return
	_syncStyleOnce()

	var p_taiji := to_local(_spriteVisualPos(taiji))

	var has_xiang := xiang_selected >= 0 and xiang_selected < xiang.size()
	var has_gua := gua_selected >= 0 and gua_selected < gua.size()

	#目标位置：选中了就跟到那个象/卦上；没选中就回到太极
	var t_xiang := p_taiji
	if has_xiang:
		t_xiang = to_local(_spriteVisualPos(xiang[xiang_selected]))
	var t_gua := p_taiji
	if has_gua:
		t_gua = to_local(_spriteVisualPos(gua[gua_selected]))

	#指数插值靠近：每帧只走「剩余距离」的一个固定比例。
	#1-exp(-speed*dt) 与帧率无关；而且它天然满足「接上」——
	#任何时候改目标都是从当前位置继续趋近，最终一定收敛到最后一次的目标。
	#往前贴用 follow_speed；退回太极用更慢的 return_speed（否则快到看不见）。
	var dt := maxf(delta, 0.0)
	circle_xiang.position = _approach(circle_xiang.position, t_xiang,
			1.0 - exp(-(follow_speed if has_xiang else return_speed) * dt))
	circle_gua.position = _approach(circle_gua.position, t_gua,
			1.0 - exp(-(follow_speed if has_gua else return_speed) * dt))

	#出场：一被选中就出现。
	#退场：**保持可见**，先插值缩回太极，确实回到太极之后才隐藏 ——
	#      于是 stage3→2 看到的是 circle_gua 平滑退回，而不是啪地消失。
	#      （中途又选中就直接从当前位置往外走，不会闪断。）
	if has_xiang:
		circle_xiang.visible = true
	elif circle_xiang.position.distance_to(p_taiji) <= RETURN_HIDE_EPS:
		circle_xiang.visible = false

	if has_gua:
		circle_gua.visible = true
	elif circle_gua.position.distance_to(p_taiji) <= RETURN_HIDE_EPS:
		circle_gua.visible = false

	var r_xiang := _circleRadius(circle_xiang)
	var r_gua := _circleRadius(circle_gua)

	#线1：太极 → circle_xiang 的圆边（太极那一端不掐）
	var d1 := circle_xiang.position - p_taiji
	line_taiji_xiang.visible = d1.length() > r_xiang + 0.5
	if line_taiji_xiang.visible:
		line_taiji_xiang.points = PackedVector2Array([
			p_taiji,
			circle_xiang.position - d1.normalized() * r_xiang,
		])

	#线2：circle_xiang 的圆边 → circle_gua 的圆边（两端都掐）
	#不按「卦有没有被选中」来隐藏，只看几何：两个圆离得比两个半径之和还远才画。
	#于是 stage3→2 时 circle_gua 一边缩回太极、这条线一边跟着收短，不会突然消失；
	#stage0/1 两个圆都在太极（d2=0）自然就不画了。
	#代价：stage2 时 circle_gua 缩在太极，这条线正好压在 line1 的同一段射线上，
	#      那段 alpha 会 0.5 叠成 0.75（看起来中心附近略亮一点）。
	var d2 := circle_gua.position - circle_xiang.position
	line_xiang_gua.visible = d2.length() > r_xiang + r_gua + 0.5
	if line_xiang_gua.visible:
		var dir2 := d2.normalized()
		line_xiang_gua.points = PackedVector2Array([
			circle_xiang.position + dir2 * r_xiang,
			circle_gua.position - dir2 * r_gua,
		])


#指数插值的一步：够近就直接对上，免得永远留一个极小残差
func _approach(cur: Vector2, target: Vector2, e: float) -> Vector2:
	if cur.distance_to(target) < 0.01:
		return target
	return cur.lerp(target, e)


#圆的实际半径（把节点自身的缩放也算上，方便在检查器里直接缩放圆）
func _circleRadius(c: Polygon2D) -> float:
	var m := 0.0
	for v in c.polygon:
		m = maxf(m, v.length())
	return m * absf(c.scale.x)

#endregion
