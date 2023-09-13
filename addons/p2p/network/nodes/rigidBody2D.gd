extends RigidBody2D
class_name P2PRigidBody2D

var network_id:int=-1
var sync_success:bool


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

	if NetworkNodeHelper.duplicate_object(self):
		return
	sync()

func emit_signals() ->bool:
	return NetworkNodeHelper.is_owner_of_object(self)

func set_mode():
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	if !P2PLobby.in_lobby():
		freeze = false
		return
	if P2PNetwork.network_data.is_server():
		freeze = false
	else:
		freeze = true
	P2PNetwork.rpc_sync(self)

func player_joined(network_id):
	sync()
	set_mode()

func player_left(id):
	if network_id == id:
		destroy()
	set_mode()

func destroy():
	P2PNetwork.rpc_remove_node(self)

func sync():
	if P2PNetwork.rpc_sync(self):
		sync_success = true
func _periodic_sync_timeout(pri:BaseNetwork.SYNC_PRIORITY):
	if sync_priority != pri && sync_success:
		return
	sync()
func server_process(delta: float) -> void:
	pass

func client_process(delta: float) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !P2PLobby.in_lobby():
		server_process(delta)
		return
	if !sync_success:
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
	if !P2PLobby.in_lobby():
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
