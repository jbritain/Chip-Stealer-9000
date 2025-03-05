extends PanelContainer

func _process(delta: float) -> void:
	$StartGameButton.visible = multiplayer.is_server()


func _on_start_game_button_pressed() -> void:
	if multiplayer.is_server():
		GlobalHandler.start_game()


func _on_game_timer_timeout() -> void:
	if !multiplayer.is_server():
		return
		
	GlobalHandler.server_end_game()
