extends Control

# 转换自 torch/game/wish_window.torch (Orchestrator OScript)
# 祈愿界面：去祭祀 / 返回事件流 按钮发出跳转信号。

signal go_to_event
signal go_to_sacrifice

func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_eventstream_pressed() -> void:
	go_to_event.emit()
