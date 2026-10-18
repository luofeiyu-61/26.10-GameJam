extends Node

#客户端
@export var EventStremPage:ClientEventPage
@export var SacrificePage:ClientSacrificePage
@export var WishPage:ClientWishPage

@onready var game_setting_ui: CanvasLayer = $GameSettingUI
@onready var close_warning: ColorRect = $options/close_warning
@onready var option: Control = $options/option


#游戏变量
#region 信仰值相关
var gua_now :ENUMS.Gua=ENUMS.Gua.NONE :					#当前卦象
	set(value):
		if WishPage:
			WishPage.changeGuaDisplay(value)
		gua_now=value

var lunar_buff_now :ENUMS.LunarPhase = ENUMS.LunarPhase.NONE	#当前起效的月相buff

@export var lunar_buff_upup:Dictionary[int,float]={#月相增益效果
	0:0.00,
	1:0.35,
	2:0.65,
	3:0.85,
	4:1.00,
	5:0.85,
	6:0.65,
	7:0.35,
	8:0.00
}
@export var lunar_buff_downdown:Dictionary[int,float]={#月相减伤效果
	0:0.00,
	1:0.08,
	2:0.18,
	3:0.35,
	4:0.50,
	5:0.35,
	6:0.18,
	7:0.08,
	8:0.00
}

@export var belief_sup:int = 100	#信仰值上限
@export var belief_value:int = 30:				#信仰值
	set(value):
		belief_value = min(belief_sup,max(0,value))
		#祈愿效果失效
		if belief_value <= 0:
			wishForGua(ENUMS.Gua.NONE)
			if EventStremPage:
				EventStremPage.renderBelief(belief_value,gua_now,lunar_buff_now)
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

#结局事件：天/地/人 任一归零后，下一张卡就是它们；发生后即进入游戏结束
const ENDING_EVENT_ID_AIR = -1		#000-天悲
const ENDING_EVENT_ID_GUY = -2		#000-人绝
const ENDING_EVENT_ID_EARTH = -3	#000-地愤
const ENDING_EVENT_IDS:Array[int]=[ENDING_EVENT_ID_AIR,ENDING_EVENT_ID_GUY,ENDING_EVENT_ID_EARTH]

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
	uiInit()
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

#游戏内容首次开始时的初始化
func firstInitGame():
	#留一份「全新开局」的状态快照（此刻场景里的值还没被任何读档 / 游玩改动过）。
	#游戏内加载空白存档时要用它把游戏恢复成全新开局。
	if _fresh_snapshot == null:
		_fresh_snapshot = _collectSaveTemplate()

	#判定进入游戏时是否带着“选中的存档”（由存档界面 ones_list 设置）
	var save_path := _consumeSelectedSavePath()
	if save_path != "":
		var save_data := _peekSaveTemplate(save_path)
		if save_data != null and !save_data.is_new_save:
			#已有游玩数据的存档：读档
			if load_game(save_path):
				return
			print("[WARNING]读档失败，改用默认值开新游戏：%s" % save_path)
		#新建但尚未游玩的存档：不载入数据，采用本脚本(one.gd)里的默认变量值

	#新游戏 / 新建存档
	if days == 0.0:
		lunar_phase_now = 0 as ENUMS.LunarPhase #具体算法已内置到变量的定义环节
		solar_term_now = int((days+solar_shift)/SOLAR_TERM_TIME)%24 as ENUMS.SolarTerm
		newEventList(solar_term_now)
	
	updateGuy()
	updateSpirit()

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
		
		#结局事件（天悲/人绝/地愤）发生 → 进入游戏结束
		if id in ENDING_EVENT_IDS:
			endGame()
		return true

#月相buff作用公式
func updateValueByLunarBuff(target_value:int,feedback_value:int)->int:
	if feedback_value>0:
		target_value+=int((1+lunar_buff_upup[lunar_buff_now])*feedback_value)
	elif feedback_value<0:
		target_value+=int((1-lunar_buff_downdown[lunar_buff_now])*feedback_value)
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
	
	var people_weight:float
	if sacrifice_people<=30:people_weight=3
	else:people_weight=4
	
	
	#计算献祭后能加多少献祭值与爻
	var sacrifice_value = \
		sacrifice_people*people_weight*(1+qi_buff_info[spirit]["people_weight"]) \
		+sacrifice_animal*0.5*(1+qi_buff_info[spirit]["animal_weight"]) \
		+sacrifice_grain*2.5*(1+qi_buff_info[spirit]["grain_weight"])
	
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

	if num*2 > temp:
		print("[WARNING]你承载不了过多的爻！多余的阴阳爻已消散！")
		@warning_ignore("integer_division")
		var t = min(yao_num_sup/2-yao_yang_num,yao_num_sup/2-yao_yin_num)
		yao_yang_num+=t
		yao_yin_num+=t
	else:
		yao_yang_num+=num
		yao_yin_num+=num


	



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




#region 主窗口管理：事件流 / 祭祀 / 祈愿 三个子界面的切换，以及返回主菜单信号。
# windowIndex: 0=事件流, 1=祭祀, 2=祈愿
func switch_window_to(window_index: int) -> void:
	match window_index:
		0:
			EventStremPage.visible = true
			SacrificePage.visible = false
			WishPage.visible = false
			#更新事件流界面数值
			EventStremPage.renderBelief(belief_value/ float(belief_sup),gua_now,lunar_buff_now)
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
			WishPage.updateQi(spirit)
			WishPage.initYaosAtSpirit(yao_yang_num,yao_yin_num,yao_num_sup)
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

#打开节气日历（Events_window 的 solar_calendar 按键 → Events_window.open_solar_calendar 信号）
#收集：天数、年份、当前节气、本节气「可能发生」与「已经发生」的事件，交给 events_stream 渲染。
func clientOpenSolarCalendar() -> void:
	if EventStremPage == null:
		return

	#① 本节气所有可发生的固定事件（EventDataBase 按 trigger_terms 收集）
	var possible_events: Array[EventCard] = []
	var possible_ids: Array[int] = EventDataBase.collectFixedEvent(solar_term_now)
	for id in possible_ids:
		if EventDataBase.all_events.has(id):
			possible_events.append(EventDataBase.all_events[id])

	#② 今年 + 本节气已经发生过的事件（all_history: {"Year0":{"SolarTerm0":[[id,result],...]}}）
	var yk: String = "Year%d" % year_now
	var tk: String = "SolarTerm%d" % int(solar_term_now)
	var happened_events: Array[EventCard] = []
	var happened_ids: Dictionary = {}
	if all_history.has(yk) and all_history[yk].has(tk):
		for row in all_history[yk][tk]:
			var hid: int = int(row[0])
			if EventDataBase.all_events.has(hid):
				happened_events.append(EventDataBase.all_events[hid])
				happened_ids[hid] = true

	#③ 「可能发生」里去掉已经发生过的，避免同一张卡出现两次
	var remain_events: Array[EventCard] = []
	for e in possible_events:
		if !happened_ids.has(e.id):
			remain_events.append(e)

	#④ 交给 events_stream：年份显示用 year_now + 1
	EventStremPage.openSolarCalendar(days, year_now + 1, solar_term_now, remain_events, happened_events)


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
		#没在回看窗口里出现过的才插队（否则同一个条件事件会在窗口内反复触发）
		if con_event_id not in history_events_:
			possible_condi_events_list.append(con_event_id)
	
	if !possible_condi_events_list.is_empty():
		#结局卡优先：天/地/人归零时，下一张必须是结局卡，不能被别的条件事件随机挤掉
		var next_event_id = possible_condi_events_list.pick_random()
		for ending_id in ENDING_EVENT_IDS:
			if ending_id in possible_condi_events_list:
				next_event_id = ending_id
				break
		event_list.insert(0,next_event_id)
		recountDurationEachEvent()
	
	
	
	#在事件流处显示事件文本->延迟->显示结果
	EventStremPage.EPupdateEventText(this_event_name,this_event_context,this_event_result_context,this_event_level,this_event_type,this_result_type,is_term_empty)
	#->结算数值
	EventStremPage.renderBelief(belief_value/ float(belief_sup),gua_now,lunar_buff_now)
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
	
	
	
	var delta_people=people_value-outcome[0]
	var delta_grain=animal_value-outcome[1]
	var delta_animal=grain_value-outcome[2]
	
	air_value-=ceil((delta_people)*0.2)+(ceil((delta_animal-20)*0.15) if delta_animal>20 else 0)
	
	earth_value-=(ceil((delta_grain-120)*0.1) if delta_grain>120 else 0)+(ceil((delta_animal-20)*0.2) if delta_animal>20 else 0)
	
	
	
	
	people_value = outcome[0]
	animal_value = outcome[1]
	grain_value = outcome[2]
	updateGuy()
	sacrifice_bar_value = outcome[4]
	spawnYaos(outcome[5])
	
	updateSpirit()
	
	clientPreviewSacrificeResult(people_ratio, animal_ratio, garin_ratio, total_ratio)
	
	SacrificePage.renderBars(people_value / float(people_sup)
		,animal_value / float(animal_sup)
		,grain_value / float(grain_sup)
		,guy_value / float(guy_sup)
		,sacrifice_bar_value / float(sacrifice_bar_sup)
		,outcome[5])
	

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
	
	updateSpirit()
	WishPage.endYaosAll()
	WishPage.initYaosAtSpirit(yao_yang_num,yao_yin_num,yao_num_sup)
	WishPage.updateQi(spirit)
	WishPage.changeGuaDisplay(gua_now)
	WishPage.updateYao(yao_yin_num,yao_yang_num)

#endregion


#region 一些按键

func uiInit():
	option.hide()
	close_warning.hide()
	game_setting_ui.hide()



#打开游戏设置
func _on_open_game_setting() -> void:
	game_setting_ui.show()
#关闭游戏设置
func _on_close_game_setting() -> void:
	game_setting_ui.hide()


#退出游戏警告
func _on_back_to_menu_pressed() -> void:
	close_warning.show()

#返回主菜单（无保存）
func _on_confirm_back_to_pressed() -> void:
	back_to_main_menu.emit()
	queue_free()

#打开/关上选项卡
func _on_option_button_pressed() -> void:
	if option.visible:option.hide()
	else:option.show()


func _on_cancel_warning_pressed() -> void:
	close_warning.hide()


#endregion


#region 存档读写（3.1 存档位置 / 3.3 存档读写）
#说明：本区只实现存档的读写函数，暂不耦合进游戏主逻辑（如 firstInitGame / anEventHappen）。
#存档文件：<存档目录>/save_N.tres，内容为 SaveTemplate 资源。
#存档目录由 GamePaths 决定：编辑器里是 res://saves/，导出成 exe 后是 exe 同目录的 saves/（绿色版，不写 C 盘）。

static var SAVE_DIR: String = GamePaths.saveDir()

#存档界面脚本（用于读取它记录下来的“选中存档路径”）
const OnesListScript := preload("res://script/pages/ones_list.gd")

#「全新开局」的状态快照：firstInitGame 一进来就抓一份（那时场景里的值还没被改过）。
#用途：游戏内加载一个「新建但还没游玩过」的空白存档时，要把游戏恢复成全新开局；
#     而那时场景初始值早被玩过一轮改掉了，所以必须先留一份。
var _fresh_snapshot: SaveTemplate = null

#取出存档界面选中的待载入存档路径，并清空（避免下次进入游戏时误用旧路径）
func _consumeSelectedSavePath() -> String:
	var path:String = OnesListScript.pending_save_path
	OnesListScript.pending_save_path = ""
	return path


#只看存档里的标志位，不载入游戏（新建存档 / 已有存档 的判定用）
func _peekSaveTemplate(game_save_file:String) -> SaveTemplate:
	if !FileAccess.file_exists(game_save_file):
		return null
	var data = ResourceLoader.load(game_save_file,"",ResourceLoader.CACHE_MODE_IGNORE)
	if data == null or !(data is SaveTemplate):
		return null
	return data

#把「当前游戏状态」收进一个 SaveTemplate（不写盘）。
#save_game 与 firstInitGame 开头的「全新开局快照」都用它 —— 以后新增存档字段只要改这一处。
func _collectSaveTemplate() -> SaveTemplate:
	var save_data := SaveTemplate.new()
	save_data.is_empty = false
	save_data.is_new_save = false
	save_data.save_time = SaveTemplate.nowSaveTime()

	#—— 信仰 / 卦象 ——
	save_data.gua_now = int(gua_now)
	save_data.lunar_buff_now = int(lunar_buff_now)
	save_data.belief_value = belief_value

	#—— 天人地 ——
	save_data.air_value = air_value
	save_data.earth_value = earth_value
	save_data.people_value = people_value
	save_data.animal_value = animal_value
	save_data.grain_value = grain_value

	#—— 献祭 ——
	save_data.sacrifice_ratio = sacrifice_ratio.duplicate(true)
	save_data.sacrifice_bar_value = sacrifice_bar_value

	#—— 阴阳爻 / 气 ——
	save_data.yao_yin_num = yao_yin_num
	save_data.yao_yang_num = yao_yang_num
	save_data.spirit = int(spirit)

	#—— 时间轴 ——
	#注意：year_now / lunar_phase_now 的 set 会根据 days 重算
	#     solar_term_now / lunar_phase_now 由函数末尾的 timePassBy(0) 刷新
	save_data.days = days
	save_data.year_now = year_now
	save_data.solar_shift = solar_shift
	save_data.lunar_shift = lunar_shift

	#—— 事件 ——
	save_data.event_list = event_list.duplicate()
	save_data.event_duration_list = event_duration_list.duplicate()
	save_data.event_history = event_history.duplicate()
	save_data.event_history_result = _resultTypesToInts(event_history_result)
	save_data.all_history = all_history.duplicate(true)

	#—— 子界面文本 ——
	#注意：必须取事件流的「原始 BBCode 镜像」getEventText()：
	#     · 不能用 text 属性——append_text() 不更新它（它只反映最后一次被赋的值）；
	#     · 也不能用 get_parsed_text()——它会把 [color=...] 标签全部剥掉，
	#       读档时就没颜色可还原了（这正是之前颜色丢失的原因）。
	#     镜像由 events_stream.gd 的 appendEventText() 维护，存的是带标签的原文。
	if EventStremPage != null:
		save_data.event_stream_text = EventStremPage.getEventText()

	return save_data


#把当前游戏状态写入存档文件 game_save_file（完整路径，如 "res://saves/save_1.tres"）
func save_game(game_save_file:String) -> bool:
	var save_data := _collectSaveTemplate()
	save_data.slot_index = _slotIndexFromPath(game_save_file)

	_ensureSaveDir()
	var err := ResourceSaver.save(save_data, game_save_file)
	if err != OK:
		print("[ERROR]存档写入失败：%s (err=%d)" % [game_save_file, err])
		return false
	print("///已保存至 %s///" % game_save_file)
	return true


#从存档文件 game_save_file 读取并载入游戏状态
func load_game(game_save_file:String) -> bool:
	if !FileAccess.file_exists(game_save_file):
		print("[WARNING]存档不存在：%s" % game_save_file)
		return false
	#CACHE_MODE_IGNORE：绕开资源缓存，保证读到的是磁盘上最新的存档
	var save_data = ResourceLoader.load(game_save_file,"",ResourceLoader.CACHE_MODE_IGNORE)
	if save_data == null or !(save_data is SaveTemplate):
		print("[ERROR]存档损坏或类型不符：%s" % game_save_file)
		return false

	#「新建但还没游玩过」的空白存档：SaveTemplate 只是数据容器，里面的游戏变量全是 0，
	#直接套上去会把当前游戏清空 —— 这就是游戏内读空白存档失败的根因。
	#正确语义：读这种存档 = 开一局全新的游戏 → 把数据源换成「全新开局快照」。
	var fresh_start:bool = save_data.is_new_save
	if fresh_start:
		if _fresh_snapshot == null:
			_fresh_snapshot = _collectSaveTemplate()
		save_data = _fresh_snapshot

	#—— 时间轴 ——
	#注意：solar_term_now / lunar_phase_now 不存盘，由函数末尾的 timePassBy(0) 刷新
	solar_shift = save_data.solar_shift
	lunar_shift = save_data.lunar_shift
	days = save_data.days
	year_now = 0
	#先按 timePassBy 里的同一公式对齐 solar_term_now，
	#这样末尾的 timePassBy(0) 不会因“节气变化”而重建事件列表（那会冲掉读到的 event_list）
	solar_term_now = int((days+solar_shift)/SOLAR_TERM_TIME)%24 as ENUMS.SolarTerm

	#—— 阴阳爻 / 气 ——
	#注意：spirit 的 set 会根据阴阳爻数量重算，直接赋值即可
	yao_yin_num = save_data.yao_yin_num
	yao_yang_num = save_data.yao_yang_num
	spirit = 0 as ENUMS.Qi

	#—— 天人地 ——
	#先设人小值，“人”由 updateGuy() 重算
	people_value = save_data.people_value
	animal_value = save_data.animal_value
	grain_value = save_data.grain_value
	updateGuy()
	air_value = save_data.air_value
	earth_value = save_data.earth_value

	#—— 献祭 ——
	#注意：sacrifice_ratio 是 Dictionary[String,float]，逐键赋值以免类型不符
	sacrifice_ratio["people_ratio"] = save_data.sacrifice_ratio.get("people_ratio", 0.0)
	sacrifice_ratio["animal_ratio"] = save_data.sacrifice_ratio.get("animal_ratio", 0.0)
	sacrifice_ratio["grain_ratio"] = save_data.sacrifice_ratio.get("grain_ratio", 0.0)
	sacrifice_ratio["total_ratio"] = save_data.sacrifice_ratio.get("total_ratio", 0.0)
	sacrifice_bar_value = save_data.sacrifice_bar_value

	#—— 信仰 / 卦象 ——
	#注意：belief_value 的 set 在 <=0 时会清空卦象，故先设 belief 再设卦象
	belief_value = save_data.belief_value
	gua_now = save_data.gua_now as ENUMS.Gua
	lunar_buff_now = save_data.lunar_buff_now as ENUMS.LunarPhase

	#—— 事件 ——
	event_list = save_data.event_list.duplicate()
	event_duration_list = save_data.event_duration_list.duplicate()
	event_history = save_data.event_history.duplicate()
	event_history_result = _intsToResultTypes(save_data.event_history_result)
	all_history = save_data.all_history.duplicate(true)

	#—— 子界面文本 ——
	#setEventText() 内部给 text 整体赋值（清空并替换内部缓冲）并按 bbcode 重新解析，
	#配合场景里 texts 节点的 bbcode_enabled = true，[color=...] 颜色即可还原
	if EventStremPage != null:
		EventStremPage.setEventText(save_data.event_stream_text)

	#刷新时间轴派生量（solar_term_now / lunar_phase_now）
	timePassBy(0)

	#全新开局：快照抓的是「场景初始值」，那会儿 event_list 还是空的，
	#所以要按当前节气重新生成一份事件列表（与 firstInitGame 的「新游戏」分支保持一致）
	if fresh_start:
		if days == 0.0:
			lunar_phase_now = 0 as ENUMS.LunarPhase
			solar_term_now = int((days+solar_shift)/SOLAR_TERM_TIME)%24 as ENUMS.SolarTerm
			newEventList(solar_term_now)
		updateGuy()
		updateSpirit()

	#读档后复原「游戏结束」状态（存档里不会记录死亡，读档就是重开）
	_setGameOver(false)

	refreshAllDisplay()
	#按“当前所在的界面”再整屏重画一次：
	#玩家可能在祭祀/祈愿界面里读档，只刷新事件流界面（refreshAllDisplay）不够，
	#当前界面上残留的还是读档前的旧数据。
	WishPage.endYaosAll()
	switch_window_to(_currentWindowIndex())
	if fresh_start:
		print("///已读取存档 %s（空白存档 → 按全新开局处理）///" % game_save_file)
	else:
		print("///已读取存档 %s///" % game_save_file)
	return true


#刷新所有界面显示（载入存档后调用）
func refreshAllDisplay() -> void:
	EventStremPage.renderBelief(belief_value/ float(belief_sup),gua_now,lunar_buff_now)
	EventStremPage.EPupdateValues(
				air_value/ float(air_sup)
				,guy_value/ float(guy_sup)
				,earth_value/ float(earth_sup)
				,people_value/ float(people_sup)
				,animal_value/ float(animal_sup)
				,grain_value/ float(grain_sup)
				)
	EventStremPage.EPupdateTimeLine(days,solar_term_now,lunar_phase_now,year_now)


#当前显示的是哪个子界面（0=事件流, 1=祭祀, 2=祈愿）
#由三个页面的 visible 反推：switch_window_to() 每次都保证恰好只有一个为 true
func _currentWindowIndex() -> int:
	if SacrificePage != null and SacrificePage.visible:
		return 1
	if WishPage != null and WishPage.visible:
		return 2
	return 0


#存档目录不存在时创建
func _ensureSaveDir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


#从存档路径解析存档位编号（res://saves/save_3.tres -> 3），解析失败返回 -1
func _slotIndexFromPath(game_save_file:String) -> int:
	var num_text := ""
	for ch in game_save_file.get_file():
		if ch >= "0" and ch <= "9":
			num_text += ch
	if num_text.is_valid_int():
		return num_text.to_int()
	return -1


#ENUMS.ResultType 数组 -> int 数组（写入存档用）
func _resultTypesToInts(results:Array) -> Array[int]:
	var out:Array[int]
	for r in results:
		out.append(int(r))
	return out


#int 数组 -> ENUMS.ResultType 数组（读取存档用）
func _intsToResultTypes(values:Array) -> Array[ENUMS.ResultType]:
	var out:Array[ENUMS.ResultType]
	for v in values:
		out.append(int(v) as ENUMS.ResultType)
	return out

#endregion

#region 存档界面（游戏内入口 1.3 / 出口 1.4）

#游戏内存档界面实例
var _save_window:Node = null

#打开存档界面（游戏内入口）：把它加入场景树；不隐藏、不改动游戏内容
func openSaveWindow() -> void:
	if _save_window != null and is_instance_valid(_save_window):
		return
	var save_window = preload("res://scenes/pages/ones_list.tscn").instantiate()
	save_window.is_from_game = true
	save_window.connect("request_load_game",Callable(self,"_on_save_window_load_game"))
	save_window.connect("request_save_game",Callable(self,"_on_save_window_save_game"))
	add_child(save_window)
	_save_window = save_window
	print("///打开存档界面（游戏内）///")


#存档界面请求“加载存档”
func _on_save_window_load_game(save_path:String) -> void:
	load_game(save_path)


#存档界面请求“保存存档”
func _on_save_window_save_game(save_path:String) -> void:
	save_game(save_path)


#按键：options/option/selections/saves（游戏内入口）
func _on_selections_saves_pressed() -> void:
	option.hide()
	openSaveWindow()


#按键：options/close_warning/HBoxContainer/save（游戏内入口）
func _on_close_warning_save_pressed() -> void:
	close_warning.hide()
	openSaveWindow()

#endregion





#region 游戏结束

#结局事件（天悲/人绝/地愤）发生后置 true；读档/新游戏时复位
var game_over: bool = false

#结局事件发生后调用：禁掉一切能继续推进游戏的操作
func endGame():
	print("游戏结束")
	_setGameOver(true)


#开关「游戏结束」状态：
#  · 事件流：禁「下一事件」（events_stream 里也留一份，文本播完不会把它重新点亮）
#  · 祭祀：禁「确认献祭」+ 4 个比例滑块
#  · 祈愿：禁「保存祈愿」
#读档时用 _setGameOver(false) 复原。
func _setGameOver(value: bool):
	game_over = value

	#事件流
	if EventStremPage != null:
		EventStremPage.setGameOver(value)

	#祭祀：确认献祭 + 比例滑块（RatioSetWindow/SacrificeRatio 下的 4 根）
	if SacrificePage != null:
		var confirm := SacrificePage.get_node_or_null("operations/confirmsacrifice")
		if confirm is BaseButton:
			(confirm as BaseButton).disabled = value
		for slider_name in ["Total", "people", "animal", "grain"]:
			var slider := SacrificePage.get_node_or_null("RatioSetWindow/SacrificeRatio/" + slider_name)
			if slider is Slider:
				(slider as Slider).editable = not value

	#祈愿：保存祈愿
	if WishPage != null:
		var save_wish := WishPage.get_node_or_null("operations/savewish")
		if save_wish is BaseButton:
			(save_wish as BaseButton).disabled = value


#endregion
