extends HTTPRequest
class_name GopotifyClient

const AUTH_URL := "https://accounts.spotify.com/"
const SPOTIFY_BASE_URL := "https://api.spotify.com/v1/"

var client_id := ""
var client_secret := ""
var access_token := ""
var refresh_token := ""


func _init(_client_id, _client_secret, _access_token, _refresh_token):
	self.client_id = _client_id
	self.client_secret = _client_secret
	self.access_token = _access_token
	self.refresh_token = _refresh_token

func request_new_credentials(code, redirect_uri):
	var url = AUTH_URL + "api/token/"
	var data = self._build_query_params({
		"grant_type": "authorization_code",
		"code": code,
		"redirect_uri": redirect_uri
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

func request_user_authorization():
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

func _build_basic_authorization_header_token():
	return Marshalls.utf8_to_base64(client_id+":"+client_secret)

func _build_query_params(params: Dictionary = {}):
	var param_array = PoolStringArray()

	for key in params:
		param_array.append(str(key) + "=" + str(params[key]))

	return "&".join(param_array)

func _spotify_request(path: String, http_method: int, body: String = "", retries: int = 1):
	var headers = [
		"Authorization: Bearer " + access_token,
		"Content-Type: application/json",
		"Content-Length: " + str(len(body))
	]
	var url = SPOTIFY_BASE_URL + path
	return yield(self.simple_request(http_method, url, headers, body), "completed")

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

func play():
	var result = yield(self._spotify_request("me/player/play", HTTPClient.METHOD_PUT), "completed")

func pause():
	var result = yield(self._spotify_request("me/player/pause", HTTPClient.METHOD_PUT), "completed")

func get_player_state():
	var result = self._spotify_request("me/player", HTTPClient.METHOD_GET)
