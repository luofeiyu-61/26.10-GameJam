extends CanvasLayer


signal close_game_setting
#传给父节点让父节点关闭设置面板


@onready var master: HSlider = $CenterContainer/window/VBoxContainer/volumn/SoundsVolumn/MasterVolumn/Master
@onready var bgmslider: HSlider = $CenterContainer/window/VBoxContainer/volumn/SoundsVolumn/BGM/BGMslider
@onready var sfxslider: HSlider = $CenterContainer/window/VBoxContainer/volumn/SoundsVolumn/SFX/SFXslider
@onready var window_size_option: OptionButton = $CenterContainer/window/VBoxContainer/windowsize/WindowSzie/OptionButton
@onready var developer_switch: CheckButton = $CenterContainer/window/VBoxContainer/developer/Developer/CheckButton
@onready var fullscreen_button: CheckButton = $CenterContainer/window/VBoxContainer/windowsize/WindowSzie/CheckButton


func _ready() -> void:
	#绘制当前设置
	master.set_value_no_signal(SettingsManager.Master_volumn)
	bgmslider.set_value_no_signal(SettingsManager.BGM_volumn)
	sfxslider.set_value_no_signal(SettingsManager.SFX_volumn)
	window_size_option.select(SettingsManager.window_size_index)
	developer_switch.button_pressed=SettingsManager.develop_mode
	fullscreen_button.button_pressed=SettingsManager.is_fullscreen


func _cancel_setting_change() -> void:
	SettingsManager.load_settings()
	emit_signal("close_game_setting")
	print("cancel settings change!")


func _apply_setting_change() -> void:
	SettingsManager.save_settings()
	emit_signal("close_game_setting")
	print("apply settings change!")



#游戏主音量大小
func _on_master_value_changed(value: float) -> void:
	SettingsManager.Master_volumn=value
	SettingsManager.set_bus_volume("Master",value)

#游戏BGM音量大小
func _on_bg_mslider_value_changed(value: float) -> void:
	SettingsManager.BGM_volumn=value
	SettingsManager.set_bus_volume("BGM",value)

#游戏SFX音量大小
func _on_sf_xslider_value_changed(value: float) -> void:
	SettingsManager.SFX_volumn=value
	SettingsManager.set_bus_volume("SFX",value)

#窗口分辨率设置
func _on_option_button_item_selected(index: int) -> void:
	SettingsManager.set_window_size(index)

#开发者模式切换
func _on_check_button_toggled(toggled_on: bool) -> void:
	SettingsManager.set_develop_mode(toggled_on)

#全屏切换
func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	SettingsManager.set_full_screen(toggled_on)
	window_size_option.disabled=toggled_on
		


func _when_open_setting() -> void:
	if visible:
		SettingsManager.load_settings()
		
		#绘制当前设置
		master.set_value_no_signal(SettingsManager.Master_volumn)
		bgmslider.set_value_no_signal(SettingsManager.BGM_volumn)
		sfxslider.set_value_no_signal(SettingsManager.SFX_volumn)
		window_size_option.select(SettingsManager.window_size_index)
		developer_switch.button_pressed=SettingsManager.develop_mode
		fullscreen_button.button_pressed=SettingsManager.is_fullscreen
		
		print("aaa")
