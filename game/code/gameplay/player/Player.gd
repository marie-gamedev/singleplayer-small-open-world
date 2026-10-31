class_name Player
extends CharacterBody3D

const LERP_VALUE : float = 0.15

var snap_vector : Vector3 = Vector3.DOWN
var speed : float

@export_group("Movement variables")
@export var walk_speed : float = 3.0
@export var run_speed : float = 9.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

const ANIMATION_BLEND : float = 7.0

@onready var player_mesh : Node3D = $Mesh
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var animator : AnimationTree = $AnimationTree

@export var animation_state: String = "grounded"
@export var movement_blend: float = -1.0

@onready var camera = %Camera3D

@onready var floor_raycast = $FloorRaycast
var in_air_time: float = 0

func _ready():
	pass

func _physics_process(delta):
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	velocity.y -= gravity * delta
	
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	
	if move_direction:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
	
	if not is_on_floor():
		in_air_time += delta
	
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
	var on_trampoline := true if floor_raycast.is_colliding() and floor_raycast.get_collider() is Trampoline else false
	
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN
		if on_trampoline:
			print("first value= ", jump_strength + jump_strength * in_air_time**2)
			print("added jump strength = ", clampf(jump_strength + jump_strength * in_air_time, jump_strength, jump_strength*3))
			velocity.y = clampf(jump_strength + jump_strength * in_air_time**2, jump_strength, jump_strength*3)
			snap_vector = Vector3.ZERO
		in_air_time = 0
	
	apply_floor_snap()
	move_and_slide()
	animate(delta)
	_apply_animation()

func animate(delta):
	if is_on_floor():
		animation_state = "grounded"
		
		if velocity.length() > 0.1:
			if speed == run_speed:
				movement_blend = move_toward(movement_blend, 1.0, delta * ANIMATION_BLEND)
			else:
				movement_blend = move_toward(movement_blend, 0.0, delta * ANIMATION_BLEND)
		else:
			movement_blend = move_toward(movement_blend, - 1.0, delta *ANIMATION_BLEND)
	else:
		animation_state = "air"

func _apply_animation() -> void:
	animator.set("parameters/ground_air_transition/transition_request",animation_state)
	animator.set("parameters/iwr_blend/blend_amount", movement_blend)
