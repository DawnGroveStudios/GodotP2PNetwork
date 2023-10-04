extends Node

class_name SteamInit

var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_NAME: String = ""

var SteamClient
func _ready():
	if Engine.has_singleton("Steam"):
		SteamClient = Engine.get_singleton("Steam")
	else:
		return
	_check_Steam_Running()
	_initialize_Steam()

func _check_Steam_Running() -> void:
	while (!Steam.isSteamRunning()):
		NetLog.info("Steam is not running, starting Steam!")
		OS.shell_open("steam://")
		NetLog.info("waiting for Steam to start.")
		await get_tree().create_timer(3).timeout
		NetLog.info("checking if Steam is started now.")


func _initialize_Steam() -> void:
	var INIT: Dictionary = SteamClient.steamInit()
	NetLog.info("Did Steam initialize?: " + str(INIT))
	if INIT["status"] != 1:
		NetLog.fatal(get_tree(),"Failed to initialize Steam. " + str(INIT["verbal"]) + " Shutting down...")
	_get_steam_data()


func _get_steam_data() -> void:
	IS_ONLINE = SteamClient.loggedOn()
	IS_OWNED = SteamClient.isSubscribed()
	if IS_OWNED == false:
		NetLog.fatal(get_tree(),"User does not own this game")
	STEAM_ID = SteamClient.getSteamID()
	STEAM_NAME = SteamClient.getFriendPersonaName(STEAM_ID)
	NetLog.info(
		(
			"Online:"
			+ str(IS_ONLINE)
			+ " STEAM_ID:"
			+ str(STEAM_ID)
			+ " IS_OWNED:"
			+ str(IS_OWNED)
			+ " STEAM_NAME: "
			+ str(STEAM_NAME)
		)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if IS_OWNED:
		SteamClient.run_callbacks()
