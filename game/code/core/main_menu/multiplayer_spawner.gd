extends MultiplayerSpawner

@export var player: PackedScene

func _init() -> void:
	spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
	if player == null:
		push_error("MultiplayerSpawner has no player scene configured.")
		return null
	if not data is Dictionary:
		push_error("Player spawn data must be a Dictionary.")
		return null
	if not data.has("peer_id") or not data.has("initial_position") or not data.has("display_name"):
		push_error("Player spawn data is missing peer_id, initial_position, or display_name.")
		return null

	var spawned_player := player.instantiate() as Player
	if spawned_player == null:
		push_error("Configured player scene must instantiate a Player.")
		return null
	var peer_id := int(data["peer_id"])
	spawned_player.initial_position = data["initial_position"]
	spawned_player.display_name = str(data["display_name"])
	spawned_player.name = str(peer_id)
	spawned_player.set_multiplayer_authority(peer_id)
	return spawned_player
