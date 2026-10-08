extends Control

# 转换自 torch/game/sacrifice_window.torch (Orchestrator OScript)
# 祭祀界面：返回事件流 / 去祈愿 按钮发出跳转信号。

signal go_to_event
signal go_to_wish
signal confirm_sacrifice

func _on_eventstream_pressed() -> void:
	go_to_event.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()
