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

var gliding : bool = false

const ANIMATION_BLEND : float = 7.0

@onready var player_mesh : Node3D = $Mesh
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var animator : AnimationTree = $AnimationTree

@export var animation_state: String = "grounded"
@export var movement_blend: float = -1.0

@onready var camera = %Camera3D

@onready var floor_raycast = $FloorRaycast
var in_air_time: float = 0

var npc_in_talkable_range : Npc
var is_dialogue_active : bool

var player_inputs_active : bool = true

@onready var env_interaction_scan = $EnvInteractionScan
var interactable_object_in_range : CollectibleItem = null


func _ready():
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _physics_process(delta):
	if player_inputs_active:
		if npc_in_talkable_range and Input.is_action_just_pressed("interact"):
			npc_in_talkable_range._start_dialogue()
		elif interactable_object_in_range and Input.is_action_just_pressed("interact"):
			PlayerInventory.add_item(interactable_object_in_range.item.item_id, 1)
			interactable_object_in_range.pickup()
			interactable_object_in_range = null
	
	if not gliding:
		velocity.y -= (gravity * delta)
	else:
		velocity.y = 0
		position.y -= gravity * delta * 0.1
	
	var move_direction : Vector3 = Vector3.ZERO
	var toggle_gliding
	var is_jumping
	if player_inputs_active:
		move_direction = _get_move_direction() 
		toggle_gliding = not is_on_floor() and Input.is_action_just_pressed("jump")
		is_jumping = is_on_floor() and Input.is_action_just_pressed("jump")
	
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	
	if move_direction:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
	
	if not is_on_floor():
		in_air_time += delta
	
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var on_trampoline := true if floor_raycast.is_colliding() and floor_raycast.get_collider() is Trampoline else false
	
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN
		gliding = false
		if on_trampoline:
			velocity.y = clampf(jump_strength + jump_strength * in_air_time**2, jump_strength, jump_strength*3)
			snap_vector = Vector3.ZERO
		in_air_time = 0
	elif toggle_gliding:
		gliding = !gliding
	
	apply_floor_snap()
	move_and_slide()
	animate(delta)
	_apply_animation()

func _get_move_direction() -> Vector3:
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	
	return move_direction

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

func _npc_entered_player_vicinity(npc):
	if npc is not Npc:
		push_error("Not an Npc!")
	
	npc_in_talkable_range = npc as Npc

func _npc_left_player_vicinity():
	npc_in_talkable_range = null

func _on_dialogue_started(resource: DialogueResource):
	is_dialogue_active = true
	_toggle_player_inputs()

func _on_dialogue_ended(resource: DialogueResource):
	is_dialogue_active = false
	_toggle_player_inputs()

func _toggle_player_inputs():
	player_inputs_active = not player_inputs_active


func _on_env_interaction_scan_body_entered(body):
	if body is not CollectibleItem:
		return
	
	print("interactable object detected!")
	interactable_object_in_range = body as CollectibleItem


func _on_env_interaction_scan_body_exited(body):
	if body is not CollectibleItem:
		return
		
	print("interactable object ouf of interaction area!")
	interactable_object_in_range = null
