extends Control

## Preloaded dialogue graph resources
@export var lineal_dialogue: DialogueGraph
@export var branching_dialogue: DialogueGraph
@export var wheel_dialogue: DialogueGraph
@export var hub_dialogue: DialogueGraph

## UI references
@onready var option_button: OptionButton = $Panel/VBOXContainer/OptionButton
@onready var start_button: Button = $Panel/VBOXContainer/Button
@onready var dialogue_ui: DialogueUIBox = $DialogueUiBox

func _on_start_pressed() -> void:
	var selected_index = option_button.selected
	var selected_graph: DialogueGraph = null
	
	match selected_index:
		0: # Lineal Dialogue
			selected_graph = lineal_dialogue
		1: # Branching Dialogue
			selected_graph = branching_dialogue
		2: # Wheel Dialogue
			selected_graph = wheel_dialogue
		3: # Hub Dialogue
			selected_graph = hub_dialogue
	
	dialogue_ui.start_dialogue(selected_graph, 0, {})
