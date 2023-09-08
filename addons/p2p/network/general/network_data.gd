class_name NetworkData

var port:int = 11111
var host:String = ""

var _current_peer:NetPeer
var server_network_peer:NetPeer

var peers={}

func get_peers_with_status(status:NetPeer.ConnectionStatus=NetPeer.ConnectionStatus.READY,greaterThan:bool=false) -> Array:
	var output = []
	for peer_id in peers.keys():
		if greaterThan:
			if peers.get(peer_id).status >= status:
				output.append(peers.get(peer_id))
		else:
			if peers.get(peer_id).status == status:
				output.append(peers.get(peer_id))
	return output

func do_all_peers_have_status(status:NetPeer.ConnectionStatus=NetPeer.ConnectionStatus.READY,greaterThan:bool=false) -> bool:
	var p = get_peers_with_status(status,greaterThan)
	return p.size() == peers.size()

func set_current_peer(current_peer:NetPeer):
	self._current_peer = current_peer
	#self._current_peer.connected = true
	set_peer(current_peer)

func get_current_peer() ->NetPeer:
	return _current_peer

func get_network_id() -> int:
	if _current_peer == null:
		_current_peer = NetPeer.new(-1)
		return -1
	return _current_peer.network_id

func is_server() -> bool:
	if !P2PLobby.in_lobby():
		return true
	return _current_peer.host || _current_peer == null

func get_server_network_peer() -> NetPeer:
	if server_network_peer != null:
		return server_network_peer
	for peer_id in peers.keys():
		if peers.get(peer_id).host:
			server_network_peer = peers.get(peer_id)
			return server_network_peer
	return null

func clear():
	peers.clear()
	server_network_peer = null
	set_current_peer(_current_peer)
# peer logic
func get_peer_network_ids() -> Array:
	return peers.keys()

func has_peer(network_id:int) -> bool:
	return peers.has(network_id)

func add_peer(peer:NetPeer) -> bool:
	if peers.has(peer.network_id):
		return false
	peers[peer.network_id] = peer
	return true

func set_peer(peer:NetPeer) -> bool:
	if _current_peer != null and peer.network_id == _current_peer.network_id:
		self._current_peer = peer
	peers[peer.network_id] = peer
	return true

func remove_peer(network_id:int):
	if peers.has(network_id):
		peers.erase(network_id)
	if server_network_peer == null:
		return
	if server_network_peer.network_id == network_id:
		GodotLogger.warn("lost connection to server: %d" % network_id)
		server_network_peer = null
		P2PLobby.leave_lobby()

func get_peer(network_id:int) ->NetPeer:
	if peers.has(network_id):
		return peers.get(network_id)
	return null


func is_peer_connected(network_id:int) -> bool:
	var peer = get_peer(network_id)
	if peer == null:
		return false
	return peer.connected


func peers_connected() -> bool:
	for peer_id in peers:
		if peers[peer_id].connected == false:
			return false
	return true


func get_connected_peer(network_id:int) ->NetPeer:
	if !_current_peer.connected:
		GodotLogger.warn("Cannot send an RPC when not connected to a network")
		return
	var to_peer = get_peer(network_id)
	if to_peer == null:
		GodotLogger.warn("Cannot send an RPC to a null peer. Check youre completed connected to the network first")
		return

	if not is_peer_connected(to_peer.network_id):
		GodotLogger.warn("Cannot send an RPC to someone who is not connected to the network!")
		return
	return to_peer
