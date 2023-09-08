extends Control

class_name ProfileBar
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_peer(peer:NetPeer):
	if peer == null:
		return
	$Panel/ProfileName.text = peer.get_profile_name()
	$Panel/Status.text = NetPeer.ConnectionStatus.keys()[peer.status]
	if peer._profile_image != null:
		$Panel/Sprite2D.texture = peer._profile_image

func set_image(peer:NetPeer):
	$Panel/Sprite2D.texture = peer._profile_image
