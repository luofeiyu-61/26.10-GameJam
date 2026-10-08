extends Resource
class_name EventResult


@export_multiline("结果内容描述") var result_context :String

#触发卦象
@export var meet_gua:Array[ENUMS.Gua]

#信仰值反馈
@export var belief_feedback:int

#数值反馈
@export var air_feedback:int
@export var earth_feedback:int
@export var people_feedback:int
@export var animal_feedback:int
@export var grain_feedback:int
