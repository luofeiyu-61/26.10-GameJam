@tool
## A basic node in the dialogue graph that displays speaker text and dialogue.
class_name DialogueNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## The speaker saying this piece of dialogue (can be empty).
@export var speaker: String = ""
## The main dialogue text to display.
@export var dialogue_text: String = ""
## ID of the next node to go to after this node.
@export var next_node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)

## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id
