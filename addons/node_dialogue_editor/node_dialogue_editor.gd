@tool
extends EditorPlugin

const EDITOR = preload("res://addons/node_dialogue_editor/EditorScreen/EditorScreen.tscn")
const AUTOLOAD_NAME = "DialogueSignals"
var editor_instance

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/node_dialogue_editor/DialogueExecution/dialogue_signals.gd")
	pass

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	pass

func _enter_tree() -> void:
	editor_instance = EDITOR.instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(editor_instance)
	
	_make_visible(false)
	pass

func _exit_tree() -> void:
	if editor_instance:
		editor_instance.queue_free()
	pass

func _has_main_screen() -> bool:
	return true
	
func _make_visible(visible):
	if editor_instance:
		editor_instance.visible = visible

func _get_plugin_name():
	return "Dialogue Editor"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
