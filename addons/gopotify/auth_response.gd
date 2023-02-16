extends Reference
class_name GopotifyAuthResponse

const status_code_to_text = {
	200: "OK",
	400: "Bad Request",
	404: "Not Found",
	418: "I'm a Teapot",
	500: "Internal Server Error"
}

# The client currently talking to the server
var client: StreamPeer

# A dictionary of headers
# Headers can be set using the `set(name, value)` function
var headers: Dictionary = {}

# Send out a raw (Bytes) response to the client
# Useful to send files faster or raw data which will be converted by the client
#
# #### Parameters
# - status: The HTTP status code to send
# - data: The body data to send []
# - content_type: The type of the content to send ["text/html"]
func send_raw(status_code: int, data: PoolByteArray = [], content_type: String = "application/octet-stream") -> void:
	client.put_data(("HTTP/1.1 %d %s\r\n" % [status_code, status_code_to_text.get(status_code, "OK")]).to_ascii())
	client.put_data("Server: Gopotify\r\n".to_ascii())
	for header in headers.keys():
		client.put_data(("%s: %s\r\n" % [header, headers[header]]).to_ascii())

	client.put_data(("Content-Length: %d\r\n" % data.size()).to_ascii())
	client.put_data("Connection: close\r\n".to_ascii())
	client.put_data(("Content-Type: %s\r\n\r\n" % content_type).to_ascii())
	client.put_data(data)

# Send out a response to the client
#
# #### Parameters
# - status: The HTTP status code to send
# - data: The body data to send []
# - content_type: The type of the content to send ["text/html"]
func send(status_code: int, data: String = "", content_type = "text/html") -> void:
	send_raw(status_code, data.to_ascii(), content_type)
