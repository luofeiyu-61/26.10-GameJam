extends Node
class_name EVENTS

const EVENT_CARDS_DIR:="res://events/"

var all_events:Dictionary[int,EventCard]={}

var fixed_events:Array[int]
var condition_events:Array[int]
var random_events:Array[int]

func _ready() -> void:
	loadAllEventCards(EVENT_CARDS_DIR)
	initClassifyEvents()


#轮询事件文件夹
func loadAllEventCards(EVENT_CARD_DIR):
	var dir := DirAccess.open(EVENT_CARD_DIR)
	if dir == null:
		push_error("事件目录不存在: " + EVENT_CARD_DIR)
		return
	
	dir.list_dir_begin()
	var file_name:=dir.get_next()
	
	while file_name!="":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var event:EventCard = load(EVENT_CARD_DIR+file_name)
			if event:
				#注册事件
				registerEvent(event)
		
		file_name=dir.get_next()
	dir.list_dir_end()
	print("已注册卡牌数量: ",all_events.size())

#注册事件
func registerEvent(event:EventCard)->bool:
	if event.id == null:
		push_error("事件缺少id："+event.resource_path)
		return false
		
	if all_events.has(event.id):
		push_error("重复事件id：	id="+str(event.id)
					+"\n	"+all_events[event.id].resource_path
					+"\n	"+event.resource_path)
		return false
		
	all_events[event.id]=event
	return true

#初分类
func initClassifyEvents():
	if all_events.is_empty():return
		
	for event_id in all_events.keys():
		match all_events[event_id].trigger_type:
			ENUMS.TriggerType.Fixed:
				fixed_events.append(event_id)
			ENUMS.TriggerType.Condition:
				condition_events.append(event_id)
			ENUMS.TriggerType.Random:
				random_events.append(event_id)


#region 事件行为

#收集指定节气事件并返回
func collectFixedEvent(solar_term:ENUMS.SolarTerm)->Array[int]:
	if fixed_events.is_empty():
		print("[WARNING]没有固定事件！")
		return []
		
	var target_events:Array[int]
	
	for id in fixed_events:
		if all_events[id].trigger_term == solar_term:
			target_events.append(id)
	
	print("///收集到%d个%s事件" % [target_events.size(), ENUMS.SolarTerm.find_key(solar_term)])
	return target_events


#查询可触发的条件事件并返回		chosen_history_event_ids: 截取一段历史用于查询前置事件，这样设计的目的是为了方便做可重复触发的序列事件
func colletConditionEvent(chosen_history_event_ids:Array[int],air_now:int,guy_now:int,earth_now:int,people_now:int,animal_now:int,grain_now:int)->Array[int]:
	
	if condition_events.is_empty():
		print("[WARNING]没有条件事件！")
		return []
	
	var target_events:Array[int]
	var is_trigger:bool=false	#用于判断最终是否满足条件的临时变量
	
	for id in condition_events:
		is_trigger=true
		if all_events[id].is_after:#查询前置事件
			for condition_id in all_events[id].trigger_after_event_id:#轮询条件
				if condition_id not in chosen_history_event_ids: #前置事件没在提供历史中
					is_trigger=false
					
		if all_events[id].is_meet:#查询数值条件
			for condition in all_events[id].trigger_meet_info:#轮询条件
				match condition.trigger_meet_type:#看是哪个值
					ENUMS.MeetWhich.Air:
						if (air_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :#不满足数值条件
							is_trigger=false
					ENUMS.MeetWhich.Guy:
						if (guy_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :
							is_trigger=false
					ENUMS.MeetWhich.Earth:
						if (earth_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :
							is_trigger=false
					ENUMS.MeetWhich.People:
						if (people_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :
							is_trigger=false
					ENUMS.MeetWhich.Animal:
						if (animal_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :
							is_trigger=false
					ENUMS.MeetWhich.Grain:
						if (grain_now-condition.trigger_meet_value)*condition.trigger_meet_type<0 :
							is_trigger=false
							
		if is_trigger:
			target_events.append(id)
	
	return target_events


#抽取最多max_event_number个随机事件并返回	*注意有可能抽不满
func collectRandomEvent(max_event_number:int)->Array[int]:
	if random_events.is_empty():
		print("[WARNING]没有随机事件！")
		return []
		
	var target_events:Array[int]
	
	var temp_=random_events.duplicate()
	for i in range(max_event_number):
		if temp_.is_empty():break
		temp_.shuffle()
		var t = temp_.pop_back()#随机选一个事件
		if randf()<=all_events[t].trigger_possibility:#根据事件的概率选择是否加入
			target_events.append(t)
	
	print("///收集到%d个随机事件" % target_events.size())
	return target_events

#返回当前卦象下应得的结果
func whatResultItIs(event_id:int,gua_now:ENUMS.Gua)->EventResult:
	
	var result_:EventResult = all_events[event_id].result_good
	
	if gua_now in all_events[event_id].result_good.meet_gua:#好结果
		result_ = all_events[event_id].result_good
		
	elif gua_now in all_events[event_id].result_bad.meet_gua:#坏结果
		result_ = all_events[event_id].result_bad
		
	else:#平凡结果
		result_ = all_events[event_id].result_normal
	
	return result_



#endregion
