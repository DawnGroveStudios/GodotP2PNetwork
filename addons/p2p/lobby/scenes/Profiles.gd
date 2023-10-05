extends HBoxContainer

func _ready():
	P2PLobby.avatar_loaded.connect(refresh)
	P2PLobby.lobby_created.connect(refresh)
	P2PLobby.lobby_joined.connect(refresh)
	P2PLobby.player_left_lobby.connect(remove)
	P2PNetwork.peer_status_updated.connect(load_avatars)

func refresh(network_id:int):
	load_avatars(0,NetPeer.ConnectionStatus.DISCONNECTED)

func load_avatars(network_id:int,status:NetPeer.ConnectionStatus):
	if !P2PLobby.in_lobby():
		return
	for c in get_children():
		remove_child(c)
	for peer_id in P2PLobby._current_lobby._members:
		var pt = preload("res://addons/p2p/lobby/scenes/ProfileBar.tscn")

		var p = pt.instantiate()
		var s = p.get_rect()
		#if !has_theme_constant("separation"):

		if peer_id == P2PLobby.get_id():
			#p.set_peer(P2PLobby.get_self())
			p.set_peer(P2PNetwork.network_data.get_peer(peer_id))
			p.set_image(P2PLobby.get_self())
		else:
			var peer = P2PNetwork.network_data.get_peer(peer_id)
			if peer == null:
				peer = P2PLobby._current_lobby._members[peer_id]
			p.set_peer(peer)
			p.set_image(P2PLobby._current_lobby._members[peer_id])
		add_child(p)


func remove(id:int):
	for c in get_children():
		remove_child(c)
	if P2PLobby.in_lobby():
		load_avatars(0,NetPeer.ConnectionStatus.DISCONNECTED)
