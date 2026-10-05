extends Node2D



func _on_main_menu_open_one_list() -> void:
	#隐藏菜单
	$MainMenu.hide()
	#打开世界列表
	var ones_list_window=preload("res://scenes/pages/ones_list.tscn").instantiate()
	ones_list_window.connect("open_selected_one",Callable(self,"enterSelectedOne"))
	ones_list_window.connect("close_ones_list",Callable(self,"closeOnesList"))
	add_child(ones_list_window)


#进入选中世界
func enterSelectedOne():
	var selected_one = preload("res://scenes/game/one.tscn").instantiate()
	selected_one.connect("back_to_main_menu",Callable(self,"closeThisOne"))
	add_child(selected_one)
	$MainMenu.hide()
	print("enter one!")

#关闭现在的世界
func closeThisOne():
	$MainMenu.show()
	pass


#关闭世界列表
func closeOnesList():
	get_child(0).show()
