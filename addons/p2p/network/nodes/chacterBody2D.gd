extends CharacterBody2D

class_name P2PCharacterBody2D
var network_id:int=-1
var sync_success:bool

@export var enable_network_sync:bool=true
@export var sync_priority:P2PNetwork.SYNC_PRIORITY = P2PNetwork.SYNC_PRIORITY.LOW
var is_owner
var whitelist:Array[String] = [
	"velocity",
	"motion_mode",
	"rotation",
	"position",
	"global_position",
	"global_rotation",
	"global_rotation_degrees",
	"network_id"
]


var _recieved:bool
func _ready() -> void:
	NetworkNodeHelper.set_object_name(self)
	if !enable_network_sync:
		sync_success = true
		return
	P2PLobby.player_left_lobby.connect(player_left)
	P2PLobby.player_joined_lobby.connect(player_joined)
	P2PNetwork.globalData.player_data_updated.connect(_player_data_updated)
	var sync:Array[permissions.SyncPermissions] = [
		permissions.SyncPermissions.new(self,permissions.PERMISSION_TYPE.ANY)
	]
	P2PNetwork.network_access.register_syncs(sync)
	P2PNetwork.disconnect.connect(destroy)
	P2PNetwork.periodic_sync.connect(_periodic_sync_timeout)
	P2PNetwork.recived_obj.connect(_recived_obj)
	if NetworkNodeHelper.duplicate_object(self):
		return
	sync()

func _recived_obj(network_id,path):
	if _recieved:
		return
	if path == get_path():
		_recieved = true
		NetLog.info("recieved obj")

func add_whitelist(varName:String):
	whitelist.append(varName)

func _player_data_updated(player_id:int,key:String):
	if key != "current_scene":
		return
	var current_scene = P2PNetwork.globalData.get_player_data(P2PNetwork.network_data.get_current_peer().network_id,"current_scene")
	var p_id_current_scene = P2PNetwork.globalData.get_player_data(player_id,"current_scene")
	if current_scene != p_id_current_scene:
		return
	#await get_tree().process_frame
	#await get_tree().create_timer(0.1).timeout
	sync()
	#P2PNetwork.rpc_sync(self,P2PNetwork.P2P_SEND_TYPE.RELIABLE,P2PNetwork.network_data.get_peer(network_id))
	pass

func emit_signals() ->bool:
	if !P2PLobby.in_lobby():
		return true
	return NetworkNodeHelper.is_owner_of_object(self)

func player_joined(network_id):
	#P2PNetwork.rpc_sync(self,P2PNetwork.P2P_SEND_TYPE.RELIABLE,P2PNetwork.network_data.get_peer(network_id))
	sync()

func player_left(id):
	if network_id == id:
		destroy()

func destroy():
	P2PNetwork.rpc_remove_node(self)

func sync():
	if !enable_network_sync:
		sync_success = true
		return
	if !P2PLobby.in_lobby():
		sync_success = true
		return
	if !NetworkNodeHelper.is_owner_of_object(self):
		sync_success = true
		return
	if P2PNetwork.rpc_sync(self):
		sync_success = true

func _periodic_sync_timeout(pri:BaseNetwork.SYNC_PRIORITY):
	if sync_priority != pri && sync_success:
		return
	sync()

func server_process(delta: float) -> void:
	return

	#_current_time += delta
	#if _current_time >= update_interval:
		#P2PNetwork.rpc_sync(self,P2PNetwork.P2P_SEND_TYPE.UNRELIABLE_NO_DELAY)
		#_current_time = 0

func client_process(delta: float) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !P2PLobby.in_lobby():
		server_process(delta)
		return
	if !sync_success:
		#if NetworkNodeHelper.is_owner_of_object(self):
		#	sync()
		return
	if NetworkNodeHelper.is_owner_of_object(self):
		server_process(delta)
	else:
		client_process(delta)

func server_physics_process(delta: float) -> void:
	pass

func client_physics_process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if !P2PLobby.in_lobby() || !enable_network_sync:
		server_physics_process(delta)
		return
	if NetworkNodeHelper.duplicate_object(self):
		return
	if !sync_success:
		return
	if NetworkNodeHelper.is_owner_of_object(self):
		server_physics_process(delta)
	else:
		client_physics_process(delta)
