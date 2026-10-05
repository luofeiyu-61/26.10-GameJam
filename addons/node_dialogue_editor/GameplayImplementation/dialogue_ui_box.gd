class_name DialogueUIBox
extends Panel

## The in‑game UI panel that displays dialogue from a DialoguePlayer.
## It shows a speaker label, formatted dialogue text, and, when a
## QuestionNode is reached, a list of answer buttons.

## UI elements 
@onready var speaker_label: Label = $ColorRect3/speaker_label
@onready var dialogue_text: RichTextLabel = $ColorRect2/VBoxContainer/dialogue_text
@onready var choices_container: VBoxContainer = $ColorRect2/VBoxContainer/answers_container
@onready var next_button: Button = $next_button

## Preloaded scene for individual answer buttons (currently unused in this script).
var ui_button = preload("res://addons/node_dialogue_editor/GameplayImplementation/DialogueUIButton.tscn")

## The [DialoguePlayer] driving the current conversation.
var player: DialoguePlayer


func _ready() -> void:
	hide()
	next_button.pressed.connect(_on_next_pressed)


## Creates a new DialoguePlayer, hooks up its signals, starts the dialogue,
## and shows this panel.
func start_dialogue(graph: DialogueGraph, start_node_id: int, initial_variables: Dictionary = {}) -> void:
	player = DialoguePlayer.new()
	player.node_changed.connect(_on_node_changed)
	player.ended.connect(_on_dialogue_ended)
	if not player.start(graph, start_node_id, initial_variables):
		push_error("Error starting dialogue UI")
		hide()
		return
	show()


## Called whenever the dialogue moves to a new node.
## Updates the speaker and dialogue text, and either shows answer choices or a continue button.
func _on_node_changed(node: Resource) -> void:
	# Replace any embedded $$variables in the speaker and dialogue text.
	speaker_label.text = _process_text(node.get("speaker") if node.get("speaker") != null else "")
	dialogue_text.text = _process_text(node.get("dialogue_text") if node.get("dialogue_text") != null else "")

	## If the new node is a question, populate answer buttons; otherwise show "next".
	if node is QuestionNode:
		_populate_choices()
	else:
		choices_container.hide()
		next_button.show()


## Called when the dialogue reaches an end.
## Hides the panel and disconnects the player's signals.
func _on_dialogue_ended() -> void:
	hide()
	if player:
		player.node_changed.disconnect(_on_node_changed)
		player.ended.disconnect(_on_dialogue_ended)
		player = null


## Advances the dialogue when the player clicks the "next" button.
func _on_next_pressed() -> void:
	if not player:
		return
	player.advance_from_current_node()


## Clears existing answer buttons and creates a new button for each option
## returned by the current [QuestionNode].
func _populate_choices() -> void:
	_clear_options()

	var options = player.get_current_options()
	for i in options.size():
		var option = options[i]
		var button = Button.new()
		# Replace any $$variables in the answer text.
		button.text = _process_text(option.text)
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

	choices_container.show()
	next_button.hide()


## Replaces placeholders of the form [code]$$variable_name[/code] with the
## current value of that variable from [member player.graph.variables].
## Supports string, int, float, and bool types.
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
			## Replace the placeholder with the variable's string representation.
			result = result.substr(0, match.get_start()) + replacement + result.substr(match.get_end())
		
	return result


## Forwards the selected answer index to the DialoguePlayer.
func _on_choice_selected(index: int) -> void:
	if not player:
		return
	player.select_answer(index)


## Removes all child buttons from the choices container.
func _clear_options():
	for child in choices_container.get_children():
		child.queue_free()
