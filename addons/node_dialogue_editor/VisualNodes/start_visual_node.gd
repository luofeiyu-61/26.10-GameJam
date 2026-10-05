@tool
## Visual representation of a StartNode inside the GraphEdit.
## Displays the start node's ID and handles resizing.
class_name StartVisualNode
extends GraphNode

## The StartNode resource this visual node is bound to.
var resource: StartNode


func _ready() -> void:
	title = "Start"
	resize_end.connect(_on_resize_end)


## Assigns the StartNode resource and updates the title with its ID.
func set_resource(res: StartNode) -> void:
	resource = res
	title = title + " " + str(res.node_id)


## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
