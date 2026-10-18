extends Node2D
class_name SacrificePie
## 献祭比例饼图（挂在 Sacrifice_window/SacrificeWindow 下，圆心 = SacrificeWindow 中心）
##
## 【一】图形部分是**场景里的节点**，可以直接在检查器里调：
##   SacrificePie/
##     ├── Slices/people、animal、grain   Polygon2D —— 三个扇区（颜色/透明度/材质都在这里改）
##     ├── Outline                        Line2D    —— 外圈（颜色、线宽、抗锯齿）
##     ├── Dividers/people、animal、grain  Line2D    —— 三根分隔线（同上）
##     ├── sacrifiys                      Node2D    —— Sprite2D 原型（运行时被隐藏，只当模板）：人 / 谷物1 / 谷物2 / 谷物堆 / 猪 / 羊 / 牛
##     └── Scatter                        Node2D    —— 运行时生成，装撒出去的精灵
##   脚本只负责**更新这些节点的几何**（polygon / points），不会覆盖你调好的颜色和线宽。
##
## 【二】几何规则
##   · 三个扇区角度 = TAU * ratio_i / (people + animal + grain)
##   · 半径 = max_radius * total_ratio；三者全 0 但 total>0 时只显示外圈
##
## 【三】散点规则
##   · 数量 ∝ 扇区面积；`sprites_at_full_circle` 是「total=1 且整圆只属一类」时的数量
##   · 精灵**放下就不再移动**；中点跑出饼图、或该类超额时才卸载
##   · 粮食用「谷物1 / 谷物2」随机；`grain_ratio>=50%` 且 `total_ratio>=40%` 时谷物堆也加入随机池
##     （开关切换时只换已有谷物的贴图，位置不变）
##   · 所有「在内/在外」判定**只按精灵中点**（尺寸只用于算最小间距）
##   · 因为只判中点，扇形的「有效范围」每侧再往里收 `sector_inset_deg` 度、离圆心留 `min_radius_ratio` 的空档，
##     避免图标贴着边界时一半露在隔壁扇区/圆外

#============== 几何参数（形状）==============
#半径上限（total_ratio = 1 时的半径，单位像素）
@export var max_radius: float = 140.0
#起始角（度）：-90 = 从正上方开始，顺时针铺开
@export var start_angle_deg: float = -90.0
#圆的细分（影响扇区边缘和外圈的平滑度）
@export_range(8, 360, 1) var segments_per_circle: int = 96
#三个比例都是 0 时，是否还显示外圈（提示 total 撑开的半径）
@export var show_ring_when_empty: bool = true
#是否显示外圈
@export var show_outline: bool = true
#是否显示三根分隔线
@export var show_dividers: bool = true

#============== 散点精灵 ==============
#原型容器节点名；找不到时按 res://assets/pictures/ 下的贴图兜底
@export var prototypes_name: String = "sacrifiys"
#把原型节点藏起来（只当模板用）
@export var hide_prototypes: bool = true
#total_ratio = 1、且整圆都属同一类时的精灵数量（其余按扇区面积等比缩放）
#按现在这套贴图缩放（人 45px / 猪牛 51px / 羊 61px / 粮 31px）实测：36 是「很满但不糊」的值
@export_range(0, 400, 1) var sprites_at_full_circle: int = 36
#精灵生成时圆心到精灵中心的距离上限系数（再按精灵半径往里收，保证不戳出饼图）
@export_range(0.1, 1.0, 0.01) var scatter_margin: float = 0.86
#最小间距系数：间距 = 精灵渲染尺寸 × 该系数
@export_range(0.2, 2.0, 0.05) var min_separation_scale: float = 0.75
#扇形判定的「内缩角」：判定和生成都用「真实扇形每侧各收这么多度」，
#这样只判中点的精灵也不会贴在扇区/圆边上露半个出去（太窄的扇形会自动按比例收）
@export_range(0.0, 30.0, 0.5) var sector_inset_deg: float = 6.0
#离圆心最近的距离比例：精灵不会生成在这么近的地方（0.12 = 半径的 12% 以内不落点）
@export_range(0.0, 0.6, 0.01) var min_radius_ratio: float = 0.12
#找不到原型时，用兜底贴图创建的精灵目标尺寸（像素）
@export var fallback_sprite_size: float = 18.0
#调试用固定随机种子（0 = 每次随机）
@export var scatter_seed: int = 0

#当前比例
var _ratio_people: float = 0.0
var _ratio_animal: float = 0.0
var _ratio_grain: float = 0.0
var _ratio_total: float = 0.0

#图形节点
@onready var _slices_root: Node2D = get_node_or_null("Slices") as Node2D
@onready var _outline: Line2D = get_node_or_null("Outline") as Line2D
@onready var _dividers_root: Node2D = get_node_or_null("Dividers") as Node2D

#散点运行时状态
var _scatter: Node2D = null
var _protos: Dictionary = {}        # kind -> Sprite2D（模板）
var _proto_box: Dictionary = {}     # kind -> Vector2（渲染尺寸，含缩放）
var _items: Array = []              # Array[Item]
var _rng := RandomNumberGenerator.new()
var _rng_seeded: bool = false
var _warned_no_proto: bool = false
var _grain_lock_state: int = -1      # 谷物堆开关：-1 未知 / 0 关 / 1 开

const GROUP_OF := {
	"people": "people",
	"grain1": "grain",
	"grain2": "grain",
	"grain_pile": "grain",
	"pig": "animal",
	"sheep": "animal",
	"cow": "animal",
}
const GROUPS := ["people", "animal", "grain"]
#贴图文件名关键字 → kind（按顺序匹配；「谷物堆」必须排在「谷物」相关之前）
const TEX_KIND := [
	["人", "people"],
	["谷物堆", "grain_pile"],
	["谷物1", "grain1"],
	["谷物2", "grain2"],
	["猪", "pig"],
	["羊", "sheep"],
	["牛", "cow"],
]
#粮（旧图标）也已不再使用：故意不放进 TEX_KIND，避免场景里留着的「粮」被当成原型


#单个散点：位置在「放下那一刻」确定，之后永不改写
class Item:
	var node: Sprite2D
	var kind: String        # people / grain1 / grain2 / grain_pile / pig / sheep / cow
	var group: String       # people / grain / animal
	var pos: Vector2        # 饼图本地坐标


func _ready() -> void:
	_recenter()
	var p := get_parent()
	if p is Control and not p.resized.is_connected(_recenter):
		p.resized.connect(_recenter)
	_prepareScatter()
	_updateShapeNodes()
	_updateScatter()


func _recenter() -> void:
	var p := get_parent()
	if p is Control:
		position = (p as Control).size * 0.5


#三个比例 + 总量（都是 0~1 的比例）
func setRatios(people_ratio: float, animal_ratio: float, grain_ratio: float, total_ratio: float) -> void:
	_ratio_people = maxf(people_ratio, 0.0)
	_ratio_animal = maxf(animal_ratio, 0.0)
	_ratio_grain = maxf(grain_ratio, 0.0)
	_ratio_total = clampf(total_ratio, 0.0, 1.0)
	_updateShapeNodes()
	_updateScatter()


#============================================================
# 一、更新图形节点（只改几何，不改颜色/线宽）
#============================================================
func _groupRatios() -> Array[float]:
	return [_ratio_people, _ratio_animal, _ratio_grain]


func _updateShapeNodes() -> void:
	var radius: float = max_radius * _ratio_total
	var vals := _groupRatios()
	var total: float = vals[0] + vals[1] + vals[2]

	#先全部隐藏，再按需要打开
	for i in 3:
		var poly := _sliceAt(i)
		if poly != null:
			poly.visible = false
		var div := _dividerAt(i)
		if div != null:
			div.visible = false
	if _outline != null:
		_outline.visible = false

	if radius <= 0.5:
		return

	#三比例全 0：只留外圈
	if total <= 0.000001:
		if show_ring_when_empty and show_outline and _outline != null:
			_setCircle(_outline, radius)
			_outline.visible = true
		return

	var ang: float = deg_to_rad(start_angle_deg)
	for i in 3:
		var span: float = TAU * vals[i] / total
		if span > 0.000001:
			var slice_node := _sliceAt(i)
			if slice_node != null:
				_setSlice(slice_node, ang, span, radius)
				slice_node.visible = true
			if show_dividers:
				var div_node := _dividerAt(i)
				if div_node != null:
					_setDivider(div_node, ang, radius)
					div_node.visible = true
		ang += span

	if show_outline and _outline != null:
		_setCircle(_outline, radius)
		_outline.visible = true


func _sliceAt(i: int) -> Polygon2D:
	if _slices_root == null:
		return null
	return _slices_root.get_node_or_null(GROUPS[i]) as Polygon2D


func _dividerAt(i: int) -> Line2D:
	if _dividers_root == null:
		return null
	return _dividers_root.get_node_or_null(GROUPS[i]) as Line2D


#一段扇形 → Polygon2D 的 polygon（圆心 + 圆弧）
func _setSlice(poly: Polygon2D, from_angle: float, span: float, radius: float) -> void:
	var steps: int = maxi(2, int(ceil(span / TAU * float(segments_per_circle))))
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for s in steps + 1:
		var a: float = from_angle + span * float(s) / float(steps)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts


#半径 R 的圆 → Line2D 的 points（closed=true 自己闭合）
func _setCircle(line: Line2D, radius: float) -> void:
	var n: int = maxi(segments_per_circle, 8)
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = pts


#一根分隔线：圆心 → 该扇区起始角的圆边
func _setDivider(line: Line2D, angle: float, radius: float) -> void:
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius])


#============================================================
# 二、散点精灵
#============================================================
func _prepareScatter() -> void:
	if not _rng_seeded:
		if scatter_seed != 0:
			_rng.seed = scatter_seed
		else:
			_rng.randomize()
		_rng_seeded = true

	_scatter = get_node_or_null("Scatter") as Node2D
	if _scatter == null:
		_scatter = Node2D.new()
		_scatter.name = "Scatter"
		add_child(_scatter)

	_protos.clear()
	_proto_box.clear()
	var root := get_node_or_null(prototypes_name)
	if root != null:
		_collectProtos(root)
	if _protos.size() < TEX_KIND.size():
		_fillProtosFromFiles()
	if hide_prototypes and root != null:
		for c in root.get_children():
			if c is CanvasItem:
				(c as CanvasItem).visible = false


func _collectProtos(n: Node) -> void:
	for c in n.get_children():
		if c is Sprite2D and (c as Sprite2D).texture != null:
			var path: String = (c as Sprite2D).texture.resource_path
			for pair in TEX_KIND:
				if path.contains(pair[0]) and not _protos.has(pair[1]):
					_protos[pair[1]] = c
					_proto_box[pair[1]] = _renderedBox(c as Sprite2D)
					break
		_collectProtos(c)


func _fillProtosFromFiles() -> void:
	var dir_path := "res://assets/pictures/"
	for pair in TEX_KIND:
		var kind: String = pair[1]
		if _protos.has(kind):
			continue
		var p: String = dir_path + pair[0] + ".png"
		if not FileAccess.file_exists(p):
			continue
		var tex: Texture2D = load(p)
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		var big: float = maxf(tex.get_size().x, tex.get_size().y)
		var k: float = fallback_sprite_size / big if big > 0.0 else 1.0
		s.scale = Vector2(k, k)
		s.visible = false
		add_child(s)
		_protos[kind] = s
		_proto_box[kind] = tex.get_size() * k
	if _protos.size() < TEX_KIND.size() and not _warned_no_proto:
		_warned_no_proto = true
		var missing: Array = []
		for pair in TEX_KIND:
			if not _protos.has(pair[1]):
				missing.append(pair[0])
		print("[SacrificePie] 缺少散点原型：%s（应为 人/谷物1/谷物2/谷物堆/猪/羊/牛）" % str(missing))


func _renderedBox(s: Sprite2D) -> Vector2:
	if s.texture == null:
		return Vector2(fallback_sprite_size, fallback_sprite_size)
	return s.texture.get_size() * s.scale.abs()


#精灵中点是否已经跑到饼图外面（只判中点）
func _outsidePie(it, radius: float) -> bool:
	return it.pos.length() > radius + 0.001


#精灵中点是否落在某段扇形里（只判中点，且判定范围比真实扇形**往里收** sector_inset_deg）
#收紧的原因：只判中点时，中点贴着边界 = 图标有一半露在隔壁扇区/饼图外，很难看
func _centerInSector(it, sec_start: float, sec_span: float) -> bool:
	if sec_span <= 0.000001:
		return false
	var inset: float = _sectorInset(sec_span)
	var usable: float = sec_span - inset * 2.0
	if usable <= 0.000001:
		return false
	var a: float = atan2(it.pos.y, it.pos.x)
	var rel: float = fposmod(a - sec_start, TAU)
	return rel >= inset and rel <= inset + usable


#每侧收进来的角度（扇形太窄时按比例收，别收成负数）
func _sectorInset(sec_span: float) -> float:
	return minf(deg_to_rad(sector_inset_deg), sec_span * 0.35)


func _updateScatter() -> void:
	if _scatter == null:
		return

	var radius: float = max_radius * _ratio_total
	var vals := _groupRatios()
	var total: float = vals[0] + vals[1] + vals[2]
	if radius <= 0.5 or total <= 0.000001:
		_clearItems()
		return

	#各扇形范围
	var sectors := {}
	var ang: float = deg_to_rad(start_angle_deg)
	for i in 3:
		var span: float = TAU * vals[i] / total
		sectors[GROUPS[i]] = [ang, span]
		ang += span

	#① 中点跑出饼图的，卸载
	_unloadOutside(radius)

	#② 中点已经不在自己扇形里的，卸载
	#   —— 三类一起判：不管这次调的是哪一类，另外两类的扇形也会跟着转/缩，
	#      跑偏的精灵一律清掉，不能只在「超额」时才处理
	_purgeOutOfSector(sectors)

	#③ 谷物堆的开关状态变了 → 把已有的谷物按新规则重新分配种类（位置不变）
	_applyGrainLock(_ratio_grain >= 0.5 and _ratio_total >= 0.4)

	#目标数量 ∝ 扇区面积 =（角度占比）×（半径占比²）
	var area_ratio: float = _ratio_total * _ratio_total
	var n_people: int = int(round(float(sprites_at_full_circle) * (vals[0] / total) * area_ratio))
	var n_grain: int = int(round(float(sprites_at_full_circle) * (vals[2] / total) * area_ratio))
	var n_animal: int = int(round(float(sprites_at_full_circle) * (vals[1] / total) * area_ratio))

	#④ 超额：人口整类删；粮食三种算一类删；牲口按猪/羊/牛分别对
	var have_people: int = _countGroup("people")
	if have_people > n_people:
		_removeOutermostIn(["people"], have_people - n_people)

	var have_grain: int = _countGroup("grain")
	if have_grain > n_grain:
		_removeOutermostIn(_grainKinds(), have_grain - n_grain)

	#牲口：猪羊 1:1；total>40% 且 animal>60% 时 猪羊牛 1:1:1
	var animal_want := _animalWant(n_animal)
	for kind in ["pig", "sheep", "cow"]:
		var have: int = _countOf(kind)
		if have > animal_want[kind]:
			_removeOutermostIn([kind], have - animal_want[kind])

	#⑤ 不够：在新扇形里补（新精灵同样不会再被移动）
	var sec_p: Array = sectors["people"]
	var need_p: int = n_people - _countGroup("people")
	for i in maxi(need_p, 0):
		_spawn("people", sec_p[0], sec_p[1], radius)

	var sec_g: Array = sectors["grain"]
	var need_g: int = n_grain - _countGroup("grain")
	for i in maxi(need_g, 0):
		_spawn(_pickGrainKind(), sec_g[0], sec_g[1], radius)

	var sec_a: Array = sectors["animal"]
	for kind in ["pig", "sheep", "cow"]:
		var need: int = animal_want[kind] - _countOf(kind)
		for i in maxi(need, 0):
			_spawn(kind, sec_a[0], sec_a[1], radius)


#牲口的目标构成：猪羊 1:1；开了三牲就 猪羊牛 1:1:1
func _animalWant(n_animal: int) -> Dictionary:
	var triple: bool = _ratio_total > 0.40 and _ratio_animal > 0.60
	var want := {"pig": 0, "sheep": 0, "cow": 0}
	if triple:
		var each: int = n_animal / 3
		var left: int = n_animal - each * 3
		want["pig"] = each + (1 if left > 0 else 0)
		want["sheep"] = each + (1 if left > 1 else 0)
		want["cow"] = each
	else:
		want["pig"] = int(ceil(n_animal / 2.0))
		want["sheep"] = n_animal - want["pig"]
	return want


#当前允许出现的谷物种类：谷物1/谷物2 永远有；谷物堆要 grain>=50% 且 total>=40%
func _grainKinds() -> Array:
	var a: Array = []
	for k in ["grain1", "grain2"]:
		if _protos.has(k):
			a.append(k)
	if _grainPileUnlocked() and _protos.has("grain_pile"):
		a.append("grain_pile")
	if a.is_empty():
		a.append("grain1")
	return a


func _grainPileUnlocked() -> bool:
	return _ratio_grain >= 0.5 and _ratio_total >= 0.4


func _pickGrainKind() -> String:
	var a := _grainKinds()
	return a[_rng.randi() % a.size()]


#谷物堆开关变化时，把已有谷物的种类重新随机一遍（只换贴图，位置不动）
func _applyGrainLock(unlocked: bool) -> void:
	var st: int = 1 if unlocked else 0
	if _grain_lock_state == st:
		return
	_grain_lock_state = st
	var allowed := _grainKinds()
	for it in _items:
		if it.group != "grain":
			continue
		var k: String = allowed[_rng.randi() % allowed.size()]
		if k != it.kind:
			_retintItem(it, k)


#把一个精灵换成另一种谷物（保持位置不变）
func _retintItem(it, new_kind: String) -> void:
	var proto: Sprite2D = _protos.get(new_kind)
	if proto == null:
		return
	var old: Sprite2D = it.node
	var node: Sprite2D = proto.duplicate() as Sprite2D
	node.visible = true
	node.position = it.pos
	_scatter.add_child(node)
	if is_instance_valid(old):
		old.queue_free()
	it.node = node
	it.kind = new_kind


func _unloadOutside(radius: float) -> void:
	var keep: Array = []
	for it in _items:
		if _outsidePie(it, radius):
			if is_instance_valid(it.node):
				it.node.queue_free()
		else:
			keep.append(it)
	_items = keep


#卸载所有「中点已经不在自己扇形里」的精灵（三类一起判）
func _purgeOutOfSector(sectors: Dictionary) -> void:
	var keep: Array = []
	for it in _items:
		var sec: Array = sectors.get(it.group, [0.0, 0.0])
		if _centerInSector(it, sec[0], sec[1]):
			keep.append(it)
		else:
			if is_instance_valid(it.node):
				it.node.queue_free()
	_items = keep


#某类超额时，删掉离圆心最远的 n 个
#删掉 kinds 里「离圆心最远」的 n 个（kinds 可给多个，比如三种谷物算一类）
func _removeOutermostIn(kinds: Array, n: int) -> void:
	var cand: Array = []
	for i in _items.size():
		if kinds.has(_items[i].kind):
			cand.append([_items[i].pos.length(), i])
	cand.sort_custom(func(a, b): return a[0] > b[0])

	var idx: Array = []
	for k in mini(n, cand.size()):
		idx.append(cand[k][1])
	idx.sort()
	for j in range(idx.size() - 1, -1, -1):
		var it = _items[idx[j]]
		if is_instance_valid(it.node):
			it.node.queue_free()
		_items.remove_at(idx[j])


#在扇形里挑一个尽量不挤的位置（中点落在 R × scatter_margin 以内）
func _spawn(kind: String, sec_start: float, sec_span: float, radius: float) -> void:
	var proto: Sprite2D = _protos.get(kind)
	if proto == null:
		return
	var node: Sprite2D = proto.duplicate() as Sprite2D
	node.visible = true
	_scatter.add_child(node)

	var limit: float = radius * scatter_margin
	var r_min: float = radius * min_radius_ratio
	if limit <= r_min:
		r_min = 0.0
	var sep: float = maxf(maxf(_proto_box.get(kind, Vector2.ONE).x, _proto_box.get(kind, Vector2.ONE).y) * min_separation_scale, 4.0)

	#角度和半径都往里收：角度避开扇区两侧边界，半径避开圆心
	var inset: float = _sectorInset(sec_span)
	var usable: float = maxf(sec_span - inset * 2.0, 0.0)

	var best_pos := Vector2.ZERO
	var best_d: float = -1.0
	for attempt in 24:
		var a: float = sec_start + inset + _rng.randf() * usable
		#在 [r_min, limit] 这段圆环里按面积均匀（r 用平方根）
		var r2: float = r_min * r_min + _rng.randf() * (limit * limit - r_min * r_min)
		var pos: Vector2 = Vector2(cos(a), sin(a)) * sqrt(maxf(r2, 0.0))
		var d: float = _minDistance(pos, GROUP_OF[kind])
		if d >= sep:
			best_pos = pos
			best_d = d
			break
		if d > best_d:
			best_d = d
			best_pos = pos

	var it := Item.new()
	it.node = node
	it.kind = kind
	it.group = GROUP_OF[kind]
	it.pos = best_pos
	node.position = best_pos
	_items.append(it)


func _minDistance(pos: Vector2, group: String) -> float:
	var m: float = 1e20
	for it in _items:
		if it.group != group:
			continue
		m = minf(m, pos.distance_to(it.pos))
	return m


func _countOf(kind: String) -> int:
	var n: int = 0
	for it in _items:
		if it.kind == kind:
			n += 1
	return n


func _countGroup(group: String) -> int:
	var n: int = 0
	for it in _items:
		if it.group == group:
			n += 1
	return n


func _clearItems() -> void:
	for it in _items:
		if is_instance_valid(it.node):
			it.node.queue_free()
	_items.clear()
