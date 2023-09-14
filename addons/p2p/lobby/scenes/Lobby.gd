extends Control

class_name LobbyScene
@export var lobby_id:int = 0
@export var lobby_name = "Default Lobby"


func _init(lobby_id:int):
	self.lobby_id = lobby_id

# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
	$VBoxContainer/HBoxContainer/JoinLobby.pressed.connect("join")
	pass # Replace with function body.

func set_lobby(lobby:LobbyData):
	return

func set_title(title:String):
	$VBoxContainer/Title.text = title

func set_model(model:String):
	$VBoxContainer/HBoxContainer/Model.text = model

func join():
	pass
