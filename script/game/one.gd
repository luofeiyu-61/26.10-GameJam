extends Node

#客户端
@export var EventStremPage:Control
@export var SacrificePage:Control
@export var WishPage:Control


#游戏变量
@export var gua_now :ENUMS.Gua					#当前卦象
@export var lunar_buff_now :ENUMS.LunarPhase	#当前起效的月相buff


@export var belief_sup:int = 100	#信仰值上限
var belief_value:int:				#信仰值
	set(value):belief_value = min(belief_sup,max(0,value))


#region 天人地

@export var air_sup:int = 100	#天上限
var air_value:int:				#天
	set(value):air_value = min(air_sup,max(0,value))

#人（内置判断机制（截断输入））
@export var guy_sup:int = 100	#人上限
var guy_value:int:				#人
	set(value):
		var a = people_value / float(people_sup)
		var b = animal_value / float(animal_sup)
		var c = grain_value / float(grain_sup)
		
		var result = guy_sup*(a*b*c)^2/(((a+b+c)/3)^5)
		
		guy_value = min(guy_sup,max(0,result))

@export var earth_sup:int = 100	#地上限
var earth_value:int:			#地
	set(value):earth_value = min(earth_sup,max(0,value))

#endregion

#region 人相关变量

@export var people_sup:int = 100	#人口上限
var people_value:int:				#人口
	set(value):people_value = min(people_sup,max(0,value))

@export var animal_sup:int = 100	#牲口上限
var animal_value:int:				#牲口
	set(value):animal_value = min(animal_sup,max(0,value))

@export var grain_sup:int = 100		#粮食上限
var grain_value:int:				#粮食
	set(value):grain_value = min(grain_sup,max(0,value))

#endregion

#region 献祭相关变量
#祭品比例分配
var sacrifice_ratio:Dictionary[String,float]={
	"people_ratio":0.0,
	"animal_ratio":0.0,
	"grain_ratio":0.0
	}

var sacrifice_bar_value:float:		#献祭值
	set(value):
		sacrifice_bar_value = min(1.0,max(0.0,value))
		if value>=1.0:spawnOnePairYao()
		#调用献祭值满时生成一对爻

#endregion

#region 阴阳爻、气相关变量
@export var yao_num_sup:int=12	#持有爻上限：偶数
var yao_yin_num:int				#阴爻
var yao_yang_num:int			#阳爻

#气（已内置根据爻数量判断机制（截断输入））
var spirit:ENUMS.Qi:
	set(value):				#气的判定
		if yao_yang_num==yao_yin_num: spirit=ENUMS.Qi.Balance
		elif yao_yang_num==0: spirit=ENUMS.Qi.FullYin
		elif yao_yin_num==0: spirit=ENUMS.Qi.FullYang
		elif yao_yang_num>yao_yin_num: spirit=ENUMS.Qi.PartYang
		elif yao_yang_num<yao_yin_num: spirit=ENUMS.Qi.PartYin

#endregion

#region 时间轴

#一个月相/节气的时长（天）
const LUNAR_PHASE_TIME=3.69
const SOLAR_TERM_TIME=15

#游戏天数
var days:float

#当前
var lunar_phase_now :ENUMS.LunarPhase:
	set(value):
		lunar_phase_now=int((days-lunar_shift)/LUNAR_PHASE_TIME)%8 as ENUMS.LunarPhase
var solar_term_now :ENUMS.SolarTerm

#游戏时间开始时的偏移（不要在局内修改！！！）
@export var solar_shift:float
@export var lunar_shift:float

#事件列表：当前已确定的该节气内可能发生的事件与顺序(存的事件id)
var event_list:Array[int]
var event_days_list:Array[float]
#历史事件
var event_history:Array[int]
var event_history_result:Array[ENUMS.ResultType]

#endregion



signal back_to_main_menu


func _ready() -> void:
	switch_window_to(0)


#region 服务端处理游戏操作

#时间流逝
func timePassBy(pass_time:float):
	#时间流逝，更新月相/节气
	days+=pass_time
	
	#具体算法已内置到变量的定义环节
	lunar_phase_now=0 as ENUMS.LunarPhase
	
	var temp_solar_term := int((days-solar_shift)/15)%24
	if temp_solar_term!=solar_term_now or pass_time>=360:
		solar_term_now=temp_solar_term as ENUMS.SolarTerm
		solarTermGoOn(solar_term_now)



#节气更替	TODO
func solarTermGoOn(this_solar_term:ENUMS.SolarTerm):
	pass


#重生成事件列表
func newEventPool():
	pass


#重新计算时长


#献祭值满了，生成一对阴阳爻 TODO
func spawnOnePairYao():
	pass

#更新人的值
func updateGuy():
	#具体算法已内置到变量的定义环节
	guy_value=0

#更新气的值
func updateSpirit():
	#具体算法已内置到变量的定义环节
	spirit=0 as ENUMS.Qi


#endregion

#返回主菜单（无保存）
func _on_back_to_menu_pressed() -> void:
	back_to_main_menu.emit()
	queue_free()


#region 主窗口管理：事件流 / 祭祀 / 祈愿 三个子界面的切换，以及返回主菜单信号。
# windowIndex: 0=事件流, 1=祭祀, 2=祈愿
func switch_window_to(window_index: int) -> void:
	match window_index:
		0:
			EventStremPage.visible = true
			SacrificePage.visible = false
			WishPage.visible = false
			print("///切换至”事件流“界面///")
		1:
			EventStremPage.visible = false
			SacrificePage.visible = true
			WishPage.visible = false
			print("///切换至”祭祀“界面///")
		2:
			EventStremPage.visible = false
			SacrificePage.visible = false
			WishPage.visible = true
			print("///切换至”祈愿“界面///")
		_:
			pass

func _events_to_sacrifice() -> void:
	switch_window_to(1)

func _events_to_wish() -> void:
	switch_window_to(2)

func _sacrifice_to_event() -> void:
	switch_window_to(0)

func _sacrifice_to_wish() -> void:
	switch_window_to(2)

func _wish_to_event() -> void:
	switch_window_to(0)

func _wish_to_sacrifice() -> void:
	switch_window_to(1)

#endregion
