extends CanvasLayer


signal close_game_setting
#传给父节点让父节点关闭设置面板


#TODO 具体游戏设置还未实现，
#核心思路是：用一个 Autoload 单例（比如 SettingsManager）统一管理所有设置项，
#负责读写配置文件并实时应用到引擎，UI 层只负责展示和修改。




func _cancel_setting_change() -> void:
	emit_signal("close_game_setting")
	print("cancel settings change!")


func _apply_setting_change() -> void:
	#TODO 保存设置信息
	
	emit_signal("close_game_setting")
	print("apply settings change!")


func _on_master_value_changed(value: float) -> void:
	
	pass # Replace with function body.


func _on_bg_mslider_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_sf_xslider_value_changed(value: float) -> void:
	pass # Replace with function body.
