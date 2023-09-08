extends Node

class_name PathCache

var _next_index:int = 0
var default_cache_time:int = 30

var _load_mutex:Mutex = Mutex.new()
var _path_mutex:Mutex = Mutex.new()
var _created_object = 0
var _created_object_size = 0

func size() -> int:
	return NetCache.size()

func created_objects() -> int:
	var s = _created_object
	_created_object = 0
	return s

func created_objects_size() -> int:
	var s = _created_object_size
	_created_object_size = 0
	return s

func get_node_path(index:int):
	if index == -1:
		return null
	var key = _get_node_path_index_key(index)
	return NetCache.get_data(key,default_cache_time)

func get_path_index(node_path: NodePath) -> int:
	var index = NetCache.get_data(str(node_path.hash()))
	if index == null:
		return -1
	return index

func remove_path(node_path: NodePath):
	var key = str(node_path.hash())
	NetCache.remove(key)
	NetCache.remove(_get_node_path_index_key(get_path_index(node_path)))
	NetCache.remove(node_path.get_concatenated_names())

func add_node_path_index(node_path: NodePath, path_cache_index: int = -1) -> int:
	var already_exists_id = get_path_index(node_path)
	if already_exists_id != -1 and already_exists_id == path_cache_index:
		NetCache.refresh_expires(str(node_path.hash()))
		NetCache.refresh_expires(_get_node_path_index_key(path_cache_index))
		return already_exists_id

	if path_cache_index == -1:
		#_next_index += 1
		path_cache_index =  _get_index()
	if !NetCache.set_data(str(node_path.hash()),path_cache_index,default_cache_time):
		return -1
	if !NetCache.set_data(_get_node_path_index_key(path_cache_index),node_path,default_cache_time):
		return -1
	return path_cache_index

func _get_index() ->int:
	randomize()
	var d = randi()
	while NetCache.get_data(_get_node_path_index_key(d)) != null:
		d = randi()
		pass
	return d


func server_confirm_peer_node_path(peer:NetPeer, path_cache_index: int) -> bool:
	#if !peer.host:
	#	return false
	return NetCache.set_data(_get_peer_key(peer,path_cache_index),true,default_cache_time)

func peer_confirmed_path(peer:NetPeer, node_path: NodePath) ->bool:
	var path_cache_index = get_path_index(node_path)
	var d = _get_peer_key(peer,path_cache_index)
	if d == null:
		return false

	return NetCache.get_data(d) != null

func _get_peer_key(peer:NetPeer,index:int) ->String:
	if peer == null:
		return "_invalid_peer_id"
	return "network_id_%d_%d" % [peer.network_id,index]

func _get_node_path_index_key(index:int) ->String:
	return "node_path_index_%d" % index



func load_at_location_with_dict(data:Dictionary,node_path:NodePath) ->bool:
	var node = get_node_or_null(node_path)
	if node != null:
		return true
	if "scene_file_path" not in data:
		return false
	var parent_path = get_parent_path(node_path)
	var parent_node = get_node_or_null(parent_path)
	if parent_node == null:
		GodotLogger.error("failed to get parent node %s base node path %s" % [parent_path,node_path])
		return false
	var obj
	if str(data["scene_file_path"]).contains(".gd"):
		obj = load(data["scene_file_path"]).new()
	else:
		obj = load(data["scene_file_path"]).instantiate()
	if obj == null:
		return false
	if !JsonData.unmarshal(data,obj):
		GodotLogger.error("failed unmarshalling obj to sync node")
		return false

	_created_object += 1
	_created_object_size = (_created_object_size + data.size()) / 2
	parent_node.add_child(obj)
	var duplicate = false
	for c in parent_node.get_children(true):
		if c.name == obj.name:
			if duplicate:
				GodotLogger.info("[CLEAN]found duplicate object:remove:",obj)
			duplicate = true
	return true


func get_parent_path(node_path:NodePath)->String:
	var path = []
	for n in range(0,node_path.get_name_count()-1):
		path.append(node_path.get_name(n))
	return "/"+"/".join(path)
