tool
extends HTTPRequest

export var client_id := ""
export var client_secret := ""
const AUTH_URL := "https://accounts.spotify.com/api/"
const SPOTIFY_BASE_URL := "https://api.spotify.com/v1/"
var token = ""
var request_handler_id = null

var port: int = 8080
var bind_address: String = "*"

onready var _auth_server = TCP_Server.new()

func _ready():
	connect("request_completed", self, "_on_request_completed")
	var err: int = self._auth_server.listen(self.port, self.bind_address)
	match err:
		22:
			_print_debug("Could not bind to port %d, already in use" % [self.port])
			stop()
		_:
			_print_debug("Server listening on http://%s:%s" % [self.bind_address, self.port])

func stop():
	for client in self._clients:
		client.disconnect_from_host()
	self._clients.clear()
	self._server.stop()
	set_process(false)
	_print_debug("Server stopped.")

func _print_debug(message: String) -> void:
	var time = OS.get_datetime()
	var time_return = "%02d-%02d-%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	print_debug("[SERVER] ",time_return," >> ", message)

func play():
	var result = self._spotify_request("me/player/play", HTTPClient.METHOD_PUT)

func pause():
	var result = self._spotify_request("me/player/pause", HTTPClient.METHOD_PUT)

func get_player_state():
	var result = self._spotify_request("me/player", HTTPClient.METHOD_GET)

func _spotify_request(path: String, http_method: int, body: String = "", retries: int = 1):
	self.request_handler_id = [path, http_method]
	var headers = self._get_headers()
	var url = SPOTIFY_BASE_URL + path
	return request(
		url,
		self._get_headers(),
		true,
		http_method,
		body
	)

func _get_headers() -> Array:
	return [
		"Authorization: Bearer " + token,
		"Content-Type: application/json"
	]

func refresh_access_token():
	var encoded_credentials = Marshalls.utf8_to_base64(client_id+":"+client_secret)
	var headers = [
		"Authorization: Basic " + encoded_credentials,
		"Content-Type: application/x-www-form-urlencoded",
	]
	var path = "token"
	var url = AUTH_URL + path
	var method = HTTPClient.METHOD_POST
	self.request_handler_id = [path, method]
	var response = request(
		url,
		headers,
		true,
		method,
		"grant_type=client_credentials"
	)

func _on_request_completed(result, response_code, headers, body):
	print(str(self.request_handler_id) + " trying to match " + str(["token", HTTPClient.METHOD_POST]))
	match(self.request_handler_id):
		["me/player", HTTPClient.METHOD_GET]:
			print("me/player")
		["me/player/play", HTTPClient.METHOD_PUT]:
			print(result)
			print(response_code)
			print(body.get_string_from_utf8())
		["me/player/pause", HTTPClient.METHOD_PUT]:
			print(result)
			print(response_code)
			print(body.get_string_from_utf8())
		["token", HTTPClient.METHOD_POST]:
			# TODO handle errors
			var parsed_body = parse_json(body.get_string_from_utf8())
			self.token = parsed_body["access_token"]
			print(self.token)
		_:
			print("No handler matched")

	self.request_handler_id = null
