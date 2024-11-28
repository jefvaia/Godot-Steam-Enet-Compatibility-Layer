extends Node

@export var networker: Networker
@export var console : Console
@export var working_dir : String
@export var network_test: NetworkMessage = load("res://struct_instances/network_test.tres")
@export var spawn_test: NetworkMessage = load("res://struct_instances/spawn_test.tres")
@export var edit_test: NetworkMessage = load("res://struct_instances/edit_test.tres")
@export var destroy_test: NetworkMessage = load("res://struct_instances/destroy_test.tres")
@export var function_test: NetworkMessage = load("res://struct_instances/function_test.tres")
