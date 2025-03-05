extends PanelContainer

func _process(delta: float) -> void:
	$StartGameButton.visible = multiplayer.is_server()


func _on_start_game_button_pressed() -> void:
	if multiplayer.is_server():
		GlobalHandler.server_start_round()
