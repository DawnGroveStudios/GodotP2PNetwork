class_name NetPeer
## required client data
##
## The description of the script, what it can do,
## and any further detail.

##
enum ConnectionStatus {
	DISCONNECTED, ##
	CONNECTED, ##
	READY, ##
	LOADING, ##
	LOADED, ##
}

var status:ConnectionStatus = ConnectionStatus.DISCONNECTED
var connected:bool=false : set = _connected_set
var host:bool = false

var network_id: int
var profile_name: String

var color:Color

var meta:Dictionary={}

## profile image texture that can be displayed in lobby
var _profile_image:ImageTexture

func _init(network_id:int,data:PackedByteArray=PackedByteArray()):
	self.network_id=network_id
	self.color = Color.DARK_CYAN
	if data.size() > 0:
		JsonData.unmarshal_bytes(data,self)
	get_profile_name()

func get_profile_name() -> String:
	return profile_name

func get_color() -> Color:
	return color

func get_color_hex() -> String:
	return "#%02x%02x%02x" % [color.r8,color.g8,color.b8]

func _connected_set(new_value):
	connected = new_value
	if connected and status < ConnectionStatus.CONNECTED:
		status = ConnectionStatus.CONNECTED
	if !connected and status > 0:
		status = ConnectionStatus.DISCONNECTED
