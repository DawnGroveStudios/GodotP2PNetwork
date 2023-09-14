extends NetPeer

class_name SteamPeer
var SteamClient
func _init(network_id:int,data:PackedByteArray=PackedByteArray()) -> void:
	super(network_id,data)
	if Engine.has_singleton("Steam"):
		SteamClient = Engine.get_singleton("Steam")
	else:
		return
func get_profile_name() -> String:
	if self.profile_name == "" || profile_name == null:
		self.profile_name = SteamClient.getFriendPersonaName(network_id)
	return profile_name
