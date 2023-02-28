extends HTTPRequest
class_name GopotifyClient

const AUTH_URL := "https://accounts.spotify.com/"
const SPOTIFY_BASE_URL := "https://api.spotify.com/v1/"
const SCOPES = [
	"user-modify-playback-state",
	"user-read-playback-state"
]

var client_id: String
var client_secret: String
var port: int
var credentials: GopotifyCredentials

var server: GopotifyAuthServer

signal credentials_updated(credentials)


class GopotifyResponse:
	var status_code: int
	var headers: PoolStringArray
	var body: PoolByteArray

	func _init(_status_code, _headers, _body):
		self.status_code = _status_code
		self.headers = _headers
		self.body = _body

	func _to_string():
		return "[{0}]\n{1}".format([self.status_code, self.body.get_string_from_ascii()])


func _init(_client_id, _client_secret, _port, _credentials) -> void:
	self.client_id = _client_id
	self.client_secret = _client_secret
	self.port = _port
	self.credentials = _credentials

func _start_auth_server() -> void:
	self.server = GopotifyAuthServer.new(self)
	add_child(self.server)

func _stop_auth_server() -> void:
	self.server.queue_free()
	self.server = null

func request_new_credentials(code) -> GopotifyCredentials:
	var url = AUTH_URL + "api/token/"
	var data = self._build_query_params({
		"grant_type": "authorization_code",
		"code": code,
		"redirect_uri": self._get_redirect_uri()
	})
	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Authorization: Basic " + self._build_basic_authorization_header_token(),
		"Content-Length: " + str(len(data))
	]

	var result = yield(self.simple_request(HTTPClient.METHOD_POST, url, headers, data), "completed")
	if result[1] == HTTPClient.RESPONSE_OK:
		var json_result = JSON.parse(result[3].get_string_from_ascii()).result
		return GopotifyCredentials.new(
			json_result["access_token"],
			json_result["refresh_token"],
			int(json_result["expires_in"]),
			OS.get_unix_time()
		)

	return null

func request_user_authorization() -> void:
	self._start_auth_server()
	var url = AUTH_URL + "authorize/"
	var result = yield(
		self.simple_request(
			HTTPClient.METHOD_GET,
			url,
			[],
			"",
			{
				"client_id": self.client_id,
				"response_type": "code",
				"redirect_uri": self._get_redirect_uri(),
				"scope": ",".join(SCOPES)
			}
		),
		"completed"
	)
	var code_url = result[2][2].substr(10)
	OS.shell_open(code_url)

func set_credentials(credentials: GopotifyCredentials) -> void:
	self.credentials = credentials

	emit_signal("credentials_updated", credentials)

	self._stop_auth_server()

func _get_redirect_uri() -> String:
	return "http://localhost:{port}{endpoint}".format({"port": self.port, "endpoint": GopotifyAuthServer.AUTH_ENDPOINT})

func _build_basic_authorization_header_token() -> String:
	return Marshalls.utf8_to_base64(client_id+":"+client_secret)

func _build_query_params(params: Dictionary = {}) -> String:
	var param_array = PoolStringArray()

	for key in params:
		param_array.append(str(key) + "=" + str(params[key]))

	return "&".join(param_array)

func _spotify_request(path: String, http_method: int, body: String = "", retries: int = 1) -> GopotifyResponse:
	if retries < 0:
		return null

	var headers = [
		"Authorization: Bearer " + self.credentials.access_token,
		"Content-Type: application/json",
		"Content-Length: " + str(len(body))
	]
	var url = SPOTIFY_BASE_URL + path

	if not self.credentials:
		self.request_user_authorization()
		yield(self.server, "credentials_received")
		return self._spotify_request(path, http_method, body, retries-1)

	var raw_response = yield(self.simple_request(http_method, url, headers, body), "completed")
	var response = GopotifyResponse.new(raw_response[1], raw_response[2], raw_response[3])
	print(response)
	if self.credentials.is_expired() or response.status_code == 401:
		self.request_user_authorization()
		yield(self.server, "credentials_received")
		return self._spotify_request(path, http_method, body, retries-1)

	return response

func simple_request(method: int, url: String, headers: Array = [], body: String = "", params: Dictionary = {}):
	var query_params = "?" + self._build_query_params(params)

	self.request(
		url + query_params,
		headers,
		true,
		method,
		body
	)

	return yield(self, "request_completed")

func play() -> GopotifyResponse:
	return yield(self._spotify_request("me/player/play", HTTPClient.METHOD_PUT), "completed")

func pause() -> GopotifyResponse:
	return yield(self._spotify_request("me/player/pause", HTTPClient.METHOD_PUT), "completed")

func get_player_state() -> GopotifyResponse:
	return yield(self._spotify_request("me/player", HTTPClient.METHOD_GET), "completed")
