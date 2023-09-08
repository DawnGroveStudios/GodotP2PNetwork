@tool
extends Node
class_name p2pConfig

const configFilePath = "res://addons/p2p/config.data"
const p2pNetworkName="P2PNetwork"
const p2pLobbyName="P2PLobby"


var p2pNetworkPath = "res://addons/p2p/network/general/network.gd"
var p2pLobbyPath = "res://addons/p2p/lobby/general/lobby.gd"
var selectedNetworkOption="Base"

var p2pNetworkPathOptions ={
	"Base":{
		p2pNetworkName : "res://addons/p2p/network/general/network.gd",
		p2pLobbyName: "res://addons/p2p/lobby/general/lobby.gd",
	},
	"Steam":{
		p2pNetworkName : "res://addons/p2p/network/implementations/steam/network.gd",
		p2pLobbyName: "res://addons/p2p/lobby/implementations/steam/lobby.gd",
	},
	"Proxy":{ # todo will have to implement this
		p2pNetworkName : "res://addons/p2p/network/general/network.gd",
		p2pLobbyName: "res://addons/p2p/lobby/general/lobby.gd",
	}
}

func _ready() -> void:
	if !Engine.has_singleton("Steam"):
		p2pNetworkPathOptions.erase("Steam")

func SelectPath(p2pOption: String) -> bool:
	if !p2pNetworkPathOptions.has(p2pOption):
		return false
	if !Engine.has_singleton("Steam") and p2pOption == "Steam":
		return false
	var options = p2pNetworkPathOptions.get(p2pOption)
	p2pNetworkPath = options.get(p2pNetworkName)
	p2pLobbyPath = options.get(p2pLobbyName)
	selectedNetworkOption=p2pOption
	return true

func GetNetwork() :
	return p2pNetworkPath

func GetNetworkLobby() :
	return p2pLobbyPath

func Save():
	var file = FileAccess.open(configFilePath,FileAccess.WRITE)
	var data = JsonData.marshal(self)
	file.store_buffer(data)

func Load():
	var data = FileAccess.get_file_as_bytes(configFilePath)
	JsonData.unmarshal_bytes(data,self)
	if !Engine.has_singleton("Steam"):
		p2pNetworkPathOptions.erase("Steam")

