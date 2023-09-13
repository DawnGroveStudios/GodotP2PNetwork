extends Node2D

class_name P2PNode2D
var network_id:int=-1
var sync_success:bool
#var whitelist_force:Array[String] = [
#	"velocity",
#	"motion_mode",
#	"rotation",
#	"position",
#	"global_position",
#	"global_rotation",
#	"global_rotation_degrees",
#	]
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
@export var sync_priority:P2PNetwork.SYNC_PRIORITY = P2PNetwork.SYNC_PRIORITY.LOW

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkNodeHelper.set_object_name(self)
	P2PLobby.player_left_lobby.connect(player_left)
	P2PLobby.player_joined_lobby.connect(player_joined)
	var sync:Array[permissions.SyncPermissions] = [
		permissions.SyncPermissions.new(self,permissions.PERMISSION_TYPE.ANY)
	]
	P2PNetwork.network_access.register_syncs(sync)
	P2PNetwork.disconnect.connect(destroy)
	P2PNetwork.periodic_sync.connect(_periodic_sync_timeout)
	sync()

func emit_signals() ->bool:
	if !P2PLobby.in_lobby():
		return true
	return NetworkNodeHelper.is_owner_of_object(self)
func player_joined(network_id):
	sync()

func player_left(id):
	if network_id == id:
		self.call_deferred("free")

func destroy():
	self.call_deferred("free")
	P2PNetwork.rpc_remove_node(self)

func sync():
	if !P2PLobby.in_lobby():
		return
	if !NetworkNodeHelper.is_owner_of_object(self):
		return
	if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.SYNC,self):
		GodotLogger.error("failed syncing %s %s " % [self.get_class(),self.name])
		sync_success = false
	else:
		sync_success = true

func _periodic_sync_timeout(pri:BaseNetwork.SYNC_PRIORITY):
	if sync_priority != pri && sync_success:
		return
	sync()
func _server_process(delta: float) -> void:
	pass

func _client_process(delta: float) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !P2PLobby.in_lobby():
		_server_process(delta)
		return
	if !sync_success:
		return
	if NetworkNodeHelper.is_owner_of_object(self):
		_server_process(delta)
	else:
		_client_process(delta)

func server_physics_process(delta: float) -> void:
	pass

func client_physics_process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if !P2PLobby.in_lobby():
		server_physics_process(delta)
		return
	if !sync_success:
		return
	if NetworkNodeHelper.is_owner_of_object(self):
		server_physics_process(delta)
	else:
		client_physics_process(delta)

func add_whitelist(varName:String):
	whitelist.append(varName)