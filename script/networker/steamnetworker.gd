extends Networker
class_name SteamNetworker

@export var players : PackedInt64Array

func _ready() -> void:
	super._ready()
	printt("Initializing SteamP2P networking")
	_connect_internals()
	Steam.allowP2PPacketRelay(true)
	var result = Steam.steamInit(true, 480, false)
	printt(result)
	if result.status != 1:
		get_tree().quit()
	self.my_id = Steam.getSteamID()

func _process(delta: float) -> void:
	Steam.run_callbacks()
	super._process(delta)
	if self.lobby_identifier != "None":
		_read_packets()

func create_lobby() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_PLAYERS)
	printt("Creating lobby")

func join_lobby(lobby_identifier) -> void:
	Steam.joinLobby(int(lobby_identifier))
	printt("Joining lobby")

func leave_lobby() -> void:
	Steam.leaveLobby(int(lobby_identifier))
	printt("Leaving lobby")

func get_players() -> PackedInt64Array:
	var member_count = Steam.getNumLobbyMembers(int(lobby_identifier))
	
	var members : Array[int]
	for this_member in range(0, member_count):
		members.append(Steam.getLobbyMemberByIndex(int(lobby_identifier), this_member))
	
	players = PackedInt64Array(members)
	
	return PackedInt64Array(members)

###
### Internal Functions
###

func _connect_internals() -> void:
	Steam.lobby_created.connect(_lobby_created)
	Steam.lobby_joined.connect(_lobby_joined)
	Steam.join_requested.connect(_join_requested)
	Steam.lobby_chat_update.connect(_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	printt("Internals connected")

func _lobby_created(connect: int, lobby_id: int) -> void:
	printt("Lobby created")

func _lobby_joined(lobby: int, permission: int, locked: int, response: int) -> void:
	lobby_identifier = str(lobby)
	host_id = Steam.getLobbyOwner(lobby)
	get_players()
	print("Joined lobby")

func _join_requested(friends_lobby_id: int, friend: int) -> void:
	printt("User requested to join lobby")
	join_lobby(str(friends_lobby_id))

func _lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		get_players()
		self.emit_signal("player_joined")
		printt("Player joined lobby")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT or Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		get_players()
		self.emit_signal("player_disconnected")
		printt("Player left lobby")
	else:
		printt("Chat state update: ", chat_state)

func _on_p2p_session_request(remote_id: int) -> void:
	printt("P2P session requested")
	Steam.acceptP2PSessionWithUser(remote_id)

func _send_reliable() -> void:
	if lobby_identifier == "None":
		return
	if self.reliable_buffer:
		var compressed_buffer = var_to_bytes(self.reliable_buffer).compress(FileAccess.COMPRESSION_GZIP)
		for player in players:
			if player == my_id:
				continue
			Steam.sendP2PPacket(player, compressed_buffer, Steam.P2P_SEND_RELIABLE, 0)
			printt("Sent to player: ", player)
	super._send_reliable()

func _send_unreliable() -> void:
	if lobby_identifier == "None":
		return
	if self.unreliable_buffer:
		var compressed_buffer = var_to_bytes(self.unreliable_buffer).compress(FileAccess.COMPRESSION_GZIP)
		for player in players:
			if player == my_id:
				continue
			Steam.sendP2PPacket(player, compressed_buffer, Steam.P2P_SEND_UNRELIABLE, 0)
			printt("Sent to player: ", player)
	super._send_reliable()

func _read_packets() -> void:
	while Steam.getAvailableP2PPacketSize(0) > 0:
		_read_packet(Steam.readP2PPacket(Steam.getAvailableP2PPacketSize(0), 0))

func _read_packet(data: Dictionary) -> void:
	if data.remote_steam_id == my_id:
		return
	var decompressed_data: Array = bytes_to_var(data.data.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	_process_packet(decompressed_data, data.remote_steam_id)
