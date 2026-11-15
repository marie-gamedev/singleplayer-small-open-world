class_name Npc
extends Node3D

var player_in_area : bool

@onready var key: String = DMSettings.get_user_value("run_key")
@export var resource: DialogueResource

#func _ready() -> void:
	#DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _start_dialogue():
	print("starting dialogue with npc!")
	DialogueManager.show_dialogue_balloon(resource, key if not key.is_empty() else resource.first_cue)

func _on_area_3d_body_entered(body):
	if body is Player:
		print("player entered npc area yey!")
		player_in_area = true
		body._npc_entered_player_vicinity(self)

func _on_area_3d_body_exited(body):
	if body is Player:
		print("player exited npc area yey!")
		player_in_area = false
		body._npc_left_player_vicinity()
