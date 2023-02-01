extends Node2D


func _on_Play_pressed():
	$SpotifyClient.play()

func _on_Pause_pressed():
	$SpotifyClient.pause()

func _on_RefreshToken_pressed():
	$SpotifyClient.refresh_access_token()
