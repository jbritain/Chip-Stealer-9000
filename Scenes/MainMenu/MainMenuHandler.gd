extends PanelContainer

@onready var seagull_selector = $"MarginContainer/VBoxContainer/isSeagull?"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_join_button_pressed() -> void:
	GlobalHandler.enet_peer.create_client($MarginContainer/VBoxContainer/addressLine.text, 9000)
	multiplayer.multiplayer_peer = GlobalHandler.enet_peer
	GlobalHandler.init_game_world()
	get_node("../GameLobby").show()
	hide()
	


func _on_host_button_pressed() -> void:
	GlobalHandler.enet_peer.create_server(9000)
	multiplayer.multiplayer_peer = GlobalHandler.enet_peer
	multiplayer.peer_connected.connect(GlobalHandler.handle_connected_peer)
	multiplayer.peer_disconnected.connect(GlobalHandler.handle_disconnected_peer)
	GlobalHandler.init_game_world()
	if GlobalHandler.is_seagull:
		GlobalHandler.add_seagull_player(multiplayer.get_unique_id(), GlobalHandler.username)
	else:
		GlobalHandler.add_walking_player(multiplayer.get_unique_id(), GlobalHandler.username)
	get_node("../GameLobby").show()
	hide()


func _on_is_seagull_toggled(toggled_on: bool) -> void:
	GlobalHandler.is_seagull = toggled_on


func _on_username_line_text_changed(new_text: String) -> void:
	GlobalHandler.username = new_text
