extends StaticBody2D


func _on_ActivationArea_body_entered(body):
	var player_state = yield($Gopotify.get_player_state(), "completed")
	print(player_state)
	if player_state.is_playing:
		$Gopotify.pause()
	else:
		$Gopotify.play()
