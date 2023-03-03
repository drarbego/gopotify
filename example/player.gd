extends Control


func _on_PlayPause_pressed():
	var player_state = JSON.parse(
		yield($Gopotify.get_player_state(), "completed").body.get_string_from_ascii()
	).result
	if player_state["is_playing"]:
		$Gopotify.pause()
		$CenterContainer/HBoxContainer/PlayPause.text = "|>"
	else:
		$Gopotify.play()
		$CenterContainer/HBoxContainer/PlayPause.text = "||"

func _on_Next_pressed():
	$Gopotify.next()

func _on_Previous_pressed():
	$Gopotify.previous()
