@tool
## Visual representation of an OperatorNode inside the GraphEdit.
## Provides fields to edit the variable name, operation, and value.
class_name OperatorVisualNode
extends GraphNode

## The OperatorNode resource this visual node is bound to.
var resource: OperatorNode

@onready var variable_edit: LineEdit = $VariableEdit
@onready var operation_option: OptionButton = $OperationOption
@onready var value_edit: LineEdit = $ValueEdit


func _ready():
	title = "Operator"
	resize_end.connect(_on_resize_end)
	variable_edit.text_changed.connect(_on_variable_changed)
	operation_option.item_selected.connect(_on_operation_changed)
	value_edit.text_changed.connect(_on_value_changed)


## Assigns the OperatorNode resource and populates the UI with its values.
func set_resource(res: OperatorNode):
	resource = res
	title = title + " " + str(res.node_id)
	variable_edit.text = resource.variable_name
	operation_option.select(resource.operation)
	value_edit.text = resource.value


## Updates the resource's variable name when the user edits the text.
func _on_variable_changed(new_text: String):
	if resource:
		resource.variable_name = new_text


## Updates the resource's operation when a new dropdown item is selected.
func _on_operation_changed(idx: int):
	if resource:
		resource.operation = idx


## Updates the resource's value when the user edits the text.
func _on_value_changed(new_text: String):
	if resource:
		resource.value = new_text
		

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
