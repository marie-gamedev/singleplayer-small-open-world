extends Camera3D

@export var mesh_instance: MeshInstance3D # Drag your 3D mesh here
@export var scroll_sensitivity: float = 0.5 # Controls how fast it moves relative to your physical speed

var material: ShaderMaterial
var total_offset: Vector2 = Vector2.ZERO
var last_position: Vector3

func _ready() -> void:
	# Cache the position and fetch the shader material
	last_position = global_position
	
	# Assumes your material is in slot 0. Adjust if using Surface 1, 2, etc.
	material = mesh_instance.get_active_material(0) as ShaderMaterial

func _process(delta: float) -> void:
	if not material:
		return
		
	# 1. Calculate the spatial displacement vector since the last frame
	var frame_movement = global_position - last_position
	
	# 2. Convert 3D movement into a 2D offset vector 
	# (Here we use X and Z for ground movement. Switch to X and Y if it's a vertical game)
	var movement_2d = Vector2(frame_movement.x, frame_movement.z)
	
	# 3. Accumulate the movement into our total tracker
	total_offset += movement_2d * scroll_sensitivity
	
	# 4. Push the accumulated offset vector to the shader
	material.set_shader_parameter("movement_offset", total_offset)
	
	# Save current position for the next frame calculation
	last_position = global_position
