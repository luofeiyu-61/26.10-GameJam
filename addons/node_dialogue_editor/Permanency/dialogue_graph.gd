@tool
## A resource that holds all nodes, start points, and variables of a dialogue graph.
## It can be saved to and loaded from a .tres file.
class_name DialogueGraph
extends Resource

## Dictionary of all non‑start nodes, keyed by their unique integer ID.
@export var nodes: Dictionary[int, Resource] = {}
## Dictionary of Start nodes, keyed by their unique integer ID.
@export var starts: Dictionary[int, Resource] = {}
## Global variables shared by the graph.
@export var variables: Dictionary = {}


## Saves the graph resource to the given file path.
## Returns ok on success, or an error code.
func save_to_file(path: String) -> int:
	var result = ResourceSaver.save(self, path, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	print("saving")
	if result != OK:
		push_error("Error on saving graph on %s: %s" % [path, result])
	return result


## Helper that loads a DialogueGraph from a file.
## Returns the loaded graph or null if the load failed.
static func load_from_file(path: String) -> DialogueGraph:
	var graph = ResourceLoader.load(path, "DialogueGraph")
	if graph == null:
		push_error("Error on load graph from %s" % path)
		return null
	return graph
