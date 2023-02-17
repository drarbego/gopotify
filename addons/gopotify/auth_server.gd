extends Node
class_name GopotifyAuthServer

var _method_regex: RegEx = RegEx.new()
var _header_regex: RegEx = RegEx.new()

var client: GopotifyClient

var port: int = 8889
var bind_address: String = "*"

var _clients: Array
var _server: TCP_Server

signal credentials_received(credentials)


class GopotifyAuthRequest:
	var headers: Dictionary
	var body: String
	var query_match: RegExMatch
	var path: String
	var method: String
	var parameters: Dictionary
	var query: Dictionary

	func _to_string() -> String:
		return JSON.print({headers=self.headers, method=self.method, path=self.path, query=self.query})

class GopotifyCredentials:
	var access_token: String
	var refresh_token: String
	var expires_in: int
	var issued_at: int

	func _init(_access_token, _refresh_token, _expires_in, _issued_at):
		self.access_token = _access_token
		self.refresh_token = _refresh_token
		self.expires_in = _expires_in
		self.issued_at = _issued_at

	func _to_string() -> String:
		return JSON.print({access_token=self.access_token, refresh_token=self.refresh_token, expires_in=self.expires_in, issued_at=self.issued_at})


func _init(_client: GopotifyClient):
	self.client = _client

func _ready():
	set_process(true)

	_method_regex.compile("^(?<method>GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS) (?<path>[^ ]+) HTTP/1.1$")
	_header_regex.compile("^(?<key>[^:]+): (?<value>.+)$")

	self._server = TCP_Server.new()
	var err: int = self._server.listen(self.port, self.bind_address)
	match err:
		22:
			print("Could not bind to port %d, already in use" % [self.port])
			self._server.stop()
		_:
			print("Server listening on http://%s:%s" % [self.bind_address, self.port])

func _exit_tree() -> void:
	for client in self._clients:
		client.disconnect_from_host()
	self._clients.clear()
	self._server.stop()

func _process(_delta: float) -> void:
	var new_client = self._server.take_connection()
	if new_client:
		self._clients.append(new_client)
	for client in self._clients:
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var bytes = client.get_available_bytes()
			if bytes > 0:
				var request_string = client.get_string(bytes)
				self._handle_request(client, request_string)

func _handle_request(client: StreamPeer, request_string: String):
	var request = self._build_request_from_string(request_string)
	var response = GopotifyAuthResponse.new()
	response.client = client
	if request.method == "GET" and request.path == "/callback":
		var code = request.query.get("code")

		var raw_credentials = yield(self.client.request_new_credentials(code), "completed")
		if raw_credentials:
			var credentials = GopotifyCredentials.new(
				raw_credentials["access_token"],
				raw_credentials["refresh_token"],
				raw_credentials["expires_in"],
				raw_credentials["issued_at"]
			)
			response.send(200, "<h1>Todo chido</h1>")
			emit_signal("credentials_received", credentials)
		else:
			response.send(500, "<h1>algo salió mal</h1>")
	else:
		response.send(404, "Not found")

func _build_request_from_string(request_string: String) -> GopotifyAuthRequest:
	var request = GopotifyAuthRequest.new()
	for line in request_string.split("\r\n"):
		var method_matches = _method_regex.search(line)
		var header_matches = _header_regex.search(line)
		if method_matches:
			request.method = method_matches.get_string("method")
			var request_path: String = method_matches.get_string("path")
			if not "?" in request_path:
				request.path = request_path
			else: # parse query parameters
				var path_query: PoolStringArray = request_path.split("?")
				request.path = path_query[0]
				request.query = _extract_query_params(path_query[1])
			request.headers = {}
			request.body = ""
		elif header_matches:
			request.headers[header_matches.get_string("key")] = \
			header_matches.get_string("value")
		else:
			request.body += line

	return request

func _extract_query_params(query_string: String) -> Dictionary:
	var query: Dictionary = {}
	if query_string == "":
		return query
	var parameters: Array = query_string.split("&")
	for param in parameters:
		if not "=" in param:
			continue
		var kv : Array = param.split("=")
		var value: String = kv[1]
		if value.is_valid_integer():
			query[kv[0]] = int(value)
		elif value.is_valid_float():
			query[kv[0]] = float(value)
		else:
			query[kv[0]] = value

	return query
