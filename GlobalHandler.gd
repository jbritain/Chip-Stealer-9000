extends Node

const Map = preload("res://Scenes/University Campus/University Campus.tscn")
const WalkingPlayer = preload("res://Scenes/WalkingPlayer/WalkingPlayer.tscn")
const SeagullPlayer = preload("res://Scenes/SeagullPlayer/SeagullPlayer.tscn")
const GameHud = preload("res://Scenes/GameHud/GameHud.tscn")
const ChipDeliveryPoint = preload("res://Scenes/Checkpoints/ChipDeliveryPoint.tscn")

var is_seagull = false
var enet_peer = ENetMultiplayerPeer.new()
var student_score = 0
var seagull_score = 0

var chip_delivery_point

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
	chip_delivery_point = ChipDeliveryPoint.instantiate()
	get_tree().get_root().add_child(chip_delivery_point)
	
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
	
func handle_disconnected_peer(peer_id):
	var player = get_node_or_null("/root/MainScene/" + str(peer_id))
	if not player: return
	
	print("player disconnected")
	player.queue_free()
	
func announce_chips_stolen():
	if multiplayer.is_server():
		server_chips_stolen()
	else:
		rpc_id(1, "server_chips_stolen") # apparently 1 is always server indeed it is alan
		
func announce_chips_delivered():
	if multiplayer.is_server():
		server_chips_delivered()
	else:
		rpc_id(1, "server_chips_delivered") # apparently 1 is always server indeed it is alan

# This function should only run on the server i think 
# yes alan that is correct
@rpc("any_peer", "reliable")		
func server_chips_stolen():
	if not multiplayer.is_server():
		return
	print("chips stolen function")
	seagull_score += 1
	print("seagull score increase to",seagull_score)
	rpc("client_update_score", student_score, seagull_score)
	client_update_score(student_score,seagull_score)
	
	var no_chips_left = true
	var students = get_tree().get_nodes_in_group("student")
	for student in students:
		if student.has_chips:
			no_chips_left = false
			return
			
	if no_chips_left:
		print("Starting new round...")
		server_start_round()
		
@rpc("any_peer", "reliable")
func server_chips_delivered():
	if not multiplayer.is_server():
		return
	print("chips delivered function")
	student_score += 1
	print("student score increase to ", student_score)
	rpc("client_update_score", student_score, seagull_score)
	
	var no_chips_left = true
	var students = get_tree().get_nodes_in_group("student")
	for student in students:
		if student.has_chips:
			no_chips_left = false
			return
			
	if no_chips_left:
		print("Starting new round...")
		server_start_round()
	

@rpc("reliable", "any_peer")
func server_start_round():
	if not multiplayer.is_server():
		return
	
	# give all walking players chips
	rpc("client_get_chips")
	
	# Set scores back to 0
	student_score = 0
	seagull_score = 0
	rpc("client_update_score", student_score, seagull_score)
	
	# put a chip delivery point at a random cafe
	var student_spawn_points = get_tree().get_nodes_in_group("student_spawn_points")
	var random_spawn_point = student_spawn_points.pick_random()
	print("placing spawn point at " + random_spawn_point.name)

	var student_delivery_points = get_tree().get_nodes_in_group("student_delivery_points")
	var random_delivery_point = student_delivery_points.pick_random()
	print("placing chip delivery point at " + random_delivery_point.name)
	chip_delivery_point.position = random_delivery_point.position
	
	rpc("client_start_round", random_spawn_point.position, chip_delivery_point.position)
	
	# TODO: Start a timer for X minutes before round ends

@rpc("any_peer","reliable","call_local")
func client_start_round(spawn_pos, delivery_pos):
	var player = get_current_player()
	if is_seagull:
		player.position = delivery_pos
		player.position.y += 100
	else:
		player.position = spawn_pos
		
@rpc("authority","reliable", "call_local")
func client_update_score(w,s):
	print("received new score from server")
	var hud = get_tree().get_root().find_child("GameHud",true,false)
	hud.update_score_display(w, s)
	
@rpc("any_peer", "reliable", "call_local")
func client_get_chips():
	var player = get_current_player()
	if player.is_in_group("student") and player.is_multiplayer_authority():
		player.has_chips = true
	
func get_current_player():
	return get_node("/root/MainScene/%s" % [multiplayer.get_unique_id()])
