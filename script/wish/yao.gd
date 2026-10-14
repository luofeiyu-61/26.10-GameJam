extends Node2D
class_name YaoBall

@onready var yao_: AnimatedSprite2D = $AnimatedSprite2D

@onready var trail: Line2D = $Line2D

@export var max_points: int = 20        # 拖尾长度（点数）
@export var point_distance: float = 3.0  # 每移动多少像素记录一个点
@export var teleport_threshold: float = 200.0  # 超过这个距离视为瞬移，清空拖尾
@export var trail_width: float = 12.0   # 拖尾宽度

var _last_point_pos: Vector2

@export var yao:bool=true

var color_:=Color(1, 1, 1, 0.8)
var is_in_spirit:bool=false
var is_in_wish:bool=false
var dragging:bool=false
var dragging_offset:Vector2=Vector2.ZERO



func _ready() -> void:
	setYao(yao)
	trail.width = trail_width
	trail.clear_points()
	# 让线更平滑
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.default_color = color_
	
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.0))   # 起点宽度 100%
	curve.add_point(Vector2(1, 1.0))   # 终点宽度 0
	trail.width_curve = curve
	
	_last_point_pos = yao_.position

func _process(delta: float) -> void:
	if dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging=false
		else:
			yao_.global_position = get_global_mouse_position() + dragging_offset
	
	
	var current_pos := yao_.position
	var delta_vec := current_pos - _last_point_pos
	var dist := delta_vec.length()

	# 瞬移检测
	if dist > teleport_threshold:
		trail.clear_points()
		_last_point_pos = current_pos
		return

	# 按固定距离插点
	
	if dist >= point_distance:
		var dir := delta_vec / dist
		var steps := mini(int(dist / point_distance), 10)
		for k in range(steps):
			_last_point_pos += dir * point_distance
			trail.add_point(_last_point_pos)
			while trail.get_point_count() > max_points:
				trail.remove_point(0)
	# 关键：插点上限跑完后，如果还没追上，直接跳到当前位置
		if _last_point_pos.distance_to(current_pos) > point_distance:
			_last_point_pos = current_pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 判断鼠标是否点在 Sprite 上
			if _is_point_on_sprite(get_global_mouse_position()):
				dragging = true
				# 记录鼠标与 Sprite 的偏移，避免跳动
				dragging_offset = yao_.global_position - get_global_mouse_position()
		else:
			dragging = false 

# 判断鼠标是否点在 Sprite 范围内
func _is_point_on_sprite(global_point: Vector2) -> bool:
	if yao_.sprite_frames == null:
		return false
	
	# 1. 获取当前动画和当前帧的纹理
	var anim_name = yao_.animation
	var frame_idx = yao_.frame
	var texture = yao_.sprite_frames.get_frame_texture(anim_name, frame_idx)
	
	if texture == null:
		return false
		
	# 2. 获取纹理尺寸
	var texture_size = texture.get_size()
	
	# 3. 计算纹理在局部坐标下的位置（考虑 centered 和 offset）
	var texture_pos = Vector2.ZERO
	if yao_.centered:
		texture_pos = -texture_size * 0.5
	texture_pos += yao_.offset
	
	# 4. 构建局部矩形并判断
	var texture_rect = Rect2(texture_pos, texture_size)
	var local_point = yao_.to_local(global_point)
	
	return texture_rect.has_point(local_point)




func setYao(yaoo:bool):
	if yaoo:
		yao_.play("yang")
		color_=Color(1.0, 1.0, 1.0, 0.588)
	else:
		yao_.play("yin")
		color_=Color(0.0, 0.0, 0.0, 0.588)
	trail.default_color = color_
	yao=yaoo
