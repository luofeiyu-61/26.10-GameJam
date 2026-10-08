extends Node

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

var Master_volumn = 100.0
var BGM_volumn = 100.0
var SFX_volumn = 100.0
var window_size_index:int =0
var develop_mode:bool =false
var is_fullscreen:bool = false

func _ready() -> void:
	#不准鼠标改变窗口大小
	get_window().unresizable = true
	load_settings()

#设置总线音量
func set_bus_volume(bus_name: String, linear_value: float) -> void:
	# linear_value 是 0.0 ~ 1.0 的线性值，来自 Slider
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("音频总线不存在: " + bus_name)
		return

	# 把线性值转成 dB，0.0 映射到 -80dB（静音）
	linear_value /= 100.0
	var db := linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(bus_idx, db)

#设置分辨率
func set_window_size(index:int):
	#计算窗口大小
	var size:=Vector2i(16,9)
	var multi:int
	match index:
		0: multi=72
		1: multi=80
		2: multi=100
		3: multi=120
		4: multi=130
		5: multi=140
		6: multi=160
	size*=multi
	get_window().size=size
	window_size_index=index
	#居中
	var screen_idx := get_window().current_screen
	var screen_pos := DisplayServer.screen_get_position(screen_idx)
	var screen_size := DisplayServer.screen_get_size(screen_idx)
	var win_size := get_window().size
	get_window().position = screen_pos + (screen_size - win_size) / 2

#设置是否全屏
func set_full_screen(enabled:bool):
	is_fullscreen=enabled
	var window := get_window()
	if enabled: window.mode = Window.MODE_FULLSCREEN
	else: 
		window.mode = Window.MODE_WINDOWED
		set_window_size(window_size_index)

#设置开发者模式
func set_develop_mode(enabled:bool):
	develop_mode=enabled
	$Label.visible=develop_mode


func save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings","Master_volumn",Master_volumn)
	config.set_value("Settings","BGM_volumn",BGM_volumn)
	config.set_value("Settings","SFX_volumn",SFX_volumn)
	config.set_value("Settings","window_size_index",window_size_index)
	config.set_value("Settings","develop_mode",develop_mode)
	config.set_value("Settings","is_fullscreen",is_fullscreen)
	config.save("user://settings.cfg")
	
	print("save settings!")


func load_settings():
	var config = ConfigFile.new()
	var result = config.load("user://settings.cfg")
	if result == OK:#加载参数
		Master_volumn = config.get_value("Settings","Master_volumn")
		BGM_volumn = config.get_value("Settings","BGM_volumn")
		SFX_volumn = config.get_value("Settings","SFX_volumn")
		window_size_index= config.get_value("Settings","window_size_index")
		develop_mode= config.get_value("Settings","develop_mode")
		is_fullscreen = config.get_value("Settings","is_fullscreen")
	#应用参数
	set_bus_volume("Master",Master_volumn)
	set_bus_volume("BGM",BGM_volumn)
	set_bus_volume("SFX",SFX_volumn)
	set_full_screen(is_fullscreen)
	set_develop_mode(develop_mode)
	if !is_fullscreen :set_window_size(window_size_index)
	
	print("load settings!")
