extends Panel

var lobby_obj = preload("res://addons/p2p/lobby/scenes/LobbyItem.tscn")
var vbox:VBoxContainer = VBoxContainer.new()
var _lobbies:Array[LobbyData] = []

var _scroll_container
var _item_container:VBoxContainer
# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
		size
	P2PLobby.found_lobbies.connect(_on_match_list)
	P2PLobby.lobby_created.connect(_lobby_created)
	P2PLobby.player_left_lobby.connect(_lobby_created)
	P2PLobby.player_joined_lobby.connect(_lobby_created)
	_scroll_container = ScrollContainer.new()
	#_scroll_container.
	_scroll_container.custom_minimum_size = custom_minimum_size
	_scroll_container.size_flags_vertical = Control.SIZE_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_FILL

	_item_container = VBoxContainer.new()
	_item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_item_container)
	add_child(_scroll_container)

func _lobby_created(id:int):
	await get_tree().create_timer(1).timeout
	P2PLobby.get_lobby_list()

func _on_match_list(lobbies:Array[LobbyData]):
	for children in _item_container.get_children():
		children.queue_free()
	#_item_container.remove_child()
	#clear()
	_lobbies.clear()

	for i in lobbies.size():
		var LOBBY = lobbies[i]
		#var data = LOBBY.string()
		#add_item(data,null,true)
		var t = lobby_obj.instantiate()
		if t.has_method("set_lobby_data"):
			t.set_lobby_data(LOBBY)
		_item_container.add_child(t)
		#add_item()
		#add_item("[%s] %s \t %d/%d" % [LOBBY.lobby_mode,LOBBY.lobby_name,LOBBY.current_members,LOBBY.max_memebers],null,true)
		#_lobbies.append(LOBBY)
		#if LOBBY.lobby_id == P2PLobby.get_lobby_id():
		#	select(i)



func on_item_selected(index:int):
	NetLog.debug("selected item",{"index":index,"data":_lobbies[index]})
	#P2PLobby.join_lobby(_lobbies[index].lobby_id)
	pass
