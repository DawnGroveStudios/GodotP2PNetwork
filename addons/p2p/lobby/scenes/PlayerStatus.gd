extends Button

@export var can_hide:bool = true
var connection_state:NetPeer.ConnectionStatus = NetPeer.ConnectionStatus.DISCONNECTED
# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree():
		return
	pressed.connect(toggle)
	P2PNetwork.peer_status_updated.connect(_peer_status_updated)
	P2PLobby.lobby_created.connect(_joined_lobby)
	P2PLobby.lobby_joined.connect(_joined_lobby)
	P2PLobby.player_left_lobby.connect(_left_lobby)
	_set_state(connection_state)

func _joined_lobby(id:int):
	var peer = P2PNetwork.network_data.get_current_peer()
	_set_state(peer.status)

func toggle():
	match connection_state:
		NetPeer.ConnectionStatus.DISCONNECTED:
			connection_state = NetPeer.ConnectionStatus.CONNECTED
		NetPeer.ConnectionStatus.CONNECTED:
			connection_state = NetPeer.ConnectionStatus.READY
		NetPeer.ConnectionStatus.READY:
			connection_state = NetPeer.ConnectionStatus.CONNECTED
	NetworkCommands.set_connection_state(connection_state)

func _left_lobby(network_id:int):
	_set_state(NetPeer.ConnectionStatus.DISCONNECTED)

func _peer_status_updated(network_id:int,status:NetPeer.ConnectionStatus):
	var peer = P2PNetwork.network_data.get_current_peer()
	if peer == null:
		return
	_set_state(peer.status)

func _set_state(status:NetPeer.ConnectionStatus):
	connection_state = status
	match status:
		NetPeer.ConnectionStatus.DISCONNECTED:
			disabled = true
		NetPeer.ConnectionStatus.CONNECTED:
			disabled = false
		NetPeer.ConnectionStatus.READY:
			disabled = false
	if can_hide:
		if disabled:
			hide()
		else:
			show()
	text = NetPeer.ConnectionStatus.keys()[connection_state]
