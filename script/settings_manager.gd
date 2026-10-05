extends Node

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

#设置总线音量
func set_bus_volume(bus_name: String, linear_value: float) -> void:
	# linear_value 是 0.0 ~ 1.0 的线性值，来自 Slider
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("音频总线不存在: " + bus_name)
		return

	# 把线性值转成 dB，0.0 映射到 -80dB（静音）
	var db := linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(bus_idx, db)
