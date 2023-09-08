extends RigidBody2D
class_name P2PRigidBody2D

var network_id:int=-1
var sync_success:bool

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
	if !P2PNetwork.rpc_sync(self):
		GodotLogger.error("failed syncing %s" % self.name)

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
	if NetworkNodeHelper.duplicate_object(self):
		return
	if !sync_success:
		return
	if NetworkNodeHelper.is_owner_of_object(self):
		server_physics_process(delta)
	else:
		client_physics_process(delta)
