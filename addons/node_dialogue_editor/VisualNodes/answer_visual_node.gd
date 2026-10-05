@tool
## Visual representation of an AnswerNode inside the GraphEdit.
## Provides fields to edit the speaker, dialogue text, and an optional answer peek.
## The answer peek text field is shown/hidden via a checkbox.
class_name AnswerVisualNode
extends GraphNode

## The AnswerNode resource this visual node is bound to.
var resource: AnswerNode

@onready var speaker_text: TextEdit = $SpeakerText
@onready var dialogue_text: TextEdit = $DialogueText
@onready var answer_peek_check: CheckBox = $HBoxContainer/CheckBox
@onready var answer_peek_text: TextEdit = $AnswerPeekText


func _ready() -> void:
	title = "Answer"
	resize_end.connect(_on_resize_end)
	answer_peek_check.toggled.connect(_on_answer_peek_toggled)
	speaker_text.text_changed.connect(_on_speaker_changed)
	dialogue_text.text_changed.connect(_on_dialogue_changed)
	answer_peek_text.text_changed.connect(_on_answer_peek_changed)


## Assigns the AnswerNode resource and populates the UI with its values,
## including the visibility of the answer peek field.
func set_resource(res: AnswerNode) -> void:
	resource = res
	title = title + " " + str(res.node_id)
	speaker_text.text = resource.speaker
	dialogue_text.text = resource.dialogue_text
	answer_peek_text.text = resource.answer_peek
	answer_peek_check.button_pressed = resource.answer_peek_enabled
	answer_peek_text.visible = resource.answer_peek_enabled


## Updates the resource's speaker when the user edits the text.
func _on_speaker_changed() -> void:
	if resource:
		resource.speaker = speaker_text.text


## Updates the resource's dialogue text when the user edits the text.
func _on_dialogue_changed() -> void:
	if resource:
		resource.dialogue_text = dialogue_text.text


## Toggles the visibility of the answer peek field and updates the resource.
func _on_answer_peek_toggled(pressed: bool) -> void:
	answer_peek_text.visible = pressed
	resource.answer_peek_enabled = pressed
	_on_answer_peek_changed()


## Updates the resource's answer peek text when the field changes.
func _on_answer_peek_changed() -> void:
	if resource:
		resource.answer_peek = answer_peek_text.text
		

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
