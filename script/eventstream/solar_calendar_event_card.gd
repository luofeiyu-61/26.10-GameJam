extends Control


@onready var event_name: Label = $ColorRect/title/event_name
@onready var good: Label = $ColorRect/yiji/good
@onready var bad: Label = $ColorRect/yiji/bad


#拖动状态：左键按住可以拖着卡片走，但始终不出父容器（calendarSo/Events）的范围
var _dragging: bool = false


func writeText(event:EventCard):
	event_name.text=event.display_name
	good.text="宜："
	for gua in event.result_good.meet_gua:
		good.text+=ENUMS.gua2Text(gua)+"、"
	good.text=good.text.left(good.text.length() - 1)
	bad.text="忌："
	for gua in event.result_bad.meet_gua:
		bad.text+=ENUMS.gua2Text(gua)+"、"
	bad.text=bad.text.left(bad.text.length() - 1)
	

func _ready() -> void:
	#场景里根节点是「铺满父节点」的，这里缩到正好包住卡片内容，
	#这样 position 就是卡片自己的左上角，拖动和边界限制才好算。
	var box: ColorRect = $ColorRect
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = box.size

	#根节点负责接鼠标；子节点用 PASS 把事件冒泡上来，Label 直接忽略
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG   #悬停提示「可拖动」
	_applyChildMouseFilter(self)


#子节点不要吃掉鼠标事件，统一冒泡到根节点
func _applyChildMouseFilter(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			var c: Control = child
			if c is Label:
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				c.mouse_filter = Control.MOUSE_FILTER_PASS
			_applyChildMouseFilter(c)


#左键按住拖动；按下时先把自己置顶（focus）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_dragging = true
			move_to_front()        #点中的卡片放到所有卡片最上面
			accept_event()
		else:
			_dragging = false
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		position += (event as InputEventMouseMotion).relative
		_clampIntoParent()         #拖动过程中也一直限制在父容器内
		accept_event()


#把卡片限制在父容器（calendarSo/Events）范围内
func _clampIntoParent() -> void:
	var parent_ctrl: Control = get_parent() as Control
	if parent_ctrl == null:
		return
	var max_pos: Vector2 = parent_ctrl.size - size
	position = Vector2(
		clampf(position.x, 0.0, maxf(max_pos.x, 0.0)),
		clampf(position.y, 0.0, maxf(max_pos.y, 0.0)))
