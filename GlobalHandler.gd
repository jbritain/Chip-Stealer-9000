extends Node

const Map = preload("res://Scenes/University Campus/University Campus.tscn")
const WalkingPlayer = preload("res://Scenes/WalkingPlayer/WalkingPlayer.tscn")
const SeagullPlayer = preload("res://Scenes/SeagullPlayer/SeagullPlayer.tscn")
const GameHud = preload("res://Scenes/GameHud/GameHud.tscn")

var is_seagull = false
var enet_peer = ENetMultiplayerPeer.new()
var student_score = 0
var seagull_score = 0

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		start_game()
	if event is InputEventKey and event.pressed and event.keycode == KEY_Y:
		print("key y pressed")
		var players = get_tree().get_nodes_in_group("student")
		for each in players:
			print(each.has_chips)

func start_game():
	if multiplayer.is_server():
		print("Starting new game round...")
		server_start_round()
	else:
		print("Requesting server to start new game round...")
		rpc_id(1, "server_start_round") # Request the server to start the round

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
	get_tree().get_root().add_child(GameHud.instantiate())
	
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
	
func announce_chips_stolen():
	if multiplayer.is_server():
		server_chips_stolen()
	else:
		rpc_id(1, "server_chips_stolen") # apparently 1 is always server

# This function should only run on the server i think
@rpc("any_peer", "reliable")		
func server_chips_stolen():
	if not multiplayer.is_server():
		return
	print("chips stolen function")
	seagull_score += 1
	print("seagull score increase to",seagull_score)
	rpc("client_update_score", student_score, seagull_score)
	client_update_score(student_score,seagull_score)


func server_start_round():
	if not multiplayer.is_server():
		return
	# Give someone chips
	var students = get_tree().get_nodes_in_group("student")
	for student in students:
		student.has_chips = true
	
	# Set scores back to 0
	student_score = 0
	seagull_score = 0
	
	# TODO: Start a timer for X minutes before round ends

@rpc("authority","reliable")
func client_start_round():
	pass
		

@rpc("authority","reliable")
func client_update_score(w,s):
	print("received new score from server")
	var hud = get_tree().get_root().find_child("GameHud",true,false)
	hud.update_score_display(w, s)
