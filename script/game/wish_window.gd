extends Control
class_name ClientWishPage

@onready var now_gua_sprite: AnimatedSprite2D = $effects/gua/now_gua

@onready var yin_label: Label = $spirit/Yao/yin
@onready var yang_label: Label = $spirit/Yao/yang

@onready var lunar_phase_now: Label = $effects/lunarPhaseNow/lunarPhase

@onready var spirit: Label = $spirit/status/spirit

@onready var check_list_for_gua: ColorRect = $effects/GuaCheckList/CheckListForGua


var temp_gua:ENUMS.Gua=ENUMS.Gua.NONE

var temp_spirit:ENUMS.Qi



signal go_to_event
signal go_to_sacrifice
signal confirm_wish (gua:ENUMS.Gua)



func _ready() -> void:
	check_list_for_gua.hide()
	spirit_center = yao_spirit_window.get_global_rect().get_center()
	wish_window_rect = wish_window.get_global_rect()
	wish_window_center = wish_window.get_global_rect().get_center()
	
	wish_circle__.position=wish_window_center

#debug
func changeGuaDisplay(gua:ENUMS.Gua):
	now_gua_sprite.play(ENUMS.gua2Binary(gua))

func renderLunarPhaseNow(lunar_phase:ENUMS.LunarPhase):
	lunar_phase_now.text=ENUMS.lunarPhase2Text(lunar_phase)
	$effects/lunarPhaseNow/moon.play(ENUMS.lunarPhase2Text(lunar_phase))





func updateYao(yin:int,yang:int):
	yin_label.text="阴爻:%d"%yin
	yang_label.text="阳爻:%d"%yang

func updateQi(spirit_now):
	spirit.text=ENUMS.qi2Text(spirit_now)

func updateTempQi():
	yao_yin_num=0
	yao_yang_num=0
	for i in range(yao_list.size()):
		if !yao_list[i]:continue
		if yao_list[i].is_in_spirit:
			if yao_list[i].yao:yao_yang_num+=1
			else:yao_yin_num+=1
		
	if yao_yang_num==yao_yin_num: temp_spirit=ENUMS.Qi.Balance
	elif yao_yang_num==0: temp_spirit=ENUMS.Qi.FullYin
	elif yao_yin_num==0: temp_spirit=ENUMS.Qi.FullYang
	elif yao_yang_num>yao_yin_num: temp_spirit=ENUMS.Qi.PartYang
	elif yao_yang_num<yao_yin_num: temp_spirit=ENUMS.Qi.PartYin
	
	spirit.text=ENUMS.qi2Text(temp_spirit)




#region 爻动画实现

@onready var yao_container: Control = $yao_container
@onready var yao_spirit_window: ColorRect = $spirit/Yao
@onready var wish_window: ColorRect = $WishWindow


const yao_scene := preload("res://scenes/sprites/yao.tscn")

var yao_list:Array[YaoBall]
var yao_yin_num:int
var yao_yang_num:int
@export var circle_scale:float = 30
var time:float
var spirit_center:Vector2 
var wish_window_rect:Rect2

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

#气中待机的爻的轨道
var yao_pairs:Array[YaoPairData]=[
	YaoPairData.new(2.24,2.24,1,0,0),
	YaoPairData.new(0.8,0.8,-2,0,1),
	YaoPairData.new(3.3,0.4,0.8,0,PI/9.0),
	YaoPairData.new(3.3,0.4,-0.8,2.5*PI/3.0,4*PI/9.0),
	YaoPairData.new(3.3,0.4,0.8,3.5*PI/3.0,7*PI/9.0),
	YaoPairData.new(4,4,0.3,0,180)
]


func _process(delta: float) -> void:
	time+=delta
	
	swangingInSpirit(time)
	swangingInWish(time)

#加载爻球
func initYaosAtSpirit(yang_yao:int,yin_yao:int,max_yao_num:int):
	yao_list.resize(max_yao_num)
	time=0
	yao_in_wish_list=[-1,-1,-1]
	#初始化爻列表
	for i in range(yang_yao+yin_yao):
		yao_list[i] = yao_scene.instantiate() as YaoBall
		yao_list[i].global_position=spirit_center+Vector2.RIGHT*300
		yao_container.add_child(yao_list[i])
		yao_list[i].setYao(true if i < yang_yao else false)

#卸载爻球
func endYaosAll():
	yao_in_wish_list=[-1,-1,-1]
	wish_circle__.clearYao()
	for i in range(yao_pairs.size()):
		yao_pairs[i].yang_ball=-1
		yao_pairs[i].yin_ball=-1
	for i in range(yao_list.size()):
		if !yao_list[i]:continue
		yao_list[i].queue_free()
		yao_list[i]=null

#爻在气中的待机
func swangingInSpirit(time_:float):
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
				updateTempQi()
				
			else:#爻在气中
				var pair_index:int=-1
				#查阴阳对
				for j in range(yao_pairs.size()):
					if yao_pairs[j].yang_ball==i or yao_pairs[j].yin_ball==i:
						pair_index=j
						break
				#旋转
				yao_list[i].yao_.global_position=spirit_center+yao_pairs[pair_index].circle(time_)*(1 if yao_list[i].yao else -1)*circle_scale
	
		else:#爻不该在气中
			for j in range(yao_pairs.size()):
				if yao_pairs[j].yang_ball==i:
					yao_pairs[j].yang_ball=-1
					yao_list[i].is_in_spirit = false
					updateTempQi()
					break
				if yao_pairs[j].yin_ball==i:
					yao_pairs[j].yin_ball=-1
					yao_list[i].is_in_spirit = false
					updateTempQi()
					break
			

var yao_in_wish_list:Array=[-1,-1,-1]
@export var wish_circle_scale:float=100.0
var phase : float
var wish_window_center:Vector2
@onready var wish_circle__: WishCircle = $WishCircle

func swangingInWish(time_:float):
	for i in range(yao_list.size()):
		if !yao_list[i]:continue
		#检测爻松手后该不该在祈愿窗口中
		if yao_list[i].dragging:
			if wish_window_rect.has_point(yao_list[i].yao_.global_position) and (i in yao_in_wish_list or yao_in_wish_list.count(-1)>0):
				yao_list[i].is_in_wish= true
			else:
				yao_list[i].is_in_wish = false
				
			if yao_list[i].is_in_wish and i not in yao_in_wish_list: 
				yao_in_wish_list[yao_in_wish_list.find(-1)]=i
				wish_circle__.addYao(i,yao_list[i].yao)
			elif !yao_list[i].is_in_wish and i in yao_in_wish_list: 
				yao_in_wish_list[yao_in_wish_list.find(i)]=-1
				wish_circle__.delYao(i)
		
	#在wish中的旋转
	for k in range(yao_in_wish_list.size()):
		if yao_in_wish_list[k]==-1:continue
		phase = 0.4*time_+ k*PI/1.5
		yao_list[yao_in_wish_list[k]].yao_.global_position = wish_window_center+ Vector2(cos(phase),sin(phase))*wish_circle_scale
			


#endregion



func confirmWish():
	if yao_in_wish_list.count("-1")==0 and wish_circle__.yaos.size()==3:
		match str(wish_circle__.yaos2gua[0])+str(wish_circle__.yaos2gua[1])+str(wish_circle__.yaos2gua[2]):
			"000":temp_gua= ENUMS.Gua.Kun
			"001":temp_gua= ENUMS.Gua.Gen
			"010":temp_gua= ENUMS.Gua.Kan
			"011":temp_gua= ENUMS.Gua.Xun
			"100":temp_gua= ENUMS.Gua.Zhen
			"101":temp_gua= ENUMS.Gua.Li
			"110":temp_gua= ENUMS.Gua.Dui
			"111":temp_gua= ENUMS.Gua.Qian
		
		
			
		
		for i in range(yao_in_wish_list.size()):
			for j in range(yao_pairs.size()):
				if yao_pairs[j].yang_ball==yao_in_wish_list[i]:
					yao_pairs[j].yang_ball=-1
					break
				elif yao_pairs[j].yin_ball==yao_in_wish_list[i]:
					yao_pairs[j].yin_ball=-1
					break
			yao_list[yao_in_wish_list[i]].queue_free()
			yao_list[yao_in_wish_list[i]]=null
			wish_circle__.delYao(yao_in_wish_list[i])
			yao_in_wish_list[i]=-1
		
		
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


func _on_wish_circle_nao_gua_sprite_change(gua_: String) -> void:
	if now_gua_sprite:
		if gua_=="":
			now_gua_sprite.play("none")
		else:
			now_gua_sprite.play(gua_)
