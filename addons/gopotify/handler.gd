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

	self.client = GopotifyClient.new(self.client_id, self.client_secret, self.access_token, self.refresh_token)
	self.client.name = "client"
	add_child(self.client)

func _start_auth_server():
	self.server = GopotifyAuthServer.new()
	add_child(self.server)
	self.server.connect("code_received", self, "_on_code_received")

func _stop_auth_server():
	self.server.queue_free()
	self.server = null

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

func _update_credentials(json_credentials: Dictionary):
	self.write_credentials(json_credentials)

	self.access_token = json_credentials["access_token"]
	self.refresh_token = json_credentials["refresh_token"]
	self.expires_in = json_credentials["expires_in"]
	self.issued_at = json_credentials["issued_at"]

	self.client.set_tokens(self.access_token, self.refresh_token)

func request_user_authorization():
	self._start_auth_server()
	self.client.request_user_authorization()

func play():
	self.client.play()

func pause():
	self.client.pause()

func _on_code_received(request, response):
	var code = request.query.get("code")

	var credentials = yield(self.client.request_new_credentials(code, self.redirect_uri), "completed")
	if credentials:
		self._update_credentials(credentials)
		response.send(200, "<h1>Todo chido</h1>")
	else:
		response.send(500, "<h1>algo salió mal</h1>")
	self._stop_auth_server()
