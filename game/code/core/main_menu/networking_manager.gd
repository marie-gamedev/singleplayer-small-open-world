class_name NetworkBootstrap
extends Node

const MAIN_GAME_SCENE := preload("res://code/core/main_game/main_game.tscn")
const VERSION_HANDSHAKE := preload("res://code/core/version_handshake.gd")
#const VOICE_CHAT := preload("res://scripts/networking/voice_chat.gd")

enum NetworkMode { LAN, STEAM }

@export var enet_port: int = 7777
@export var enet_max_clients: int = 16
var is_joining : bool = false
var network_mode := NetworkMode.LAN
var steam_initialized := false
var ready_peers: Dictionary = {}
var current_lobby_code := ""
var lan_player_numbers: Dictionary = {}
var next_lan_player_number := 1

@onready var join_button: Button = $MenuUI/join_button
@onready var id_prompt: LineEdit = $MenuUI/id_prompt
@onready var network_mode_selector: OptionButton = $MenuUI/network_mode
@onready var menu: Control = $MenuUI

var main_game: MainGame
var version_handshake: RefCounted
var join_error: AcceptDialog
#var voice_chat: ProximityVoiceChat

func _ready() -> void:
	#voice_chat = VOICE_CHAT.new()
	#voice_chat.name = "VoiceChat"
	#add_child(voice_chat)
	join_error = AcceptDialog.new()
	join_error.title = "Unable to join"
	add_child(join_error)
	version_handshake = VERSION_HANDSHAKE.new(multiplayer as SceneMultiplayer,
		str(ProjectSettings.get_setting("application/config/version", "")))
	version_handshake.version_mismatch.connect(_on_version_mismatch)
	version_handshake.version_accepted.connect(join_world)
	version_handshake.authentication_failed.connect(_on_authentication_failed)
	print("[NET][BOOT] networking manager ready; peer_id=", multiplayer.get_unique_id())
	network_mode_selector.clear()
	network_mode_selector.add_item("Local / LAN (ENet)", NetworkMode.LAN)
	network_mode_selector.add_item("Steam", NetworkMode.STEAM)
	network_mode_selector.select(NetworkMode.LAN)
	_update_network_mode_ui()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected_debug)

func _initialize_steam() -> bool:
	if steam_initialized:
		return true

	var result = Steam.steamInit(480, true)
	print("[NET][STEAM] initialized: ", result)
	if result != true:
		push_error("[NET][STEAM] Steam initialization failed")
		return false

	steam_initialized = true
	Steam.initRelayNetworkAccess()
	if not Steam.lobby_created.is_connected(_on_lobby_created):
		Steam.lobby_created.connect(_on_lobby_created)
	if not Steam.lobby_joined.is_connected(_on_lobby_joined):
		Steam.lobby_joined.connect(_on_lobby_joined)
	return true

func _on_peer_connected_debug(peer_id: int) -> void:
	print("[NET][SIGNAL] peer_connected; local_peer=", multiplayer.get_unique_id(), " remote_peer=", peer_id, " server=", multiplayer.is_server())

func _on_version_mismatch(host_version: String) -> void:
	_show_join_error.call_deferred("version mismatch, doesnt match hosts game version: " + host_version)

func _on_authentication_failed() -> void:
	if is_joining:
		_show_join_error.call_deferred("Could not verify the host's game version. Connection rejected.")

func _show_join_error(message: String) -> void:
	_leave_session()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	join_error.dialog_text = message
	join_error.popup_centered()

func _on_connection_failed() -> void:
	print("[NET][SIGNAL] connection_failed; local_peer=", multiplayer.get_unique_id())
	_leave_session()

func _on_server_disconnected() -> void:
	print("[NET][SIGNAL] server_disconnected; local_peer=", multiplayer.get_unique_id())
	_leave_session()

func host_lobby() -> void:
	if not _initialize_steam():
		return
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)
	print("host lobby")


func _on_lobby_created(result: int, lobby_id: int) -> void:
	print("[NET][HOST] lobby_created; result=", result, " lobby_id=", lobby_id)
	if result == Steam.Result.RESULT_OK:
		current_lobby_code = str(lobby_id)
		var steam_peer := SteamMultiplayerPeer.new()
		steam_peer.server_relay = true
		steam_peer.create_host()

		# The replicated nodes must exist before networking starts. Otherwise a
		# synchronizer packet can arrive while /root/World is still missing.
		join_world()
		print("[NET][HOST] main_game added; assigning multiplayer peer")
		multiplayer.multiplayer_peer = steam_peer
		print("[NET][HOST] peer assigned; peer_id=", multiplayer.get_unique_id(), " server=", multiplayer.is_server())
		if not multiplayer.peer_disconnected.is_connected(_remove_player):
			multiplayer.peer_disconnected.connect(_remove_player)
		spawn_player_when_ready()

		print("Lobby created, lobby id: ", lobby_id)
		DisplayServer.clipboard_set(str(lobby_id))

func join_lobby(lobby_id: int) -> void:
	if not _initialize_steam():
		return
	print("[NET][CLIENT] requesting lobby join; lobby_id=", lobby_id)
	is_joining = true
	Steam.joinLobby(lobby_id)

func _on_lobby_joined(id: int, _permissions: int, _locked: bool, _response: int) -> void:
	print("[NET][CLIENT] lobby_joined callback; id=", id, " is_joining=", is_joining, " response=", _response)
	if !is_joining:
		print("[NET][CLIENT] ignoring lobby_joined because is_joining is false")
		return
	if _response != 1:
		push_error("[NET][CLIENT] Steam lobby join failed; response=" + str(_response) + " lobby_id=" + str(id))
		is_joining = false
		menu.visible = true
		return

	var lobby_owner := Steam.getLobbyOwner(id)
	if lobby_owner == 0:
		push_error("[NET][CLIENT] Steam returned no lobby owner for lobby_id=" + str(id))
		is_joining = false
		menu.visible = true
		return

	var steam_peer := SteamMultiplayerPeer.new()
	steam_peer.server_relay = true
	steam_peer.create_client(lobby_owner)
	current_lobby_code = str(id)
	print("[NET][CLIENT] Steam peer created; owner=", lobby_owner, " status=", steam_peer.get_connection_status())
	# Version authentication creates the main_game only after the host matches.
	multiplayer.multiplayer_peer = steam_peer
	print("[NET][CLIENT] peer assigned; peer_id=", multiplayer.get_unique_id(), " status=", steam_peer.get_connection_status())

func _on_connected_to_server() -> void:
	is_joining = false
	print("[NET][CLIENT] connected_to_server emitted; peer_id=", multiplayer.get_unique_id())
	print("[NET][CLIENT] waiting for local main_game/synchronizer")
	await _wait_for_main_game()
	print("[NET][CLIENT] main_game/synchronizer ready; sending client_world_ready RPC to host")
	var requested_display_name := ""
	if network_mode == NetworkMode.STEAM:
		requested_display_name = Steam.getPersonaName()
	_client_world_ready.rpc_id(1, requested_display_name)
	print("[NET][CLIENT] client_world_ready RPC queued")

@rpc("any_peer", "call_remote", "reliable")
func _client_world_ready(requested_display_name: String = "") -> void:
	print("[NET][HOST] client_world_ready RPC received; sender=", multiplayer.get_remote_sender_id(), " server=", multiplayer.is_server())
	if not multiplayer.is_server():
		print("[NET][HOST] rejecting ready RPC because this peer is not server")
		return

	var peer_id := multiplayer.get_remote_sender_id()
	if ready_peers.has(peer_id):
		print("[NET][HOST] peer already marked ready; peer_id=", peer_id)
		return

	ready_peers[peer_id] = true
	print("[NET][HOST] peer marked ready; beginning player spawn; peer_id=", peer_id)
	spawn_player_when_ready(peer_id, requested_display_name)

func _wait_for_main_game() -> MainGame:
	while true:
		var main_game := get_tree().get_first_node_in_group("main_game") as MainGame
		
		if main_game != null and main_game.has_loaded_level():
			return main_game
		
		await get_tree().process_frame
	
	return null

func spawn_player_when_ready(peer_id: int = 1, requested_display_name: String = "") -> void:
	var main_game := await _wait_for_main_game()
	
	if not multiplayer.is_server():
		return
	
	_add_player(peer_id, requested_display_name, main_game.get_player_spawn_position())

func _add_player(peer_id: int, requested_display_name: String, spawn_position: Vector3) -> void:
	if not multiplayer.is_server():
		return
	
	if not is_instance_valid(main_game):
		push_error("Cannot spawn player: MainGame doesnt exist :(")
		return
	
	var display_name := requested_display_name.strip_edges()
	
	if network_mode == NetworkMode.LAN:
		display_name = _get_lan_player_name(peer_id)
	elif display_name.is_empty():
		display_name = "Player"
	
	var spawned_player = main_game.multiplayer_spawner.spawn({
		"peer_id": peer_id,
		"initial_position": spawn_position,
		"display_name": display_name,
	})
	
	if spawned_player == null:
		push_error("Failed to spawn player : ", str(peer_id))
		return
	
	print("[NET][HOST] MultiplayerSpawner.spawn returned; target_peer=", peer_id)

func _get_lan_player_name(peer_id: int) -> String:
	if not lan_player_numbers.has(peer_id):
		lan_player_numbers[peer_id] = next_lan_player_number
		next_lan_player_number += 1
	return "Pirrrate %d" % int(lan_player_numbers[peer_id])

func _remove_player(id: int) -> void:
	ready_peers.erase(id)
	lan_player_numbers.erase(id)
	if !self.has_node(str(id)):
		return

	self.get_node(str(id)).queue_free()

func host_enet() -> void:
	var enet_peer := ENetMultiplayerPeer.new()
	var error := enet_peer.create_server(enet_port, enet_max_clients)
	if error != OK:
		push_error("[NET][ENET] Could not host on port %d: %s" % [enet_port, error_string(error)])
		return

	join_world()
	multiplayer.multiplayer_peer = enet_peer
	if not multiplayer.peer_disconnected.is_connected(_remove_player):
		multiplayer.peer_disconnected.connect(_remove_player)
	spawn_player_when_ready()
	print("[NET][ENET] Hosting on port ", enet_port)

func join_enet(address: String) -> void:
	if address.strip_edges().is_empty():
		address = "127.0.0.1"

	var enet_peer := ENetMultiplayerPeer.new()
	var error := enet_peer.create_client(address.strip_edges(), enet_port)
	if error != OK:
		push_error("[NET][ENET] Could not connect to %s:%d: %s" % [address, enet_port, error_string(error)])
		return

	is_joining = true
	multiplayer.multiplayer_peer = enet_peer
	print("[NET][ENET] Connecting to %s:%d" % [address, enet_port])


func _on_host_button_pressed() -> void:
	if network_mode == NetworkMode.LAN:
		host_enet()
	else:
		host_lobby()

func join_world() -> void:
	if is_instance_valid(main_game):
		menu.visibile = false
		return
	
	main_game = MAIN_GAME_SCENE.instantiate() as MainGame
	
	if main_game == null:
		push_error("Failed to instantiate MainGame!")
		return
	
	get_tree().root.add_child(main_game)
	menu.visible = false
	print("[NET] join_world adding World; peer_id=", multiplayer.get_unique_id())

func _on_id_prompt_text_changed(new_text: String) -> void:
	join_button.disabled = network_mode == NetworkMode.STEAM and new_text.length() == 0

func _on_join_button_pressed() -> void:
	if network_mode == NetworkMode.LAN:
		join_enet(id_prompt.text)
	else:
		join_lobby(id_prompt.text.to_int())

func _on_network_mode_item_selected(index: int) -> void:
	network_mode = network_mode_selector.get_item_id(index)
	_update_network_mode_ui()

func _update_network_mode_ui() -> void:
	if network_mode == NetworkMode.LAN:
		id_prompt.placeholder_text = "Server address (127.0.0.1)"
		id_prompt.text = "127.0.0.1"
		join_button.disabled = false
	else:
		id_prompt.placeholder_text = "Steam Lobby ID"
		id_prompt.text = ""
		join_button.disabled = true

func _leave_session() -> void:
	#voice_chat.reset_session()
	for child in get_children():
		if child.is_in_group("player"):
			child.queue_free()
	is_joining = false
	if steam_initialized and not current_lobby_code.is_empty():
		Steam.leaveLobby(current_lobby_code.to_int())
	current_lobby_code = ""
	ready_peers.clear()
	lan_player_numbers.clear()
	next_lan_player_number = 1
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if main_game != null and is_instance_valid(main_game):
		main_game.queue_free()
	main_game = null
	menu.visible = true
