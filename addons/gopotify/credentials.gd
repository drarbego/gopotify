extends Reference

class_name GopotifyCredentials

var access_token: String
var refresh_token: String
var expires_in: int
var issued_at: int

func _init(_access_token, _refresh_token, _expires_in, _issued_at):
	self.access_token = _access_token
	self.refresh_token = _refresh_token
	self.expires_in = _expires_in
	self.issued_at = _issued_at

func is_expired() -> bool:
	return OS.get_unix_time() > self.issued_at + self.expires_in

func _to_string() -> String:
	return JSON.print({access_token=self.access_token, refresh_token=self.refresh_token, expires_in=self.expires_in, issued_at=self.issued_at})
