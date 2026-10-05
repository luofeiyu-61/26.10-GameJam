@tool
## Visual representation of a SignalNode inside the GraphEdit.
## Allows editing the signal name and a dynamic list of arguments.
class_name SignalVisualNode
extends GraphNode

## The SignalNode resource this visual node is bound to.
var resource: SignalNode

@onready var signal_edit: LineEdit = $SignalEdit
@onready var args_container: VBoxContainer = $ArgsContainer
@onready var add_button: Button = $AddButton

## Keeps track of the LineEdit widgets for each argument.
var arg_edits: Array = []


func _ready():
	title = "Signal"
	resize_end.connect(_on_resize_end)
	signal_edit.text_changed.connect(_on_signal_changed)
	add_button.pressed.connect(_add_argument)


## Assigns the SignalNode resource and rebuilds the argument fields from the resource data.
func set_resource(res: SignalNode):
	resource = res
	title = title + " " + str(res.node_id)
	signal_edit.text = resource.signal_name
	
	## Clear existing argument fields.
	for edit in arg_edits:
		edit.queue_free()
	arg_edits.clear()
	
	## Create a field for each existing argument, populating it with the stored value.
	for i in range(resource.arguments.size()):
		_add_argument(i)


## Adds a new argument field. If index is provided, the field is populated
## from the resource at that index; otherwise an empty field is added.
func _add_argument(index: int = -1):
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edit = LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "Argument or $variable"
	var remove_btn = Button.new()
	remove_btn.text = "X"
	hbox.add_child(edit)
	hbox.add_child(remove_btn)
	args_container.add_child(hbox)
	arg_edits.append(edit)
	
	remove_btn.pressed.connect(_remove_argument.bind(hbox, edit))
	edit.text_changed.connect(_on_args_changed)
	
	if index != -1 and resource:
		edit.text = resource.arguments[index]


## Removes an argument field and updates the resource's argument list.
func _remove_argument(hbox: HBoxContainer, edit: LineEdit):
	var idx = arg_edits.find(edit)
	if idx != -1:
		arg_edits.remove_at(idx)
		if resource and idx < resource.arguments.size():
			resource.arguments.remove_at(idx)
	hbox.queue_free()


## Called when any argument text changes; rebuilds the resource's argument array
## from the current fields.
func _on_args_changed(_new_text: String):
	if not resource:
		return
	var new_args: Array[String] = []
	for edit in arg_edits:
		new_args.append(edit.text)
	resource.arguments = new_args


## Updates the resource's signal name when the user edits the text.
func _on_signal_changed(new_text: String):
	if resource:
		resource.signal_name = new_text
		

## Saves the new node size to the resource when the resize handle is released.
func _on_resize_end(new_size: Vector2) -> void:
	resource.size = new_size
