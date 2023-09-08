extends ItemList

var lobby_obj = preload("res://addons/p2p/lobby/scenes/Lobby.tscn")
var vbox:VBoxContainer = VBoxContainer.new()
var _lobbies:Array[LobbyData] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
	P2PLobby.found_lobbies.connect(_on_match_list)
	P2PLobby.lobby_created.connect(_lobby_created)
	P2PLobby.player_left_lobby.connect(_lobby_created)
	P2PLobby.player_joined_lobby.connect(_lobby_created)
	item_selected.connect(on_item_selected)

func _lobby_created(id:int):
	await get_tree().create_timer(1).timeout
	P2PLobby.get_lobby_list()

func _on_match_list(lobbies:Array[LobbyData]):
	clear()
	_lobbies.clear()
	for i in lobbies.size():
		var LOBBY = lobbies[i]
		var data = LOBBY.string()
		add_item(data,null,true)
		#add_item("[%s] %s \t %d/%d" % [LOBBY.lobby_mode,LOBBY.lobby_name,LOBBY.current_members,LOBBY.max_memebers],null,true)
		_lobbies.append(LOBBY)
		if LOBBY.lobby_id == P2PLobby.get_lobby_id():
			select(i)



func on_item_selected(index:int):
	GodotLogger.debug("selected item",{"index":index,"data":_lobbies[index]})
	P2PLobby.join_lobby(_lobbies[index].lobby_id)
	pass
