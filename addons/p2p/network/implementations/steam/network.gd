extends BaseNetwork
var SteamClient

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if Engine.has_singleton("Steam"):
		SteamClient = Engine.get_singleton("Steam")
	else:
		return
	SteamClient.p2p_session_request.connect(_on_p2p_session_request)
	SteamClient.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)

	_packet_payload = SteamPayload.new()
	add_child(SteamInit.new())
	network_data.set_current_peer(SteamPeer.new(SteamClient.getSteamID(), PackedByteArray()))
	NetLog.info("current peer", network_data.get_current_peer())


func _close_p2p_session(network_id):
	if network_id == P2PLobby.get_self().network_id:
		if network_data.get_server_network_peer() != null:
			SteamClient.closeP2PSessionWithUser(network_data.get_server_network_peer().network_id)
		else:
			SteamClient.closeP2PSessionWithUser(SteamClient.getLobbyOwner(P2PLobby.get_lobby_id()))
		#_server_steam_id = 0
		network_data.clear()
		return

	NetLog.info("Closing P2P Session with %s" % network_id)
	var session_state = SteamClient.getP2PSessionState(network_id)
	if session_state.has("connection_active") and session_state["connection_active"]:
		SteamClient.closeP2PSessionWithUser(network_id)
	network_data.remove_peer(network_id)
	if network_data.get_server_network_peer() == null:
		return
	if network_data.get_server_network_peer().network_id != SteamClient.getLobbyOwner(P2PLobby.get_lobby_id()):
		var peer = network_data.get_peer(SteamClient.getLobbyOwner(P2PLobby.get_lobby_id()))
		network_data.host
	NetworkCommands.server_send_peer_state()

func _init_p2p_session(network_id):
	if not network_data.is_server():
		NetLog.debug("only server should initialize p2p requests")
		return
	NetLog.info("Initializing P2P Session with %s" % network_id)
	var current = network_data.get_current_peer()
	if current != null and current.network_id == network_id:
		emit_signal("peer_status_updated", network_id,current.status)
		NetworkCommands.send_p2p_command_packet(network_id, BasePayload.PACKET_TYPE.HANDSHAKE)
		return
	network_data.set_peer(SteamPeer.new(network_id))
	emit_signal("peer_status_updated", network_id,network_data.get_peer(network_id).status)
	NetworkCommands.send_p2p_command_packet(network_id, BasePayload.PACKET_TYPE.HANDSHAKE)

# _init_p2p_host initializes lobby host
func _init_p2p_host(lobby_id):
	NetLog.info("Initializing P2P Host as %s" % P2PLobby.get_self().network_id)
	var host_peer = SteamPeer.new(P2PLobby.get_self().network_id)
	host_peer.host = true
	host_peer.connected = true
	network_data.set_current_peer(host_peer)
	emit_signal("all_peers_connected")

func _on_p2p_session_request(remote_steam_id):
	NetLog.info("Received p2p session request from %s" % remote_steam_id)

	# Get the requester's name
	var requestor = SteamClient.getFriendPersonaName(remote_steam_id)
	# Only accept this p2p request if its from the host of the lobby.
	var owner = SteamClient.getLobbyOwner(P2PLobby.get_lobby_id())
	# todo fix this
	if owner != null && owner == remote_steam_id:
		SteamClient.acceptP2PSessionWithUser(remote_steam_id)
	else:
		NetLog.warn("Got a rogue p2p session request from %s. Not accepting." % remote_steam_id)


func _on_p2p_session_connect_fail(steam_id: int, session_error):
	match session_error:
		SteamClient.P2P_SESSION_ERROR_NONE:
			NetLog.warn("Session failure with " + str(steam_id) + " [no error given].")
		SteamClient.P2P_SESSION_ERROR_NOT_RUNNING_APP:
			NetLog.warn(
				(
					"Session failure with "
					+ str(steam_id)
					+ " [target user not running the same game]."
				)
			)
		SteamClient.P2P_SESSION_ERROR_NO_RIGHTS_TO_APP:
			NetLog.warn(
				"Session failure with " + str(steam_id) + " [local user doesn't own app / game]."
			)
		SteamClient.P2P_SESSION_ERROR_DESTINATION_NOT_LOGGED_ON:
			NetLog.warn(
				"Session failure with " + str(steam_id) + " [target user isn't connected to Steam]."
			)
		SteamClient.P2P_SESSION_ERROR_TIMEOUT:
			NetLog.warn("Session failure with " + str(steam_id) + " [connection timed out].")
		SteamClient.P2P_SESSION_ERROR_MAX:
			NetLog.warn("Session failure with " + str(steam_id) + " [unused].")
		_:
			NetLog.warn(
				(
					"Session failure with "
					+ str(steam_id)
					+ " [unknown error "
					+ str(session_error)
					+ "]."
				)
			)

	emit_signal("peer_session_failure", steam_id, session_error)
	if steam_id in network_data.get_peer_network_ids():
		network_data.get_peer(steam_id).connected = false
		emit_signal("peer_status_updated", steam_id,NetPeer.ConnectionStatus.DISCONNECTED)
		NetworkCommands.server_send_peer_state()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if SteamClient == null:
		return
	# Ensure that Steam.run_callbacks() is being called somewhere in a _process()
	var packet_size = SteamClient.getAvailableP2PPacketSize(0)
	while packet_size > 0:
		# There is a packet
		#threading.run(_read_p2p_packet.bind(packet_size))
		_read_p2p_packet(packet_size)
		# Check for more available packets
		packet_size = SteamClient.getAvailableP2PPacketSize(0)

# _read_p2p_packet reads a packet given a packet_size
func _read_p2p_packet(packet_size: int):
	# Packet is a Dict which contains {"data": PoolByteArray, "steamIDRemote": CSteamID}
	var packet: Dictionary = SteamClient.readP2PPacket(packet_size, 0)
	# or empty if it fails
	if packet.is_empty():
		NetLog.warn("Steam Networking: read an empty packet with non-zero size!")
		return
	# Get the remote user's ID
	var sender_id: int = packet.get("steam_id_remote")
	var packet_data: PackedByteArray = packet.get("data")
	var payload = SteamPayload.new()
	payload.parse(packet_data)
	_handle_packet(sender_id, payload)
