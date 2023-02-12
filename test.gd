extends Node2D


func _on_Play_pressed():
	$Gopotify.play()

func _on_Pause_pressed():
	$Gopotify.pause()

func _on_RefreshToken_pressed():
	$Gopotify.request_user_authorization()
