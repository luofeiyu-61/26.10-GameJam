extends Resource
class_name SaveTemplate

#游戏存档模板
#用于 one.gd 的 save_game() / load_game() 读写
#存档文件位于 res://saves/save_N.tres
#
#★注意：本类只是“数据容器”。
# 下面各游戏变量的初值一律留 0/空，**不代表游戏默认值**。
# 新游戏的默认值以 one.gd 里的变量定义为准（便于后续调整数值）。

#region 存档元信息
@export var slot_index:int = -1				#存档位（1~4），-1=未指定
@export var is_empty:bool = true			#是否为空存档（没有存档文件 / 已删除）
@export var is_new_save:bool = true			#是否是“新建但还没游玩过”的存档
@export var save_time:String = ""			#存档时间（显示用，格式 2026/10/13  21：05）
#endregion


#region 信仰值相关
@export var gua_now:int = 0					#当前卦象（ENUMS.Gua）
@export var lunar_buff_now:int = 0			#当前起效的月相buff（ENUMS.LunarPhase）
@export var belief_value:int = 0			#信仰值
#endregion


#region 天人地
@export var air_value:int = 0				#天
@export var earth_value:int = 0				#地
@export var people_value:int = 0			#人口
@export var animal_value:int = 0			#牲口
@export var grain_value:int = 0				#粮食
#endregion


#region 献祭、祈愿相关
@export var sacrifice_ratio:Dictionary = {}	#祭品比例分配
@export var sacrifice_bar_value:int = 0		#献祭值
#endregion


#region 阴阳爻、气
@export var yao_yin_num:int = 0				#阴爻
@export var yao_yang_num:int = 0			#阳爻
@export var spirit:int = 0					#气（ENUMS.Qi）
#endregion


#region 时间轴
#solar_term_now / lunar_phase_now 不存：它们由 days / solar_shift / lunar_shift 推导，
#读档后调用一次 one.gd 的 timePassBy(0) 即可刷新。
@export var days:float = 0.0				#游戏天数
@export var year_now:int = 0				#当前年
@export var solar_shift:float = 0.0			#开局节气偏移（不要在局内修改）
@export var lunar_shift:float = 0.0			#开局月相偏移（不要在局内修改）
#endregion


#region 事件相关
@export var event_list:Array[int] = []					#当前节气内待发生的事件id
@export var event_duration_list:Array[float] = []		#对应事件的持续时长
@export var event_history:Array[int] = []				#历史事件id
@export var event_history_result:Array[int] = []		#历史事件结果（ENUMS.ResultType）
@export var all_history:Dictionary = {}					#史记：{YearN:{SolarTermN:[[event_id,result]]}}
#endregion


#region 子界面状态
@export_multiline var event_stream_text:String = ""		#事件流富文本原文（带 BBCode 标签，来自 events_stream.gd 的 getEventText()）
#endregion


#region 游戏结束
#结局事件（天悲/人绝/地愤）已经发生过：读档时要把「下一事件 / 确认献祭 / 4 根比例滑块 / 保存祈愿」
#全部重新禁掉，否则读一个已经死掉的档会把操作又解锁。
@export var game_over:bool = false
#endregion


#当前时间，格式化为存档显示格式：2026/10/13  21：05
static func nowSaveTime() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d/%02d/%02d\n%02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute]
