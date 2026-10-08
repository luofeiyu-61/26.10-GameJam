extends Control

# 转换自 torch/game/events_stream.torch (Orchestrator OScript)
# 事件流界面：祭祀/祈愿按钮发出跳转信号，下一事件按钮向事件流文本追加一行。

signal go_to_wish
signal go_to_sacrifice
signal next_event

@export var event_stream_text: RichTextLabel
@export var debug_event: String = "[some event context]"
const NEW_LINE: String = "[br]"

func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()

func nextEvent() -> void:
	print("NextEvent")
	event_stream_text.append_text(NEW_LINE + debug_event)
