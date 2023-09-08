extends Node

class_name SteamInit

var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_NAME: String = ""


func _ready():
	_initialize_Steam()


func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	GodotLogger.info("Did Steam initialize?: " + str(INIT))
	if INIT["status"] != 1:
		GodotLogger.fatal("Failed to initialize Steam. " + str(INIT["verbal"]) + " Shutting down...")
	_get_steam_data()


func _get_steam_data() -> void:
	IS_ONLINE = Steam.loggedOn()
	IS_OWNED = Steam.isSubscribed()
	if IS_OWNED == false:
		GodotLogger.fatal("User does not own this game")
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getFriendPersonaName(STEAM_ID)
	GodotLogger.info(
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
		Steam.run_callbacks()
