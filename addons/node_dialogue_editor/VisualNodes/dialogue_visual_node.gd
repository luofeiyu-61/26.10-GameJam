@tool
## Visual representation of a DialogueNode inside the GraphEdit.
## Provides fields to edit the speaker and dialogue text, and handles resizing.
class_name DialogueVisualNode
extends GraphNode

## The DialogueNode resource this visual node is bound to.
var resource: DialogueNode

@onready var speaker_text: TextEdit = $SpeakerText
@onready var dialogue_text: TextEdit = $DialogueText


func _ready() -> void:
	title = "Dialogue"
	resize_end.connect(_on_resize_end)
	speaker_text.text_changed.connect(_on_speaker_changed)
	dialogue_text.text_changed.connect(_on_dialogue_changed)


## Assigns the [DialogueNode] resource and populates the UI with its values.
func set_resource(res: DialogueNode) -> void:
	resource = res
	title = title + " " + str(res.node_id)
	speaker_text.text = resource.speaker
	dialogue_text.text = resource.dialogue_text


## Updates the resource's speaker when the user edits the text.
func _on_speaker_changed() -> void:
	if resource:
		resource.speaker = speaker_text.text


## Updates the resource's dialogue text when the user edits the text.
func _on_dialogue_changed() -> void:
	if resource:
		resource.dialogue_text = dialogue_text.text
		

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
