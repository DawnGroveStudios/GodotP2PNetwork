extends Control


var chatLog = RichTextLabel.new()
var inputField = LineEdit.new()
enum MESSAGE_GROUP_TYPE { LOBBY,FRIENDS,TEAM,ALL,SYSTEM}
@export var default_group:MESSAGE_GROUP_TYPE=0
var current_group:MESSAGE_GROUP_TYPE=default_group
var groups = {
	MESSAGE_GROUP_TYPE.LOBBY:Color.CYAN,
	MESSAGE_GROUP_TYPE.FRIENDS:Color.REBECCA_PURPLE,
	MESSAGE_GROUP_TYPE.TEAM:Color.FOREST_GREEN,
	MESSAGE_GROUP_TYPE.ALL:Color.YELLOW_GREEN,
	MESSAGE_GROUP_TYPE.SYSTEM:Color.LIGHT_SLATE_GRAY
}


func _ready():
	if !is_inside_tree():
		return
	P2PLobby.chat_message_received.connect(add_message)
	chatLog.bbcode_enabled = true
	var vbox = VBoxContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_spacer(false)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(inputField)
	inputField.custom_minimum_size = Vector2(size.x * .75,25)
	chatLog.custom_minimum_size = Vector2(size.x,size.y*0.8)
	chatLog.scroll_following = true
	vbox.add_child(chatLog)
	vbox.add_child(hbox)

	add_child(vbox)
	inputField.text_submitted.connect(text_entered)

func add_message(id,username, text:String):
	var member = P2PLobby.get_lobby_member(id)
	var textColor = default_group
	if member != null:
		textColor = member.color
	if id == 0:
		textColor = groups[MESSAGE_GROUP_TYPE.SYSTEM]
	elif current_group != default_group:
		textColor = default_group


	var group = default_group
	if text.begins_with("/"):
		var cmd = text.split(" ")[0].lstrip("/").to_upper()
		_command(cmd,text.split(" ").slice(1))
		return
	chatLog.text += '\n'
	chatLog.text += '[color=' + _to_hex(textColor) + ']'
	if username != '':
		chatLog.text += '[' + username + ']: '
	chatLog.text += text
	chatLog.text += '[/color]'

func _to_hex(color:Color) -> String:
	return "#%02x%02x%02x" % [color.r8,color.g8,color.b8]

func _command(cmd: String,args:Array=[]):
	match cmd:
		"GROUP":
			_set_group(args[0])
		_:
			GodotLogger.warn("unknown cmd")


func _set_group(cmd:String):
	for i in range(MESSAGE_GROUP_TYPE.keys().size()):
		if cmd == MESSAGE_GROUP_TYPE.keys()[i]:
			current_group = i
	if cmd == "default":
		current_group = default_group


func text_entered(text):
	if text =='/h':
		add_message(0,"SYSTEM", 'There is no help message yet!',)
		inputField.text = ''
		return
	if text != '':
		#add_message(P2P.get_lobby_member(SteamLobby._my_steam_id), text, group_index)
		# Here you have to send the message to the server
		#print(text)
		P2PLobby.send_message(text)
		inputField.text = ''


#@tool
#extends TextEdit

#func _ready():
#	placeholder_text = "Steam Chat..."

#func _input(event):
#	if event.is_action_pressed("ui_text_newline") && text.length() > 0:
#		var success = SteamLobby.send_chat_message(text.rstrip("\n"))
#		if !success:
#		else:
#			text = ""

