@tool
extends Control

signal select

var config

func _ready():
	config = p2pConfig.new()
	if config != null:
		config.Load()
	var selected = 0
	var index = 0
	for k in config._p2pNetworkPathOptions.keys():
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
	print("selecting ",config._p2pNetworkPathOptions.keys()[index])
	var valid = config.SelectPath(config._p2pNetworkPathOptions.keys()[index])
	if !valid:
		return
	if config != null:
		config.Save()
	refresh()
