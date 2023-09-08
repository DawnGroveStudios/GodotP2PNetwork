extends Button

@export_enum("Private","Friends Only","Public","Invisible") var lobby_privacy:int = 2
@export
var max_players:int=4
# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(P2PLobby.create_lobby.bind(LobbyData.new(0,"DGS - DDD",0,max_players)))
	P2PLobby.lobby_joined.connect(_joined_lobby)
	P2PLobby.player_left_lobby.connect(_left_lobby)
	pass
func _joined_lobby(id:int):
	disabled = true
	text = "JOINED"

func _left_lobby(id:int):
	disabled = false
	text = "Create Lobby"
