extends Panel

@export var LOBBY_FULL_COLOR=Color.FIREBRICK
@export var LOBBY_LIMITED_SPACE_COLOR=Color.YELLOW
@export var LOBBY_NORMAL_SPACE_COLOR=Color.LIME_GREEN

var _current_lobby:LobbyData
# Called when the node enters the scene tree for the first time.

func set_lobby_data(lb:LobbyData):
	if lb == null:
		return
	_current_lobby = lb
	$MarginContainer/VBoxContainer/HBoxContainer/GridContainer/Name.text = "[left]%s[/left]" % lb.lobby_name
	$MarginContainer/VBoxContainer/HBoxContainer/GridContainer/LobbySize.text = _get_lobby_size()
	$MarginContainer/VBoxContainer/HBoxContainer/GridContainer/LobbyMode.text = "[left]%s[/left]" % lb.get_lobby_visiblity_str()
	$MarginContainer/VBoxContainer/HBoxContainer/GridContainer/Join.disabled = lb.current_members == lb.max_memebers || P2PLobby.get_lobby_id() == lb.lobby_id

func _on_join_pressed() -> void:
	if _current_lobby == null:
		return
	P2PLobby.join_lobby(_current_lobby.lobby_id)

func _get_lobby_size()->String:
	var c = Color.WHITE
	if _current_lobby.current_members == _current_lobby.max_memebers:
		c = LOBBY_FULL_COLOR
	elif _current_lobby.current_members >= _current_lobby.max_memebers/2:
		c = LOBBY_LIMITED_SPACE_COLOR
	else:
		c = Color.LIME_GREEN

	return "[center][color=%s]%d/%d[/color][center]" % [_to_hex(c),_current_lobby.current_members,_current_lobby.max_memebers]


func _to_hex(color:Color) -> String:
	return "#%02x%02x%02x" % [color.r8,color.g8,color.b8]
