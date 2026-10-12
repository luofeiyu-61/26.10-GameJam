extends Node

#客户端
@export var EventStremPage:ClientEventPage
@export var SacrificePage:ClientSacrificePage
@export var WishPage:ClientWishPage

@onready var game_setting_ui: CanvasLayer = $GameSettingUI

#游戏变量
#region 信仰值相关
@export var gua_now :ENUMS.Gua=ENUMS.Gua.NONE :					#当前卦象
	set(value):
		WishPage.changeGuaDisplay(value)
		gua_now=value

@export var lunar_buff_now :ENUMS.LunarPhase = ENUMS.LunarPhase.NONE	#当前起效的月相buff

@export var lunar_buff_upup:Dictionary[int,float]={#月相增益效果
	0:0.00,
	1:0.35,
	2:0.65,
	3:0.85,
	4:1.00,
	5:0.85,
	6:0.65,
	7:0.35
}
@export var lunar_buff_downdown:Dictionary[int,float]={#月相减伤效果
	0:0.00,
	1:0.08,
	2:0.18,
	3:0.35,
	4:0.50,
	5:0.35,
	6:0.18,
	7:0.08
}

@export var belief_sup:int = 100	#信仰值上限
@export var belief_value:int = 30:				#信仰值
	set(value):
		belief_value = min(belief_sup,max(0,value))
		#祈愿效果失效
		if belief_value <= 0:
			wishForGua(ENUMS.Gua.NONE)
			EventStremPage.rederBelief(belief_value,gua_now,lunar_buff_now)
#endregion

#region 天人地

@export var air_sup:int = 120	#天上限
@export var air_value:int = 40:				#天
	set(value):air_value = min(air_sup,max(0,value))

#人（内置判断机制（截断输入））
@export var guy_sup:int = 1000	#人上限
var guy_value:int:				#人
	set(value):
		var a = people_value / float(people_sup)
		var b = animal_value / float(animal_sup)
		var c = grain_value / float(grain_sup)
		
		var result = int(guy_sup*(a*b*c)**2/(((a+b+c)/3)**5)) if (a+b+c) != 0 else 0
		
		guy_value = min(guy_sup,max(0,result))

@export var earth_sup:int = 120	#地上限
@export var earth_value:int = 40:			#地
	set(value):earth_value = min(earth_sup,max(0,value))

#endregion

#region 人相关变量

@export var people_sup:int = 100	#人口上限
@export var people_value:int = 50:				#人口
	set(value):people_value = min(people_sup,max(0,value))

@export var animal_sup:int = 80	#牲口上限
@export var animal_value:int = 30:				#牲口
	set(value):animal_value = min(animal_sup,max(0,value))

@export var grain_sup:int = 200		#粮食上限
@export var grain_value:int = 80:				#粮食
	set(value):grain_value = min(grain_sup,max(0,value))

#endregion

#region 献祭、祈愿相关变量
#祭品比例分配
var sacrifice_ratio:Dictionary[String,float]={
	"people_ratio":0.0,
	"animal_ratio":0.0,
	"grain_ratio":0.0,
	"total_ratio":0.0
	}

@export var sacrifice_bar_sup:int = 100
var sacrifice_bar_value:int:		#献祭值
	set(value):
		sacrifice_bar_value = min(sacrifice_bar_sup,max(0,value))
		#调用献祭值满时生成一对爻

#每次祈愿时增加的信仰值量
@export var wish_belief_addition:int = 30

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

@export var qi_buff_info:Dictionary={
	0:{#"Balance"
		"people_weight":0.0,
		"animal_weight":0.0,
		"grain_weight":0.0
	},
	-2:{#"FullYin"
		"people_weight":0.0,
		"animal_weight":0.0,
		"grain_weight":0.0
	},
	2:{#"FullYang"
		"people_weight":0.0,
		"animal_weight":0.0,
		"grain_weight":0.0
	},
	1:{#"PartYang"
		"people_weight":0.0,
		"animal_weight":0.0,
		"grain_weight":0.0
	},
	-1:{#"PartYin"
		"people_weight":0.0,
		"animal_weight":0.0,
		"grain_weight":0.0
	}
}

#endregion

#region 时间轴

#一个月相/节气的时长（天）
const LUNAR_PHASE_TIME=3.69
const SOLAR_TERM_TIME=15
const YEAR_DAYS=360		#SOLAR_TERM_TIME*ENUMS.SolarTerm.size()->15*24

#游戏天数
var days:float=0.0

#当前
var lunar_phase_now :ENUMS.LunarPhase:
	set(value):
		lunar_phase_now=int((days+lunar_shift)/LUNAR_PHASE_TIME)%8 as ENUMS.LunarPhase
var solar_term_now :ENUMS.SolarTerm
var year_now:int:
	set(value):
		year_now=int(days/YEAR_DAYS)

#游戏时间开始时的偏移（不要在局内修改！）
@export var solar_shift:float=0.0
@export var lunar_shift:float=0.0

#endregion

#region 事件相关
#每个节气最多发生X个随机事件
const MAX_RANDOM_EVENT_PER_SOLAR_TERM = 2
#每个节气最多发生X个固定事件
const MAX_FIXED_EVENT_PER_SOLAR_TERM = 4

#事件列表：当前已确定的该节气内可能发生的事件与顺序(存的事件id)
var event_list:Array[int]
var event_duration_list:Array[float]

#条件事件中查询前置事件时回看历史的最大事件数
const MAX_CONDITION_LOOK_BACK_NUMBER=30

#历史事件
var event_history:Array[int]
var event_history_result:Array[ENUMS.ResultType]


var all_history:Dictionary
#格式
#{Year0:
#	{SolarTerm0:
#		[
#			[event_id,result:ENUMS.ResultType]
#		]
#	}
#}


#endregion



#region 客户端用临时变量

const EVENT_LIST_IS_EMPTY = "当前节气无事发生。"
const EVENT_LIST_IS_EMPTY_RESULT = "时间来到下一个节气。"

var this_event_name:String
var this_event_context:String
var this_event_result_context:String
var this_event_level :ENUMS.EventLevel
var this_event_type :ENUMS.EventType
var this_result_type:ENUMS.ResultType

#endregion




signal back_to_main_menu

#游戏首次开始时
func _ready() -> void:
	firstInitGame()
	switch_window_to(0)

func _process(delta: float) -> void:
	developrInfo()

#开发者模式
func developrInfo():
	if SettingsManager.develop_mode:
		$values.show()
		$values.text="游戏数值："+\
		"\n"+"信仰值：%d/%d"%[belief_value,belief_sup]+\
		"\n"+"当前卦象：%s"%ENUMS.Gua.find_key(gua_now)+\
		"\n"+"当前月相buff：%s"%ENUMS.lunarPhase2Text(lunar_buff_now)+\
		"\n"+"游戏天数：%d"%days+\
		"\n"+"年：%d"%year_now+\
		"\n"+"节气：%s"%ENUMS.solarTerm2Text(solar_term_now)+\
		"\n"+"月相：%s"%ENUMS.lunarPhase2Text(lunar_phase_now)+\
		"\n"+"“天”：%d/%d"%[air_value,air_sup]+\
		"\n"+"“人”：%d/%d"%[guy_value,guy_sup]+\
		"\n"+"“地”：%d/%d"%[earth_value,earth_sup]+\
		"\n"+"人口：%d/%d"%[people_value,people_sup]+\
		"\n"+"牲口：%d/%d"%[animal_value,animal_sup]+\
		"\n"+"粮食：%d/%d"%[grain_value,grain_sup]
	else:
		$values.hide()



#region 服务端处理游戏操作

#游戏首次开始时的初始化 TODO
func firstInitGame():
	#加载存档 TODO
	updateGuy()
	if days == 0.0:
		lunar_phase_now = 0 as ENUMS.LunarPhase #具体算法已内置到变量的定义环节
		solar_term_now = int((days+solar_shift)/SOLAR_TERM_TIME)%24 as ENUMS.SolarTerm
		newEventList(solar_term_now)

#region 事件流相关

#时间流逝
func timePassBy(pass_time:float):
	#时间流逝，更新月相/节气
	days+=pass_time
	
	#具体算法已内置到变量的定义环节
	lunar_phase_now=0 as ENUMS.LunarPhase
	
	var temp_solar_term := int((days+solar_shift)/SOLAR_TERM_TIME)%24
	#节气更替
	if temp_solar_term!=solar_term_now or pass_time>=360:
		solar_term_now=temp_solar_term as ENUMS.SolarTerm
		newEventList(solar_term_now)

#强制度过当下节气
func enforceTimeToNextSolarTerm():
	var left_time:float=SOLAR_TERM_TIME-(days+solar_shift)+int((days+solar_shift)/SOLAR_TERM_TIME)*SOLAR_TERM_TIME
	timePassBy(left_time)


#生成事件列表
func newEventList(this_solar_term:ENUMS.SolarTerm):
	#此时事件列表是否为空？
	if !event_list.is_empty():
		print("[ERROR]上一个节气%s结束前还有事件没有经历" % ENUMS.SolarTerm.find_key(this_solar_term-1 as ENUMS.SolarTerm))
		for i in range(event_list.size()):
			print("[ERROR]剩余事件id：%d" % event_list[i])
	
	#收集固定事件、随机事件；打乱顺序
	event_list.clear()
	event_list+=EventDataBase.collectFixedEvent(this_solar_term)
	
	if event_list.size()>MAX_FIXED_EVENT_PER_SOLAR_TERM:
		event_list.shuffle()
		event_list=event_list.slice(0,MAX_FIXED_EVENT_PER_SOLAR_TERM)
	
	event_list+=EventDataBase.collectRandomEvent(MAX_RANDOM_EVENT_PER_SOLAR_TERM)
	event_list.shuffle()
	
	
	#计算每个事件的时间
	var left_time:float=SOLAR_TERM_TIME-(days+solar_shift)+int((days+solar_shift)/SOLAR_TERM_TIME)*SOLAR_TERM_TIME
	event_duration_list.clear()
	event_duration_list.append(left_time)
	
	recountDurationEachEvent(left_time)

#重新计算事件时长（传入 新的事件列表、旧的剩余时间）(这个数组传入的是引用类型，会直接改动，无需返回)
func recountDurationEachEvent(left_time:float=0.0):
	#剩余时间
	var total_time := 0.0
	for dur in event_duration_list:
		total_time+=dur
	
	#剩余事件的时长比例
	var temp_total_time_:=0.0
	for id in event_list:
		temp_total_time_ += float(EventDataBase.all_events[id].time_consume)
	
	#重分配剩余时间
	event_duration_list.clear()
	for i in range(event_list.size()):
		event_duration_list.append(total_time*(EventDataBase.all_events[event_list[i]].time_consume/temp_total_time_))
	
	#没有事件时
	if event_duration_list.size()==0:
		event_duration_list.append(left_time)
	return

#按顺序向历史中写入事件与结果
func autoWriteHistory(year_:int,solar_term_:ENUMS.SolarTerm,event_id:int,event_result:ENUMS.ResultType):
	if !all_history.has("Year%d"%year_):
		all_history["Year%d"%year_]={}
	if !all_history["Year%d"%year_].has("SolarTerm%d"%solar_term_):
		all_history["Year%d"%year_]["SolarTerm%d"%solar_term_]=[]
	
	all_history["Year%d"%year_]["SolarTerm%d"%solar_term_].append([event_id,event_result])
#格式
#{Year0:
#	{SolarTerm0:
#		[
#			[event_id,result:ENUMS.ResultType]
#		]
#	}
#}

#事件发生（结算事件）(这个函数会使时间流逝)
func anEventHappen()->bool:
	if event_list.is_empty():
		print("[WARNING]当前节气%s没有事件！ 已自动跳至下一节气！"%ENUMS.SolarTerm.find_key(solar_term_now))
		this_event_context = EVENT_LIST_IS_EMPTY
		this_event_result_context = EVENT_LIST_IS_EMPTY_RESULT
		enforceTimeToNextSolarTerm()
		return false
	
	else:
		var id = event_list.pop_front()
		var dur = event_duration_list.pop_front()
		var result = EventDataBase.whatResultItIs(id,gua_now)
		
		#要往客户端传的文本信息
		this_event_name = EventDataBase.all_events[id].display_name
		this_event_context = EventDataBase.all_events[id].context
		this_event_result_context = result.result_context
		this_event_level =EventDataBase.all_events[id].event_level
		this_event_type=EventDataBase.all_events[id].event_type
		this_result_type=result.result_type
		
		#数值反馈
		belief_value+=result.belief_feedback
		
		people_value=updateValueByLunarBuff(people_value,result.people_feedback)
		animal_value=updateValueByLunarBuff(animal_value,result.animal_feedback)
		grain_value=updateValueByLunarBuff(grain_value,result.grain_feedback)
		updateGuy()
		air_value+=result.air_feedback
		earth_value+=result.earth_feedback
		
		
		#写史记
		autoWriteHistory(year_now,solar_term_now,id,result.result_type)
		#写历史列表
		event_history.append(id)
		event_history_result.append(result.result_type)
		
		timePassBy(dur)
		return true

#月相buff作用公式
func updateValueByLunarBuff(target_value:int,feedback_value:int)->int:
	if feedback_value>0:
		target_value+=int(1+(lunar_buff_upup[lunar_buff_now])*feedback_value)
	elif feedback_value<0:
		target_value+=int(1-(lunar_buff_downdown[lunar_buff_now])*feedback_value)
	return target_value

#endregion

#region 祭祀相关

#计算当下的献祭比例会产出多少献祭值（但不应用，相当于一个预览）
#返回改变后的[人，牲，粮，“人”，献祭条，爻]
func calculateScrificeValue(ratio_people:float, ratio_animal:float, ratio_grain:float, total_ratio:float)->Array:
	var outcome:Array = [people_value,animal_value,grain_value,guy_value,0,0]
	
	var sacrifice_people=outcome[0]*ratio_people*total_ratio
	var sacrifice_animal=outcome[1]*ratio_animal*total_ratio
	var sacrifice_grain=outcome[2]*ratio_grain*total_ratio
	
	#献祭后人、牲、粮的剩余值
	outcome[0]-=sacrifice_people
	outcome[1]-=sacrifice_animal
	outcome[2]-=sacrifice_grain
	
	#计算献祭后guy值
	var a = outcome[0] / float(people_sup)
	var b = outcome[1] / float(animal_sup)
	var c = outcome[2] / float(grain_sup)
	
	outcome[3]=guy_sup*(a*b*c)**2/(((a+b+c)/3)**5) if (a+b+c) != 0 else 0
	
	#计算献祭后能加多少献祭值与爻
	var sacrifice_value = \
		sacrifice_people*(1+qi_buff_info[spirit]["people_weight"]) \
		+sacrifice_animal*(1+qi_buff_info[spirit]["animal_weight"]) \
		+sacrifice_grain*(1+qi_buff_info[spirit]["grain_weight"])
	
	var sacri_ := updateScrificeValue(sacrifice_value)
	
	outcome[4]=sacri_[0]
	outcome[5]=sacri_[1]
	
	return outcome



#更新献祭值，满了生成一对阴阳爻，返回阴阳爻对数
func updateScrificeValue(sacrifice_value:int)->Array:
	@warning_ignore("integer_division")
	var yao_num:int = (sacrifice_value+sacrifice_bar_value) / sacrifice_bar_sup
	var left_value:int = (sacrifice_value+sacrifice_bar_value) % sacrifice_bar_sup
	
	
	return [left_value,yao_num]

#生成了这么多对爻
func spawnYaos(num:int):
	#当生成的爻大于上线了之后直接没了。（偷懒嘻嘻
	var temp = yao_num_sup-yao_yang_num-yao_yin_num
	if num*2>temp:
		print("[WARNING]你承载不了过多的爻！多余的阴阳爻已消散！")
	else:
		temp = num
	
	yao_yang_num+=temp
	yao_yin_num+=temp
	
	



#endregion

#region 祈愿相关

func wishForGua(gua_:ENUMS.Gua):
	gua_now=gua_
	if gua_!=ENUMS.Gua.NONE:
		belief_value+=wish_belief_addition
		lunar_buff_now=lunar_phase_now
	else:
		lunar_buff_now=ENUMS.LunarPhase.NONE

#endregion


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
			#更新事件流界面数值
			EventStremPage.rederBelief(belief_value/ float(belief_sup),gua_now,lunar_buff_now)
			EventStremPage.EPupdateValues(
				air_value/ float(air_sup)
				,guy_value/ float(guy_sup)
				,earth_value/ float(earth_sup)
				,people_value/ float(people_sup)
				,animal_value/ float(animal_sup)
				,grain_value/ float(grain_sup)
				)
			EventStremPage.EPupdateTimeLine(days,solar_term_now,lunar_phase_now,year_now)
			print("///切换至”事件流“界面///")
		1:
			EventStremPage.visible = false
			SacrificePage.visible = true
			WishPage.visible = false
			#更新祭祀界面的数值
			SacrificePage.renderBars(people_value / float(people_sup)
				,animal_value / float(animal_sup)
				,grain_value / float(grain_sup)
				,guy_value / float(guy_sup)
				,sacrifice_bar_value / float(sacrifice_bar_sup)
				,0)
			SacrificePage.renderPreviewBars(people_value / float(people_sup)
				,animal_value / float(animal_sup)
				,grain_value / float(grain_sup)
				,guy_value / float(guy_sup)
				,sacrifice_bar_value / float(sacrifice_bar_sup)
				,0)
			print("///切换至”祭祀“界面///")
		2:
			EventStremPage.visible = false
			SacrificePage.visible = false
			WishPage.visible = true
			#更新爻的数值
			WishPage.updateYao(yao_yin_num,yao_yang_num)
			WishPage.changeGuaDisplay(gua_now)
			WishPage.renderLunarPhaseNow(lunar_phase_now)
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


#region 客户端操作

#玩家按下“下一个事件”
func clientPushNextEvent() -> void:
	print("结算一次事件！")
	var is_term_empty = anEventHappen()
	
	#判定条件事件 
	var history_events_ = event_history.duplicate()
	if event_history.size()>MAX_CONDITION_LOOK_BACK_NUMBER:
		history_events_ = history_events_.slice(event_history.size()-MAX_CONDITION_LOOK_BACK_NUMBER-1,event_history.size())
	var condi_events_list = EventDataBase.colletConditionEvent(history_events_,air_value,guy_value,earth_value,people_value,animal_value,grain_value)
	var possible_condi_events_list:Array
	for con_event_id in condi_events_list:
		if con_event_id in history_events_:
			possible_condi_events_list.append(con_event_id)
	
	if !possible_condi_events_list.is_empty():
		event_list.insert(0,possible_condi_events_list.pick_random())
		recountDurationEachEvent()
	
	
	
	#在事件流处显示事件文本->延迟->显示结果
	EventStremPage.EPupdateEventText(this_event_name,this_event_context,this_event_result_context,this_event_level,this_event_type,this_result_type,is_term_empty)
	#->结算数值
	EventStremPage.rederBelief(belief_value/ float(belief_sup),gua_now,lunar_buff_now)
	EventStremPage.EPupdateValues(
				air_value/ float(air_sup)
				,guy_value/ float(guy_sup)
				,earth_value/ float(earth_sup)
				,people_value/ float(people_sup)
				,animal_value/ float(animal_sup)
				,grain_value/ float(grain_sup)
				)
	#->时间改变
	EventStremPage.EPupdateTimeLine(days,solar_term_now,lunar_phase_now,year_now)


#玩家调整献祭比例
func clientPreviewSacrificeResult(people_ratio: float, animal_ratio: float, garin_ratio: float, total_ratio: float) -> void:
	var pre_outcome:=calculateScrificeValue(people_ratio,animal_ratio,garin_ratio,total_ratio)
	
	var p = pre_outcome[0]/ float(people_sup)
	var a = pre_outcome[1]/ float(animal_sup)
	var g = pre_outcome[2]/ float(grain_sup)
	var guy = pre_outcome[3]/ float(guy_sup)
	var sac = pre_outcome[4]/ float(sacrifice_bar_sup)
	var yao = pre_outcome[5]
	
	
	SacrificePage.renderPreviewBars(p,a,g,guy,sac,yao)


#玩家按下“确认祭祀”
func clientConfirmSacrifice(people_ratio: float, animal_ratio: float, garin_ratio: float, total_ratio: float) -> void:
	sacrifice_ratio["people_ratio"]=people_ratio
	sacrifice_ratio["animal_ratio"]=animal_ratio
	sacrifice_ratio["grain_ratio"]=garin_ratio
	sacrifice_ratio["total_ratio"]=total_ratio
	var outcome = calculateScrificeValue(people_ratio,animal_ratio,garin_ratio,total_ratio)
	people_value = outcome[0]
	animal_value = outcome[1]
	grain_value = outcome[2]
	updateGuy()
	sacrifice_bar_value = outcome[4]
	spawnYaos(outcome[5])
	
	SacrificePage.renderBars(people_value / float(people_sup)
		,animal_value / float(animal_sup)
		,grain_value / float(grain_sup)
		,guy_value / float(guy_sup)
		,sacrifice_bar_value / float(sacrifice_bar_sup)
		,outcome[5])
	
	clientPreviewSacrificeResult(people_ratio, animal_ratio, garin_ratio, total_ratio)

#Hamming距离
func popcount(n:int)->int:
	var count =0
	while n != 0:
		n=n&(n-1)
		count+=1
	return count

#玩家按下“确认祈愿结果”
func clientConfirmWish(gua: ENUMS.Gua) -> void:
	var p=popcount(gua)
	if yao_yang_num>=p and yao_yin_num>=3-p:
		yao_yang_num-=p
		yao_yin_num-=(3-p)
		wishForGua(gua)
	else:
		print("[WARNIG]祈愿失败，所需爻不够！")
	
	WishPage.changeGuaDisplay(gua_now)
	WishPage.updateYao(yao_yin_num,yao_yang_num)


func _on_open_options_pressed() -> void:
	game_setting_ui.show()

func _on_close_game_setting() -> void:
	game_setting_ui.hide()
