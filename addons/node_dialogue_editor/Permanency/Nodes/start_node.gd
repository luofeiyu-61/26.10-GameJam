@tool
## A node in the dialogue graph that marks an entry point for the dialogue.
## A graph can have multiple start nodes, each leading to a different conversation path.
class_name StartNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## ID of the first node to jump to when this start point is chosen.
@export var next_node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)

## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id
