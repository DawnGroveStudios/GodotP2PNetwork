extends Node
class_name NetworkNodeHelper

static func get_parent_path(node_path:NodePath)->NodePath:
	var path = []
	for n in range(0,node_path.get_name_count()-1):
		path.append(node_path.get_name(n))
	return NodePath("/"+"/".join(path))


static func set_object_name(obj:Object,args:Array=[])->bool:
	if !"name" in obj:
		return false

	NetworkNodeHelper.set_object_owner(obj)
	if valid_name(obj):
		return true
	var random = RandomNumberGenerator.new()
	randomize()
	var invalidChar = RegEx.new()
	invalidChar.compile("[-_\\s@]")
	var n = invalidChar.sub(obj.name,"",true)
	var data = [str(P2PNetwork.network_data.get_network_id()),str(obj.get_class()),str(random.randi()),n]
	data.append_array(args)
	if obj.has_method("set_name"):
		obj.call_deferred("set_name","_".join(data))
	else:
		obj.name = "_".join(data)
	return true

static func valid_name(obj:Object) -> bool:
	if !"name" in obj:
		return false
	P2PNetwork.network_name.compile("([0-9]+_[0-9a-zA-Z]+_[0-9]+)(_[0-9a-zA-Z]+)*")
	if P2PNetwork.network_name.search(obj.name) != null:
		return true
	return false

static func duplicate_object(obj:Node) ->bool:
	var path = "%s:%s" % [obj.get_path().get_concatenated_names(),obj.get_path().get_concatenated_subnames()]
	if !valid_name(obj):
		return false

	var parent = obj.get_parent()
	if parent == null:
		return false
	var duplicate=false
	var duplicate_count = 0
	for c in parent.get_children():
		if c.name == obj.name:
			duplicate = true
			duplicate_count += 1
	return duplicate_count > 1

static func is_owner_of_object(obj:Object,or_server:bool=false) ->bool:
	if !P2PLobby.in_lobby():
		return true
	if !"network_id" in obj:
		return true
	if obj["network_id"] == P2PNetwork.network_data.get_network_id():
		return true
	if or_server && P2PNetwork.network_data.is_server():
		return true
	return obj["network_id"] <= 0


static func set_object_owner(obj:Object) ->bool:
	if !"network_id" in obj:
		return false
	if obj.network_id >= 0:
		return false
	obj.network_id = P2PNetwork.network_data.get_network_id()
	return true


static func valid_sync_object(obj:Object) -> bool:
	return "scene_file_path" in obj and len(obj["scene_file_path"]) > 0


static func valid_sync_dict(obj:Dictionary) -> bool:
	return obj.has("scene_file_path") and len(obj["scene_file_path"]) > 0


static func get_sync_object(data:Dictionary) -> Node:
	if !data.has("scene_file_path"):
		return null
	return load(data["scene_file_path"]).instantiate()
