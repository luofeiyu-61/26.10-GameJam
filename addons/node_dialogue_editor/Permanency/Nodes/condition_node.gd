@tool
## A node in the dialogue graph that evaluates a condition on a variable.
## Based on the result, the dialogue branches to true_branch_id or false_branch_id].
class_name ConditionNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## The name of the graph variable to check.
@export var variable_name: String = ""
## The comparison operator to apply.
@export var operator: enums.ComparisonOperator = enums.ComparisonOperator.EQUAL
## The value to compare against (as a string). Will be parsed to match the variable's type.
@export var compare_value: String = ""  
## ID of the node to go to if the condition is true.
@export var true_branch_id: int = -1
## ID of the node to go to if the condition is false.
@export var false_branch_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(0,0)

## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id

## Evaluates the condition using the current variable values.
## Returns true if the condition holds, false otherwise.
## If the variable does not exist, the result is false.
func evaluate(variables: Dictionary) -> bool:
	if not variables.has(variable_name):
		return false
	var current = variables[variable_name]
	var target = _parse_value(compare_value, typeof(current))
	return _compare(current, target)

## Converts a string representation into a value that matches target_type.
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

## Applies the configured comparison operator to param a and param b.
func _compare(a, b) -> bool:
	match operator:
		enums.ComparisonOperator.EQUAL:
			return a == b
		enums.ComparisonOperator.NOT_EQUAL:
			return a != b
		enums.ComparisonOperator.GREATER:
			return a > b
		enums.ComparisonOperator.LESS:
			return a < b
		enums.ComparisonOperator.GREATER_EQUAL:
			return a >= b
		enums.ComparisonOperator.LESS_EQUAL:
			return a <= b
	return false
