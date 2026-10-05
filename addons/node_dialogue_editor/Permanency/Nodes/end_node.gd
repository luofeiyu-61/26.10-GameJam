@tool
## A node in the dialogue graph that signals the end of a dialogue branch.
## When the dialogue reaches this node, the conversation finishes.
class_name EndNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)

## Must have a default value to avoid errors when loading nested resources like DialogueGraph.
func _init(p_id: int = -1) -> void:
	node_id = p_id
