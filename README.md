# GodotP2PNetwork

## Summary
GodotP2PNetwork adds a network/lobby layer over existing networking infrastructure. Currently we Support
- [https://github.com/CoaguCo-Industries/GodotSteam](https://github.com/CoaguCo-Industries/GodotSteam)

#### Future Plans to Support:
- Native Godot Networking
- Peer to Peer Proxy server
	- To avoid having players have to port forward to play with friends


## Plugins
### Required
- GodotLogger
	- [https://github.com/DawnGroveStudios/GodotLogger](https://github.com/DawnGroveStudios/GodotLogger)
	- [AssetStore]()

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
