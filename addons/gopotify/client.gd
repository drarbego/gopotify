extends HTTPRequest
class_name GopotifyClient

const AUTH_URL := "https://accounts.spotify.com/"
const SPOTIFY_BASE_URL := "https://api.spotify.com/v1/"

var client_id := ""
var client_secret := ""
var redirect_uri := ""

var access_token := ""
var refresh_token := ""
var expires_in := 0
var issued_at := 0

var server: GopotifyAuthServer

signal credentials_updated(credentials)

class Callback:
	var function_reference: FuncRef
	var arguments: Array

	func _init(_func_ref: FuncRef, _arguments: Array):
		self.function_reference = _func_ref
		self.arguments = _arguments

	func exec():
		return self.function_reference.call_funcv(self.arguments)


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


func _init(_client_id, _client_secret, _redirect_uri, _credentials) -> void:
	self.client_id = _client_id
	self.client_secret = _client_secret
	self.redirect_uri = _redirect_uri
	if _credentials:
		self.access_token = _credentials.access_token
		self.refresh_token = _credentials.refresh_token
		self.expires_in = _credentials.expires_in
		self.issued_at = _credentials.issued_at

func _start_auth_server(callback=null) -> void:
	self.server = GopotifyAuthServer.new(self, callback)
	add_child(self.server)

func _stop_auth_server() -> void:
	self.server.queue_free()
	self.server = null

func request_new_credentials(code):
	var url = AUTH_URL + "api/token/"
	var data = self._build_query_params({
		"grant_type": "authorization_code",
		"code": code,
		"redirect_uri": self.redirect_uri
	})
	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Authorization: Basic " + self._build_basic_authorization_header_token(),
		"Content-Length: " + str(len(data))
	]

	var result = yield(self.simple_request(HTTPClient.METHOD_POST, url, headers, data), "completed")
	if result[1] == HTTPClient.RESPONSE_OK:
		var json_result = JSON.parse(result[3].get_string_from_ascii()).result
		return {
			"access_token": json_result["access_token"],
			"refresh_token": json_result["refresh_token"],
			"expires_in": int(json_result["expires_in"]),
			"issued_at": OS.get_unix_time()
		}

	return null

func request_user_authorization(callback: Callback = null) -> void:
	self._start_auth_server(callback)
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
				"redirect_uri": "http://localhost:8889/callback",
				"scope": "user-modify-playback-state"
			}
		),
		"completed"
	)
	var code_url = result[2][2].substr(10)
	OS.shell_open(code_url)

func receive_credentials(credentials: GopotifyAuthServer.GopotifyCredentials) -> void:
	# self.write_credentials(credentials)

	self.access_token = credentials["access_token"]
	self.refresh_token = credentials["refresh_token"]
	self.expires_in = credentials["expires_in"]
	self.issued_at = credentials["issued_at"]

	emit_signal("credentials_updated", credentials)

	self._stop_auth_server()

func _build_basic_authorization_header_token() -> String:
	return Marshalls.utf8_to_base64(client_id+":"+client_secret)

func _build_query_params(params: Dictionary = {}) -> String:
	var param_array = PoolStringArray()

	for key in params:
		param_array.append(str(key) + "=" + str(params[key]))

	return "&".join(param_array)

func _spotify_request(path: String, http_method: int, body: String = "", retries: int = 1) -> GopotifyResponse:
	var headers = [
		"Authorization: Bearer " + self.access_token,
		"Content-Type: application/json",
		"Content-Length: " + str(len(body))
	]
	var url = SPOTIFY_BASE_URL + path
	var response = yield(self.simple_request(http_method, url, headers, body), "completed")
	return GopotifyResponse.new(response[1], response[2], response[3])

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

func set_tokens(access: String, refresh: String):
	self.access_token = access
	self.refresh_token = refresh

func play(retries=1) -> GopotifyResponse:
	if retries < 0:
		return null

	var response = yield(self._spotify_request("me/player/play", HTTPClient.METHOD_PUT), "completed")
	if response.status_code == 401:
		var callback = Callback.new(funcref(self, "play"), [retries-1])
		self.request_user_authorization(callback)
	return response

func pause() -> GopotifyResponse:
	return yield(self._spotify_request("me/player/pause", HTTPClient.METHOD_PUT), "completed")

func get_player_state() -> GopotifyResponse:
	return yield(self._spotify_request("me/player", HTTPClient.METHOD_GET), "completed")
