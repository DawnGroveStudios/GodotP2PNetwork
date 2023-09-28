# GodotP2PNetwork

## Summary
GodotP2PNetwork adds a network/lobby layer over existing networking infrastructure. Currently we Support
- [https://github.com/CoaguCo-Industries/GodotSteam](https://github.com/CoaguCo-Industries/GodotSteam)

#### Future Plans to Support:
- Native Godot Networking
- Peer to Peer Proxy server
	- To avoid having players have to port forward to play with friends


## Plugins

### Optional - Highly recommend since this is the only working Networking layer currently
- Steam
	- [https://github.com/CoaguCo-Industries/GodotSteam](https://github.com/CoaguCo-Industries/GodotSteam)
	- [https://godotsteam.com/](https://godotsteam.com/)


## Features
- RPC Signals
	- Send singals to any connected clients
- RPC Method
	- Make method calls on any connected clients
- RPC Sync
	- Sync Objects Across all clients
- Network Lobby
- Network Chat
- Lobby Search
- Configurable Network timing
- Allow for client side processing with period server syncs to reduce network load

## Singletons
- `P2PNetwork`
- `P2PLobby`



## Example
- [GodotP2PNetworkExample](https://github.com/DawnGroveStudios/GodotP2PNetworkExample)


## RPC Signal

```gdscript
P2PNetwork.rpc_emit_signal(object,"SingalName")
P2PNetwork.rpc_emit_signal(object,"SingalName",[args])
```

Example
```gdscript
P2PNetwork.rpc_emit_signal(SignalBus,"Explosion",[damage,damage_type])
```

## RPC Method

```gdscript
func _ready():
	P2PNetwork.network_access.register_method(Callable)
	P2PNetwork.rpc_method(Callable)
```


```gdscript
func _ready():
	P2PNetwork.network_access.register_method(send_message)
	P2PNetwork.rpc_method(send_message.bind("Hello!"))

func send_message(msg:String):
	print(msg)
```


## RPC Sync

```gdscript
extends Node

@export var sync_priority:P2PNetwork.SYNC_PRIORITY = P2PNetwork.SYNC_PRIORITY.LOW
var network_id:int
var _recieved:bool

func _ready():
	NetworkNodeHelper.set_object_name(self)
	P2PLobby.player_left_lobby.connect(player_left)
	P2PLobby.player_joined_lobby.connect(player_joined)
	P2PNetwork.globalData.player_data_updated.connect(_player_data_updated)
	P2PNetwork.disconnect.connect(destroy)
	P2PNetwork.periodic_sync.connect(_periodic_sync_timeout)

func _recived_obj(network_id,path):
	if _recieved:
		return
	if path == get_path():
		_recieved = true
```


## RPC Queue Free
Deletes the provided object for all connected clients. You will have to be a server or object owner to call.

```gdcsript
	P2PNetwork.rpc_remove_node(self)
```

### Global Data

```gdcript
P2PNetwork.globalData.set_game_data("key",value)
```

Example
```gdcript
P2PNetwork.globalData.set_game_data("map_seed",map_seed)
var map_seed = P2PNetwork.globalData.get_game_data("map_seed")
```
