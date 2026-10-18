extends Control
class_name ClientSacrificePage


@onready var guy: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/Guy
@onready var people: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/people
@onready var animal: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/animal
@onready var grain: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/grain

@onready var guy_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/GuyPre
@onready var people_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/peoplePre
@onready var animal_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/animalPre
@onready var grain_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/grainPre


@onready var sacrifice_bar_pre: TextureProgressBar = $SacrificeBar/BarPre
@onready var sacrifice_bar: TextureProgressBar = $SacrificeBar/Bar

@onready var yao_pre_num: Label = $SacrificeBar/Qi/Label

#SacrificeWindow 中心的比例饼图（人口/牲口/粮食 三扇区，半径由 total_ratio 决定）
@onready var sacrifice_pie: SacrificePie = $SacrificeWindow/SacrificePie



#玩家调整的比例
var total_ratio:float
var people_ratio:float
var animal_ratio:float
var garin_ratio:float




signal go_to_event
signal go_to_wish
signal confirm_sacrifice(people_ratio:float,animal_ratio:float,garin_ratio:float,total_ratio:float)
signal preview_sacrifice_result(people_ratio:float,animal_ratio:float,garin_ratio:float,total_ratio:float)


#进场景先按当前比例画一次（滑块的初始值也一并反映进饼图）
func _ready() -> void:
	_updateSacrificePie()




#接受的是百分比
func renderPreviewBars(pre_people,pre_animal,pre_grain,pre_guy,sacrifice_value,new_yao_num):
	guy_pre.set_value_no_signal(pre_guy*guy_pre.max_value)
	people_pre.set_value_no_signal(pre_people*people_pre.max_value)
	animal_pre.set_value_no_signal(pre_animal*animal_pre.max_value)
	grain_pre.set_value_no_signal(pre_grain*grain_pre.max_value)
	if new_yao_num == 0:
		temp_bar_pre_value=sacrifice_value*sacrifice_bar_pre.max_value
		yao_pre_num.text=""
	else:
		temp_bar_pre_value=sacrifice_bar_pre.max_value
		yao_pre_num.text="+%d"%new_yao_num


#============================================================
# 数值条动画
#  · renderBars         —— 开始播放动画：记下最终值 + 重置 sacrifice_bar 的段落状态
#  · applyBarsAnimation —— 管理动画（放进 _process，每帧推进）
#  两个函数的参数都是「最终值」（百分比 0~1，沿用 renderBars 原有约定）。
#
#  · guy / people / animal / grain：指数插值，从当前值平滑推到最终值，
#    可增可减、与帧率无关；半路再次 renderBars 会直接换目标、从当前位置继续。
#  · sacrifice_bar：
#    - new_yao_num > 0：线性「充满」n 次 —— 第 1 次是「当前值 → max」，
#      第 2 次起是「0 → max」（充满即归零重来）；
#      最后一次再用 smoothstep 从 0 平滑落到 sacrifice_value。
#    - new_yao_num = 0：不充能，跟其它四条一样 —— 从**旧值**平滑变到新值。
#============================================================

@export var bar_follow_speed: float = 12.0      #四条资源条的趋近速度（越大越快）
@export var yao_charge_time: float = 0.20      #sacrifice_bar 每「充满」一次用时（秒）
@export var yao_charge_hold: float = 0.05      #充满后停在满格的时长（秒），停顿一下再归零
@export var sacrifice_fill_time: float = 0.4  #sacrifice_bar 最后 0→sacrifice_value 用时（秒）

#renderBars 传来的最终值（百分比，原样存下来给 _process 用）
var _p_people: float = 0.0
var _p_animal: float = 0.0
var _p_grain: float = 0.0
var _p_guy: float = 0.0
var _p_sacrifice: float = 0.0

#四条资源条的「动画内部值」。
#★不能拿 bar.value 当动画状态：这些 TextureProgressBar 的 step = 1，
#  写进去的浮点会被量化成整数，读回来当起点的话，每帧只走零点几格会被四舍五入吃掉，
#  动画会永远停在离目标十几格的地方（实测过）。
#  所以自己维护浮点值，只把结果写给 bar。
var _v_guy: float = 0.0
var _v_people: float = 0.0
var _v_animal: float = 0.0
var _v_grain: float = 0.0
var _v_sacrifice: float = 0.0       #sacrifice_bar 在「不充能」时（new_yao_num = 0）的内部值

#sacrifice_bar 的分段动画状态
var _sb_charge_left: int = 0        #还要「充满」几次
var _sb_running: bool = false       #分段动画是否正在跑
var _sb_final_phase: bool = false   #当前这段是不是最后那段(0→sacrifice_value)
var _sb_seg_start: float = 0.0
var _sb_seg_end: float = 0.0
var _sb_seg_time: float = 0.0
var _sb_t: float = 0.0
var _sb_hold_left: float = 0.0      #段末满格的停留剩余时间
#第一次「充满」是否从当前显示值起跑（而不是先归零）：
#new_yao_num > 0 时，第 1 次是「当前值 → max」，第 2 次起才是「0 → max」
var _sb_first_charge_from_current: bool = false

#动画是否激活：renderBars 打开；全部到位后自动关掉，免得空转或跟外部改值打架
var _bars_active: bool = false


#接受的是百分比
func renderBars(people_,animal_,grain_,guy_,sacrifice_value,new_yao_num):
	_p_people = people_
	_p_animal = animal_
	_p_grain = grain_
	_p_guy = guy_
	_p_sacrifice = sacrifice_value
	_bars_active = true
	#动画起点 = 各条当前显示的值（step=1 最多差半格，看不出来）
	_v_guy = guy.value
	_v_people = people.value
	_v_animal = animal.value
	_v_grain = grain.value
	_v_sacrifice = sacrifice_bar.value
	#sacrifice_bar：
	#  new_yao_num > 0 → 先「充满」n 次，最后再 0→sacrifice_value（分段动画）
	#  new_yao_num = 0 → 不充能，直接走下面 applyBarsAnimation 的「从旧值平滑变到新值」
	_sb_charge_left = maxi(int(new_yao_num), 0)
	_sb_hold_left = 0.0
	_sb_running = _sb_charge_left > 0
	_sb_first_charge_from_current = _sb_running

	redrawSacrificePreBar()
	if _sb_running:
		_beginSacrificeSegment(sacrifice_value)
	#这次没有爻要飞（new_yao_num = 0）→ 立刻解除锁定，
	#否则「按下确认时锁上」会让按钮白闪一帧。
	#有爻要飞时交给 _process 里的 _refreshActionLock 每帧判断。
	if !_sb_running:
		_refreshActionLock()


#每帧推进动画（由 _process 调用）。参数都是最终值，单位与 renderBars 一致（百分比）。
func applyBarsAnimation(people_,animal_,grain_,guy_,sacrifice_value):
	if !_bars_active:
		return
	var dt := get_process_delta_time()

	#—— 四条资源条：指数插值，可增可减 ——
	var t_guy: float = guy_*guy.max_value
	var t_people: float = people_*people.max_value
	var t_animal: float = animal_*animal.max_value
	var t_grain: float = grain_*grain.max_value
	_v_guy = _advanceBar(guy, _v_guy, t_guy, dt)
	_v_people = _advanceBar(people, _v_people, t_people, dt)
	_v_animal = _advanceBar(animal, _v_animal, t_animal, dt)
	_v_grain = _advanceBar(grain, _v_grain, t_grain, dt)
	var settled := absf(_v_guy - t_guy) < 0.01
	settled = absf(_v_people - t_people) < 0.01 and settled
	settled = absf(_v_animal - t_animal) < 0.01 and settled
	settled = absf(_v_grain - t_grain) < 0.01 and settled

	#—— sacrifice_bar ——
	if _sb_running:
		#new_yao_num > 0：分段推进（n 次充满 + 最后落定）
		if _sb_hold_left > 0.0:
			#段末停留：这段时间不写值，让「充满」的满格真的显示出来
			#（跑满的那一帧若立刻开始下一段，满格会被同帧覆盖成 0，等于永远充不满）
			_sb_hold_left -= dt
			if _sb_hold_left <= 0.0:
				_sb_hold_left = 0.0
				_sb_charge_left -= 1
				_beginSacrificeSegment(sacrifice_value)
		else:
			_sb_t += dt
			if _sb_seg_time <= 0.0 or _sb_t >= _sb_seg_time:
				#这一段跑完
				_setSacrificeBar(_sb_seg_end)
				if _sb_final_phase:
					_sb_running = false
				else:
					#「充满」一次 → 飞一个爻进祈愿圈（new_yao_num 有几个，就飞几个）
					spawnYaoAnimation(1)
					_sb_hold_left = maxf(yao_charge_hold, dt)   #至少停一帧，否则满格看不见
					if _sb_hold_left <= 0.0:
						_sb_charge_left -= 1
						_beginSacrificeSegment(sacrifice_value)
			else:
				var k: float = _sb_t / _sb_seg_time
				if _sb_final_phase:
					k = smoothstep(0.0, 1.0, k)     #最后一段：平滑落定
				#（「充满」那几段保持线性，读起来就是一次一次地充）
				_setSacrificeBar(lerpf(_sb_seg_start, _sb_seg_end, k))
	else:
		#new_yao_num = 0：不充能，跟其它四条一样 —— 从旧值平滑变到新值
		var t_sac: float = sacrifice_value * sacrifice_bar.max_value
		_v_sacrifice = _advanceBar(sacrifice_bar, _v_sacrifice, t_sac, dt)
		settled = absf(_v_sacrifice - t_sac) < 0.01 and settled

	if settled and !_sb_running and _sb_hold_left <= 0.0:
		_bars_active = false


func _process(delta: float) -> void:
	applyBarsAnimation(_p_people, _p_animal, _p_grain, _p_guy, _p_sacrifice)
	_advance_yao_animations(delta)
	taiji_sprite_rotation(delta)


@onready var taiji_sprite_2d: Sprite2D = $SacrificeBar/Taiji/Sprite2D

var taiji_time:float=0
var taiji_v = 5.0
func taiji_sprite_rotation(delta:float):
	taiji_time+=delta*taiji_v
	taiji_sprite_2d.rotation_degrees=-taiji_time





#开始 sacrifice_bar 的下一段：还有次数就跑 max_value，否则跑最后的 0→sacrifice_value
#起跑点：
#  · 第 1 次「充满」= 当前显示值 → max（不先归零，接得上画面）
#  · 第 2 次起的「充满」和最后那段 = 0 起跑（充满后归零再充，是「一次次充能」的观感来源）
func _beginSacrificeSegment(sacrifice_value: float) -> void:
	_sb_t = 0.0
	_sb_final_phase = _sb_charge_left <= 0
	if _sb_final_phase:
		_sb_seg_start = 0.0
		_sb_seg_end = sacrifice_value * sacrifice_bar.max_value
		_sb_seg_time = maxf(sacrifice_fill_time, 0.0)
	else:
		_sb_seg_start = _v_sacrifice if _sb_first_charge_from_current else 0.0
		_sb_first_charge_from_current = false
		_sb_seg_end = sacrifice_bar.max_value
		_sb_seg_time = maxf(yao_charge_time, 0.0)
	_setSacrificeBar(_sb_seg_start)


#写 sacrifice_bar 并顺手同步内部值。
#必须同步：分段动画结束后会切回「指数插值」分支，
#若 _v_sacrifice 还停在旧值，下一帧就会把已经到位的 bar 拉回去（跳一下）。
func _setSacrificeBar(v: float) -> void:
	sacrifice_bar.set_value_no_signal(v)
	_v_sacrifice = v


#把一条推进一个指数步并把结果写给 bar；返回新的动画值
func _advanceBar(bar: TextureProgressBar, cur: float, target: float, dt: float) -> float:
	var v: float = cur
	if absf(target - cur) < 0.01:
		v = target
	else:
		v = lerpf(cur, target, 1.0 - exp(-bar_follow_speed * maxf(dt, 0.0)))
	bar.set_value_no_signal(v)
	return v



#region 爻动画
const yao_scene := preload("res://scenes/sprites/yao.tscn")
@onready var yao_container: Control = $YaoContainer

#爻的飞行起点 / 终点：太极中心 → 气（Qi）中心
@onready var taiji_: ColorRect = $SacrificeBar/Taiji
@onready var qi_: ColorRect = $SacrificeBar/Qi

#正在播放中的爻动画（播完由 anime_end 信号卸载）
var _yao_anims: Array[SpawnYaoAnimator] = []

#—— 爻飞行期间要禁用的操作按键（eventstream / wish / confirmsacrifice）——
@onready var eventstream_bt: BaseButton = $operations/eventstream
@onready var wish_bt: BaseButton = $operations/wish
@onready var confirmsacrifice_bt: BaseButton = $operations/confirmsacrifice

#这三个是 TextureButton：没设 texture_disabled 时，disabled 只挡点击、外观完全不变，
#看起来像「没生效」。所以默认顺手把按键变淡，让禁用状态看得见。
@export var dim_buttons_when_busy: bool = true

#本轮「献祭动画」是否锁住了按键。
#按下 confirmsacrifice 时立刻置 true（不等第一对爻生成），
#等这一轮不会再有新爻（!_sb_running）**且**现有爻全部飞完，才解锁。
var _action_lock: bool = false

#当前按键是否已经处于禁用状态（缓存值，只在变化时写属性，避免每帧重复赋值）
var _actions_busy: bool = false


class SpawnYaoAnimator:
	
	var yin_yao:YaoBall
	var yang_yao:YaoBall
	
	var vec:Vector2
	
	var _velocity:= 1.0
	var _is_playing:bool
	var _t:float
	var _t_max:=1.0
	var _lambda:float
	
	var A:Vector2
	var B1:Vector2
	var B2:Vector2
	var C:Vector2
	var D:Vector2
	
	signal anime_end
	
	func _init(source:Vector2,target:Vector2):
		yin_yao=yao_scene.instantiate() as YaoBall
		yang_yao=yao_scene.instantiate() as YaoBall
		
		A=source
		var temp = 0.4*((target-source).length())*Vector2.RIGHT.rotated(randf_range(45,135)*(1 if randi_range(0,1)==1 else -1))
		B1=source+temp
		B2=source-temp
		C=0.5*(source+target)
		D=target
		
		
	func startAnimation(yao_container:Control):
		_t=0
		if yin_yao.get_parent() == null:
			yao_container.add_child(yin_yao)
			yin_yao.yao=false
		if yang_yao.get_parent() == null:
			yao_container.add_child(yang_yao)
			yang_yao.yao=true
		_is_playing=true

	func bezierCurve(B:Vector2,lambda:float)->Vector2:
		var mu = 1-lambda
		return (mu**3)*A+3*(mu**2)*lambda*B+3*mu*(lambda**2)*C+(lambda**3)*D

	func playAnimation(delta:float):
		if _is_playing:
			_t+=delta*_velocity
			if _t>=_t_max:
				_t=_t_max
				_is_playing=false
				yin_yao.queue_free()
				yang_yao.queue_free()
				
				anime_end.emit()
			
			#_lambda=(1.513*(_t/_t_max)-0.5848)**3+0.2
			_lambda=_t/_t_max
			yang_yao.yao_.global_position=bezierCurve(B1,_lambda)
			yin_yao.yao_.global_position=bezierCurve(B2,_lambda)
			
			
		
		



#生成 yao_num 个「爻从太极飞进祈愿圈」的动画并立刻开始播放。
#source = 太极中心，target = 气(Qi)中心。
#每调用一次就生成 yao_num 个 SpawnYaoAnimator（各自独立，互不影响）。
#sacrifice_bar 每「充满」一次就调一次 spawnYaoAnimation(1)。
func spawnYaoAnimation(yao_num:int):
	var n := maxi(int(yao_num), 0)
	if n <= 0:
		return
	var source := taiji_.get_global_rect().get_center()
	var target := qi_.get_global_rect().get_center()
	for i in n:
		var anim := SpawnYaoAnimator.new(source, target)
		#两个球一阴一阳（YaoBall 默认是阳，这里把它落实成一对）
		anim.yin_yao.yao = false
		anim.yang_yao.yao = true
		anim.anime_end.connect(_on_yao_anim_end.bind(anim))
		_yao_anims.append(anim)
		anim.startAnimation(yao_container)
	#爻一生成就把三个操作按键禁掉（本轮全部飞完由 _refreshActionLock 恢复）
	_updateActionButtons()


#把当前的锁定状态写到三个按键上。
#幂等：状态没变就早退，所以可以放心每帧调用。
func _updateActionButtons() -> void:
	var busy := _action_lock or !_yao_anims.is_empty()
	if busy == _actions_busy:
		return
	_actions_busy = busy
	var bts: Array[BaseButton] = [eventstream_bt, wish_bt, confirmsacrifice_bt]
	for bt in bts:
		if bt == null:
			continue
		bt.disabled = busy
		if dim_buttons_when_busy:
			bt.modulate = Color(1.0, 1.0, 1.0, 0.45) if busy else Color(1.0, 1.0, 1.0, 1.0)


#刷新锁定状态并写按键：
#解锁条件 = 这一轮不可能再生成新爻（!_sb_running）且现有爻全部飞完。
#做成幂等 + 每帧调用，所以既不会漏禁用，也不会因为中途被打断/连续生成
#或某个信号漏掉而把按键永久禁死。
func _refreshActionLock() -> void:
	if _action_lock and !_sb_running and _yao_anims.is_empty():
		_action_lock = false
	_updateActionButtons()


#每帧推进所有爻动画。
#注意：放在 _process 里而不是 applyBarsAnimation 里 ——
#爻的飞行(1s)可能比数值条动画更晚结束，而 applyBarsAnimation 在 _bars_active
#变 false 后会直接 return，塞进去的话爻会飞到一半就不动了。
func _advance_yao_animations(delta: float) -> void:
	if !_yao_anims.is_empty():
		for anim in _yao_anims.duplicate():
			anim.playAnimation(delta)
	#每帧刷新一次：全部爻飞完 + 不会再有新爻，才恢复
	_refreshActionLock()


#爻飞完：即刻卸载这个动画类。
#先把它自己的信号连接断掉：connect 时 bind 了 anim 自己，不断开就是自引用，
#这个 RefCounted 的引用计数永远回不到 0（YaoBall 已经 queue_free 了，但类本体不会回收）。
func _on_yao_anim_end(anim: SpawnYaoAnimator) -> void:
	for c in anim.anime_end.get_connections():
		anim.anime_end.disconnect(c["callable"])
	_yao_anims.erase(anim)
	#这一对飞完了：若本轮不会再有新爻就立刻恢复按键（否则继续禁用）
	_refreshActionLock()


#endregion



func _on_eventstream_pressed() -> void:
	go_to_event.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()



#确认祭祀
func _on_confirmsacrifice_pressed() -> void:
	#一按下就锁住三个操作键（不等第一对爻生成）：
	#emit 是同步的，one.gd 的 clientConfirmSacrifice 会当场调 renderBars，
	#若这次有爻要生成，_sb_running 会被置 true，锁定就自然延续到爻全部飞完。
	_action_lock = true
	_updateActionButtons()
	confirm_sacrifice.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)
	total_ratio=0
	$RatioSetWindow/SacrificeRatio/Total.value=0




#调整比例滑条时实时计算预览结果
@onready var bar_pre: TextureProgressBar = $SacrificeBar/BarPre
var temp_bar_pre_value

func redrawSacrificePreBar():
	if $RatioSetWindow/SacrificeRatio/Total.value==0:sacrifice_bar_pre.set_value_no_signal(0)
	else:sacrifice_bar_pre.set_value_no_signal(temp_bar_pre_value)

func _on_total_value_changed(value: float) -> void:
	total_ratio=value/100.0
	redrawSacrificePreBar()
	_updateSacrificePie()
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_people_value_changed(value: float) -> void:
	people_ratio=value/100.0
	redrawSacrificePreBar()
	_updateSacrificePie()
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_animal_value_changed(value: float) -> void:
	animal_ratio=value/100.0
	redrawSacrificePreBar()
	_updateSacrificePie()
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_grain_value_changed(value: float) -> void:
	garin_ratio=value/100.0
	redrawSacrificePreBar()
	_updateSacrificePie()
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)


#把「三个比例 + 总量比例」推给 SacrificeWindow 中心的饼图。
#更新时机：_on_total / _on_people / _on_animal / _on_grain 四个回调（外加 _ready 一次）。
func _updateSacrificePie() -> void:
	if sacrifice_pie != null:
		sacrifice_pie.setRatios(people_ratio,animal_ratio,garin_ratio,total_ratio)
