extends Node
class_name Networker

const MAX_PLAYERS = 4

signal player_joined
signal player_disconnected
signal server_disconnected

@export var lobby_identifier: String = "None"
@export var my_id: int = -1
@export var host_id : int = -1

var reliable_buffer: Array
var unreliable_buffer: Array

func _ready() -> void:
	self.name = "Networker"
	Static.networker = self

func _process(delta: float) -> void:
	_send_reliable()
	_send_unreliable()

func create_lobby() -> void:
	pass

func join_lobby(lobby_identifier : String) -> void:
	pass

func leave_lobby() -> void:
	pass

func get_players() -> PackedInt64Array:
	pass
	return []

func queue_message(message: NetworkMessage) -> void:
	if lobby_identifier == "None":
		return
	message.time_sent = Time.get_unix_time_from_system()
	var arr_message = Util.resource_to_arr(message)
	if message is NetworkMessageReliable:
		reliable_buffer.append(arr_message)
	if message is NetworkMessageUnreliable:
		unreliable_buffer.append(arr_message)

func _send_reliable() -> void:
	reliable_buffer = []

func _send_unreliable() -> void:
	unreliable_buffer = []

func _process_auth() -> void:
	pass

func _process_packet(packet: Array, from: int) -> void:
	for sub_packet: Array[Dictionary] in packet:
		printt("Received packet: ", sub_packet)
		
		var resource = Util.arr_to_resource(sub_packet)
		if resource is AuthMessageRequest:
			var response = AuthMessageResponse.new()
			response.success = true
			queue_message(response)
		elif resource is AuthMessageResponse:
			_process_auth()
		elif resource is NetworkPingRequest:
			var response = NetworkPingResponse.new()
			queue_message(response)
		elif resource is NetworkPingResponse:
			printt("Received ping response: ", resource.message, resource.time_sent)
		elif resource is NetworkObjectStatusReliable:
			Util.handle_network_object(resource)
