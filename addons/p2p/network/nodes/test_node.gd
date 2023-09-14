extends Node

var _test_logger:Log=NetLog.with("[TEST]")
var testing_name="default"
# Called when the node enters the scene tree for the first time.
func _ready():
	scene_file_path="res://addons/p2p/network/nodes/test_node.gd"
	#func _init(n:Node,callable:Callable,permission_type:PERMISSION_TYPE=PERMISSION_TYPE.ANY,network_id:int=0):
	var methods:Array[permissions.MethodPermissions] = [
		permissions.MethodPermissions.new(self,test_all_sync,permissions.PERMISSION_TYPE.ANY),
		permissions.MethodPermissions.new(self,test_server_sync,permissions.PERMISSION_TYPE.SERVER)
		#permissions.MethodPermissions.new(self,test_server_sync,permissions.PERMISSION_TYPE.)
	]
	var sync:Array[permissions.SyncPermissions] = [
		permissions.SyncPermissions.new(self,permissions.PERMISSION_TYPE.ANY)
	]

	#Logger.info("Script",get_script())
	P2PNetwork.network_access.register_methods(methods)
	P2PNetwork.network_access.register_syncs(sync)
	P2PNetwork.all_peers_connected.connect(start_tests)
	#P2PLobby.player_left_lobby.connect()
	pass # Replace with function body.

func start_tests():
	var t = Timer.new()
	t.wait_time = 2.0
	t.autostart = true
	t.one_shot = false
	t.timeout.connect(connected)
	add_child(t)

func connected():
	_test_logger.info("all peers connected",{"testing_sync":testing_name})
	if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.ALL,self,null,test_all_sync.bind("all peers connected")):
		_test_logger.error("failed sending rpc func")
	if P2PNetwork.network_data.is_server():
		if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.ALL,self,null,test_server_sync.bind("all peers connected")):
			_test_logger.error("failed sending rpc func")

	if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.SYNC,self):
		_test_logger.error("failed syncing self")
	else:
		testing_name = RandomGen.generate_word()

func test_all_sync(network_id:int,msg:String):
	_test_logger.info("[test_all_method]",{"id":network_id,"msg":msg})
	return

func test_server_sync(network_id:int,msg:String):
	_test_logger.info("[test_server_method]",{"id":network_id,"msg":msg})
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
