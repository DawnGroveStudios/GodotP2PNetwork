@tool
extends EditorPlugin
const scene_prefix="P2P_"

const ConfigMenu = preload("res://addons/p2p/scene/p2pConfigMenu.tscn")
var loadSingletonPlugin = {
	"NetCache":"res://addons/p2p/helper/cache.gd",
	"P2PNetwork" : "res://addons/p2p/network/general/network.gd",
	"P2PLobby": "res://addons/p2p/lobby/general/lobby.gd",
}

var config:p2pConfig = p2pConfig.new()
var config_panel_instance
var loadScenePlugin = {
	"Button":[
			{
				"Name":"LeaveLobbyButton",
				"Path":preload("res://addons/p2p/lobby/scenes/LeaveLobbyBtn.gd"),
				"Icon":get_editor_interface().get_base_control().get_theme_icon("Button")
			},
			{
				"Name":"CreateLobbyButton",
				"Path":preload("res://addons/p2p/lobby/scenes/CreateLobbyBtn.gd"),
				"Icon":get_editor_interface().get_base_control().get_theme_icon("Button")
			},
			{
				"Name":"GetLobbyButton",
				"Path":preload("res://addons/p2p/lobby/scenes/GetLobbyBtn.gd"),
				"Icon":get_editor_interface().get_base_control().get_theme_icon("Button")
			},
			{
				"Name":"PlayerStatusButton",
				"Path":preload("res://addons/p2p/lobby/scenes/PlayerStatus.gd"),
				"Icon":get_editor_interface().get_base_control().get_theme_icon("Button")
			}
		],
	"TextEdit":[
		{
			"Name":"ChatText",
			"Path":preload("res://addons/p2p/lobby/scenes/LobbyChat.gd"),
			"Icon":get_editor_interface().get_base_control().get_theme_icon("TextEdit")
		}

	],
	"ItemList":[
		{
			"Name":"LobbyList",
			"Path": preload("res://addons/p2p/lobby/scenes/LobbyList.gd"),
			"Icon":get_editor_interface().get_base_control().get_theme_icon("ItemList")
		}
	],
	"Node":[
		{
			"Name":"NodeTest",
			"Path": preload("res://addons/p2p/network/nodes/test_node.gd"),
			"Icon":get_editor_interface().get_base_control().get_theme_icon("Node")
		}
		],
	"HBoxContainer":[
		{
			"Name":"Profiles",
			"Path" :preload("res://addons/p2p/lobby/scenes/Profiles.gd"),
			"Icon":get_editor_interface().get_base_control().get_theme_icon("HBoxContainer")
		}

	]
}

func _enter_tree():
	config_panel_instance = ConfigMenu.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, config_panel_instance)
	config_panel_instance.select.connect(refresh)
	config.Load()
	loadSingletonPlugin[config.p2pNetworkName] = config.GetNetwork()
	loadSingletonPlugin[config.p2pLobbyName] = config.GetNetworkLobby()
	for names in loadSingletonPlugin.keys():
		print_debug("[p2p] adding singleton %s %s" % [names,loadSingletonPlugin[names]])
		add_autoload_singleton(names, loadSingletonPlugin[names])
	for t in loadScenePlugin:
		var sceneType = loadScenePlugin[t]
		for obj in sceneType:
			print_debug("[p2p] Loading Nodes %s%s" % [scene_prefix,obj["Name"]])
			add_custom_type("%s%s" % [scene_prefix,obj["Name"]],t,obj["Path"],obj["Icon"])

func refresh():
	config.Load()
	loadSingletonPlugin[config.p2pNetworkName] = config.GetNetwork()
	loadSingletonPlugin[config.p2pLobbyName] = config.GetNetworkLobby()
	for names in loadSingletonPlugin.keys():
		print_debug("[p2p] removing singleton %s %s" % [names,loadSingletonPlugin[names]])
		remove_autoload_singleton(names)
	for names in loadSingletonPlugin.keys():
		print_debug("[p2p] adding singleton %s %s" % [names,loadSingletonPlugin[names]])
		add_autoload_singleton(names, loadSingletonPlugin[names])

func _exit_tree():
	if config_panel_instance:
		config_panel_instance.queue_free()
	for names in loadSingletonPlugin.keys():
		print_debug("[p2p] removing singleton %s %s" % [names,loadSingletonPlugin[names]])
		remove_autoload_singleton(names)
	for t in loadScenePlugin:
		for obj in loadScenePlugin[t]:
			print_debug("[p2p] UnLoading Nodes %s%s" % [scene_prefix,obj["Name"]])
			remove_custom_type("%s%s" % [scene_prefix,obj["Name"]])

