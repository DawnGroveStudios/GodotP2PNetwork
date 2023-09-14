class_name BasePayload

enum PACKET_TYPE {
	HANDSHAKE = 1,
	HANDSHAKE_REPLY = 2,
	PEER_STATE = 3,
	NODE_PATH_UPDATE = 4,
	NODE_PATH_CONFIRM = 5,
	RPC = 6,
	RPC_WITH_NODE_PATH = 7,
	SYNC = 8,
	SYNC_WITH_NODE_PATH = 9,
	REMOVE_NODE=10,
	CLIENT_PEER_STATE=11,
	RPC_SIGNAL=12,
}

var NoDataPayload = [PACKET_TYPE.HANDSHAKE,PACKET_TYPE.HANDSHAKE_REPLY]

var _packet_type:PACKET_TYPE
var _data:PackedByteArray
var sender_id:int
var _rpc_type:int=0
var _node_path_index:int=0
var _node_path:NodePath
var _size:int

func clone() ->BasePayload:
	return BasePayload.new()

func size() ->int:
	return _size

func parse(data:PackedByteArray)->bool:
	if data == null:
		return false
	_packet_type = data[0]
	_node_path_index = data[1]

	var size = data[2]
	if size > 0:
		var raw_path = data.slice(3,3+size)
		_node_path = bytes_to_var(raw_path)

	if data.size() > 3 + size:
		_data = data.slice(3+size, data.size())
	return true

func get_payload() -> PackedByteArray:
	var payload = PackedByteArray()
	payload.append(_packet_type)
	payload.append(_node_path_index)
	var path = var_to_bytes(_node_path)
	payload.append(path.size())
	if path.size() > 0:
		payload.append_array(path)


	if _data != null:
		payload.append_array(_data)
	_size = payload.size()
	return payload

func set_node_path(node_path:NodePath):
	self._node_path = node_path

func get_node_path() ->NodePath:
	return self._node_path


func set_node_path_index(node_path_index:int):
	self._node_path_index = node_path_index

func get_node_path_index() ->int:
	return _node_path_index

func set_data(data) -> bool:
	if data == null:
		return false
	_data = var_to_bytes(data)
	return true

func get_data() ->PackedByteArray:
	return _data.duplicate()

func set_type(packet_type:PACKET_TYPE):
	_packet_type = packet_type

func get_type() -> PACKET_TYPE:
	return _packet_type

func is_empty() ->bool:
	return _data.is_empty() || _data.size() == 0

func broadcast_p2p_packet(my_network_id:int, peers:Array, send_type: int = 2, channel: int = 0):
	for peer_id in peers:
		if peer_id != my_network_id:
			send_p2p_packet(peer_id, send_type, channel)

# todo send_p2p_packet make this not dependant on steam
func send_p2p_packet(my_network_id, send_type: int = 2, channel: int = 0) -> bool:
	if get_type() < 0:
		NetLog.error("invalid packet type",{"type":get_type()})
		return false

	return true
