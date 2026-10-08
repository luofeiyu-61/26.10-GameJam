extends SceneTree

func _initialize() -> void:
	var scenes = [
		"res://scenes/game/one.tscn",
		"res://scenes/game/events_stream.tscn",
		"res://scenes/game/sacrifice_window.tscn",
		"res://scenes/game/wish_window.tscn",
	]
	for s in scenes:
		var res = load(s)
		if res == null or not res is PackedScene:
			print("FAIL_LOAD: ", s)
			continue
		var inst = res.instantiate()
		if inst == null:
			print("FAIL_INSTANTIATE: ", s)
			continue
		# 验证信号已声明（连接所需）
		var expected = {
			"res://scenes/game/one.tscn": ["back_to_main_menu"],
			"res://scenes/game/events_stream.tscn": ["go_to_wish", "go_to_sacrifice", "next_event"],
			"res://scenes/game/sacrifice_window.tscn": ["go_to_event", "go_to_wish", "confirm_sacrifice"],
			"res://scenes/game/wish_window.tscn": ["go_to_event", "go_to_sacrifice"],
		}
		var ok = true
		for sig in expected[s]:
			if not inst.has_signal(sig):
				print("MISSING_SIGNAL ", sig, " in ", s)
				ok = false
		inst.free()
		print("OK" if ok else "OK_BUT_SIGNAL_ISSUE", ": ", s)
	print("VALIDATE_DONE")
	quit()
