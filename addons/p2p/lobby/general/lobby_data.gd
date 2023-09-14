extends Node

class_name LobbyData

var lobby_id:int = 0
var lobby_name:String = "default"
var lobby_mode:String = "default"
var max_memebers:int = 4
var min_members:int = 1
var current_members:int = 0
var auto_start:int=-1
var visablity:int=0

var meta:Dictionary={}

var _my_self:NetPeer
var _lobby_host:NetPeer

var _members:Dictionary = {}

func _init(id:int,name:String,visablity:int,max_members:int,min_members:int=1,auto_start:int=-1,meta:Dictionary={}):
	self.lobby_id = id
	self.lobby_name = name
	self.max_memebers = max_members
	self.min_members = min_members
	self.auto_start = auto_start
	self.meta = meta
	self.visablity = visablity

func send_data():
	pass

func can_start_game() -> bool:
	return _members.size() >= min_members

func join(member:NetPeer) -> bool:
	set_member(member)
	return true

func leave(member:NetPeer) -> bool:
	# todo add support for rejoining
	if _members.has(member.network_id):
		_members.erase(member.network_id)
	if _lobby_host.network_id == member.network_id:
		_lobby_host = null
		P2PLobby.leave_lobby()
	return true

func is_ready() -> bool:
	var count = 0
	for id in _members:
		var member = get_member(id)
		if !(member.is_ready && member.connected):
			return false
		#todo check for min members
	return true

func add_meta_value(key:String,value) -> bool:
	if meta.has(key):
		return false
	meta[key] = value
	return true

func set_meta_value(key:String,value):
	meta[key] = value

func get_member(id:int) ->NetPeer:
	NetLog.info("base lobby data: get_member")
	return _members.get(id)

func update_lobby_members():
	NetLog.info("base lobby data: update_lobby_members")
	pass

func set_lobby_owner(member:NetPeer)->bool:
	if member == null:
		return false
	#if _lobby_host == null:
	_lobby_host = member
	#elif member.network_id == _lobby_host.network_id:
	#	return false
	set_member(member)
	return false

func get_lobby_owner()->NetPeer:
	return _lobby_host

func get_self() -> NetPeer:
	return _my_self

func set_self(member:NetPeer):
	_my_self = member
	set_member(member)

func set_member(member:NetPeer) ->bool:
	_members[member.network_id] = member
	return true

func get_members() -> Dictionary:
	return _members

func string() ->String:
	#return lobby_name
	return "[%s] %s \t(%d/%d)" % [lobby_mode,lobby_name,current_members,max_memebers]
