@tool
extends Control

signal select

var config:p2pConfig = p2pConfig.new()

func _ready():
	config.Load()
	var selected = 0
	var index = 0
	for k in config.p2pNetworkPathOptions.keys():
		$options.add_item("P2P Mode: %s" % k)
		if k == config.selectedNetworkOption:
			selected = index
		index += 1
	$options.select(selected)

func _process(delta):
	pass

func refresh():
	emit_signal("select")

func _on_refresh_pressed():
	refresh()

func _on_options_item_selected(index):
	print("selecting ",config.p2pNetworkPathOptions.keys()[index])
	var valid = config.SelectPath(config.p2pNetworkPathOptions.keys()[index])
	if !valid:
		return
	config.Save()
	refresh()
