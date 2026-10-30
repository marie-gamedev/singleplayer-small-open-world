extends BaseLevel

@onready var player_spawn : Marker3D = $PlayerSpawn

## Provides a player spawn location
func get_default_player_spawn() -> Vector3:
	return player_spawn.global_position

## Provides the camera used in the level
func get_player_camera() -> Camera3D:
	return null
