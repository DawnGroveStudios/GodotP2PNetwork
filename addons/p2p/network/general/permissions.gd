extends Node

class_name permissions

enum PERMISSION_TYPE {
	SERVER,
	SERVER_OR_CLIENT_OWNER,
	CLIENT_ALL,
	ANY
}

#todo sync data across network?
var permission_data_r = {}

class SyncPermissions:
	var c_name = "" # class_name
	var node_path:NodePath
	var permission_type:PERMISSION_TYPE
	var network_id:int #owner
	func _init(n:Node,permission_type:PERMISSION_TYPE=PERMISSION_TYPE.ANY,network_id:int=0):
		node_path = n.get_path()
		c_name = n.get_class()
		self.permission_type = permission_type
		self.network_id = network_id

	func get_key(can_use_network:bool=true) -> String:
		if network_id > 0 and can_use_network:
			return str("sync_permisisons_%s_%d" % [node_path,network_id]).md5_text()
		return str("sync_permisisons_%s" % node_path).md5_text()

	func has_access(mp:SyncPermissions,server_id:int) -> bool:
		match mp.permission_type:
			PERMISSION_TYPE.SERVER:
				return mp.network_id == server_id
			PERMISSION_TYPE.SERVER_OR_CLIENT_OWNER:
				return mp.network_id == server_id || mp.network_id == network_id
			PERMISSION_TYPE.CLIENT_ALL:
				return mp.network_id != server_id
			PERMISSION_TYPE.ANY:
				return true
		return false

class MethodPermissions:
	var c_name = "" # class_name
	var method_name = ""
	var node_path:NodePath
	var permission_type:PERMISSION_TYPE
	var network_id:int
	func _init(n:Node,callable:Callable,permission_type:PERMISSION_TYPE=PERMISSION_TYPE.ANY,network_id:int=0):
		node_path = n.get_path()
		c_name = n.get_class()
		callable.get_object()
		method_name = callable.get_method()
		self.permission_type = permission_type
		self.network_id = network_id

	func get_key(can_use_network:bool=true) -> String:
		if network_id > 0 && can_use_network:
			return str("method_access_%s_%s_%d" % [node_path,method_name,network_id]).md5_text()
		return str("method_access_%s_%s" % [node_path,method_name]).md5_text()

	func has_access(mp:MethodPermissions,server_id:int) -> bool:
		match mp.permission_type:
			PERMISSION_TYPE.SERVER:
				return mp.network_id == server_id
			PERMISSION_TYPE.SERVER_OR_CLIENT_OWNER:
				return mp.network_id == server_id || mp.network_id == network_id
			PERMISSION_TYPE.CLIENT_ALL:
				return mp.network_id != server_id
			PERMISSION_TYPE.ANY:
				return true
		return false

func get_owner_id(node:Node) ->int:
	if "network_id" in node:
		return node.network_id
	return -1

func has_general_access(mp:PERMISSION_TYPE,network_id:int,server_id:int,object_owner:int=-1) -> bool:
	match mp:
		PERMISSION_TYPE.SERVER:
			return network_id == server_id
		PERMISSION_TYPE.SERVER_OR_CLIENT_OWNER:
			return network_id == server_id || network_id == object_owner
		PERMISSION_TYPE.CLIENT_ALL:
			return network_id != server_id
		PERMISSION_TYPE.ANY:
			return true
	return false

func register_method(mp:MethodPermissions) ->bool:
	if permission_data_r.has(mp.get_key()):
		return false
	permission_data_r[mp.get_key()] = mp
	return true

func register_methods(mps:Array[MethodPermissions]) ->bool:
	for method in mps:
		if !register_method(method):
			return false
	return true

func register_sync(mp:SyncPermissions) ->bool:
	if permission_data_r.has(mp.get_key()):
		return false
	permission_data_r[mp.get_key()] = mp
	return true

func register_syncs(syncs:Array[SyncPermissions]) ->bool:
	for sync in syncs:
		if !register_sync(sync):
			return false
	return true

func sender_has_access_to_method(peer:NetPeer,n:Node,method:String,server_id:int) ->bool:
	var mp = MethodPermissions.new(n,Callable(n,method),PERMISSION_TYPE.ANY,peer.network_id)
	var hashes = [mp.get_key(),mp.get_key(false)]
	for hash in hashes:
		if permission_data_r.has(hash):
			return permission_data_r[hash].has_access(mp,server_id)

	return has_general_access(PERMISSION_TYPE.SERVER_OR_CLIENT_OWNER,peer.network_id,server_id,get_owner_id(n))

func sender_has_access_to_object(peer:NetPeer,n:Node,server_id:int) ->bool:
	var mp = SyncPermissions.new(n,PERMISSION_TYPE.ANY,peer.network_id)
	var hashes = [mp.get_key(),mp.get_key(false)]
	for hash in hashes:
		if permission_data_r.has(hash):
			return permission_data_r[hash].has_access(mp,server_id)
	return has_general_access(PERMISSION_TYPE.SERVER_OR_CLIENT_OWNER,peer.network_id,server_id,get_owner_id(n))
