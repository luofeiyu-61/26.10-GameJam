@tool
## A node in the dialogue graph that modifies a variable's value.
## Supports setting, addition, subtraction, multiplication, division, and toggling.

class_name OperatorNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## The name of the graph variable to modify.
@export var variable_name: String = ""
## The operation to perform on the variable.
@export var operation: enums.OperatorOperation = enums.OperatorOperation.SET
## The right‑hand value (as a string) used by the operation.
@export var value: String = ""  
## ID of the next node to go to after the operation.
@export var next_node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)

## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id


## Performs the configured operation on variable_name using value.
## If the variable doesn't exist, it is created with a null value first.
func operate(variables: Dictionary) -> void:
	# Ensure the variable exists in the dictionary.
	if not variables.has(variable_name):
		variables[variable_name] = null
	var current = variables[variable_name]
	var new_val = _parse_value(value, typeof(current))
	match operation:
		enums.OperatorOperation.SET:
			variables[variable_name] = new_val
		enums.OperatorOperation.ADD:
			# Booleans are not compatible with addition.
			if current is bool:
				push_error("Bool variable is not compatible with Add operation. Node id: ", node_id)
				return	
			variables[variable_name] = current + new_val
		enums.OperatorOperation.SUBTRACT:
			if current is not int and current is not float:
				push_error("Only float or interger are compatible with Subtract operation. Node id: ", node_id)
				return
			variables[variable_name] = current - new_val
		enums.OperatorOperation.MULTIPLY:
			if current is not int and current is not float:
				push_error("Only float or interger are compatible with Multiply operation. Node id: ", node_id)
				return
			variables[variable_name] = current * new_val
		enums.OperatorOperation.DIVIDE:
			if current is not int and current is not float:
				push_error("Only float or interger are compatible with Divide operation. Node id: ", node_id)
				return
			variables[variable_name] = current / new_val if new_val != 0 else current
		enums.OperatorOperation.TOGGLE:
			if current is not bool:
				push_error("Only bool is compatible with tToggle operation. Node id: ", node_id)
				return
			variables[variable_name] = not current

## Parses  str_val into a value matching target_type.
## Returns the parsed value, falling back to the string itself for unknown types.
func _parse_value(str_val: String, target_type: int):
	match target_type:
		TYPE_INT:
			return int(str_val)
		TYPE_FLOAT:
			return float(str_val)
		TYPE_BOOL:
			return str_val.to_lower() == "true"
		TYPE_STRING:
			return str_val
		_:
			return str_val
