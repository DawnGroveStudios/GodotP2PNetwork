extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
	pressed.connect(P2PLobby.get_lobby_list)
	pass

