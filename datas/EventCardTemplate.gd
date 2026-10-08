extends Resource
class_name EventCard

#事件基本属性
@export_category("事件基本属性")
@export var id:int
@export var id_name:String
@export var display_name:String
#持续时间
@export var time_consume:ENUMS.TimeLength

#事件内容
@export_category("事件内容")
@export_multiline("事件内容描述") var context :String
@export var event_level :ENUMS.EventLevel
@export var event_type :ENUMS.EventType

#触发条件
@export_category("触发条件")
@export var trigger_type :ENUMS.TriggerType

@export_subgroup("固定：发生节气")
@export var trigger_term :ENUMS.SolarTerm

@export_subgroup("条件：具体条件")

#在单个指定事件发生后才发生
@export var is_after:bool
@export var trigger_after_event_id:Array[int]

#在某指定值达到某个条件后才发生(条件：目标变量、值、关系，索引分别对应)
@export var is_meet:bool
@export var trigger_meet_info:Array[TriggerCondition]

@export_subgroup("随机：发生概率")
@export_range(0,1.0) var trigger_possibility:float



#事件结果
@export_category("事件结果")
@export_subgroup("好")

@export var result_good :EventResult

@export_subgroup("平庸")

@export var result_normal :EventResult

@export_subgroup("坏")

@export var result_bad :EventResult
