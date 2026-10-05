@tool
## A node in the dialogue graph that presents a question and branches to different
## answers. Each answer is represented by an AnswerNode referenced in next_node_ids.
class_name QuestionNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## The speaker asking the question (can be empty).
@export var speaker: String = ""
## The question text to display.
@export var dialogue_text: String = ""
## Ordered list of node IDs pointing to the AnswerNodes that form the choices.
@export var next_node_ids: Array[int]
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)

## Must have a default value to avoid errors when loading nested resources like DialogueGraph.
func _init(p_id: int = -1) -> void:
	node_id = p_id

## Returns the node ID of the answer at the given index.
func get_answer_node_id(answer_index: int) -> int:
	return next_node_ids[answer_index] if answer_index < next_node_ids.size() else -1
