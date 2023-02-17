extends Node

const CREDENTIALS_FILE = "gopotify_credentials.txt"

export var client_id := ""
export var client_secret := ""
export var redirect_uri : = ""

var access_token := ""
var refresh_token := ""
var expires_in := 0
var issued_at := 0


var server: GopotifyAuthServer
var client: GopotifyClient


func _ready() -> void:
	self.read_credentials()

	self.client = GopotifyClient.new(self.client_id, self.client_secret, self.access_token, self.refresh_token, self.redirect_uri)
	add_child(self.client)

func _start_auth_server() -> void:
	self.server = GopotifyAuthServer.new(self.client)
	add_child(self.server)
	self.server.connect("credentials_received", self, "_on_credentials_received")

func _stop_auth_server() -> void:
	self.server.queue_free()
	self.server = null

func read_credentials() -> void:
	var file = File.new()
	if file.file_exists("user://" + CREDENTIALS_FILE):
		file.open("user://" + CREDENTIALS_FILE, File.READ)
		var parsed = JSON.parse(file.get_as_text())
		file.close()
		if not parsed.error:
			self.access_token = parsed.result["access_token"]
			self.refresh_token = parsed.result["refresh_token"]
			self.expires_in = parsed.result["expires_in"]
			self.issued_at = parsed.result["issued_at"]

func write_credentials(credentials: GopotifyAuthServer.GopotifyCredentials) -> void:
	var file = File.new()
	file.open("user://" + CREDENTIALS_FILE, File.WRITE)
	file.store_string(JSON.print({
		"access_token": credentials.access_token,
		"refresh_token": credentials.refresh_token,
		"expires_in": credentials.expires_in,
		"issued_at": credentials.issued_at
	}))
	file.close()

func play():
	self.client.play()

func pause():
	self.client.pause()

func request_user_authorization() -> void:
	self._start_auth_server()
	self.client.request_user_authorization()

func _on_credentials_received(credentials: GopotifyAuthServer.GopotifyCredentials) -> void:
	self.write_credentials(credentials)

	self.access_token = credentials["access_token"]
	self.refresh_token = credentials["refresh_token"]
	self.expires_in = credentials["expires_in"]
	self.issued_at = credentials["issued_at"]

	self._stop_auth_server()
