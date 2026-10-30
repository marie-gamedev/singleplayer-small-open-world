class_name MainGame
extends Node

@onready var multiplayer_spawner = $Systems/MultiplayerSpawner

const LEVEL_PROTOTYPE = "uid://wxw3v1fy8mr5"

var player : Player = null

var _current_level : BaseLevel = null
signal level_loaded
var is_level_ready := false

# Game World root nodes
@onready var level_root = $World/LevelRoot
@onready var entity_root = $World/EntityRoot
@onready var effect_root = $World/EffectRoot

# UI Root Nodes
@onready var hud_root = $HUDLayer/HudRoot
@onready var pause_root = $PauseLayer/PauseRoot
@onready var transition_root = $TransitionLayer/TransitionRoot
@onready var debug_root = $DebugLayer/DebugRoot

func _ready():
	load_level(LEVEL_PROTOTYPE)

func _process(delta):
	pass

func register_player(new_player : Player) -> void:
	if not new_player.is_multiplayer_authority():
		return
	
	player = new_player
	
	# TODO
	#if has_loaded_level():
		 #setuplevelcamera
	
	print("[GAME] Local player registed: ", player.name)

'func _init_player() -> void:
	var player_scene : PackedScene = PLAYER_SCENE_UID
	if player_scene == null:
		push_error("Could not load player scene: ", PLAYER_SCENE_UID)
		return
	
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Loaded player scene does not extend player ", PLAYER_SCENE_UID)
		return
	
	entity_root.add_child(player)
	print("player initialized!")
	'
	
func load_level(level_scene : String) -> void:
	_deferred_load_level.call_deferred(level_scene)

func _deferred_load_level(level_scene_uid : String) -> void:
	is_level_ready = false
	
	if _current_level != null:
		_current_level.queue_free()
		_current_level = null
	
	await get_tree().process_frame
	
	var new_level_packed : PackedScene =\
		ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	if new_level_packed == null:
		push_error("Could not load level as a packed scene: ", level_scene_uid)
		return
	
	_current_level = new_level_packed.instantiate() as BaseLevel
	if _current_level == null:
		push_error("Loaded level is not of type level or does not exist")
		return
		# TODO (main menu): fall back scene
	
	level_root.add_child(_current_level)
	
	await get_tree().process_frame
	
	is_level_ready = true
	level_loaded.emit()
	
	print("[GAME] Level loaded!")
	#_place_player_at_level_spawn()
	#_setup_level_camera()

func has_loaded_level() -> bool:
	return is_level_ready and is_instance_valid(_current_level) and not _current_level.is_queued_for_deletion()

func get_player_spawn_position() -> Vector3:
	if _current_level == null:
		push_error("Cannot get spawn pos: no level loaded!")
		return Vector3.ZERO
	
	return _current_level.get_default_player_spawn()
'
func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level, because player is null")
		return
	if _current_level == null:
		push_error("Cannot place player in level, because level is null")
		return
	
	player.global_position = _current_level.get_default_player_spawn()'

func _setup_level_camera() -> void:
	if player == null or _current_level == null:
		return
	
	var level_camera : Camera3D = _current_level.get_player_camera()
	if level_camera == null:
		return
	
	# TODO hook up camera to player
