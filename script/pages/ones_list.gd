extends CanvasLayer

signal open_selected_one
signal close_ones_list


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#关闭列表 TODO
func closeOnesList() -> void:
	emit_signal("close_ones_list")
	queue_free()


#打开游戏 TODO
func _open_one() -> void:
	emit_signal("open_selected_one")
	queue_free()
