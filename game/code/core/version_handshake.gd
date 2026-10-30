extends RefCounted

signal version_mismatch(host_version: String)
signal version_accepted
signal authentication_failed

var api: SceneMultiplayer
var version: String


func _init(multiplayer_api: SceneMultiplayer, game_version: String) -> void:
	api = multiplayer_api
	version = game_version
	api.auth_callback = _receive_version
	api.peer_authenticating.connect(_send_version)
	api.peer_authentication_failed.connect(_authentication_failed)


func _send_version(peer_id: int) -> void:
	api.send_auth(peer_id, version.to_utf8_buffer())


func _receive_version(peer_id: int, data: PackedByteArray) -> void:
	var remote_version := data.get_string_from_utf8()
	if version.is_empty() or remote_version != version:
		if not api.is_server() and peer_id == 1:
			version_mismatch.emit(remote_version if not remote_version.is_empty() else "unknown")
		# Never admit a mismatched peer. Let the client receive our version and
		# disconnect; auth_timeout also removes clients that do not disconnect.
		return
	if not api.is_server() and peer_id == 1:
		# Create replicated scene paths before allowing gameplay packets.
		version_accepted.emit()
	api.complete_auth(peer_id)


func _authentication_failed(peer_id: int) -> void:
	if not api.is_server() and peer_id == 1:
		authentication_failed.emit()
