extends Control
class_name ClientEventPage

# 转换自 torch/game/events_stream.torch (Orchestrator OScript)
# 事件流界面：祭祀/祈愿按钮发出跳转信号，下一事件按钮向事件流文本追加一行。

signal go_to_wish
signal go_to_sacrifice
signal next_event
#按下日历按键：只发出请求，由 one.gd 收集数据后再回调 openSolarCalendar()
signal open_solar_calendar

@export var event_stream_text: RichTextLabel
@export var debug_event: String = "[some event context]"
const NEW_LINE: String = "\n"
#月历面板标签的前缀（文案要改的话改这里；场景里那两个 Label 的 text 会被运行时覆盖）
const LUNAR_NOW_PREFIX: String = "今夜月相："
const LUNAR_BUFF_PREFIX: String = "当前起效月相:"

#事件流的「原始 BBCode 镜像」。
#RichTextLabel 没有任何接口能取回 append_text() 追加进去的带标签原文：
#  · text 属性只反映「最后一次被赋值」的内容，append_text() 不更新它；
#  · get_parsed_text() 会把 [color=...] 之类的标签全部剥掉。
#所以这里自己留一份原文，存档/读档都走它，颜色标签才不会丢。
var event_text_log: String = ""

#游戏结束：结局事件发生后「下一事件」永久禁用。
#不能只在 endGame() 里置一次 disabled = true —— EPupdateEventText 播完文本时会把按钮重新启用，
#所以这里留一个标志，播完时按它决定要不要恢复。
var game_over: bool = false


#由 one.gd 的 endGame() / 读档时调用
func setGameOver(value: bool) -> void:
	game_over = value
	if next_button != null:
		next_button.disabled = value

@onready var lunar_calendar: Control = $Calendar/lunar/LunarCalendar

func _ready() -> void:
	solar_calendar.hide()
	lunar_calendar.hide()
	#场景里的初始占位文本也记进镜像，否则没触发过事件时存档会存成空串
	if event_stream_text != null:
		event_text_log = event_stream_text.text


#追加事件流文本（事件流里所有追加都应走这里，不要直接调 event_stream_text.append_text）
func appendEventText(bbcode: String) -> void:
	event_text_log += bbcode
	event_stream_text.append_text(bbcode)


#取事件流原始 BBCode 原文（存档用）
func getEventText() -> String:
	return event_text_log


#设置事件流原文（读档用）：整体赋值会清空缓冲并按 bbcode 重新解析，颜色即可还原
func setEventText(bbcode: String) -> void:
	event_text_log = bbcode
	event_stream_text.text = bbcode


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

@onready var next_button: TextureButton = $operations/next
@onready var timer_text: Timer = $EventStreamWindow/texts/Timer
@onready var moon_sprite: AnimatedSprite2D = $Calendar/lunar/moon

#月历面板（LunarCalendar）：中间那颗月亮 + 三个文字 Label
@onready var moon_calendar: AnimatedSprite2D = $Calendar/lunar/LunarCalendar/ColorRect/ColorRect/moon_
@onready var lunar_now_label: Label = $Calendar/lunar/LunarCalendar/lunarnow
@onready var lunar_buff_now_label: Label = $Calendar/lunar/LunarCalendar/lunarbuff_now
@onready var lunar_upup_label: Label = $Calendar/lunar/LunarCalendar/lunarnow/upup/Label
@onready var lunar_downdown_label: Label = $Calendar/lunar/LunarCalendar/lunarnow/downdown/Label
#one.gd 所在的节点（lunar_buff_upup / lunar_buff_downdown 两张表挂在它身上）
@onready var _one: Node = get_parent()


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
	days.text="游戏天数："+str(server_day)
	solar.text=ENUMS.solarTerm2Text(server_solar_term)
	lunar.text=ENUMS.lunarPhase2Text(server_lunar_phase)
	moon_sprite.play(ENUMS.lunarPhase2Text(server_lunar_phase))
	#月历面板：中间月亮的动画 + 今夜月相
	#（两栏百分比不在这里刷：它跟的是「当前起效的月相 buff」，在 renderBelief 里更新）
	moon_calendar.play(ENUMS.lunarPhase2Text(server_lunar_phase))
	lunar_now_label.text=LUNAR_NOW_PREFIX+ENUMS.lunarPhase2Text(server_lunar_phase)


#月历面板：把 upup / downdown 两行填成「当前起效的月相（lunar_buff_now）」对应的百分比
#数值来自 one.gd 的 lunar_buff_upup / lunar_buff_downdown（0.15 → 15%）
func _updateLunarPanel(lunar_phase:ENUMS.LunarPhase):
	var up := {}
	var down := {}
	if _one != null:
		var u = _one.get("lunar_buff_upup")
		if u is Dictionary:
			up = u
		var d = _one.get("lunar_buff_downdown")
		if d is Dictionary:
			down = d
	var key:int = int(lunar_phase)
	lunar_upup_label.text=_buffPercentText(float(up.get(key,0.0)))
	lunar_downdown_label.text=_buffPercentText(float(down.get(key,0.0)))


#人口/牲口/粮食三行，同一月相共用一个系数
func _buffPercentText(ratio:float)->String:
	var p:int = roundi(ratio*100.0)
	return "人口：%d%%" % p + NEW_LINE + "牲口：%d%%" % p + NEW_LINE + "粮食：%d%%" % p

#更新事件流文本
func EPupdateEventText(
	server_event_name:String,
	server_event_text:String,
	server_event_result_text:String,
	this_event_level :ENUMS.EventLevel,
	this_event_type :ENUMS.EventType,
	this_result_type:ENUMS.ResultType,
	is_term_empty:bool
):
	#debug
	if is_term_empty:
		var split_line:="--------新事件---------"
		var event_level_:String
		#事件等级：琐碎、重大、故事
		match this_event_level:
			ENUMS.EventLevel.Common:
				split_line="|"+split_line+"|"
				event_level_="[琐碎]"
			ENUMS.EventLevel.Heavy:
				split_line="||"+split_line+"||"
				event_level_="[重大]"
			ENUMS.EventLevel.Story:
				split_line="*"+split_line+"*"
				event_level_="[故事]"
		
		appendEventText(NEW_LINE+NEW_LINE+NEW_LINE+NEW_LINE+split_line)
		
		#事件好坏：好、普通、坏
		var color :String
		match this_event_type:
			ENUMS.EventType.Good:color="#4ef700"
			ENUMS.EventType.Normal:color="#aeff9a"
			ENUMS.EventType.Bad:color="#ff6044"
		
		color = "[color="+color+"]"
		appendEventText(NEW_LINE+NEW_LINE+event_level_+"	"+ color+server_event_name+"[/color]")
		
		#播放故事内容
		next_button.disabled = true
		
		var context_ = server_event_text.split("\n")
		for i in range(context_.size()):
			#等待
			timer_text.wait_time=1.5
			timer_text.start()
			await timer_text.timeout
			
			appendEventText(NEW_LINE+context_[i])
			
		appendEventText(NEW_LINE+NEW_LINE)
		#等待
		timer_text.wait_time=1
		timer_text.start()
		await timer_text.timeout
		for i in range(3):
			appendEventText('. ')
			timer_text.wait_time=1
			timer_text.start()
			await timer_text.timeout
		
		#结果好坏
		match this_result_type:
			ENUMS.ResultType.Good:color="#80ffbf"
			ENUMS.ResultType.Normal:color="#efffdd"
			ENUMS.ResultType.Bad:color="#ff9b58"
		color = "[color="+color+"]"
		
		appendEventText(NEW_LINE+NEW_LINE+"·"+color+"结果"+"[/color]"+"·")
		
		appendEventText(NEW_LINE+server_event_result_text)
		
		next_button.disabled = game_over
	else:
		appendEventText(NEW_LINE+server_event_text)
		appendEventText(NEW_LINE+server_event_result_text)

#endregion

@onready var moon__: AnimatedSprite2D = $"BeliefBar/1/moon__"

#更新信仰值#接受的是百分比
func renderBelief(belief_now:float,gua:ENUMS.Gua,lunar_buff_now:ENUMS.LunarPhase):
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
	
	if lunar_buff_now == ENUMS.LunarPhase.NONE:
		lunar_buff.text=""
		lunar_buff_now_label.text=LUNAR_BUFF_PREFIX+"无"
	else:
		lunar_buff.text="月相buff："+ENUMS.lunarPhase2Text(lunar_buff_now)
		lunar_buff_now_label.text=LUNAR_BUFF_PREFIX+ENUMS.lunarPhase2Text(lunar_buff_now)
	
	#两栏百分比也跟「当前起效的月相」走（无 buff 时按 NONE 那一项，即 0%）
	_updateLunarPanel(lunar_buff_now)
	
	moon__.play(ENUMS.lunarPhase2Text(lunar_buff_now))




@onready var day: Label = $Calendar/sun/SolarCalendar/calendarSo/time/day
@onready var year: Label = $Calendar/sun/SolarCalendar/calendarSo/time/year
@onready var last: Label = $Calendar/sun/SolarCalendar/calendarSo/SolarTerm/HBoxContainer/last
@onready var now: Label = $Calendar/sun/SolarCalendar/calendarSo/SolarTerm/HBoxContainer/now
@onready var next: Label = $Calendar/sun/SolarCalendar/calendarSo/SolarTerm/HBoxContainer/next














func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()

func nextEvent() -> void:
	emit_signal("next_event")



@onready var solar_calendar: Control = $Calendar/sun/SolarCalendar
func _on_close_pressed() -> void:
	solar_calendar.hide()


func _on_solar_calendar_pressed() -> void:
	#只发信号：由 one.gd 的 clientOpenSolarCalendar() 收集数据后，再回调 openSolarCalendar()
	open_solar_calendar.emit()


#region 节气日历（天数 / 年份 / 上一·当前·下一节气 + 事件卡片）

#日历卡片场景（内部 ColorRect 固定 179×213）
const SOLAR_CALENDAR_CARD_SCENE := preload("res://scenes/sprites/SolarCalendarEventCard.tscn")

#卡片摆放容器：Calendar/sun/SolarCalendar/calendarSo/Events
@onready var calendar_events_rect: ColorRect = $Calendar/sun/SolarCalendar/calendarSo/Events

#当前已生成的卡片（重新打开时先清掉）
var _calendar_cards: Array[Control] = []


#由 one.gd 调用：传入已经收集好的信息，填 label + 在 Events 区域里随机摆卡片。
#  day_now          当前天数（days，这里取整）
#  year_now         年份（one.gd 已经 +1，直接显示）
#  solar_term       当前节气
#  possible_events  本节气可能发生（尚未发生）的事件
#  happened_events  本节气已经发生过的事件
func openSolarCalendar(day_now: float, year_now: int, solar_term: ENUMS.SolarTerm,
		possible_events: Array[EventCard], happened_events: Array[EventCard]) -> void:
	day.text = "第%d天" % int(day_now)
	year.text = "第%d年" % year_now

	#上一 / 当前 / 下一节气：按 ENUMS.SolarTerm 的顺序 ±1（24 个一轮）
	var term_index: int = int(solar_term)
	last.text = ENUMS.solarTerm2Text((term_index + 23) % 24)
	now.text = ENUMS.solarTerm2Text(term_index % 24)
	next.text = ENUMS.solarTerm2Text((term_index + 1) % 24)

	_clearCalendarCards()

	#① 先把卡片全部实例化（顺便量出卡片实际尺寸），顺序：先「已发生」再「可能发生」
	var all_events: Array[EventCard] = []
	all_events.append_array(happened_events)
	all_events.append_array(possible_events)
	for e in all_events:
		var card: Control = SOLAR_CALENDAR_CARD_SCENE.instantiate()
		calendar_events_rect.add_child(card)
		card.writeText(e)          #用户的接口：只喂事件对象
		_calendar_cards.append(card)

	#② 一次性算好全部位置再摆：优先不重叠（区域够用时一定不重叠）
	if !_calendar_cards.is_empty():
		var card_size: Vector2 = (_calendar_cards[0].get_node("ColorRect") as ColorRect).size
		var positions: Array[Vector2] = _layoutCardPositions(
			_calendar_cards.size(), card_size, calendar_events_rect.size)
		for i in _calendar_cards.size():
			_placeCalendarCard(_calendar_cards[i], positions[i])

	solar_calendar.show()


#清掉上一次打开日历生成的卡片
func _clearCalendarCards() -> void:
	for c in _calendar_cards:
		if is_instance_valid(c):
			calendar_events_rect.remove_child(c)
			c.queue_free()
	_calendar_cards.clear()


#算一整套卡片位置，保证「优先不重叠」：
#  ① 把区域切成 cols × rows 个格子（每个格子 ≥ 一张卡片），一张卡片占一个格子
#     → 格子之间不重叠，卡片自然也一定不重叠；
#     格子顺序随机打乱、并在格子内再做一次随机偏移，保留「随机摆放」的手感。
#  ② 卡片数量超过格子数 → 多出来的只能放到随机位置（允许重叠，但仍在区域内）。
func _layoutCardPositions(count: int, card_size: Vector2, area: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if count <= 0:
		return out

	var max_x: float = maxf(area.x - card_size.x, 0.0)
	var max_y: float = maxf(area.y - card_size.y, 0.0)

	#能切出几列几行（至少 1×1）
	var cols: int = maxi(int(area.x / card_size.x), 1)
	var rows: int = maxi(int(area.y / card_size.y), 1)
	var cell: Vector2 = Vector2(area.x / cols, area.y / rows)
	#格子里多出来的余量，用来做随机抖动
	var slack: Vector2 = Vector2(maxf(cell.x - card_size.x, 0.0), maxf(cell.y - card_size.y, 0.0))

	#所有格子，打乱后按顺序分配
	var grid: Array[Vector2] = []
	for r in rows:
		for c in cols:
			grid.append(Vector2(c, r))
	grid.shuffle()

	for i in count:
		if i < grid.size():
			var cell_index: Vector2 = grid[i]
			var base: Vector2 = Vector2(cell_index.x * cell.x, cell_index.y * cell.y)
			out.append(base + Vector2(randf_range(0.0, slack.x), randf_range(0.0, slack.y)))
		else:
			out.append(Vector2(randf_range(0.0, max_x), randf_range(0.0, max_y)))
	return out


#把卡片放到指定位置。
#场景里的根 Control 是「铺满父节点」的，这里改成正好卡片大小，避免溢出 Events 区域。
func _placeCalendarCard(card: Control, pos: Vector2) -> void:
	var card_size: Vector2 = (card.get_node("ColorRect") as ColorRect).size
	card.anchor_right = 0.0
	card.anchor_bottom = 0.0
	card.size = card_size
	card.position = pos

#endregion


func _on_close_lunar_calendar() -> void:
	lunar_calendar.hide()


func _on_lunar_calendar_open_2_pressed() -> void:
	lunar_calendar.show()
