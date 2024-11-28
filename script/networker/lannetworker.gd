extends Networker
class_name LANNetworker

const PORT : int = 6567

var peer : MultiplayerPeer

var authenticated: bool

func _ready() -> void:
	super._ready()
	_connect_callbacks()
	printt("Initializing LAN networking")
	lobby_identifier = "None"
	authenticated = false

func _process(delta: float) -> void:
	super._process(delta)

###
### Exposed Functions
###

func create_lobby() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	peer.host.compress(ENetConnection.COMPRESS_FASTLZ)
	multiplayer.multiplayer_peer = peer
	self.host_id = 1
	my_id = 1
	lobby_identifier = str("127.0.0.1:", PORT)
	printt("Created lobby")
	self.emit_signal("player_joined")

func join_lobby(_lobby_identifier : String) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(_lobby_identifier.split(":")[0], int(_lobby_identifier.split(":")[1]))
	peer.host.compress(ENetConnection.COMPRESS_FASTLZ)
	multiplayer.multiplayer_peer = peer
	lobby_identifier = _lobby_identifier
	printt("Joining a lobby")

func leave_lobby() -> void:
	multiplayer.multiplayer_peer = null
	peer = null
	authenticated = false
	lobby_identifier = "None"
	printt("Left lobby")

func get_players() -> PackedInt64Array:
	var members = multiplayer.get_peers()
	members.append(my_id)
	return members.to_byte_array().to_int64_array()

###
### Internal Functions
###

func _connect_callbacks() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)

func _peer_connected(id: int) -> void:
	if authenticated == false:
		return
	printt(multiplayer.get_unique_id(), id)
	self.emit_signal("player_joined")

func _peer_disconnected(id: int) -> void:
	self.emit_signal("player_disconnected")

func _server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	peer = null
	authenticated = false
	emit_signal("server_disconnected")

func _on_connected_ok() -> void:
	self.my_id = multiplayer.get_unique_id()
	self.host_id = 1
	printt("Joined server")
	_send_auth()

func _send_auth() -> void:
	var auth_token = AuthMessageRequest.new()
	auth_token.username = "Default"
	queue_message(auth_token)
	printt("Authenticating...")

func _process_auth() -> void:
	self.authenticated = true
	printt("Authentication successful")

func _send_reliable() -> void:
	if lobby_identifier == "None":
		return
	if self.reliable_buffer:
		_receive_packet_reliable.rpc(self.reliable_buffer)
	super._send_reliable()

func _send_unreliable() -> void:
	if lobby_identifier == "None":
		return
	if self.unreliable_buffer:
		_receive_packet_unreliable.rpc(self.unreliable_buffer)
	super._send_unreliable()

@rpc("call_local", "reliable", "any_peer")
func _receive_packet_reliable(packet):
	if multiplayer.get_remote_sender_id() == self.my_id:
		return
	_process_packet(packet, multiplayer.get_remote_sender_id())

@rpc("call_local", "unreliable", "any_peer")
func _receive_packet_unreliable(packet):
	if multiplayer.get_remote_sender_id() == self.my_id:
		return
	_process_packet(packet, multiplayer.get_remote_sender_id())
