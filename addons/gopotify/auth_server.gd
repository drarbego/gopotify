extends Node
class_name GopotifyAuthServer

var _method_regex: RegEx = RegEx.new()
var _header_regex: RegEx = RegEx.new()

var port: int = 8889
var server_identifier: String = "GopotifyAuthServer"
var bind_address: String = "*"

var _clients: Array
var _server: TCP_Server

signal code_received(request)


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

func _exit_tree():
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
	var request = GopotifyAuthRequest.new()
	for line in request_string.split("\r\n"):
		var method_matches = _method_regex.search(line)
		var header_matches = _header_regex.search(line)
		if method_matches:
			request.method = method_matches.get_string("method")
			var request_path: String = method_matches.get_string("path")
			# Check if request_path contains "?" character, could be a query parameter
			if not "?" in request_path:
				request.path = request_path
			else:
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
	self._perform_current_request(client, request)

func _perform_current_request(client: StreamPeer, request: GopotifyAuthRequest):
	var found = false
	var response = GopotifyAuthResponse.new()
	response.client = client
	if request.method == "GET" and request.path == "/callback":
		emit_signal("code_received", request, response)
	else:
		response.send(404, "Not found")

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
