extends NetPeer

class_name SteamPeer


func get_profile_name() -> String:
	if self.profile_name == "" || profile_name == null:
		self.profile_name = Steam.getFriendPersonaName(network_id)
	return profile_name
