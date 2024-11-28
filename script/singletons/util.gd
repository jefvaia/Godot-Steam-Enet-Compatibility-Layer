extends Node

func _ready() -> void:
	_ready_core()
	_ready_networking()
	_test()

func _test():
	pass

###
### Core
###

func _ready_core() -> void:
	Static.working_dir = string_arr_to_string(OS.get_executable_path().split("/").slice(0, len(OS.get_executable_path().split("/")) - 1), "/")

func string_arr_to_string(string_arr: Array[String], piece_suffix: String = "") -> String:
	var string = ""
	
	for index in string_arr:
		string += index + piece_suffix
	
	return string

###
### Networking Related
###

@export var lan : Script
@export var steam : Script

@onready var default_resource: Resource = Resource.new()

func _ready_networking() -> void:
	Util.initialize_networker()

func initialize_networker() -> void:
	printt("Initializing multiplayer layer!")
	lan = load("res://script/networker/lannetworker.gd")
	steam = load("res://script/networker/steamnetworker.gd")
	if lan == null:
		if !Engine.has_singleton("Steam"):
			printt("You have the wrong game binary! Exiting...")
			get_tree().quit()
		get_tree().root.add_child.call_deferred(steam.new(), true)
	elif steam == null:
		get_tree().root.add_child.call_deferred(lan.new(), true)
	else:
		get_tree().root.add_child.call_deferred(lan.new(), true)

func resource_to_arr(resource: Resource) -> Array[Dictionary]:
	var properties = resource.get_property_list()
	
	var properties_cut1: Array[Dictionary]
	
	for property in properties:
		if property["name"].contains(".gd"):
			continue
		var contains = false
		for default_property in default_resource.get_property_list():
			if property["name"] == default_property["name"]:
				contains = true
		if contains == false:
			property["value"] = resource.get(property["name"])
			properties_cut1.append({"name": property.name, "value": property.value})
	
	properties_cut1.append({"name": "script", "script_path": resource.get_script().resource_path})
	
	return properties_cut1

func arr_to_resource(arr: Array[Dictionary]) -> Resource:
	var script_path: String = ""
	
	for property in arr:
		if property["name"] == "script":
			script_path = property["script_path"]
			break
	
	var resource: Resource = load(script_path).new()
	
	for property in arr:
		if property.name == "script":
			continue
		resource.set(property["name"], property["value"])
	
	return resource

func handle_network_object(message: NetworkMessage) -> void:
	if message is NetworkObjectStatusReliableSpawn:
		if message.data.has("test"):
			if message.data["test"] == true:
				printt("Received test spawn")
				return
	
	if message is NetworkObjectStatusReliableSpawn or message is NetworkObjectStatusUnreliableSpawn:
		if get_node_or_null(message.object_path) == null:
			var new_object: Object
			if ClassDB.class_exists(message.object_type):
				new_object = ClassDB.instantiate(message.object_type)
			else:
				new_object = load(message.object_type)
			
			new_object.name = message.object_path.split("/")[len(message.object_path.split("/")) - 1]
			
			var path = string_arr_to_string(message.object_path.split("/").slice(0, len(message.object_path.split("/")) - 1), "/")
			
			get_node(path).add_child(new_object)
			
			_apply_data_to_object(new_object, message.data)
	
	if message is NetworkObjectStatusReliableEdit or message is NetworkObjectStatusUnreliableEdit:
		var node = get_node_or_null(message.object_path)
		
		if node == null:
			return
		
		if ClassDB.class_exists(message.object_type):
			if not node.get_class() == ClassDB.instantiate(message.object_type).get_class():
				printt("Wrong type")
				return
		else:
			if not node.get_class() == load(message.object_type).get_class():
				printt("Wrong type")
				return
		
		printt("Edited object")
		
		_apply_data_to_object(node, message.data)
	
	if message is NetworkObjectStatusReliableDestroy or message is NetworkObjectStatusUnreliableDestroy:
		var node = get_node_or_null(message.object_path)
		
		if node == null:
			return
		
		node.queue_free()
	
	if message is NetworkObjectStatusReliableFunction or message is NetworkObjectStatusUnreliableFunction:
		var node = get_node_or_null(message.object_path)
		
		if node == null:
			return
		
		if len(message.parameters) == 0:
			node.call(message.function)
		else:
			node.call(message.function, message.parameters)

func object_params_to_dict(object: Node, params: Array[String]) -> Dictionary:
	var new_dict: Dictionary
	
	for param in params:
		if !param.contains("/"):
			new_dict[param] = object[param]
		else:
			new_dict[param] = object.get_node(string_arr_to_string(param.split("/").slice(0, len(param.split("/")) - 1), "/")).get(param.split("/")[len(param.split("/")) - 1])
	
	return new_dict

func _apply_data_to_object(object: Node, data: Dictionary):
	for data_key: String in data:
		if !data_key.contains("/"):
			object.set(data_key, data[data_key])
		else:
			object.get_node(string_arr_to_string(data_key.split("/").slice(0, len(data_key.split("/")) - 1), "/")).set(data_key.split("/")[len(data_key.split("/")) - 1], data[data_key])
