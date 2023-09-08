extends Node

class_name NetworkHandler


static func update_peer_state(payload:BasePayload,payload_data: PackedByteArray):
	if P2PNetwork.network_data.is_server():
		return
	var serialized_peers = bytes_to_var(payload_data)
	GodotLogger.info("Updating Peer State",{"serialized_peers":serialized_peers.size()})

	for serialized_peer in serialized_peers:
		var peer = NetPeer.new(0,serialized_peer)
		GodotLogger.info("Updating Peer State",peer)
		if P2PNetwork.network_data.has_peer(peer.network_id):
			P2PNetwork.network_data.set_peer(peer)
			P2PNetwork.emit_signal("peer_status_updated", peer.network_id,peer.status)
		elif !P2PNetwork.network_data.add_peer(peer):
			GodotLogger.warn("failed adding peer",peer)


static func update_client_peer_state(payload:BasePayload,payload_data: PackedByteArray):
	var peer = NetPeer.new(0,payload_data)
	GodotLogger.info("Update Client Peer State",peer)
	if P2PNetwork.network_data.has_peer(peer.network_id):
		P2PNetwork.network_data.set_peer(peer)
		P2PNetwork.emit_signal("peer_status_updated", peer.network_id,peer.status)
	elif !P2PNetwork.network_data.add_peer(peer):
		GodotLogger.warn("failed adding peer",peer)
