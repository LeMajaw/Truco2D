# File: utils/debug_utils.gd
extends Node

static func save_node_properties_as_json(node: Node, path: String = "user://node_debug.json") -> void:
	var data = {}
	for property in node.get_property_list():
		var property_name = property.name
		var value = node.get(property_name)
		data[property_name] = value

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
