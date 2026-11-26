class_name ReactObject
extends Node3D
## Environment Interaction Object with different Input and Output Types
## that can be mix and matched to create different objects and interactions

signal perform_output

enum InputType {TOUCH, OBSERVE}

enum OutputType {GLOW, SOUND, COLORCHANGE}

@export var input : InputType = InputType.TOUCH
@export var output : OutputType = OutputType.GLOW
@export var objects_to_glow : Array[MeshInstance3D]

var _player : Player

@onready var output_sound = $OutputSound

func _ready():
	_player = get_tree().get_first_node_in_group("player")

# OUTPUT LOGIC
func _on_perform_output():
	match output:
		OutputType.GLOW:
			_output_glow()
		OutputType.SOUND:
			_output_sound()
		OutputType.COLORCHANGE:
			_output_color_change()

func _output_glow():
	print("glow!")
	for object in objects_to_glow:
		var amount = object.get_surface_override_material_count()
		print("meow-1")
		for i in amount:
			var mat = object.get_surface_override_material(i)
			print("meow0")
			if not mat is ShaderMaterial:
				continue
			
			print("meow")
			var tween = create_tween()
			
			tween.tween_property(mat, "shader_parameter/glow_intensity", 5.0, 0.1)
			
			tween.tween_property(mat, "shader_parameter/glow_intensity", 0.0, 5.0)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)

func _output_sound():
	print("play sound!")
	output_sound.play()

func _output_color_change():
	print("change color")


# INPUT LOGIC
func _on_touch_area_3d_body_entered(body):
	if body == _player:
		perform_output.emit()
