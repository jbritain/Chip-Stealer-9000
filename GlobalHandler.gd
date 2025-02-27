extends Node

const Map = preload("res://Scenes/University Campus/University Campus.tscn")
const WalkingPlayer = preload("res://Scenes/WalkingPlayer/WalkingPlayer.tscn")
const SeagullPlayer = preload("res://Scenes/SeagullPlayer/SeagullPlayer.tscn")

var is_seagull = false
var enet_peer = ENetMultiplayerPeer.new()

@rpc("any_peer", "reliable")
func handle_connection_info(peer_is_seagull):
	var peer_id = multiplayer.get_remote_sender_id()
	if peer_is_seagull:
		add_seagull_player(peer_id)
	else:
		add_walking_player(peer_id)

@rpc("any_peer", "reliable")
func request_connection_info():
	rpc_id(multiplayer.get_remote_sender_id(), "handle_connection_info", is_seagull)

func init_game_world():
	get_tree().get_root().add_child(Map.instantiate())
	
func add_walking_player(peer_id):
	if multiplayer.is_server():
		print("server: add walking player")
	else:
		print("client: add walking player")
	var player = WalkingPlayer.instantiate()
	player.name = str(peer_id)
	$/root/MainScene.add_child(player)
	
func add_seagull_player(peer_id):
	if multiplayer.is_server():
		print("server: add seagull player")
	else:
		print("client: add seagull player")
	var player = SeagullPlayer.instantiate()
	player.name = str(peer_id)
	$/root/MainScene.add_child(player)

func handle_connected_peer(peer_id):
	rpc_id(peer_id, "request_connection_info")
