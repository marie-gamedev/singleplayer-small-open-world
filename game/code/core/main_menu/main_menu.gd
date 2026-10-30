extends Node2D

const MAIN_GAME_SCENE := preload("res://code/core/main_game/main_game.tscn")
var main_game : MainGame

@onready var menu_ui = $MenuUI

func _ready():
	pass # Replace with function body.


func _process(delta):
	pass

func _on_play_btn_pressed():
	main_game = MAIN_GAME_SCENE.instantiate() as MainGame
	
	if main_game == null:
		push_error("Failed to instantiate MainGame!")
		return
	
	get_tree().root.add_child(main_game)
	menu_ui.visible = false
