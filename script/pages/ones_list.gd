extends CanvasLayer

signal open_selected_one
signal close_ones_list




#关闭列表 TODO
func closeOnesList() -> void:
	emit_signal("close_ones_list")
	queue_free()


#打开游戏 TODO
func _open_one() -> void:
	emit_signal("open_selected_one")
	queue_free()


#region 存档系统（2.2 存档位 / 2.3 存档详细 / 3.1 存档位置 / 3.4 入口标志）

#存档目录与文件名（3.1）
#目录由 GamePaths 决定：编辑器里 res://saves/，导出版是 exe 同目录的 saves/（绿色版，不写 C 盘）
static var SAVE_DIR: String = GamePaths.saveDir()
const SAVE_FILE_FORMAT := "save_%d.tres"
const SAVE_SLOT_COUNT := 4

#存档界面是被哪个场景打开的（3.4）：false=主菜单，true=游戏内
var is_from_game:bool = false

#当前选中的存档位（1~4，0=未选中）
var selected_slot:int = 0

#主菜单→打开游戏 流程中待载入的存档路径
#（供 one.gd 的 firstInitGame 后续接入，当前按要求不耦合进主逻辑）
static var pending_save_path:String = ""

#发给游戏场景 one 的请求（游戏内打开时由 one.gd 连接）
signal request_load_game(save_path:String)
signal request_save_game(save_path:String)


@onready var _slots_box:VBoxContainer = $OnesContainer/ColorRect/HBoxContainer/saves
@onready var _bt_new:Button = $OnesContainer/ColorRect/HBoxContainer/operations/VBoxContainer/new
@onready var _bt_load:Button = $OnesContainer/ColorRect/HBoxContainer/operations/VBoxContainer/load
@onready var _bt_save:Button = $OnesContainer/ColorRect/HBoxContainer/operations/VBoxContainer/save
@onready var _bt_delete:Button = $OnesContainer/ColorRect/HBoxContainer/operations/VBoxContainer/delete
@onready var _lbl_save_name:Label = $OnesContainer/ColorRect/HBoxContainer/operations/saveName

@onready var warning_page: Control = $OnesContainer/ColorRect/warningPage

func _ready() -> void:
	_bindSaveSlots()
	_bindOperationButtons()
	refreshSlots()
	selectSlot(1)
	warning_page.hide()


#region 存档位
#存档位对应的文件路径
func savePathOf(slot:int) -> String:
	return SAVE_DIR + (SAVE_FILE_FORMAT % slot)


#存档位是否为空（文件不存在 / 读不出来 / 标记为空存档）
func isSlotEmpty(slot:int) -> bool:
	var data := loadSaveOf(slot)
	if data == null or data.is_empty:
		return true
	return false


#读取存档位资源，失败返回 null
func loadSaveOf(slot:int) -> SaveTemplate:
	var path := savePathOf(slot)
	if !FileAccess.file_exists(path):
		return null
	#CACHE_MODE_IGNORE：绕开资源缓存，保证读到磁盘上最新的存档
	var data = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
	if data == null or !(data is SaveTemplate):
		return null
	return data


#绑定 saves 下的 4 个存档位按钮
func _bindSaveSlots() -> void:
	for i in range(SAVE_SLOT_COUNT):
		_bindOneSlot(i + 1)


func _bindOneSlot(slot:int) -> void:
	var btn := _slots_box.get_node_or_null("save%02d" % slot)
	if btn != null:
		(btn as Button).pressed.connect(_on_save_slot_pressed.bind(slot))


#绑定 operations 下的 4 个操作按钮
func _bindOperationButtons() -> void:
	_bt_new.pressed.connect(_on_new_pressed)


#按下存档位：选中它（2.2）
func _on_save_slot_pressed(slot:int) -> void:
	selectSlot(slot)


#选中某个存档位（2.3.1）
func selectSlot(slot:int) -> void:
	selected_slot = clampi(slot, 1, SAVE_SLOT_COUNT)
	_refreshOperations()


#刷新全部存档位的显示
func refreshSlots() -> void:
	for i in range(SAVE_SLOT_COUNT):
		var slot := i + 1
		var btn := _slots_box.get_node_or_null("save%02d" % slot)
		if btn == null:
			continue
		var data := loadSaveOf(slot)
		if data == null or data.is_empty:
			(btn as Button).text = "存档_%d" % slot
		else:
			(btn as Button).text = "存档_%d" % slot
	if selected_slot > 0:
		_refreshOperations()


#按当前选中存档刷新 operations 区（2.3.1~2.3.5）
func _refreshOperations() -> void:
	if selected_slot <= 0:
		return
	var empty := isSlotEmpty(selected_slot)
	#2.3.1 显示当前选中的存档：存档名 + 保存时间（两行）
	var time_text := "（空存档）"
	if !empty:
		var data := loadSaveOf(selected_slot)
		if data != null and data.save_time != "":
			time_text = data.save_time
	_lbl_save_name.text = "存档_%d\n%s" % [selected_slot, time_text]
	#2.3.2 空存档：仅“新建”可视
	_bt_new.visible = empty
	#2.3.3 / 2.3.5 非空存档：加载、删除可视
	_bt_load.visible = !empty
	_bt_delete.visible = !empty
	#2.3.4 游戏内打开时：保存可视
	_bt_save.visible = is_from_game

#endregion


#region 对当前选中存档的操作
#2.3.2 新建存档
#主菜单 / 游戏内**语义一致**：都只新建一个「尚未游玩」的空白存档
#（is_new_save = true，不写任何游戏数据）—— 要保存当前进度请用「保存」按钮。
#新建之后点「加载」就会按全新开局进入（one.gd 的 load_game 会识别 is_new_save，
#用「全新开局快照」而不是文件里的全 0 数据）。
func _on_new_pressed() -> void:
	if selected_slot <= 0:
		return
	var path := savePathOf(selected_slot)
	var data := SaveTemplate.new()
	data.slot_index = selected_slot
	data.is_empty = false
	data.is_new_save = true
	data.save_time = SaveTemplate.nowSaveTime()
	_ensureSaveDir()
	ResourceSaver.save(data, path)
	if !is_from_game:
		#主菜单：记下待载入存档并停留本界面；等玩家点「加载」再打开游戏
		pending_save_path = path
	refreshSlots()
	selectSlot(selected_slot)


#2.3.3 加载存档
func _on_load_pressed() -> void:
	if selected_slot <= 0 or isSlotEmpty(selected_slot):
		return
	var path := savePathOf(selected_slot)
	pending_save_path = path
	if is_from_game:
		#游戏内：直接让 one.gd 读取该存档
		request_load_game.emit(path)
		queue_free()
	else:
		#主菜单：打开游戏（由 one.gd 后续读取 pending_save_path）
		emit_signal("open_selected_one")
		queue_free()


#2.3.4 保存存档
func _on_save_pressed() -> void:
	if selected_slot <= 0:
		return
	request_save_game.emit(savePathOf(selected_slot))
	refreshSlots()


#2.3.5 删除存档：删除文件，使其变为空白存档
func _on_delete_pressed() -> void:
	if selected_slot <= 0:
		return
	var path := savePathOf(selected_slot)
	#注意：不能用 ResourceLoader.exists 判断（资源缓存会误报），用 FileAccess 查磁盘
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	#删不掉则写一个空存档把它标记为空
	if FileAccess.file_exists(path):
		var empty_data := SaveTemplate.new()
		empty_data.slot_index = selected_slot
		empty_data.is_empty = true
		ResourceSaver.save(empty_data, path)
	refreshSlots()
	_refreshOperations()


#存档目录不存在时创建
func _ensureSaveDir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

#endregion


var index__=-1
#0:save 1:load 2:delete
func warningMixin():
	warning_page.hide()
	match index__:
		0:_on_save_pressed()
		1:_on_load_pressed()
		2:_on_delete_pressed()

#endregion

func load_pressed() -> void:
	if is_from_game:
		index__=1
		warning_page.show()
	else:
		_on_load_pressed()

func save_pressed() -> void:
	index__=0
	warning_page.show()

func delete_pressed() -> void:
	index__=2
	warning_page.show()

func _on_cancel_pressed() -> void:
	index__=-1
	warning_page.hide()
