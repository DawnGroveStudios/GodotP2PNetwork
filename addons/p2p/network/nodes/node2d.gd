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

var _periodic_sync_timer=Timer.new()
@export var default_periodic_sync_duration=1.0
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
	_periodic_sync_timer.autostart = false
	_periodic_sync_timer.one_shot = false
	_periodic_sync_timer.timeout.connect(_periodic_sync_timeout)
	add_child(_periodic_sync_timer)
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

func start_periodic_sync(duration:float=default_periodic_sync_duration):
	if !sync_success:
		return
	if !P2PLobby.in_lobby():
		return
	if !NetworkNodeHelper.is_owner_of_object(self):
		return
	if duration <= 0:
		duration = default_periodic_sync_duration
	_periodic_sync_timer.start(duration)

func _periodic_sync_timeout():
	if !P2PLobby.in_lobby():
		_periodic_sync_timer.stop()
		return
	if !NetworkNodeHelper.is_owner_of_object(self):
		_periodic_sync_timer.stop()
		return
	#func net_rpc(rpc_type:RPC_TYPE, caller:Node,peer:NetPeer=null, method:Callable=Callable(), send_type: int = 2) -> bool:
	if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.SYNC,self,null,Callable(),P2PNetwork.P2P_SEND_TYPE.UNRELIABLE):
		GodotLogger.error("failed syncing %s" % self.get_class())

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
