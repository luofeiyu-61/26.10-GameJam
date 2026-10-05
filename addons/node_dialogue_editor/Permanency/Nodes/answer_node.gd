@tool
## A node in the dialogue graph representing a single answer within a question.
## It can contain its own speaker and dialogue text (shown when the answer is selected),
## and an optional answer_peek that is displayed in the question's choice list
## instead of the full dialogue text.
class_name AnswerNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## The speaker who delivers this answer's dialogue.
@export var speaker: String = ""
## A short preview of the answer shown in the question's choice list.
## Only used when answer_peek_enabled is true.
@export var answer_peek: String = "" 
## If true, answer_peek is shown instead of  dialogue_text in the question's choices.
@export var answer_peek_enabled: bool = false
## The full dialogue text spoken when this answer is selected.
@export var dialogue_text: String = ""
## ID of the next node to go to after this answer is fully displayed.
@export var next_node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)


## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id
