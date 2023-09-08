extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
	pressed.connect(P2PLobby.leave_lobby)
	P2PLobby.lobby_created.connect(_joined_lobby)
	P2PLobby.lobby_joined.connect(_joined_lobby)
	P2PLobby.player_left_lobby.connect(_left_lobby)
	disabled = true

func _joined_lobby(id:int):
	disabled = false

func _left_lobby(steam_id:int):
	disabled = true

func _peer_status_updated(network_id:int,status):
	pass
