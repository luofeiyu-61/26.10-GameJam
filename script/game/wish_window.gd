extends Control
class_name ClientWishPage

@onready var now_gua_sprite: AnimatedSprite2D = $effects/gua/now_gua

@onready var yin_label: Label = $spirit/Yao/yin
@onready var yang_label: Label = $spirit/Yao/yang

@onready var lunar_phase_now: Label = $effects/lunarPhaseNow/lunarPhase

@onready var spirit: Label = $spirit/status/spirit

@onready var check_list_for_gua: ColorRect = $effects/GuaCheckList/CheckListForGua


var temp_gua:ENUMS.Gua

signal go_to_event
signal go_to_sacrifice
signal confirm_wish (gua:ENUMS.Gua)


func _ready() -> void:
	#debug
	var gua_popup:PopupMenu= $WishWindow/GuaMenuButton.get_popup()
	gua_popup.id_pressed.connect(changeGua)
	check_list_for_gua.hide()
	spirit_center = yao_spirit_window.get_global_rect().get_center()

#debug
func changeGuaDisplay(gua:ENUMS.Gua):
	now_gua_sprite.play(ENUMS.gua2Binary(gua))

func renderLunarPhaseNow(lunar_phase:ENUMS.LunarPhase):
	lunar_phase_now.text="当前月相："+"\n"+ENUMS.lunarPhase2Text(lunar_phase)

#debug
func changeGua(gua_index:int):
	match gua_index:
		0:temp_gua=ENUMS.Gua.Qian
		1:temp_gua=ENUMS.Gua.Dui
		2:temp_gua=ENUMS.Gua.Li
		3:temp_gua=ENUMS.Gua.Zhen
		4:temp_gua=ENUMS.Gua.Xun
		5:temp_gua=ENUMS.Gua.Kan
		6:temp_gua=ENUMS.Gua.Gen
		7:temp_gua=ENUMS.Gua.Kun
	changeGuaDisplay(temp_gua)


func updateYao(yin:int,yang:int):
	yin_label.text="阴爻:%d"%yin
	yang_label.text="阳爻:%d"%yang

func updateQi(spirit_now):
	spirit.text=ENUMS.qi2Text(spirit_now)



#region 祈愿动画实现

@onready var yao_container: Control = $yao_container
@onready var yao_spirit_window: ColorRect = $spirit/Yao

const yao_scene := preload("res://scenes/sprites/yao.tscn")

var yao_list:Array[YaoBall]
var yao_yin_list:Array
var yao_yang_list:Array
@export var circle_scale:float = 30
var time:float
var spirit_center:Vector2 

class YaoPairData:
	var a:float#长轴
	var b:float#短轴
	var w:float#角速度
	var theta:float#轴倾角
	var phi:float#初相
	var yin_ball:int=-1
	var yang_ball:int=-1
	var phase:float
	
	func _init(a_,b_,w_,theta_,phi_) -> void:
		a=a_
		b=b_
		w=w_
		theta=theta_
		phi=phi_
	
	func circle(t:float)->Vector2:
		phase=w*t+phi
		return Vector2(a*cos(phase),b*sin(phase)).rotated(theta)

var yao_pairs:Array[YaoPairData]=[
	YaoPairData.new(2.24,2.24,1,0,0),
	YaoPairData.new(0.8,0.8,-2,0,1),
	YaoPairData.new(3.3,1.4,0.8,0,40),
	YaoPairData.new(3.3,1.4,-0.8,120,160),
	YaoPairData.new(3.3,1.4,0.8,240,280),
	YaoPairData.new(4,4,0.3,0,180)
]


func _process(delta: float) -> void:
	swangingInSpirit(delta)
	

#加载爻球
func initYaosAtSpirit(yang_yao:int,yin_yao:int,max_yao_num:int):
	yao_list.resize(max_yao_num)
	time=0
	#初始化爻列表
	for i in range(yang_yao+yin_yao):
		yao_list[i] = yao_scene.instantiate() as YaoBall
		yao_container.add_child(yao_list[i])
		yao_list[i].setYao(true if i < yang_yao else false)
	

#卸载爻球
func endYaosAll():
	for i in range(yao_list.size()):
		if !yao_list[i]:continue
		yao_list[i].queue_free()
		yao_list[i]=null


func swangingInSpirit(delta:float):
	time+=delta
	
	for i in range(yao_list.size()):
		#检测爻状态是否应该回到气中
		if !yao_list[i]:continue
		if !yao_list[i].dragging and !yao_list[i].is_in_wish :#爻该在气中
			
			if !yao_list[i].is_in_spirit:#爻没在气中
				for j in range(yao_pairs.size()):
					#阳爻顺入
					if yao_list[i].yao and yao_pairs[j].yang_ball==-1:
						yao_pairs[j].yang_ball=i
						break
					#阴爻顺入
					if !yao_list[i].yao and yao_pairs[j].yin_ball==-1:
						yao_pairs[j].yin_ball=i
						break
						
				yao_list[i].is_in_spirit=true#现在爻在气中了
				
			else:#爻在气中
				var pair_index:int=-1
				#查阴阳对
				for j in range(yao_pairs.size()):
					if yao_pairs[j].yang_ball==i or yao_pairs[j].yin_ball==i:
						pair_index=j
						break
				#旋转
				yao_list[i].yao_.global_position=spirit_center+yao_pairs[pair_index].circle(time)*(1 if yao_list[i].yao else -1)*circle_scale
	
		else:#爻不该在气中
			for j in range(yao_pairs.size()):
				if yao_pairs[j].yang_ball==i:
					yao_pairs[j].yang_ball=-1
					break
				if yao_pairs[j].yin_ball==i:
					yao_pairs[j].yin_ball=-1
					break
			yao_list[i].is_in_spirit = false




#endregion


#TODO
func confirmWish():
	confirm_wish.emit(temp_gua)


func _on_sacrifice_pressed() -> void:
	endYaosAll()
	go_to_sacrifice.emit()

func _on_eventstream_pressed() -> void:
	endYaosAll()
	go_to_event.emit()


func _on_gua_check_bt_pressed() -> void:
	if check_list_for_gua.visible:check_list_for_gua.hide()
	else:check_list_for_gua.show()


func _on_close_bt_pressed() -> void:
	if check_list_for_gua.visible:check_list_for_gua.hide()
	else:check_list_for_gua.show()
