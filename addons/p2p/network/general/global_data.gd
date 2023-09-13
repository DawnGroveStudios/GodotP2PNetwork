extends Node

class_name P2PGlobalData

signal player_data_updated(player_id:int,key:String)
signal game_data_updated(key:String)

var game_data:Dictionary={

}
var player_data:Dictionary={

}


# Called when the node enters the scene tree for the first time.
func _ready():
	P2PNetwork.network_access.register_methods([
		permissions.MethodPermissions.new(
			self,
			_set_player_data
		),
		permissions.MethodPermissions.new(
			self,
			set_game_data
		),
		permissions.MethodPermissions.new(
			self,
			_network_init
		)
	])
	P2PLobby.player_left_lobby.connect(player_left)
	#P2PNetwork.peer_status_updated.connect(_peer_status)

func _peer_status(network_id:int,status:NetPeer.ConnectionStatus):
	if !P2PLobby.in_lobby():
		return
	if !P2PNetwork.network_data.is_server():
		return
	if P2PNetwork.network_data.get_peer_network_ids().size() <= 2:
		return
	if !P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.CLIENT,self,P2PNetwork.network_data.get_peer(network_id),_network_init.bind(game_data,player_data)):
		GodotLogger.error("failed to sync global game data with client")


func player_left(network_id:int):
	if !P2PLobby.in_lobby():
		reset()
		return
	if network_id == P2PLobby.get_id():
		reset()
	if player_data.has(network_id):
		player_data.erase(network_id)


func set_player_data(key:String,value):
	if !P2PLobby.in_lobby():
		return
	var current_player_id = P2PLobby.get_id()
	if !player_data.has(current_player_id):
		player_data[current_player_id] = {}
	var emit_signal = true
	if player_data[current_player_id].has(key):
		if player_data[current_player_id][key] == value:
			emit_signal = false
	if emit_signal:
		player_data[current_player_id][key] = value
		emit_signal("player_data_updated",current_player_id,key)
		P2PNetwork.rpc_method(_set_player_data.bind(key,value),P2PNetwork.RPC_TYPE.ALL)

func _set_player_data(player_id:int,key:String,value):
	if !P2PLobby.in_lobby():
		return
	if !player_data.has(player_id):
		player_data[player_id] = {}
	var emit_signal = true
	if player_data[player_id].has(key):
		if player_data[player_id][key] == value:
			emit_signal = false
	if emit_signal:
		player_data[player_id][key] = value
		emit_signal("player_data_updated",player_id,key)

func set_game_data(key:String,value):
	if !P2PLobby.in_lobby():
		return
	var emit_signal = true
	if game_data.has(key):
		if game_data[key] == value:
			emit_signal = false
	if emit_signal:
		game_data[key] = value
		emit_signal("game_data_updated",key)
	if P2PNetwork.network_data.is_server():
		P2PNetwork.net_rpc(P2PNetwork.RPC_TYPE.ALL_CLIENTS,self,null,set_game_data.bind(key,value))

func get_game_data(key:String):
	return game_data.get(key)

func get_player_data(peer_id:int,key:String):
	if player_data.has(peer_id):
		return player_data.get(peer_id).get(key)
	return null

func reset():
	player_data.clear()
	game_data.clear()

func _network_init(id:int,gd:Dictionary,pd:Dictionary):
	game_data.merge(gd)
	player_data.merge(pd)

