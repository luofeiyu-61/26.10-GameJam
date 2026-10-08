extends Control

@export var graph:Graph
@export var one_template:PackedScene
@export var progress_db:ProgressDB

@export var world: Control 
@export var root_one: Atom 
@export var graph_branch: GraphBranch 

#聚焦速度参数
@export var pan_speed: float = 7.0      # 越大越快，越小越柔

#聚焦用目的坐标
var _target_pan: Vector2 = Vector2.ZERO

#拖拽用变量
var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_position := Vector2.ZERO

#节点管理
var node_counter:=0

func _ready() -> void:
	#获取屏幕中心
	if world: _target_pan = world.position
	
	#补一次注册
	graph.add_atom(root_one, graph_branch)
	
	# 生成节点
	var root = _spawn(root_one,"SON")
	print(root_one)
	_spawn(root,"SON1")
	_spawn(root,"SON2")
	_spawn(_spawn(_spawn(root_one,"0"),"1"),"2")
	
	if progress_db:
		graph.sync_with_progress(progress_db)


func _process(delta: float) -> void:
	
	#聚焦移动
	var t:=1.0
	if !_dragging and _target_pan.distance_to(world.position)>1:
		t = 1.0 - exp(-pan_speed * delta)   # 帧率无关的指数缓动
		world.position = world.position.lerp(_target_pan, t)

#生成一个节点
func _spawn(parent:Atom,title:String)->Atom:
	var atom:=one_template.instantiate() as Atom
	
	#atom信息初始化
	atom.data=AtomData.new()
	atom.data.id=StringName("node_%d" % node_counter)
	node_counter+=1
	atom.data.title=title
	
	if parent:
		#随机方向
		atom.global_position = parent.global_position + 100*Vector2.RIGHT.rotated(randf_range(0,360))
		graph.connect_atoms(parent, atom)
		graph.wake_up_atom(parent)
	else:
		atom.global_position = root_one.global_position
	
	graph.add_atom(atom,world)
	
	graph.sync_with_progress(progress_db)
	graph.wake_up_atom(atom)   # 唤醒，弹簧才开始拉

	return atom


# 把视窗中心聚焦到某个全局坐标（通常是 atom.global_position）
func focus_on(global_target: Vector2) -> void:
	if not (world and graph): return
	var center := graph.get_global_rect().get_center()
	# 推导：world.global_position = graph.global_position + world.position（无缩放时）
	# 令目标原子的全局坐标移动到窗口中心，反推 world 应有的局部位置：
	_target_pan = world.position + (center - global_target)


func _input(event: InputEvent) -> void:
	
	if !is_instance_valid(graph._hovered_atom):   #没有悬停在节点上的时候
		# 鼠标按下：开始拖拽
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_dragging = true
					_drag_start_mouse = get_global_mouse_position()
					_drag_start_position = world.position
				else:
					_dragging = false

		# 鼠标移动：更新位置
		elif event is InputEventMouseMotion and _dragging:
			var current_mouse := get_global_mouse_position()
			var delta := current_mouse - _drag_start_mouse
			world.position = _drag_start_position + delta
			_target_pan = world.position


func _on_next_pressed() -> void:
	focus_on(root_one.global_position)
