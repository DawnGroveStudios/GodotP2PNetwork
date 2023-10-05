extends Node
class_name BaseNetwork

signal peer_status_updated(network_id:int,status:NetPeer.ConnectionStatus)
signal peer_session_failure(network_id, reason)
signal all_peers_connected
signal disconnect
signal periodic_sync(priority:SYNC_PRIORITY)
signal recived_obj(network_id,path)

enum P2P_SEND_TYPE {
	UNRELIABLE = 0,
	UNRELIABLE_NO_DELAY = 1,
	RELIABLE = 2,
	RELIABLE_WITH_BUFFERING = 3,
}

enum RPC_TYPE {
	CLIENT,
	ALL_CLIENTS,
	SERVER,
	ALL,
	SYNC,
	ALL_INCLUDING_SELF,
}

enum SYNC_PRIORITY {
	LOW,
	MEDIUM,
	HIGH
}
var network_data:NetworkData = NetworkData.new()
@export var require_same_scene: bool = true
@export var periodic_interval_low: float = 1.0
@export var periodic_interval_high: float = 0.05

var globalData:P2PGlobalData = P2PGlobalData.new()
var network_access:permissions = permissions.new()
var threading:ThreadingUtil = ThreadingUtil.new()
var network_name = RegEx.new()
var network_name_duplicate = RegEx.new()
var _path_cache:PathCache = PathCache.new()
var _packet_payload:BasePayload = BasePayload.new()
var _periodic_sync_high_timer=Timer.new()
var _periodic_sync_low_timer=Timer.new()

var _called_sync:int=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(globalData)

	add_child(_path_cache)
	P2PLobby.lobby_created.connect(_init_p2p_host)
	P2PLobby.player_joined_lobby.connect(_init_p2p_session)
	P2PLobby.player_left_lobby.connect(_close_p2p_session)
	add_child(threading)
	_verify_payloads()
	add_metrics()
	_periodic_sync_high_timer.autostart = true
	_periodic_sync_high_timer.one_shot = false
	_periodic_sync_high_timer.wait_time = periodic_interval_high
	_periodic_sync_high_timer.timeout.connect(_periodic_high_interval)
	add_child(_periodic_sync_high_timer)
	_periodic_sync_low_timer.autostart = true
	_periodic_sync_low_timer.one_shot = false
	_periodic_sync_low_timer.wait_time = periodic_interval_low
	_periodic_sync_low_timer.timeout.connect(_periodic_low_interval)
	add_child(_periodic_sync_low_timer)

func _periodic_high_interval():
	emit_signal("periodic_sync",SYNC_PRIORITY.HIGH)

func _periodic_low_interval():
	emit_signal("periodic_sync",SYNC_PRIORITY.LOW)

func add_metrics():
	Performance.add_custom_monitor("p2p_network/cache", _path_cache.size)
	Performance.add_custom_monitor("p2p_network/created_objects", _path_cache.created_objects)
	Performance.add_custom_monitor("p2p_network/created_objects_avg_size", _path_cache.created_objects_size)
	Performance.add_custom_monitor("p2p_network/cache_miss", NetCache.cache_miss)
	Performance.add_custom_monitor("p2p_network/threads",threading.size)
	Performance.add_custom_monitor("p2p_network/mutexes",threading.mutex_size)
	Performance.add_custom_monitor("p2p_network/sync",_get_sync_called)

func _get_sync_called():
	var s = _called_sync
	_called_sync = 0
	return s
## _verify_payloads checks the network payload being used to verify it will be encoded and decoded correctly
func _verify_payloads():
	var p = _packet_payload.clone()
	p.set_data("test")
	p.set_node_path(get_path())
	var test_payload = p.get_payload()
	p.parse(test_payload)
	#if p.get_node_path() != get_path():
	#	NetLog.fatal(get_tree(),"failed verifing payload")
	#if bytes_to_var(p.get_data()) != "test":
	#	NetLog.fatal(get_tree(),"failed verifing payload")

func set_current_scene(sceneName:String,node:Node):
	if !P2PLobby.in_lobby():
		return
	await get_tree().process_frame

	if network_data.is_server():
		globalData.set_game_data("current_scene",node.get_path())
		globalData.set_game_data("current_scene_name",sceneName)
	if network_data.get_current_peer() == null:
		return
	globalData.set_player_data("current_scene",node.get_path())
	globalData.set_player_data("current_scene_name",sceneName)


func rpc_emit_signal(obj:Node,signal_name:String,args:Array=[],peer:NetPeer=null) -> bool:
	if !P2PLobby.in_lobby():
		obj.emit_signal.bindv(args).call(signal_name)
		return true
	if !obj.has_signal(signal_name):
		return false
	var network_id = -1
	if peer != null:
		network_id = peer.network_id
	if !NetworkCommands.send_p2p_signal_packet(obj,signal_name,args,network_id):
		return false
	if peer == null || peer.network_id == network_data.get_current_peer().network_id:
		obj.emit_signal.bindv(args).call(signal_name)
	return true


# Sync
func rpc_sync(obj:Node,send_type:P2P_SEND_TYPE=P2P_SEND_TYPE.RELIABLE,peer:NetPeer=null) -> bool:
	if !P2PLobby.in_lobby():
		return true
	#NetworkNodeHelper.set_object_owner(obj)
	if !obj.is_inside_tree():
		NetLog.warn("not inside tree",[obj.get_class(),obj.name])
		return false
	if NetworkNodeHelper.duplicate_object(obj):
		return false
	_called_sync += 1
	if !P2PNetwork.net_rpc(RPC_TYPE.SYNC,obj,peer,Callable(),send_type):
		NetLog.error("failed syncing %s %s " % [obj.get_class(),obj.name])
		return false
	return true


func rpc_method(method:Callable,rpc_type:RPC_TYPE=RPC_TYPE.ALL, send_type: P2P_SEND_TYPE = P2P_SEND_TYPE.RELIABLE):
	if !P2PLobby.in_lobby():
		if rpc_type == RPC_TYPE.ALL_INCLUDING_SELF:
			method.call()
		return true
	return net_rpc(rpc_type,method.get_object(),null,method,send_type)

# RPC
func net_rpc(rpc_type:RPC_TYPE, caller:Node,peer:NetPeer=null, method:Callable=Callable(), send_type: P2P_SEND_TYPE = P2P_SEND_TYPE.RELIABLE) -> bool:
	if !P2PLobby.in_lobby():
		if rpc_type == RPC_TYPE.ALL_INCLUDING_SELF:
			if method == null:
				return false
			_rpc(network_data.get_network_id(),caller,method,send_type)
		return true

	if caller == null:
		NetLog.warn("caller is null")
		return false
	var net_data:PackedByteArray
	if rpc_type in [RPC_TYPE.SYNC]:
		if !NetworkNodeHelper.valid_sync_object(caller):
			NetLog.warn("invalid sync object")
			return false
		if !NetworkNodeHelper.valid_name(caller):
			if !NetworkNodeHelper.set_object_name(caller):
				NetLog.warn("invalid object name",caller.name)
				return false
		if !NetworkNodeHelper.is_owner_of_object(caller):
			NetLog.warn("unable to call sync on object",
					{
						"node_network_id":caller["network_id"],
						"node_name":caller.name,
						"current_network_id":network_data.get_current_peer().network_id
					})
			return false
		var compress: bool = send_type == P2P_SEND_TYPE.UNRELIABLE or send_type == P2P_SEND_TYPE.UNRELIABLE_NO_DELAY
		net_data = JsonData.marshal(caller,compress)

	var connected_peers = network_data.get_peers_with_status(NetPeer.ConnectionStatus.CONNECTED,true)
	if connected_peers.size() == 0:
		NetLog.warn("no connected peers",caller.name)
		return false

	match rpc_type:
		RPC_TYPE.SYNC:
			var current_scene = globalData.get_player_data(network_data.get_current_peer().network_id,"current_scene")
			for connected_peer in connected_peers:
				if connected_peer.network_id == network_data.get_current_peer().network_id:
					continue
				else:
					var scene = globalData.get_player_data(connected_peer.network_id,"current_scene")
					if scene == null && !require_same_scene:
						_rpc_sync(connected_peer.network_id,caller,net_data,send_type)
					elif scene == current_scene:
						_rpc_sync(connected_peer.network_id,caller,net_data,send_type)
					#if !threading.run(_rpc_sync.bind(network_id,caller,send_type)):
					#_rpc_sync(network_id,caller,send_type)
					#_rpc_sync(network_id,caller,send_type)
			return true
		RPC_TYPE.ALL:
			if method == null:
				return false
			for connected_peer in connected_peers:
				if connected_peer.network_id == network_data.get_current_peer().network_id:
					continue
				else:
					_rpc(connected_peer.network_id,caller,method,send_type)
			return true
		RPC_TYPE.ALL_INCLUDING_SELF:
			if method == null:
				return false
			for connected_peer in connected_peers:
				_rpc(connected_peer.network_id,caller,method,send_type)
			return true
		RPC_TYPE.SERVER:
			if method == null:
				return false
			_rpc(network_data.get_server_network_peer().network_id,caller,method,send_type)
			return true
		RPC_TYPE.ALL_CLIENTS:
			if method == null:
				return false
			for connected_peer in connected_peers:
				if connected_peer.network_id != network_data.get_server_network_peer().network_id:
					_rpc(connected_peer.network_id,caller,method,send_type)
					#threading.run(_rpc.bind(network_id,caller,method,send_type))
			return true
		RPC_TYPE.CLIENT:
			if method == null:
				return false
			if peer == null:
				return false
			#threading.run(_rpc.bind(peer.network_id,caller,method,send_type))
			_rpc(peer.network_id,caller,method,send_type)
			return true
	return false

func rpc_remove_node(caller:Node):
	if !P2PLobby.in_lobby():
		caller.queue_free()
		return
	if !NetworkNodeHelper.is_owner_of_object(caller):
		caller.queue_free()
		return
	var connected_peers = network_data.get_peers_with_status(NetPeer.ConnectionStatus.CONNECTED,true)
	for connected_peer in connected_peers:
		if connected_peer.network_id != network_data.get_server_network_peer().network_id:
			NetworkCommands.send_p2p_command_packet(connected_peer.network_id ,BasePayload.PACKET_TYPE.REMOVE_NODE,caller.get_path())
	caller.queue_free()


func _rpc_sync(to_peer_network_id:int,node: Node,node_data:PackedByteArray=PackedByteArray(), send_type: int = 2) -> bool:
	var to_peer = network_data.get_connected_peer(to_peer_network_id)
	if to_peer == null:
		return false
	var node_path = node.get_path()
	var packet = _packet_payload.clone()
	var payload = [node_data]

	packet.set_node_path(node_path)
	if network_data.get_current_peer().network_id == to_peer_network_id:
		_execute_rpc_sync(to_peer,-1,node_data,packet)
		return true

	packet.set_type(BasePayload.PACKET_TYPE.SYNC)
	packet.set_data(payload)
	if not packet.send_p2p_packet(to_peer.network_id,send_type):
		NetLog.warn("failed sending sync packet to peer")
	return true

func _get_node_path(index:int,node_path:NodePath) -> NodePath:
	var np = _path_cache.get_node_path(index)
	if np != null:
		return np
	if index != -1:
		_path_cache.add_node_path_index(node_path,index)
	return node_path

func _execute_rpc_sync(sender:NetPeer, path_cache_index: int,raw_data:PackedByteArray,packet:BasePayload):
	var node_path = packet.get_node_path()# _get_node_path(path_cache_index,packet.get_node_path())
	if node_path == null || node_path.is_empty():
		NetLog.error("NodePath index %s does not exist on this client! Cannot call RPC SYNC" % path_cache_index,
			{
				"sender":sender,
				"path_cache_index":path_cache_index,
			}
		)
		return

	# todo permissions
	var raw_dict = JsonData.unmarshal_bytes_to_dict(raw_data)
	threading.lock_mutex()
	var node = get_node_or_null(packet.get_node_path())
	threading.unlock_mutex()
	if node == null:
		if !NetworkNodeHelper.valid_sync_dict(raw_dict):
			NetLog.warn("unable to create sync object: %s" % node_path)
			return
		var key = "%s_invalid_path" % node_path.get_concatenated_names().capitalize()
		var created_key = "created_%s" % node_path.get_concatenated_names().capitalize()

		if NetCache.get_data(key) != null:
			return
		if NetCache.get_data(created_key) != null:
			return

		threading.lock_mutex()
		if !_path_cache.load_at_location_with_dict(raw_dict,packet.get_node_path()):
			NetCache.set_data(key,"invalid path",5)
			NetLog.error("Unable to load node at location: %s" % node_path)
			threading.unlock_mutex()
			return
		NetCache.set_data(created_key,true,15)
		node = get_node_or_null(node_path)
		threading.unlock_mutex()

		if node == null:
			NetCache.set_data(key,"invalid path",5)
			NetLog.error("Unable to find node at location: %s" % node_path)
			return
		else:
			NetCache.set_data(created_key,true,5)
	else:
		JsonData.unmarshal(raw_dict,node)



func _rpc(to_peer_network_id:int,caller: Node, method:Callable=Callable(),send_type:P2P_SEND_TYPE = P2P_SEND_TYPE.RELIABLE) -> bool:
	var to_peer = network_data.get_connected_peer(to_peer_network_id)
	if to_peer == null:
		return false
	if !caller.is_inside_tree():
		NetLog.error("node is not inside of tree",caller)
		return false
	var node_path = caller.get_path()

	var packet = _packet_payload.clone()
	packet.set_node_path(node_path)
	var payload = [method.get_method(), method.get_bound_arguments()]
	if to_peer.network_id == network_data.get_network_id():
		_execute_rpc(to_peer,-1,method.get_method(),method.get_bound_arguments(),packet)
		return true
	#if network_data.is_server() and (not _path_cache.peer_confirmed_path(to_peer,node_path) or path_cache_index == -1):
	#	payload.push_front(node_path)
	#	packet.set_type(BasePayload.PACKET_TYPE.RPC_WITH_NODE_PATH)
	#else:
	packet.set_type(BasePayload.PACKET_TYPE.RPC)
	#packet.set_node_path_index(path_cache_index)
	packet.set_data(payload)
	packet.set_node_path(node_path)
	if not packet.send_p2p_packet(to_peer.network_id,send_type):
		NetLog.warn("failed sending packet to peer")
		return false
	return true

func _execute_rpc(sender:NetPeer, path_cache_index: int, method: String, args: Array,packet:BasePayload) -> bool:
	var node_path = packet.get_node_path()
	if node_path == null || node_path.is_empty():
		NetLog.error("NodePath index %s does not exist on this client! Cannot call RPC" % path_cache_index,
			{
				"sender":sender,
				"path_cache_index":path_cache_index,
				"method":method,
				"args":args,
			}
		)
		return false

	var node = get_node_or_null(node_path)
	if node == null:
		NetLog.error("Node %s does not exist on this client! Cannot call RPC" % node_path)
		return false
	if network_data.get_server_network_peer() == null:
		#todo fix
		args.push_front(sender.network_id)
		node.callv(method, args)
		return true
	if not network_access.sender_has_access_to_method(sender,node,method,network_data.get_server_network_peer().network_id):
		NetLog.error("Sender does not have permission to execute method %s on node %s" % [method, node_path],
			{
				"sender":sender,
				"path_cache_index":path_cache_index,
				"method":method,
				"args":args,
			})
		return false
	if not node.has_method(method):
		NetLog.error("Node %s does not have a method %s" % [node.name, method])
		return false
	var expected_args = _get_callable(node,method)
	if expected_args.size() == 0:
		NetLog.error("failed getting method args",{"method":method,"args":args})
		return false
	if expected_args[0] == args.size():
		node.callv(method, args)
	elif expected_args[0] + 1 == args.size():
		args.push_front(sender.network_id)
		node.callv(method, args)
	elif expected_args[0] - expected_args[1] < args.size() and args.size() <= expected_args[0]:
		node.callv(method, args)
	else:
		NetLog.error("expected args does not match recieved args",{"method":method,"args":args})
		return false
	return true

func _get_callable(node:Node,method_name:String) ->Array[int]:
	for method in node.get_method_list():
		if method["name"] == method_name:
			NetLog.debug("callable methods",method)
			return [method["args"].size(),method["default_args"].size()]
	return []

func _handle_remove_node(payload:BasePayload,data:PackedByteArray) :
	var node_path = bytes_to_var(data)
	var node = get_node_or_null(node_path)
	if node == null:
		return
	_path_cache.remove_path(node_path)
	node.queue_free()

func get_packet() -> BasePayload:
	return _packet_payload.clone()

# passes in payload to reuse in func
func _confirm_peer(payload:BasePayload,network_id:int):
	if not network_data.has_peer(network_id):
		NetLog.error("Cannot confirm peer %s as they do not exist locally!" % network_id)
		return

	NetLog.info("Peer Confirmed %s" % network_id)
	network_data.get_peer(network_id).connected = true
	network_data.get_peer(network_id).status = NetPeer.ConnectionStatus.CONNECTED
	emit_signal("peer_status_updated", network_id,NetPeer.ConnectionStatus.CONNECTED)
	NetworkCommands.server_send_peer_state()

	if network_data.peers_connected():
		emit_signal("all_peers_connected")

func _handle_rpc_packet(sender_id: int, payload: BasePayload):
	var peer = network_data.get_peer(sender_id)
	var data = bytes_to_var(payload.get_data())
	var path_cache_index = payload.get_node_path_index()
	var method = data[0]
	var args = data[1]

	_execute_rpc(peer, path_cache_index, method, args,payload)

func _handle_rpc_sync_packet_with_path(sender_id: int, payload: BasePayload):
	var peer = network_data.get_peer(sender_id)
	var data = bytes_to_var(payload.get_data())
	var path = data[0]
	var node_data = data[1]

	var path_cache_index = payload.get_node_path_index()
	if network_data.is_server():
		# send rpc path + cache num to this client
		path_cache_index = _path_cache.get_path_index(path)
		#if this path cache doesnt exist yet, lets create it now and send to client
		if path_cache_index == -1:
			path_cache_index = _path_cache.add_node_path_index(path)
		NetworkCommands.server_update_node_path_cache(payload,sender_id, path)
	else:
		_path_cache.add_node_path_index(path,path_cache_index)
		NetworkCommands.send_p2p_command_packet(sender_id, BasePayload.PACKET_TYPE.NODE_PATH_CONFIRM, path_cache_index)
	_execute_rpc_sync(peer, path_cache_index, node_data,payload)

func _handle_rpc_sync_packet(sender_id: int, payload: BasePayload):
	var peer = network_data.get_peer(sender_id)
	var data = bytes_to_var(payload.get_data())
	var path_cache_index = payload.get_node_path_index()
	_execute_rpc_sync(peer, path_cache_index, data[0], payload)

func _handle_rpc_packet_with_path(sender_id: int, payload: BasePayload):
	var peer = network_data.get_peer(sender_id)
	var data = bytes_to_var(payload.get_data())
	var path = data[0]
	var method = data[1]
	var args = data[2]

	var path_cache_index = payload.get_node_path_index()

	if network_data.is_server():
		path_cache_index = _path_cache.get_path_index(path)
		if path_cache_index == -1:
			path_cache_index = _path_cache.add_node_path_index(path)
		NetworkCommands.server_update_node_path_cache(payload,sender_id, path)
	else:
		_path_cache.add_node_path_index(path,path_cache_index)
		NetworkCommands.send_p2p_command_packet(sender_id, BasePayload.PACKET_TYPE.NODE_PATH_CONFIRM, path_cache_index)

	_execute_rpc(peer, path_cache_index, method, args, payload)

func _handle_rpc_signal(sender_id: int, payload: BasePayload):
	var node = get_node_or_null(payload.get_node_path())
	if node == null:
		NetLog.warn("unable to find node to send signal to",payload)
		return
	var data = bytes_to_var(payload.get_data())
	var signal_name = data[0]
	var args:Array = data[1]
	if !node.has_signal(signal_name):
		NetLog.warn("node is missing singal name",signal_name)
		return
	node.emit_signal.bindv(args).call(signal_name);

## _handle_packet will route and process a given packet of data.
## [enum BasePayload.PACKET_TYPE]
func _handle_packet(sender_id, payload: BasePayload):
	if payload.is_empty() && !payload.NoDataPayload.has(payload.get_type()):
		NetLog.warn("invalid payload, was expecting data for type",{"payload_type":payload.get_type(),"name":BasePayload.PACKET_TYPE.keys()[payload.get_type()-1]})
		return
	match payload.get_type():
		BasePayload.PACKET_TYPE.HANDSHAKE:
			NetworkCommands.send_p2p_command_packet(sender_id, BasePayload.PACKET_TYPE.HANDSHAKE_REPLY)
		BasePayload.PACKET_TYPE.HANDSHAKE_REPLY:
			_confirm_peer(payload,sender_id)
		BasePayload.PACKET_TYPE.PEER_STATE:
			NetworkHandler.update_peer_state(payload,payload.get_data())
		BasePayload.PACKET_TYPE.CLIENT_PEER_STATE:
			NetworkHandler.update_client_peer_state(payload,payload.get_data())
		BasePayload.PACKET_TYPE.REMOVE_NODE:
			_handle_remove_node(payload,payload.get_data())
		BasePayload.PACKET_TYPE.NODE_PATH_CONFIRM:
			if !_path_cache.server_confirm_peer_node_path(network_data.get_peer(sender_id),bytes_to_var(payload.get_data())):
				NetLog.warn("failed confirming server node path")
		BasePayload.PACKET_TYPE.NODE_PATH_UPDATE:
			NetworkCommands.update_node_path_cache(sender_id,payload.get_data())
		BasePayload.PACKET_TYPE.RPC_WITH_NODE_PATH:
			_handle_rpc_packet_with_path(sender_id, payload)
		BasePayload.PACKET_TYPE.RPC:
			_handle_rpc_packet(sender_id,payload)
		BasePayload.PACKET_TYPE.SYNC:
			_handle_rpc_sync_packet(sender_id,payload)
		BasePayload.PACKET_TYPE.SYNC_WITH_NODE_PATH:
			_handle_rpc_sync_packet_with_path(sender_id,payload)
		BasePayload.PACKET_TYPE.RPC_SIGNAL:
			_handle_rpc_signal(sender_id,payload)
		_:
			NetLog.warn("payload type not implemented yet",{"payload_type":payload.get_type()})
			return

# _init_p2p_host initializes lobby host
func _init_p2p_host(lobby_id):
	NetLog.info("Initializing P2P Host as %s" % P2PLobby.get_self().network_id)
	var host_peer = NetPeer.new(P2PLobby.get_self().network_id)
	host_peer.host = true
	host_peer.connected = true
	network_data.set_current_peer(host_peer)
	emit_signal("all_peers_connected")


## _init_p2p_session initializes p2p network connection
##
## This will only be referenced by the P2PLobby Signal when a player connects to
## the lobby
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
	network_data.set_peer(NetPeer.new(network_id))
	emit_signal("peer_status_updated", network_id,network_data.get_peer(network_id).status)
	NetworkCommands.send_p2p_command_packet(network_id, BasePayload.PACKET_TYPE.HANDSHAKE)


## _close_p2p_session close connection to p2p network.
##
## This will only be referenced by the P2PLobby Signal when a player disconnects
## from the lobby
func _close_p2p_session(network_id):
	if network_id == P2PLobby._self.id:
		emit_signal("disconnect")
		network_data.clear()
		return
	NetLog.info("Closing P2P Session with %s" % network_id)
	network_data.remove_peer(network_id)
	NetCache.clear()
	NetworkCommands.server_send_peer_state()


## _process_packet will handle each packet recieved.
## this will be unique and variy based on each of the implementations
func _process_packet(sender_network_id, payload: BasePayload):
	pass


# _read_p2p_packet reads a packet given a packet_size
func _read_p2p_packet(packet_size:int):
	pass


