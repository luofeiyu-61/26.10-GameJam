## Manages the traversal of a dialogue graph.
## Emits signals when nodes change or when the dialogue ends.
@tool
class_name DialoguePlayer
extends RefCounted

 ## Emitted when the active dialogue node changes.
signal node_changed(node: Resource)
## Emitted when the dialogue reaches an end.
signal ended                           

## The DialogueGraph resource currently being played.
var graph: DialogueGraph
## ID of the node that is currently active (-1 if none).
var current_node_id: int = -1
## If the player is currently showing an [AnswerNode] that has text, it is held here.
## Used to display the answer text before moving on.
var pending_answer_node: AnswerNode = null


## Initializes and starts the dialogue at a given start node.
## [param initial_variables] can be used to set or override graph variables before the dialogue begins.
## Returns true if the start was successful.
func start(graph_resource: DialogueGraph, start_node_id: int, initial_variables: Dictionary = {}) -> bool:
	graph = graph_resource

	# Ensure the graph has a variable dictionary and merge initial values.
	if graph.variables == null:
		graph.variables = {}
	for key in initial_variables:
		graph.variables[key] = initial_variables[key]

	## Validate the start node.
	if not graph or not graph.starts.has(start_node_id):
		push_error("Invalid graph or start node ID")
		return false

	var start_node = graph.starts[start_node_id]
	if not start_node is StartNode:
		push_error("Node is not a StartNode")
		return false

	var next_id = start_node.next_node_id
	if next_id == -1:
		push_error("Start node has no next node")
		return false

	## Begin traversal from the node after the start node.
	return go_to_node(next_id)


## Moves the dialogue to the node with the given [param node_id].
## Returns true if the node was successfully processed and the dialogue continues
## Returns false if the dialogue ended or the node ID was invalid.
func go_to_node(node_id: int) -> bool:
	if not graph or not graph.nodes.has(node_id):
		return false

	current_node_id = node_id
	var node = graph.nodes[node_id]

	## EndNode terminates the dialogue.
	if node is EndNode:
		ended.emit()
		return false

	## ConditionNode automatically branches based on graph variables.
	if node is ConditionNode:
		var condition = node as ConditionNode
		var next_id = condition.true_branch_id if condition.evaluate(graph.variables) else condition.false_branch_id
		if next_id == -1:
			ended.emit()
			return false
		return go_to_node(next_id)

	## OperatorNode modifies variables and then moves to the next node.
	if node is OperatorNode:
		var operator = node as OperatorNode
		operator.operate(graph.variables)
		var next_id = operator.next_node_id
		if next_id == -1:
			ended.emit()
			return false
		return go_to_node(next_id)

	## SignalNode emits custom signals (e.g., to trigger events) and then moves on.
	if node is SignalNode:
		var signal_node = node as SignalNode
		signal_node.emit_signals(graph.variables)
		var next_id = signal_node.next_node_id
		if next_id == -1:
			ended.emit()
			return false
		return go_to_node(next_id)

	## AnswerNode may contain dialogue text to display.
	## If it has text, store it as pending and signal a node change so the UI can show it.
	## If it has no text, treat it as a silent passthrough and advance immediately.
	if node is AnswerNode:
		pending_answer_node = node as AnswerNode
		if not pending_answer_node.dialogue_text.is_empty():
			node_changed.emit(node)
			return true
		else:
			return _advance_from_answer()

	## For any other node type (e.g., DialogueNode, QuestionNode), simply emit the change.
	node_changed.emit(node)
	return true


## Moves past the currently pending AnswerNode to its next node.
## If the answer had text, this should be called after the UI has displayed it and the player advances.
## Returns true if the dialogue continues, false if it ends.
func _advance_from_answer() -> bool:
	if not pending_answer_node:
		return false
	var next_id = pending_answer_node.next_node_id
	pending_answer_node = null
	if next_id == -1:
		ended.emit()
		return false
	return go_to_node(next_id)


## Advances the dialogue from the current node, if possible.
## This is used for nodes where the player presses a button to continue (like DialogueNode or a pending answer).
## Returns true if the dialogue advanced, false if it ended or no valid next node.
func advance_from_current_node() -> bool:
	var node = get_current_node()
	if not node:
		return false

	## If a pending AnswerNode is active, advance past it.
	if pending_answer_node and node == pending_answer_node:
		return _advance_from_answer()

	## DialogueNode can be advanced directly.
	if node is DialogueNode:
		var next_id = node.next_node_id
		if next_id == -1:
			ended.emit()
			return false
		return go_to_node(next_id)
		
	return false


## Returns the currently active Resource node
func get_current_node() -> Resource:
	if current_node_id == -1 or not graph:
		return null
	return graph.nodes.get(current_node_id)


## If the current node is a QuestionNode, returns an array of dictionaries describing each option.
## Each dictionary contains:
##   - "text": the text to show the player. answer_peek if enabled, otherwise dialogue_text.
##   - "answer_node": the AnswerNode resource
##   - "next_node_id": the ID of the node that follows the answer
func get_current_options() -> Array:
	var node = get_current_node()
	if not node is QuestionNode:
		return []

	var question = node as QuestionNode
	var options = []
	for target_id in question.next_node_ids:
		var target_node = graph.nodes.get(target_id)
		if target_node and target_node is AnswerNode:
			var answer = target_node as AnswerNode
			var display_text = answer.answer_peek if answer.answer_peek_enabled and not answer.answer_peek.is_empty() else answer.dialogue_text
			options.append({
				"text": display_text,
				"answer_node": answer,
				"next_node_id": answer.next_node_id
			})
	return options


## Selects an answer option by its index.
## If the chosen AnswerNode has dialogue text, it becomes the pending answer and is emitted as the new node.
## If it has no text, the dialogue immediately moves to the answer's next node.
## Returns true if the selection was valid and the dialogue continues
## Returns false if the index was invalid or the dialogue ends.
func select_answer(index: int) -> bool:
	var options = get_current_options()
	if index < 0 or index >= options.size():
		return false
	var selected = options[index]
	var answer_node = selected.answer_node

	if not answer_node.dialogue_text.is_empty():
		## Display the answer text before continuing.
		pending_answer_node = answer_node
		current_node_id = answer_node.node_id
		node_changed.emit(answer_node)
		return true
	else:
		## Answer peek only answer, go directly to the next node.
		var next_id = answer_node.next_node_id
		if next_id == -1:
			ended.emit()
			return false
		return go_to_node(next_id)


## Checks whether the player can manually advance the dialogue.
## Returns true if the current node is a DialogueNode or a pending AnswerNode.
func can_advance() -> bool:
	var node = get_current_node()
	if not node:
		return false
	if node is DialogueNode:
		return true
	if pending_answer_node and node == pending_answer_node:
		return true
	return false
