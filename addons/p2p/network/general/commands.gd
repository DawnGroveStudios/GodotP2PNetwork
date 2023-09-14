extends Node

class_name NetworkCommands

# passes in payload to reuse
static func send_p2p_command_packet(network_id:int, packet_type: int, arg = null) -> bool:
	if !P2PLobby.in_lobby():
		return false
	var payload = P2PNetwork.get_packet()
	payload.set_type(packet_type)
	payload.set_data(arg)
	if not payload.send_p2p_packet(network_id):
		NetLog.error("Failed to send command packet %s" % packet_type)
		return false
	return true

static func send_p2p_signal_packet(obj:Node,signalName:String, arg = null,network_id:int=-1) ->bool:
	if !P2PLobby.in_lobby():
		return false
	if !obj.has_signal(signalName):
		return false
	var payload = P2PNetwork.get_packet()
	payload.set_type(BasePayload.PACKET_TYPE.RPC_SIGNAL)
	payload.set_node_path(obj.get_path())
	payload.set_data([signalName,arg])
	if network_id > -1:
		if not payload.send_p2p_packet(network_id):
			NetLog.error("Failed to send signal packet :%s" % signalName,arg)
			return false
		return true
	payload.broadcast_p2p_packet(P2PLobby.get_self().network_id,P2PNetwork.network_data.get_peer_network_ids())
	return true


static func update_node_path_cache(sender_id: int, packet_data: PackedByteArray):
	if !P2PLobby.in_lobby():
		return
	if sender_id != P2PNetwork.network_data.get_server_network_peer().network_id:
		return
	var data = bytes_to_var(packet_data)
	var path_cache_index = data[0]
	var node_path = data[1]
	P2PNetwork._path_cache.add_node_path_index(node_path, path_cache_index)
	NetworkCommands.send_p2p_command_packet(
			P2PNetwork.network_data.get_server_network_peer().network_id,
			BasePayload.PACKET_TYPE.NODE_PATH_CONFIRM,
			path_cache_index
		)


static func server_update_node_path_cache(payload:BasePayload,peer_id: int, node_path: NodePath):
	if !P2PLobby.in_lobby():
		return
	if not P2PNetwork.network_data.is_server():
		return
	var path_cache_index = P2PNetwork._path_cache.get_path_index(node_path)
	if path_cache_index == -1:
		path_cache_index = P2PNetwork._path_cache.add_node_path_index(node_path)
	payload.set_type(BasePayload.PACKET_TYPE.NODE_PATH_UPDATE)
	payload.set_data([path_cache_index, node_path])
	payload.set_node_path(node_path)
	if not payload.send_p2p_packet(peer_id):
		NetLog.error("failed updating node path cache")



static func server_send_peer_state():
	if !P2PLobby.in_lobby():
		return
	if not P2PNetwork.network_data.is_server():
		return
	NetLog.info("Sending Peer State",P2PNetwork.network_data)
	var peers = []
	for peer_id in P2PNetwork.network_data.get_peer_network_ids():
		NetLog.info("Peer",{"id":peer_id})
		peers.append(JsonData.marshal(P2PNetwork.network_data.get_peer(peer_id)))

	var payload = P2PNetwork.get_packet()
	payload.set_type(BasePayload.PACKET_TYPE.PEER_STATE)
	payload.set_data(peers)
	payload.broadcast_p2p_packet(
		P2PLobby.get_self().network_id,
		P2PNetwork.network_data.get_peer_network_ids(),
	)


static func set_connection_state(state:NetPeer.ConnectionStatus) ->bool:
	if !P2PLobby.in_lobby():
		P2PNetwork.emit_signal("peer_status_updated",-1,state)
		return true
	var current = P2PNetwork.network_data.get_current_peer()
	if current == null:
		return false
	if current.status == state:
		return false
	if current.status == NetPeer.ConnectionStatus.DISCONNECTED:
		return false
	current.status = state
	P2PLobby.send_message("[SYSTEM][%s set status to: %s]" % [current.profile_name,NetPeer.ConnectionStatus.keys()[current.status]])
	NetLog.info("Sending Peer State Client",current)
	var payload = P2PNetwork.get_packet()
	payload.set_type(BasePayload.PACKET_TYPE.CLIENT_PEER_STATE)
	payload.set_data(JsonData.to_dict(current,false))
	payload.broadcast_p2p_packet(
		P2PLobby.get_id(),
		P2PNetwork.network_data.get_peer_network_ids(),
	)
	P2PNetwork.emit_signal("peer_status_updated",current.network_id,state)
	return true
