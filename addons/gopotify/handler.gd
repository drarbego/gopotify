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


func _ready():
	self.read_credentials()

	self.server = GopotifyAuthServer.new()
	add_child(self.server)
	self.server.connect("code_received", self, "_on_code_received")

	self.client = GopotifyClient.new(self.client_id, self.client_secret, self.access_token, self.refresh_token)
	self.client.name = "client"
	add_child(self.client)
	self.client.connect("update_credentials", self, "_on_update_credentials")

func read_credentials():
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

func write_credentials(credentials: Dictionary):
	var file = File.new()
	file.open("user://" + CREDENTIALS_FILE, File.WRITE)
	file.store_string(JSON.print(credentials))
	file.close()

func _on_update_credentials(
	_access_token: String,
	_refresh_token: String,
	_expires_in: int,
	_issued_at: int
	):
	self.write_credentials({
		"access_token": _access_token,
		"refresh_token": _refresh_token,
		"expires_in": _expires_in,
		"issued_at": _issued_at
	})

	self.access_token = _access_token
	self.refresh_token = _refresh_token
	self.expires_in = _expires_in
	self.issued_at = _issued_at

	self.client.access_token = self.access_token
	self.client.refresh_token = self.refresh_token

func request_user_authorization():
	self.client.request_user_authorization()

func play():
	self.client.play()

func pause():
	self.client.pause()

func _on_code_received(request, response):
	var code = request.query.get("code")

	var result = yield(self.client.request_new_credentials(code, self.redirect_uri), "completed")
	print(result)

	response.send(200, "<h1>Todo chido</h1>")
