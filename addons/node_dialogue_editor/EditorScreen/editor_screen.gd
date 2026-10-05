@tool
## Main editor panel for the Dialogue Graph plugin.
## Provides a graph editing area, a variable inspector, a recent‑files list,
## and the possibility to run dialogues in a DialogueRunWindow.
extends Control

## Preloaded scene for the floating dialogue window.
var window_scene = preload("res://addons/node_dialogue_editor/EditorScreen/RunWindow/DialogueRunWindow.tscn")

## List of recently opened file paths (stored in editor settings).
var recent_files: Array[String] = []
## The [DialogueGraph] resource currently being edited.
var current_graph: DialogueGraph
## Path of the currently opened graph file (empty if never saved).
var current_file_path: String = ""
## Shortcut for Ctrl+S to trigger save.
var save_shortcut = Shortcut.new()

## Graph
@onready var graph_edit: GraphEdit = $VBoxContainer/HSplitContainer/HSplitContainer/GraphEdit

## Toolbar
@onready var file_menu: PopupMenu = $VBoxContainer/PanelContainer/FileMenu/PopupMenu
@onready var run_menu: PopupMenu = $VBoxContainer/PanelContainer/FileMenu/RunMenu

## Var Inspector
@onready var variable_panel: PanelContainer = $VBoxContainer/HSplitContainer/HSplitContainer/VariablePanel
@onready var variables_tree: Tree = $VBoxContainer/HSplitContainer/HSplitContainer/VariablePanel/VBoxContainer/VariablesTree
@onready var add_var_button: Button = $VBoxContainer/HSplitContainer/HSplitContainer/VariablePanel/VBoxContainer/HBoxContainer/AddVariable
@onready var remove_var_button: Button = $VBoxContainer/HSplitContainer/HSplitContainer/VariablePanel/VBoxContainer/HBoxContainer/RemoveVariable

## Recent files
@onready var recent_panel: PanelContainer = $VBoxContainer/HSplitContainer/RecentFilesContainer
@onready var recent_list: ItemList = $VBoxContainer/HSplitContainer/RecentFilesContainer/RecentFilesList


func _ready():
	## Hide graph edit and inspector on start
	graph_edit.visible = false

	## Connect file menu 
	file_menu.id_pressed.connect(_on_file_menu_id_pressed)
	
	## Connect run menu
	run_menu.id_pressed.connect(_on_run_menu_id_pressed)

	## Connect graph edit
	graph_edit.node_selected.connect(_on_graph_node_selected)
	graph_edit.node_deselected.connect(_on_graph_node_deselected)
	
	## Connect recent files
	recent_list.item_activated.connect(_on_recent_file_selected)
	
	## Build Ctrl+S shortcut
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_S
	key_event.ctrl_pressed = true
	key_event.command_or_control_autoremap = true
	save_shortcut.events = [key_event]
	
	_setup_variables_panel()
	_setup_recent_files_panel()


## Detects the Ctrl+S shortcut and triggers save if a graph is loaded and the panel is visible.
func _input(event):
	if current_graph != null and is_visible_in_tree() and save_shortcut.matches_event(event) and event.is_pressed() and not event.is_echo():
		_save_graph()


# File menu functions


## Handles the File menu commands (New, Open, Save, Save As).
func _on_file_menu_id_pressed(id: int):
	match id:
		0: _new_graph()
		1: _open_graph()
		2: _save_graph()
		3: _save_as_graph()


## Creates a new empty DialogueGraph and switches the editor to it.
func _new_graph():
	current_graph = DialogueGraph.new()
	current_file_path = ""
	graph_edit.set_graph_resource(current_graph)
	graph_edit.visible = true
	_update_variables_panel() 


## Opens a file dialog to load an existing graph.
func _open_graph():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.tres; Dialogue Graph")
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.title = "Open Dialogue Graph"
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_open_file_selected)
	file_dialog.popup_centered()


## Callback when a file is selected in the open dialog.
## Duplicates the loaded graph to avoid modifying the original resource directly.
func _on_open_file_selected(path: String):
	var graph = DialogueGraph.load_from_file(path)
	var new_copy = graph.duplicate(true)
	if graph:
		current_graph = new_copy
		current_file_path = path
		graph_edit.set_graph_resource(current_graph)
		graph_edit.visible = true
		_update_variables_panel()
		_add_recent_file(path)
	else:
		push_error("Failed to load graph from: ", path)


## Saves the current graph. If no file path is set, calls _save_as_graph.
func _save_graph():
	if current_file_path.is_empty():
		_save_as_graph()
	else:
		var result = current_graph.save_to_file(current_file_path)
		if result != OK:
			push_error("Save failed: ", result)


## Opens a file dialog to save the graph under a new name.
func _save_as_graph():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.tres ; Dialogue Graph")
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.title = "Save Dialogue Graph As"
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_save_as_selected)
	file_dialog.popup_centered()


## Sets the current file path to the chosen one and saves.
func _on_save_as_selected(path: String):
	current_file_path = path
	_save_graph()
	

# Run menu functions


func _on_run_menu_id_pressed(id: int):
	match id:
		0: _on_run_pressed()


## Initiates the dialogue run process.
## Finds all StartNodes that have a valid next node and lets the user pick one.
func _on_run_pressed():
	if not current_graph or current_graph.nodes.is_empty():
		printerr("No graph loaded or empty graph")
		return
	
	var start_nodes = []
	for node_id in current_graph.starts:
		var start: StartNode = current_graph.starts[node_id]
		if start.next_node_id != -1:
			start_nodes.append(node_id)
	
	if start_nodes.is_empty():
		printerr("No start nodes in graph")
		return
	
	_show_start_node_selection(start_nodes)


## Displays a small dialog where the user can choose which start node to run from.
func _show_start_node_selection(start_nodes: Array):
	var popup = AcceptDialog.new()
	popup.title = "Select Start Node"
	popup.ok_button_text = "Close"
	var vbox = VBoxContainer.new()
	var option_button = OptionButton.new()
	for node_id in start_nodes:
		option_button.add_item("Start Node %d" % node_id, node_id)
	vbox.add_child(option_button)
	var ok_btn = Button.new()
	ok_btn.text = "Run"
	ok_btn.pressed.connect(func():
		var selected_id = option_button.get_selected_id()
		popup.queue_free()
		_run_dialogue(selected_id)
	)
	vbox.add_child(ok_btn)
	popup.add_child(vbox)
	self.add_child(popup)
	popup.popup_centered()


## Instantiates a DialogueRunWindow and starts the dialogue from the chosen start node.
func _run_dialogue(start_id: int):
	var window: DialogueRunWindow = window_scene.instantiate()
	self.add_child(window)
	window.start_dialogue(graph_edit, current_graph, start_id, {})

# Graph selection handling 

func _on_graph_node_selected(node: GraphNode):
	return

func _on_graph_node_deselected(node: GraphNode):
	return


# Recent files panel


## Sets up the recent files panel: loads saved list and updates the UI.
func _setup_recent_files_panel():
	_load_recent_files()
	_update_recent_panel()


## Retrieves the recent file paths from editor settings.
func _load_recent_files():
	var settings = EditorInterface.get_editor_settings() if Engine.is_editor_hint() else null
	if settings:
		recent_files = settings.get_setting("dialogue_editor/recent_files")


## Saves the recent file list to editor settings (only in the editor).
func _save_recent_files():
	if Engine.is_editor_hint():
		var settings = EditorInterface.get_editor_settings()
		settings.set_setting("dialogue_editor/recent_files", recent_files)
		

## Refreshes the recent files [ItemList] with the stored paths.
func _update_recent_panel():
	recent_list.clear()
	for path in recent_files:
		recent_list.add_item(path.get_file().get_basename())
		var idx = recent_list.item_count - 1
		recent_list.set_item_metadata(idx, path)
		

## Adds a file path to the front of the recent list, trimming to a maximum of 20 entries.
func _add_recent_file(path: String):
	if path.is_empty():
		return
	if not recent_files.has(path):
		recent_files.insert(0, path)
		if recent_files.size() > 20:
			recent_files.resize(20)
			_save_recent_files()
	_update_recent_panel()


## Opens the selected recent file.
func _on_recent_file_selected(idx: int):
	var path = recent_list.get_item_metadata(idx)
	if FileAccess.file_exists(path):
		_on_open_file_selected(path)
	else:
		recent_files.remove_at(idx)
		_save_recent_files()
		_update_recent_panel()


# Variables panel


## Configures the Tree for the variable inspector and connects its signals.
func _setup_variables_panel():
	variables_tree.columns = 3
	variables_tree.set_column_title(0, "Name")
	variables_tree.set_column_title(1, "Type")
	variables_tree.set_column_title(2, "Value")
	variables_tree.set_column_expand(0,true)
	variables_tree.set_column_custom_minimum_width(0,70)
	
	add_var_button.pressed.connect(_on_add_variable_pressed)
	remove_var_button.pressed.connect(_on_remove_variable_pressed)
	variables_tree.item_edited.connect(_on_variable_edited)
	
	variable_panel.visible = false


## Refreshes the variable tree with the current graph's variables.
func _update_variables_panel():
	if not current_graph:
		variable_panel.visible = false
		return
	
	variable_panel.visible = true
	variables_tree.clear()
	
	var root = variables_tree.create_item()
	for var_name in current_graph.variables:
		var value = current_graph.variables[var_name]
		var type_str = typeof(value)
		var type_name = type_to_string(type_str)
		var default_str = str(value)
		
		var item = variables_tree.create_item(root)
		item.set_text(0, var_name)
		item.set_text(1, type_name)
		## Booleans are represented as checkboxes.
		if type_name == "bool":
			item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			item.set_checked(2, value)
		else:
			item.set_text(2, default_str)
		item.set_editable(0, true)
		item.set_editable(2, true)


## Converts a GDScript type to a human‑readable string.
func type_to_string(type_int: int) -> String:
	match type_int:
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		_: return "unknown"


## Converts a type string back to a GDScript type integer.
func string_to_type(type_str: String) -> int:
	match type_str:
		"bool": return TYPE_BOOL
		"int": return TYPE_INT
		"float": return TYPE_FLOAT
		"String": return TYPE_STRING
		_: return TYPE_NIL


## Opens a dialog to create a new variable, with name, type, and initial value fields.
func _on_add_variable_pressed():
	if not current_graph:
		return
	
	var dialog = AcceptDialog.new()
	dialog.title = "Add Variable"
	dialog.ok_button_text = "Add"
	
	var vbox = VBoxContainer.new()
	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "Variable name"
	var type_option = OptionButton.new()
	type_option.add_item("bool")
	type_option.add_item("int")
	type_option.add_item("float")
	type_option.add_item("String")
	var value_edit = LineEdit.new()
	value_edit.placeholder_text = "Value"
	
	var label_name = Label.new()
	label_name.text = "Name:"
	vbox.add_child(label_name)
	
	vbox.add_child(name_edit)
	
	var label_type = Label.new()
	label_type.text = "Type:"
	vbox.add_child(label_type)
	
	vbox.add_child(type_option)
	
	var label_value = Label.new()
	label_value.text = "Value:"
	vbox.add_child(label_value)
	vbox.add_child(value_edit)
	
	dialog.add_child(vbox)
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		var var_name = name_edit.text.strip_edges()
		if var_name.is_empty():
			return
		if current_graph.variables.has(var_name):
			push_error("Variable already exists: ", var_name)
			return
		var type_str = type_option.get_item_text(type_option.selected)
		var type_int = string_to_type(type_str)
		var default_value = _parse_value(value_edit.text, type_int)
		current_graph.variables[var_name] = default_value
		_update_variables_panel()
	)
	dialog.popup_centered()


## Removes the currently selected variable from the graph.
func _on_remove_variable_pressed():
	var selected = variables_tree.get_selected()
	if not selected or selected.get_parent() != variables_tree.get_root():
		return
	var var_name = selected.get_text(0)
	if current_graph and current_graph.variables.has(var_name):
		current_graph.variables.erase(var_name)
		_update_variables_panel()


## Called when the user edits a variable name or value in the tree.
## Handles renaming and updating values with the correct type.
func _on_variable_edited():
	var selected = variables_tree.get_selected()
	if not selected:
		return
	var col = variables_tree.get_selected_column()
	var var_name = selected.get_text(0)
	if not current_graph:
		return
	match col:
		0: # rename
			var new_name = selected.get_text(0)
			if new_name != var_name and not new_name.is_empty() and not current_graph.variables.has(new_name):
				var value = current_graph.variables[var_name]
				current_graph.variables.erase(var_name)
				current_graph.variables[new_name] = value
				_update_variables_panel()
			else:
				selected.set_text(0, var_name)
		2: # edit value
			var old_value = current_graph.variables[var_name]
			var type_name = type_to_string(typeof(old_value))
			if type_name == "bool":
				var new_value = selected.is_checked(2)
				current_graph.variables[var_name] = new_value
			else:
				var new_value_str = selected.get_text(2)
				var new_value = _parse_value(new_value_str, typeof(old_value))
				current_graph.variables[var_name] = new_value
				selected.set_text(2, str(new_value))


## Parses a string into a value of the given type, returning a default if invalid.
func _parse_value(str_val: String, target_type: int):
	match target_type:
		TYPE_BOOL:
			return str_val.to_lower() == "true"
		TYPE_INT:
			return int(str_val) if str_val.is_valid_int() else 0
		TYPE_FLOAT:
			return float(str_val) if str_val.is_valid_float() else 0.0
		TYPE_STRING:
			return str_val
		_:
			return str_val
