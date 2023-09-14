# GodotP2PNetwork

## Summary
This plugin adds a network/lobby layer over existing networking infrastructure. Currently we Support
- [Github](https://github.com/CoaguCo-Industries/GodotSteam)

We Plan to support
- Native Godot Networking
- Peer to Peer Proxy server
	- To avoid having players have to port forward to play with friends


## Plugins

### Optional - Highly recommend since this is the only working Networking layer currently
- Steam
	- [Github](https://github.com/CoaguCo-Industries/GodotSteam)
	- [GodotSteam](https://godotsteam.com/)


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
