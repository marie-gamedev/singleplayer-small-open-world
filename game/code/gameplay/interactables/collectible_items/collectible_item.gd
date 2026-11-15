class_name CollectibleItem extends StaticBody3D

@export var item : ItemData

#var disabled: bool

@onready var label = $Label
@onready var hitbox = $Hitbox

'func is_interactable() -> bool:
	if disabled:
		return false
	
	return true'

func pickup():
	queue_free()
