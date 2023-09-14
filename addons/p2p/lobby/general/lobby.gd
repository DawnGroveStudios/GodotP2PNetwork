extends Node

class_name BaseLobby
enum LobbyType {
LOBBY_TYPE_PRIVATE = 0,
LOBBY_TYPE_FRIENDS_ONLY = 1,
LOBBY_TYPE_PUBLIC = 2,
LOBBY_TYPE_INVISIBLE = 3,
}

signal player_joined_lobby(network_id)
signal player_left_lobby(network_id)
signal lobby_created(lobby_id)
signal lobby_joined(lobby_id)
signal lobby_join_requested(lobby_id)
signal lobby_owner_changed(previous_owner, new_owner)
signal lobby_data_updated(network_id)
signal chat_message_received(from_network_id, message)

signal found_lobbies(lobbies:Array[LobbyData])
signal avatar_loaded(network_id)
var _current_lobby:LobbyData

var _self:NetPeer
var _creating_lobby:bool


func _ready():
	_self = NetPeer.new(0)

func get_self() ->NetPeer:
	return _self

func get_id() -> int:
	return _self.network_id

func create_lobby(lb:LobbyData) ->bool:
	if in_lobby():
		return false
	NetLog.info("Trying to create lobby of type %s" % lb.visablity)
	_current_lobby = lb
	return true

func join_lobby(lobby_id: int) ->bool:
	if in_lobby():
		if lobby_id == _current_lobby.lobby_id:
			return false
		emit_signal("player_left_lobby", _current_lobby.lobby_id)
		leave_lobby()
	return true

func leave_lobby():
	if in_lobby():
		NetLog.info("Leaving Lobby %s" % get_lobby_id())
		_current_lobby = null
	return

func get_lobby_id() -> int:
	if !in_lobby():
		return -1
	return _current_lobby.lobby_id

func in_lobby() ->bool:
	return _current_lobby != null

func get_lobby_member(id:int) ->NetPeer:
	if !in_lobby():
		return null
	return _current_lobby.get_memeber(id)

func get_lobby_members() -> Dictionary:
	if !in_lobby():
		return {}
	return _current_lobby.get_members()

func get_lobby_list():
	return

func get_owner_id() -> int:
	if !in_lobby():
		return -1
	return _current_lobby.get_lobby_owner().network_id

func is_lobby_owner() -> bool:
	if !in_lobby():
		return false
	return _current_lobby.get_lobby_owner().network_id == _current_lobby.get_id()


func send_message(msg:String,to:int = -1) ->bool:
	if !in_lobby():
		return false
	return true

