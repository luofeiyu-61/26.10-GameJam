extends CanvasLayer

signal open_one_list
#发给main节点让他切换到世界列表

@onready var game_setting_ui: CanvasLayer = $GameSettingUI

func backToMenu():
	show()

#让main打开世界列表
func _open_ones_list() -> void:
	emit_signal("open_one_list")
	hide()

#打开游戏设置面板
func _on_game_setting_bt_pressed() -> void:
	game_setting_ui.show()

#关闭游戏设置面板
func _on_game_setting_ui_close_game_setting() -> void:
	game_setting_ui.hide()


#退出游戏
func _exit_game() -> void:
	get_tree().quit()
