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

@onready var gua_sprite: AnimatedSprite2D = $"BeliefBar/1/Gua"
@onready var belief_bar_sprite: TextureProgressBar = $"BeliefBar/1"
@onready var lunar_buff: Label = $"BeliefBar/1/lunarBuff"

@onready var air_label: Label = $AirGuyEarth/Air/airLabel
@onready var guy_label: Label = $AirGuyEarth/Guy/guyLabel
@onready var people_label: Label = $AirGuyEarth/Guy/peopleLabel
@onready var animal_label: Label = $AirGuyEarth/Guy/animalLabel
@onready var grain_label: Label = $AirGuyEarth/Guy/grainLabel
@onready var earth_label: Label = $AirGuyEarth/Earth/earthLabel

@onready var air_bar: TextureProgressBar = $AirGuyEarth/Air/air_bar
@onready var guy_bar: TextureProgressBar = $AirGuyEarth/Guy/guy_bar
@onready var people_bar: TextureProgressBar = $AirGuyEarth/Guy/people_bar
@onready var animal_bar: TextureProgressBar = $AirGuyEarth/Guy/animal_bar
@onready var grain_bar: TextureProgressBar = $AirGuyEarth/Guy/grain_bar
@onready var earth_bar: TextureProgressBar = $AirGuyEarth/Earth/earth_bar


@onready var solar: Label = $Calendar/sun/solar
@onready var lunar: Label = $Calendar/lunar/lunar
@onready var days: Label = $Calendar/days



#region 客户端：事件流 操作




#更新三值、人小值	#接受的是百分比
func EPupdateValues(
	server_air:float,
	server_guy:float,
	server_earth:float,
	server_people:float,
	server_animal:float,
	server_grain:float
	):
	#debug
	air_bar.set_value_no_signal(server_air*air_bar.max_value)
	guy_bar.set_value_no_signal(server_guy*guy_bar.max_value)
	people_bar.set_value_no_signal(server_people*people_bar.max_value)
	animal_bar.set_value_no_signal(server_animal*animal_bar.max_value)
	grain_bar.set_value_no_signal(server_grain*grain_bar.max_value)
	earth_bar.set_value_no_signal(server_earth*earth_bar.max_value)
	
	
	
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
	
	
	days.text="游戏天数："+str(server_day)
	solar.text="节气："+"\n"+ENUMS.solarTerm2Text(server_solar_term)
	lunar.text="月相："+"\n"+ENUMS.lunarPhase2Text(server_lunar_phase)
	
	
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


#更新信仰值#接受的是百分比
func rederBelief(belief_now:float,gua:ENUMS.Gua,lunar_buff_now:ENUMS.LunarPhase):
	belief_bar_sprite.set_value_no_signal(belief_now*belief_bar_sprite.max_value)
	
	match gua:
		ENUMS.Gua.Kun:gua_sprite.play("000")
		ENUMS.Gua.Gen:gua_sprite.play("001")
		ENUMS.Gua.Kan:gua_sprite.play("010")
		ENUMS.Gua.Xun:gua_sprite.play("011")
		ENUMS.Gua.Zhen:gua_sprite.play("100")
		ENUMS.Gua.Li:gua_sprite.play("101")
		ENUMS.Gua.Dui:gua_sprite.play("110")
		ENUMS.Gua.Qian:gua_sprite.play("111")
		ENUMS.Gua.NONE:gua_sprite.play("none")
	
	
	lunar_buff.text="月相buff："+ENUMS.lunarPhase2Text(lunar_buff_now)



func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()

func nextEvent() -> void:
	event_stream_text.append_text(NEW_LINE+"--------[下一事件]---------")
	emit_signal("next_event")
