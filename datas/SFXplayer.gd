extends Node
class_name SFX

func play_sfx(stream: AudioStream, bus: String = "SFX") -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus  # 关键：路由到对应的音频总线
	add_child(player)
	player.finished.connect(player.queue_free) # 播放完毕后自动销毁
	player.play()
