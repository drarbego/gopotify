extends Node

const CREDENTIALS_FILE = "gopotify_credentials.txt"

export var client_id := ""
export var client_secret := ""
export var redirect_uri : = ""

var access_token := ""
var refresh_token := ""
var expires_in := 0
var issued_at := 0


var client: GopotifyClient


func _ready() -> void:
	var credentials = self.read_credentials()
	self.client = GopotifyClient.new(self.client_id, self.client_secret, self.redirect_uri, credentials)
	add_child(self.client)
	self.client.connect("credentials_updated", self, "write_credentials")

func read_credentials() -> GopotifyAuthServer.GopotifyCredentials:
	var file = File.new()
	if file.file_exists("user://" + CREDENTIALS_FILE):
		file.open("user://" + CREDENTIALS_FILE, File.READ)
		var parsed = JSON.parse(file.get_as_text())
		file.close()
		if not parsed.error:
			return GopotifyAuthServer.GopotifyCredentials.new(
				parsed.result["access_token"],
				parsed.result["refresh_token"],
				parsed.result["expires_in"],
				parsed.result["issued_at"]
			)

	return null

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
	var response = yield(self.client.play(), "completed")

func pause():
	var response = self.client.pause()

func request_user_authorization() -> void:
	self.client.request_user_authorization()
