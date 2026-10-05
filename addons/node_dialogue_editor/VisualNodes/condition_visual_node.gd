@tool
## Visual representation of a ConditionNode inside the GraphEdit.
## Provides fields to edit the variable name, operator, and comparison value,
## and keeps the underlying resource in sync.
class_name ConditionVisualNode
extends GraphNode

## The ConditionNode resource this visual node is bound to.
var resource: ConditionNode

## Input field for the variable name.
@onready var variable_edit: LineEdit = $VariableEdit
## Dropdown for the comparison operator.
@onready var operator_option: OptionButton = $OperatorOption
## Input field for the value to compare against.
@onready var value_edit: LineEdit = $ValueEdit


func _ready() -> void:
	title = "Condition"
	resize_end.connect(_on_resize_end)
	variable_edit.text_changed.connect(_on_variable_changed)
	operator_option.item_selected.connect(_on_operator_changed)
	value_edit.text_changed.connect(_on_value_changed)


## Assigns the ConditionNode resource and populates the UI with its values.
func set_resource(res: ConditionNode):
	resource = res
	title = title + " " + str(res.node_id)
	variable_edit.text = resource.variable_name
	operator_option.select(resource.operator)
	value_edit.text = resource.compare_value


## Updates the resource's variable name when the user edits the text.
func _on_variable_changed(new_text: String):
	if resource:
		resource.variable_name = new_text


## Updates the resource's operator when a new dropdown item is selected.
func _on_operator_changed(idx: int):
	if resource:
		resource.operator = idx


## Updates the resource's compare value when the text is changed.
func _on_value_changed(new_text: String):
	if resource:
		resource.compare_value = new_text
		

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
