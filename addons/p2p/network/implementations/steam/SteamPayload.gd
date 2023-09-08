extends BasePayload

class_name SteamPayload


func clone() -> BasePayload:
	return SteamPayload.new()


func send_p2p_packet(
	my_network_id, send_type: int = Steam.P2P_SEND_RELIABLE, channel: int = 0
) -> bool:
	if get_type() < 0:
		GodotLogger.error("invalid packet type", {"type": get_type()})
		return false
	var succeces = Steam.sendP2PPacket(my_network_id, get_payload(), send_type, channel)
	if succeces:
		return true
	elif send_type != Steam.P2P_SEND_RELIABLE:
		return true
	return false
