extends Node2D


func _on_Play_pressed():
	$Spotidot.play()

func _on_Pause_pressed():
	$Spotidot.pause()

func _on_RefreshToken_pressed():
	$Spotidot.request_user_authorization()
