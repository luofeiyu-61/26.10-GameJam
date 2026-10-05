## Floating window used in editor that displays dialogue from a DialoguePlayer.
## It shows the speaker, the dialogue text, and a list of answer buttons.
@tool
class_name DialogueRunWindow
extends Window

var player: DialoguePlayer             ## The player currently driving the dialogue.
var start_node_id: int = -1            ## The ID of the start node used to begin the dialogue.
var _graph_edit: GraphEdit = null      ## Reference to the GraphEdit (for visual node selection).

## UI elements. 
@onready var speaker_label: Label = $ColorRect3/speaker_label
@onready var dialogue_text: RichTextLabel = $ColorRect2/VBoxContainer/dialogue_text
@onready var choices_container: VBoxContainer = $ColorRect2/VBoxContainer/answers_container
@onready var next_button: Button = $next_button


## Connects signals and hides dynamic UI elements that aren't needed at start.
func _ready():
	next_button.pressed.connect(_on_next_pressed)
	close_requested.connect(_on_close_requested)
	
	choices_container.visible = false
	next_button.visible = false
	

## Creates a new DialoguePlayer, connects signals, starts the dialogue,
## and shows this window at the current mouse position.
func start_dialogue(graph_edit: GraphEdit, graph: DialogueGraph, start_node_id: int, initial_variables: Dictionary = {}) -> void:
	player = DialoguePlayer.new()
	_graph_edit = graph_edit
	player.node_changed.connect(_on_node_changed)
	player.ended.connect(_on_dialogue_ended)
	if not player.start(graph, start_node_id, initial_variables):
		push_error("Error starting dialogue UI")
		hide()
		return
	show()
	position = get_mouse_position()


## Called whenever the dialogue moves to a new node.
## Updates the speaker and dialogue text, highlights the corresponding node in the GraphEdit,
## and either populates answer choices or shows the "next" button.
func _on_node_changed(node: Resource) -> void:
	## Highlight the node in the editor's graph.
	_graph_edit.set_selected(_graph_edit.resource_to_node[node])  
	
	# Replace any embedded $$variables in the speaker and dialogue text.
	speaker_label.text = _process_text(node.get("speaker") if node.get("speaker") != null else "")
	dialogue_text.text = _process_text(node.get("dialogue_text") if node.get("dialogue_text") != null else "")

	## If the node is a QuestionNode, show the answer buttons.
	if node is QuestionNode:
		_populate_choices()
	else:
		choices_container.hide()
		next_button.show()


## Called when the dialogue reaches an end.
## Hides the window and disconnects the player's signals.
func _on_dialogue_ended() -> void:
	hide()
	if player:
		player.node_changed.disconnect(_on_node_changed)
		player.ended.disconnect(_on_dialogue_ended)
		player = null
	queue_free()


## Handles the "next" button press to advance simple dialogue nodes.
func _on_next_pressed() -> void:
	if not player:
		return
	player.advance_from_current_node()


## Clears previous answer buttons and creates new ones for the current QuestionNode.
func _populate_choices() -> void:
	_clear_options()

	var options = player.get_current_options()
	for i in options.size():
		var option = options[i]
		var button = Button.new()
		## Replace any $$variables in the answer text.
		button.text = _process_text(option.text)
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

	choices_container.show()
	next_button.hide()


## Replaces placeholders of the form $$variable_name with the
## current value of that variable from graph.variables
func _process_text(str: String) -> String:
	var result = str
	var regex = RegEx.new()
	
	## Find all occurrences of $$ followed by word characters.
	regex.compile("\\$\\$(\\w+)")
		
	var matches = regex.search_all(result)
	
	## Process matches in reverse to keep string indices valid.
	matches.reverse()
	for match in matches:
		var full_match = match.get_string()
		var var_name = match.get_string(1)
		
		if player.graph.variables.has(var_name):
			var value = player.graph.variables[var_name]
			
			var replacement = ""
			match typeof(value):
				TYPE_STRING:
					replacement = value
				TYPE_INT:
					replacement = str(value)
				TYPE_FLOAT:
					replacement = str(value)
				TYPE_BOOL:
					replacement = str(value).to_lower()
			# Replace the placeholder with the variable's string representation.
			result = result.substr(0, match.get_start()) + replacement + result.substr(match.get_end())
		
	return result


## Called when the player clicks one of the answer buttons.
## Forwards the choice index to the DialoguePlayer.
func _on_choice_selected(index: int) -> void:
	if not player:
		return
	player.select_answer(index)


## Removes all child nodes from the choices container.
func _clear_options():
	for child in choices_container.get_children():
		child.queue_free()
		

## Handles the close request of the window.
func _on_close_requested():
	queue_free()
