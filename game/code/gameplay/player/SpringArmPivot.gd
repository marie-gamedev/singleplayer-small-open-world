extends Node3D

@export_group("Camera modes")
@export var third_person_distance: float = 2.0
@export var transition_duration: float = 0.25

@export_group("FOV")
@export var change_fov_on_run : bool
@export var normal_fov : float = 75.0
@export var run_fov : float = 90.0

const CAMERA_BLEND : float = 0.05

@onready var spring_arm : SpringArm3D = $SpringArm3D
@onready var camera : Camera3D = $SpringArm3D/Camera3D

var is_first_person: bool = false
var camera_tween: Tween

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.spring_length = third_person_distance

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func toggle_camera_mode():
	set_first_person(not is_first_person)
	print("toggled camera mode to ", is_first_person)

func set_first_person(enabled: bool):
	if is_first_person == enabled:
		return
	
	is_first_person = enabled
	
	spring_arm.spring_length = 0 if enabled else third_person_distance

func _physics_process(_delta):
	if change_fov_on_run:
		if owner.is_on_floor():
			if Input.is_action_pressed("run"):
				camera.fov = lerp(camera.fov, run_fov, CAMERA_BLEND)
			else:
				camera.fov = lerp(camera.fov, normal_fov, CAMERA_BLEND)
		else:
			camera.fov = lerp(camera.fov, normal_fov, CAMERA_BLEND)
