@tool
## Visual representation of an EndNode inside the GraphEdit.
## Displays the end node's ID and handles resizing.
class_name EndVisualNode
extends GraphNode

## The EndNode resource this visual node is bound to.
var resource: EndNode


func _ready() -> void:
	title = "End"
	resize_end.connect(_on_resize_end)


## Assigns the EndNode resource and updates the title with its ID.
func set_resource(res: EndNode) -> void:
	title = title + " " + str(res.node_id)
	resource = res
	

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
