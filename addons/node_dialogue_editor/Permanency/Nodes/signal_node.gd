@tool
## A node in the dialogue graph that emits a signal to DialogueSignals.
## It can pass arguments from the graph's variables or literal values.
class_name SignalNode
extends Resource

## Unique identifier for this node in the graph.
@export var node_id: int = -1
## Name of the signal to emit. Must exist as a signal in DialogueSignals.
@export var signal_name: String = ""
## Arguments to pass with the signal. If an argument starts with "$",
## the rest is interpreted as a variable name and its current value is passed;
## otherwise the argument is parsed as a literal (int, float, bool, or string).
@export var arguments: Array[String] = []
## ID of the next node to go to after emitting the signal.
@export var next_node_id: int = -1
## Position of the node in the graph editor.
@export var position: Vector2 = Vector2(0, 0)
## Size of the visual node in the graph editor.
@export var size: Vector2 = Vector2(200,200)


## Must have default value to avoid errors when loading nested resources like DialogueGraph
func _init(p_id: int = -1) -> void:
	node_id = p_id


## Emits the configured signal with the evaluated arguments.
## Arguments prefixed with "$" are replaced by the corresponding variable value
## from DialogueGraph variables. Other arguments are parsed as literals.
func emit_signals(variables: Dictionary) -> void:
	var parsed_args = []
	for arg in arguments:
		if arg.begins_with("$"):
			var var_name = arg.substr(1)
			parsed_args.append(variables.get(var_name, null))
		else:
			parsed_args.append(_parse_literal(arg))
	if DialogueSignals.has_signal(signal_name):
		DialogueSignals.emit_signal(signal_name, parsed_args)


## Converts a string representation to a typed literal value (int, float, bool, or string).
func _parse_literal(str_val: String):
	if str_val.is_valid_int():
		return int(str_val)
	if str_val.is_valid_float():
		return float(str_val)
	if str_val.to_lower() == "true":
		return true
	if str_val.to_lower() == "false":
		return false
	return str_val
