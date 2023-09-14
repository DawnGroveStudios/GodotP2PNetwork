extends LobbyData

class_name SteamLobbyData

var SteamClient
# Called when the node enters the scene tree for the first time.
func _init(id:int):
	if Engine.has_singleton("Steam"):
		SteamClient = Engine.get_singleton("Steam")
	else:
		return
	self.lobby_id = id
	self.lobby_name = SteamClient.getLobbyData(lobby_id, "name")
	self.lobby_mode = SteamClient.getLobbyData(lobby_id, "mode")
	self.max_memebers = SteamClient.getLobbyMemberLimit(lobby_id)
	self.current_members = SteamClient.getNumLobbyMembers(lobby_id)
	var data = SteamClient.getLobbyData(lobby_id, "meta")
	if data.length() > 0:
		var m = JSON.parse_string(data)
		if m != null:
			self.meta = m
	update_lobby_members()

func get_members() -> Dictionary:
	update_lobby_members()
	return _members

func get_member(id:int) ->NetPeer:
	if _members.has(id):
		return _members.get(id)
	update_lobby_members()
	return _members.get(id)

func send_data():
	NetLog.info("sending data")
	if !SteamClient.setLobbyData(lobby_id,"name",lobby_name):
		NetLog.warn("failed to set lobby name")
	if !SteamClient.setLobbyData(lobby_id,"mode",lobby_mode):
		NetLog.warn("failed to set lobby mode")
	if !SteamClient.setLobbyData(lobby_id,"meta",JSON.stringify(meta)):
		NetLog.warn("failed to set lobby meta")

func update_lobby_members():
	_members.clear()

	var _steam_lobby_host_id = SteamClient.getLobbyOwner(lobby_id)
	set_lobby_owner(SteamPeer.new(_steam_lobby_host_id))
	# Get the number of members from this lobby from Steam
	var num_members: int = SteamClient.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for member_index in range(0, num_members):

		# Get the member's Steam ID
		var member_steam_id = SteamClient.getLobbyMemberByIndex(lobby_id, member_index)
		# Get the member's Steam name
		var member_steam_name = SteamClient.getFriendPersonaName(member_steam_id)
		var m = SteamPeer.new(member_steam_id)
		m.profile_name = member_steam_name
		SteamClient.getPlayerAvatar(SteamClient.AVATAR_MEDIUM,member_steam_id)
		#Steam.getMediumFriendAvatar(member_steam_id)
		if member_steam_id == _steam_lobby_host_id:
			continue
		set_member(m)
