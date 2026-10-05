extends Node
signal back_to_main_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#默认显示事件流界面
	$EventsStream.show()
	$Sacrifice_window.hide()
	$Wish_window.hide()
	$options.show()
	$GameSettingUI.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#返回主菜单（不保存）	TODO
func _on_back_to_menu_pressed() -> void:
	emit_signal("back_to_main_menu")
	queue_free()
