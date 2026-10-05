@tool
## Custom [GraphEdit] node used as the canvas for the Dialogue Graph editor.
## It manages the creation, connection, deletion, copy/paste/cut, and visual
## representation of all dialogue node types stored in a [DialogueGraph] resource.
extends GraphEdit

## Holds copied GraphNodes data for paste operations.
var clipboard_data: Array[Dictionary] = []

## The DialogueGraph resource currently being edited.
var graph_resource: DialogueGraph

## Maps each Resource node to its visual GraphNode counterpart.
var resource_to_node: Dictionary = {}

## PopupMenu that appears when right‑clicking the graph to add new nodes.
@onready var popupmenu: PopupMenu = $PopupMenu

## Preloaded scenes for each type of visual node.
@onready var node_visuals: Array[PackedScene] = [
	preload("res://addons/node_dialogue_editor/VisualNodes/start_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/dialogue_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/question_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/answer_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/end_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/condition_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/operator_visual_node.tscn"),
	preload("res://addons/node_dialogue_editor/VisualNodes/signal_visual_node.tscn")
]


func _ready() -> void:
	# Connect all built‑in GraphEdit signals to handlers.
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)
	delete_nodes_request.connect(_on_delete_nodes_request)
	copy_nodes_request.connect(_on_copy_nodes)
	cut_nodes_request.connect(_on_cut_nodes)
	paste_nodes_request.connect(_on_paste_nodes)


# Editor screen managing

## Removes all visual nodes and clears the resource mappings and current graph.
func clear_graph() -> void:
	for child in get_children():
		if child is GraphNode:
			child.queue_free()
	resource_to_node.clear()
	graph_resource = null


## Assigns a new DialogueGraph to edit and rebuilds the entire visual graph from it.
func set_graph_resource(graph: DialogueGraph) -> void:
	clear_graph()
	graph_resource = graph
	_rebuild_from_resource()


# =============================================
# PopupMenu managing
# =============================================

## Called when the user right‑clicks on the graph background.
## Shows the popup menu at the corrected global position.
func on_graph_edit_popup_request(position: Vector2) -> void:
	var pop_position = position + global_position + Vector2(get_window().position)
	popupmenu.popup(Rect2(pop_position.x, pop_position.y, 100, 100))


## Handles the selection of a menu item; adds the corresponding node at the mouse position.
func _on_popup_menu_id_pressed(id: int) -> void:
	
	_add_node_at_position(id, (get_local_mouse_position() + scroll_offset) / zoom)

# Adding nodes

## Creates a new visual node of the given type at the position in graph space,
## adds it to the graph resource, and wires up its signals.
func _add_node_at_position(type: int, position: Vector2) -> void:
	if type < 0 or type >= node_visuals.size():
		return
	var scene = node_visuals[type]
	if not scene:
		return

	var visual_node = scene.instantiate()
	var node_id = _get_next_node_id()
	var resource = _create_resource_for_type(type, node_id)
	resource.position = position

	add_child(visual_node)
	if visual_node.has_method("set_resource"):
		visual_node.set_resource(resource)
	else:
		push_error("Visual node missing set_resource method")
		visual_node.queue_free()
		return

	visual_node.position_offset = position

	## Connect movement signal to can update the resource's position.
	visual_node.position_offset_changed.connect(_on_node_moved.bind(visual_node, resource))

	resource.size = visual_node.size

	resource_to_node[resource] = visual_node
	if resource is StartNode:
		graph_resource.starts[node_id] = resource
	else:
		graph_resource.nodes[node_id] = resource


## Scans all existing start and normal nodes to find the next available unique ID.
func _get_next_node_id() -> int:
	var max_id = -1
	for id in graph_resource.nodes.keys():
		if id > max_id:
			max_id = id
	for id in graph_resource.starts.keys():
		if id > max_id:
			max_id = id
	return max_id + 1


## Instantiates the correct resource subclass based on the popup menu index.
func _create_resource_for_type(type: int, node_id: int):
	match type:
		0: return StartNode.new(node_id)
		1:
			var q = DialogueNode.new(node_id)
			q.next_node_id = -1
			return q
		2:
			var d = QuestionNode.new(node_id)
			d.next_node_ids.assign([])
			return d
		3:
			var a = AnswerNode.new(node_id)
			a.next_node_id = -1
			return a
		4: return EndNode.new(node_id)
		5:
			var c = ConditionNode.new(node_id)
			c.true_branch_id = -1
			c.false_branch_id = -1
			return c
		6: 
			var s = OperatorNode.new(node_id)
			s.next_node_id = -1
			return s
		7: 
			var sig = SignalNode.new(node_id)
			sig.next_node_id = -1
			return sig


# Connections

## Handles a new connection request between two ports.
## Works bidirectionally since from_port is always the right side port of a Node.
## Updates the underlying resources (next_node_id, branch ids, or question list)
## and then calls connect_node to draw the visual connection line.
func _on_connection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	var from_graph_node = get_node(NodePath(from_node))
	var to_graph_node = get_node(NodePath(to_node))
	if not from_graph_node or not to_graph_node:
		return
	
	var from_resource = from_graph_node.resource
	var to_resource = to_graph_node.resource
	if not from_resource or not to_resource:
		return
	
	## If output port belongs to a QuestionNode, append the target to its answer list.
	if from_resource is QuestionNode:
		var question = from_resource as QuestionNode
		if to_resource.node_id not in question.next_node_ids:
			question.next_node_ids.append(to_resource.node_id)
	else:
		## For other nodes, only one connection per output port is allowed.
		## Remove any existing connection on the same port first.
		var existing_connections = get_connection_list()
		for conn in existing_connections:
			if conn.get("from_node") == from_node and conn.get("from_port") == from_port:
				disconnect_node(conn.get("from_node"), conn.get("from_port"), conn.get("to_node"), conn.get("to_port"))
				break
		## ConditionNode has two possible branches.
		if from_resource is ConditionNode:
			var condition = from_resource as ConditionNode
			if from_port == 0:
				condition.true_branch_id = to_resource.node_id
			else:
				condition.false_branch_id = to_resource.node_id
		## All other nodes use a single next_node_id.
		else:
			from_resource.next_node_id = to_resource.node_id
	connect_node(from_node, from_port, to_node, to_port)


## Handles disconnection. Clears the relevant fields in the resources and removes the visual connection line.
func _on_disconnection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	var from_graph_node = get_node(NodePath(from_node))
	var to_graph_node = get_node(NodePath(to_node))
	if not from_graph_node or not to_graph_node:
		return

	var from_resource = from_graph_node.resource
	var to_resource = to_graph_node.resource
	if not from_resource or not to_resource:
		return

	if from_resource is QuestionNode:
		var question = from_resource as QuestionNode
		var target_id = to_resource.node_id
		var idx = question.next_node_ids.find(target_id)
		if idx != -1:
			question.next_node_ids.remove_at(idx)
	elif from_resource is ConditionNode:
		var condition = from_resource as ConditionNode
		if from_port == 0:
			condition.true_branch_id = -1
		else:
			condition.false_branch_id = -1
	else:
		from_resource.next_node_id = -1

	disconnect_node(from_node, from_port, to_node, to_port)


# Deletion

## Called when the user presses Delete. Removes all selected nodes.
func _on_delete_nodes_request(nodes: Array) -> void:
	for node_name in nodes:
		var node = get_node(NodePath(node_name))
		if node:
			_delete_node(node)


## Removes a single visual node and its resource from the graph, disconnecting all associated connections first.
func _delete_node(visual_node: GraphNode) -> void:
	var resource = visual_node.resource
	if not resource:
		return

	# Remove all connections touching this node.
	var connections = get_connection_list()
	for conn in connections:
		if conn.get("from_node") == visual_node.name or conn.get("to_node") == visual_node.name:
			_on_disconnection_request(conn.get("from_node"), conn.get("from_port"), conn.get("to_node"), conn.get("to_port"))

	resource_to_node.erase(resource)
	if resource is StartNode:
		graph_resource.starts.erase(resource.node_id)
	else:
		graph_resource.nodes.erase(resource.node_id)
	if visual_node.position_offset_changed.is_connected(_on_node_moved):
		visual_node.position_offset_changed.disconnect(_on_node_moved)
	
	visual_node.queue_free()

# Selection

func _on_node_selected(node: GraphNode) -> void:
	pass

func _on_node_deselected(node: GraphNode) -> void:
	pass


## Updates the resource's stored position whenever a visual node is moved.
func _on_node_moved(visual_node: GraphNode, resource) -> void:
	if resource:
		resource.position = visual_node.position_offset


# Copy / Paste / Cut actions


## Copies the resources and relative positions of all selected nodes into clipboard_data.
func _on_copy_nodes() -> void:
	clipboard_data.clear()
	var selected = get_selected_nodes()
	var base_pos = null
	
	for node in selected:
		var res = node.resource
		## Use the first selected node as the reference point for relative offsets.
		if base_pos == null:
			base_pos = node.position_offset
		clipboard_data.append({
			"resource": res.duplicate(true),
			"pos_offset": node.position_offset - base_pos,
			"old_id": res.node_id
		})


## Copies the selected nodes and then deletes them.
func _on_cut_nodes() -> void:
	_on_copy_nodes()
	for node in get_selected_nodes():
		_delete_node(node)


## Pastes the copied nodes at the mouse position, reassigning IDs and
## restoring internal connections between the pasted nodes.
func _on_paste_nodes() -> void:
	if clipboard_data.is_empty():
		return
	
	## Mouse position in graph coordinates.
	var mouse_pos = get_local_mouse_position() + scroll_offset / zoom
	## Maps old node IDs to newly assigned IDs so we can reconnect pasted nodes.
	var old_id_to_new_id = {}
	
	for item in clipboard_data:
		var new_id = _get_next_node_id()
		## Duplicate again to allow multiple pastes.
		var new_res = item["resource"].duplicate(true)
		new_res.node_id = new_id	
		
		var scene = _get_scene_for_resource(new_res)
		var visual = scene.instantiate()
		add_child(visual)
		visual.set_resource(new_res)
		var new_pos = mouse_pos + item["pos_offset"]
		visual.position_offset = new_pos
		new_res.position = new_pos
		visual.position_offset_changed.connect(_on_node_moved.bind(visual, new_res))
		visual.set_deferred("size", new_res.size)
		resource_to_node[new_res] = visual
		
		if new_res is StartNode:
			graph_resource.starts[new_id] = new_res
		else:
			graph_resource.nodes[new_id] = new_res
		
		old_id_to_new_id[item["old_id"]] = new_id
		visual.selected = true
	
	## Rebuild connections between the pasted nodes.
	for item in clipboard_data:
		var from_res = item["resource"]
		var old_from_id = item["old_id"]
		
		## EndNodes don't have outgoing connections
		if from_res is EndNode:
			continue
		
		## Get the new resources
		var new_from_id = old_id_to_new_id[old_from_id]
		var new_from_res
		if from_res is StartNode:
			new_from_res = graph_resource.starts.get(new_from_id)
		else:
			new_from_res = graph_resource.nodes.get(new_from_id)
		
		## Get all the connections from the original nodes
		var connections = []
		if new_from_res is QuestionNode:
			new_from_res.next_node_ids.clear()
			connections = from_res.next_node_ids
		elif new_from_res is ConditionNode:
			if from_res.true_branch_id != null:
				connections.append(from_res.true_branch_id)
			if from_res.false_branch_id != null:
				connections.append(from_res.false_branch_id)
		else:
			if from_res.next_node_id != null:
				connections.append(from_res.next_node_id)
		
		## Check all connections from original nodes
		for old_to_id in connections:
			## If next_node_id node hasn't been copy pasted skip
			if not old_id_to_new_id.has(old_to_id):
				continue
			## Look for the new resources of next nodes
			var new_to_id = old_id_to_new_id[old_to_id]
			var new_to_res = graph_resource.nodes.get(new_to_id)
						
			var new_from_visual = resource_to_node[new_from_res]
			var new_to_visual = resource_to_node[new_to_res]
			
			## Depending on type of node update the resources and form visual connections
			if new_from_res is QuestionNode:
				new_from_res.next_node_ids.append(new_to_res.node_id)
				connect_node(new_from_visual.name, 0, new_to_visual.name, 0)
			elif new_from_res is ConditionNode:
				if from_res.true_branch_id == old_to_id:
					new_from_res.true_branch_id = new_to_res.node_id
					connect_node(new_from_visual.name, 0, new_to_visual.name, 0)
				elif from_res.false_branch_id == old_to_id:
					new_from_res.false_branch_id = new_to_res.node_id
					connect_node(new_from_visual.name, 1, new_to_visual.name, 0)
			else:
				new_from_res.next_node_id = new_to_res.node_id
				connect_node(new_from_visual.name, 0, new_to_visual.name, 0)


# Loading from resource

## Destroys all current visuals and rebuilds the entire graph from graph_resource.
func _rebuild_from_resource() -> void:
	if not graph_resource:
		return
	
	## Create normal nodes.
	for node_id in graph_resource.nodes.keys():
		var resource = graph_resource.nodes[node_id]
		var scene = _get_scene_for_resource(resource)
		if not scene:
			continue
		var visual_node = scene.instantiate()
		add_child(visual_node)
		visual_node.position_offset_changed.connect(_on_node_moved.bind(visual_node, resource))
		visual_node.set_resource(resource)
		visual_node.position_offset = resource.position
		visual_node.set_deferred("size", resource.size)
		resource_to_node[resource] = visual_node
	
	## Create start nodes.
	for node_id in graph_resource.starts.keys():
		var resource = graph_resource.starts[node_id]
		var scene = _get_scene_for_resource(resource)
		if not scene:
			continue
		var visual_node: StartVisualNode = scene.instantiate()
		add_child(visual_node)
		visual_node.position_offset_changed.connect(_on_node_moved.bind(visual_node, resource))
		visual_node.set_resource(resource)
		visual_node.position_offset = resource.position
		visual_node.set_deferred("size", resource.size)
		resource_to_node[resource] = visual_node
	
	## Restore all connections.
	for resource in resource_to_node.keys():
		var visual_node = resource_to_node.get(resource)
		if not visual_node:
			continue

		if resource is QuestionNode:
			var question = resource as QuestionNode
			for i in range(question.next_node_ids.size()):
				var target_id = question.next_node_ids[i]
				if target_id != -1:
					var target_resource = graph_resource.nodes.get(target_id)
					if target_resource:
						var target_node = resource_to_node.get(target_resource)
						if target_node:
							connect_node(visual_node.name, 0, target_node.name, 0)
		elif resource is ConditionNode:
			var condition = resource as ConditionNode
			if condition.true_branch_id != -1:
				var target_resource = graph_resource.nodes.get(condition.true_branch_id)
				if target_resource:
					var target_node = resource_to_node.get(target_resource)
					if target_node:
						connect_node(visual_node.name, 0, target_node.name, 0)
			if condition.false_branch_id != -1:
				var target_resource = graph_resource.nodes.get(condition.false_branch_id)
				if target_resource:
					var target_node = resource_to_node.get(target_resource)
					if target_node:
						connect_node(visual_node.name, 1, target_node.name, 0)
		else:
			if resource.get("next_node_id") != null:
				var target_id = resource.next_node_id
				if target_id != -1:
					var target_resource = graph_resource.nodes.get(target_id)
					if target_resource:
						var target_node = resource_to_node.get(target_resource)
						if target_node:
							connect_node(visual_node.name, 0, target_node.name, 0)


## Returns the PackedScene that corresponds to the given resource type.
func _get_scene_for_resource(resource) -> PackedScene:
	if resource is StartNode:
		return node_visuals[0]
	elif resource is DialogueNode:
		return node_visuals[1]
	elif resource is QuestionNode:
		return node_visuals[2]
	elif resource is AnswerNode:
		return node_visuals[3]
	elif resource is EndNode:
		return node_visuals[4]
	elif resource is ConditionNode:
		return node_visuals[5]
	elif resource is OperatorNode:
		return node_visuals[6]
	elif resource is SignalNode:
		return node_visuals[7]
	return null


## Returns all currently selected GraphNode children.
func get_selected_nodes() -> Array[GraphNode]:
	var selected : Array[GraphNode] = []
	for child in get_children():
		if child is GraphNode and child.selected:
			selected.append(child)
	return selected
