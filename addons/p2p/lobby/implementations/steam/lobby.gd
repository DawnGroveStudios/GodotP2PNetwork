extends BaseLobby

# Called when the node enters the scene tree for the first time.
func _ready():

	_self = SteamPeer.new(Steam.getSteamID())
	if _self.network_id == 0:
		GodotLogger.warn("Unable to get steam id of user, check steam has been initialized first.")
		return

	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM)

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.avatar_image_loaded.connect(_on_avatar_image_loaded)
	Steam.avatar_loaded.connect(_on_avatar_loaded)

	_lobby_invite_cmd_line()

func get_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.addRequestLobbyListFilterSlotsAvailable(1)
	#Steam.addRequestLobb
	Steam.requestLobbyList()

func create_lobby(lb:LobbyData) ->bool:
	var can_create = super(lb)
	if !can_create:
		return false

	_current_lobby.set_lobby_owner(get_self())
	GodotLogger.info("creating lobby...",_current_lobby)
	Steam.createLobby(lb.visablity, lb.max_memebers)
	return true

func join_lobby(lobby_id: int)  -> bool:
	if !super(lobby_id):
		return false
	GodotLogger.info("Trying to join lobby %s" % lobby_id)
	_current_lobby = null
	Steam.joinLobby(lobby_id)
	get_lobby_list()
	return true

func get_lobby_member(id:int) -> NetPeer:
	return _current_lobby.get_member(id)

func leave_lobby():
	# If in a lobby, leave it
	if in_lobby():
		GodotLogger.info("Leaving Lobby %s" % _current_lobby.lobby_id)
		# Send leave request to Steam
		send_message("[SYSTEM][%s Left Lobby]" % get_self().get_profile_name())
		Steam.leaveLobby(_current_lobby.lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		# Close session with all users
		# This is a bit of a hack for now to keep SteamNetwork isolated
		for network_id in _current_lobby.get_members().keys():
			var session_state = Steam.getP2PSessionState(network_id)
			if session_state.has("connection_active") and session_state["connection_active"]:
				Steam.closeP2PSessionWithUser(network_id)
		# Clear the local lobby list
		_current_lobby = null
		super.leave_lobby()
		emit_signal("player_left_lobby", get_id())

func send_message(message: String,to:int=-1) -> bool:
	if !in_lobby():
		GodotLogger.warn("not connected to steam lobby")
		return false
	return Steam.sendLobbyChatMsg(_current_lobby.lobby_id, message)

func _lobby_invite_cmd_line():
	var lobbyId = Config.get_int("connect_lobby")
	if lobbyId > 0:
		GodotLogger.info("attempting to join lobby",{"id":lobbyId})
		emit_signal("lobby_join_requested", int(lobbyId))

func _on_lobby_created(connect, lobby_id):
	GodotLogger.info("Lobby Created called")
	_creating_lobby = false
	if connect == 1:
		if !Steam.setLobbyData(lobby_id,"name",_current_lobby.lobby_name):
			GodotLogger.warn("failed to set lobby name")
		if !Steam.setLobbyData(lobby_id,"mode",_current_lobby.lobby_mode):
			GodotLogger.warn("failed to set lobby mode")
		if !Steam.setLobbyData(lobby_id,"meta",JSON.stringify(_current_lobby.meta)):
			GodotLogger.warn("failed to set lobby meta")
		_current_lobby = SteamLobbyData.new(lobby_id)
		GodotLogger.info("Created Steam Lobby with id: %s" % lobby_id,{"owner":get_owner_id()})
		var relay = Steam.allowP2PPacketRelay(true)
		GodotLogger.info("Relay configuration response: %s" % relay)
		emit_signal("lobby_created", lobby_id)
	else:
		GodotLogger.error("Failed to create lobby: %s" % connect)

func _on_lobby_joined(lobby_id:int, permissions, locked: bool, response):
	if response == 1:
		# Set this lobby ID as your lobby ID
		GodotLogger.info("Lobby Joined!",{"lobby_id":lobby_id})
		if _current_lobby == null:
			_current_lobby = SteamLobbyData.new(lobby_id)
		send_message("[SYSTEM][ LOBBY %s ] " %  _current_lobby.lobby_name,-1)
		send_message("[SYSTEM][%s Joined Lobby] " %  _current_lobby.get_member(_self.network_id).get_profile_name(),-1)
		_current_lobby.update_lobby_members()
		#Steam.getMediumFriendAvatar(_self.network_id)
		emit_signal("lobby_joined", lobby_id)
		#send_chat_message("hello!")
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		GodotLogger.error(FAIL_REASON)

func _on_lobby_join_requested(lobby_id: int, friend_id):
	GodotLogger.info("Attempting to join lobby %s from request" % lobby_id)
	# Attempt to join the lobby
	emit_signal("lobby_join_requested", lobby_id)

func _on_lobby_invite(inviter, lobby, game):
	pass

func _owner_changed(was_steam_id, now_steam_id):
	emit_signal("lobby_owner_changed", was_steam_id, now_steam_id)

func _on_lobby_data_update(success, lobby_id, member_id):
	if success:
		# check for host change
		var host = Steam.getLobbyOwner(lobby_id)
		if host != get_owner_id() and host > 0:
			_owner_changed(get_owner_id(), host)
			if _current_lobby.get_member(host) != null:
				_current_lobby.set_lobby_owner(_current_lobby.get_member(host))
			else:
				GodotLogger.error("failed changing lobby owner",{"new_host":host,"old_host":get_owner_id()})
		emit_signal("lobby_data_updated", member_id)

func _on_lobby_message(result, sender_steam_id, message, chat_type):
	if result == 0:
		GodotLogger.error("Received lobby message, but 0 bytes were retrieved!")

	match(chat_type):
		Steam.CHAT_ENTRY_TYPE_CHAT_MSG:
			if str(message).begins_with("[SYSTEM]"):
				emit_signal("chat_message_received", 0, "", message)
				return
			var member = get_lobby_member(sender_steam_id)
			if member == null:
				_current_lobby.update_lobby_members()
			if member != null:
				GodotLogger.debug("recieved message",{"profile_name":member.get_profile_name(),"message":message})
				emit_signal("chat_message_received", sender_steam_id, member.get_profile_name(), message)
			else:
				emit_signal("chat_message_received", -1, "unknown", message)
		_:
			GodotLogger.warn("Unhandled chat message type received: %s" % chat_type)

func _on_lobby_chat_update(lobby_id, changed_user_steam_id, user_made_change_steam_id, chat_state):
	var user: String = Steam.getFriendPersonaName(changed_user_steam_id)
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			GodotLogger.info("Player joined lobby %s" % changed_user_steam_id)
			emit_signal("player_joined_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			GodotLogger.info("Player left the lobby %s" % changed_user_steam_id)
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			GodotLogger.info("Player %s was kicked by %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			GodotLogger.info("Player %s was banned by %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			GodotLogger.info("Player disconnected %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)
		_:
			GodotLogger.info("Player %s did something...." % [user,chat_state])

func _on_avatar_image_loaded(avatar_id: int, avatar_index: int, width: int, height: int):
	GodotLogger.info("avatar image loaded",{"avatar_id":avatar_id})
	var peer = get_lobby_member(avatar_id)
	#peer.profile_image_r = Image.create_from_data(width,height,false,Image.FORMAT_BPTC_RGB,peer.profile_data)
	GodotLogger.info("loaded image")

func _on_avatar_loaded(avatar_id: int, size: int, data: Array):
	if avatar_id == get_id():
		var peer = get_self()
		# Create the image and texture for loading
		var AVATAR: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
		# Apply it to the texture
		peer._profile_image = ImageTexture.create_from_image(AVATAR)
		_self = peer
		emit_signal("avatar_loaded",peer.network_id)
		return
	var peer = get_lobby_member(avatar_id)
	if peer == null:
		return
	var AVATAR: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	# Apply it to the texture
	peer._profile_image = ImageTexture.create_from_image(AVATAR)
	_current_lobby.set_member(peer)
	emit_signal("avatar_loaded",peer.network_id)

func _on_match_list(lobbies: Array):
	var output:Array[LobbyData]
	for lobby_id in lobbies:
		var lobby = SteamLobbyData.new(lobby_id)
		if lobby.lobby_name == "":
			continue
		output.append(lobby)

	emit_signal("found_lobbies",output)
