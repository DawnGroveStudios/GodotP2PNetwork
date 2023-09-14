extends BasePayload

class_name SteamPayload
var SteamClient

func _init() -> void:
	super()
	if Engine.has_singleton("Steam"):
		SteamClient = Engine.get_singleton("Steam")
	else:
		return

func clone() -> BasePayload:
	return SteamPayload.new()


func send_p2p_packet(
	my_network_id, send_type: int = BaseNetwork.P2P_SEND_TYPE.RELIABLE, channel: int = 0
) -> bool:
	if get_type() < 0:
		NetLog.error("invalid packet type", {"type": get_type()})
		return false
	var success = SteamClient.sendP2PPacket(my_network_id, get_payload(), send_type, channel)
	if success:
		return true
	elif send_type != BaseNetwork.P2P_SEND_TYPE.RELIABLE:
		return true
	return false
