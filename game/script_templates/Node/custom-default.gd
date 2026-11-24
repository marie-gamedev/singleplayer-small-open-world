# meta-description: Base template for Node with default Godot cycle methods

#class_name
extends _BASE_

## Short Description
##

# signals
# enums
# constants (CONSTANT_CASE)
# export variables (snake_case)
# public variables (non-underscore-prefixed snake_case)
# private variables (underscore-prefixed _snake_case)
# onready variables (snake_case)

# built in virtual methods (init, enter_tree, ready, process, physics_process)
func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	pass

# public methods (a_func)
# private methods (_a_func)
# callbacks/ signals
