extends Control
class_name ClientEventPage

# 转换自 torch/game/events_stream.torch (Orchestrator OScript)
# 事件流界面：祭祀/祈愿按钮发出跳转信号，下一事件按钮向事件流文本追加一行。

signal go_to_wish
signal go_to_sacrifice
signal next_event

@export var event_stream_text: RichTextLabel
@export var debug_event: String = "[some event context]"
const NEW_LINE: String = "[br]"




#region 客户端：事件流 操作

#更新信仰值
func EPupdateBelief(server_belief:int):
	#debug
	print("server_belief"+str(server_belief))

#更新三值、人小值
func EPupdateValues(
	server_air:int,
	server_guy:int,
	server_earth:int,
	server_people:int,
	server_animal:int,
	server_grain:int
	):
	#debug
	print("server_air"+str(server_air))
	print("server_guy"+str(server_guy))
	print("server_earth"+str(server_earth))
	print("server_people"+str(server_people))
	print("server_animal"+str(server_animal))
	print("server_grain"+str(server_grain))
	
	
#更新时间轴
func EPupdateTimeLine(
	server_day:float,
	server_solar_term:ENUMS.SolarTerm,
	server_lunar_phase:ENUMS.LunarPhase,
	server_years:int
	):
	#debug
	print("server_day"+str(server_day))
	print("server_solar_term"+str(server_solar_term))
	print("server_lunar_phase"+str(server_lunar_phase))
	print("server_years"+str(server_years))
	
#更新事件流文本
func EPupdateEventText(
	server_event_name:String,
	server_event_text:String,
	server_event_result_text:String,
	this_event_level :ENUMS.EventLevel,
	this_event_type :ENUMS.EventType,
	is_term_empty:bool
):
	#debug
	if is_term_empty:
		event_stream_text.append_text(NEW_LINE+server_event_name)
		event_stream_text.append_text(NEW_LINE+server_event_text)
		event_stream_text.append_text(NEW_LINE+server_event_result_text)
		event_stream_text.append_text(NEW_LINE+ENUMS.EventLevel.find_key(this_event_level))
		event_stream_text.append_text(NEW_LINE+ENUMS.EventType.find_key(this_event_type))
	else:
		event_stream_text.append_text(NEW_LINE+server_event_text)
		event_stream_text.append_text(NEW_LINE+server_event_result_text)

#endregion




func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()

func nextEvent() -> void:
	event_stream_text.append_text(NEW_LINE + debug_event)
	emit_signal("next_event")
