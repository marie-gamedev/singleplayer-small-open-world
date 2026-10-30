@tool
extends EditorScript

## Applies the baseline project settings used by this project.
const PROJECT_SETTINGS : Dictionary = {
	"display/window/size/viewport_width": 1920,
	"display/window/size/viewport_height": 1080,
	"display/window/stretch/mode": "canvas_items",
	"display/window/stretch/aspect": "keep",
	"display/window/stretch/scale_mode": "fractional",
	"application/config/version": "0.1.0",
	"display/window/size/window_width_override": 960,
	"display/window/size/window_height_override": 540,
}

const PHYSICS_3D_LAYERS : Dictionary = {
	1: "World",
	2: "Player",
	3: "Interactable",
}

func _run() -> void:
	_apply_project_settings()
	_apply_layer_names()

	var error : Error = ProjectSettings.save()

	if error == OK:
		print("Project setup settings saved.")
	else:
		push_error("Project settings could not be saved. Error: " + str(error))


func _apply_project_settings() -> void:
	for setting_path: String in PROJECT_SETTINGS:
		ProjectSettings.set_setting(setting_path, PROJECT_SETTINGS[setting_path])


func _apply_layer_names() -> void:
	for layer_number: int in PHYSICS_3D_LAYERS:
		ProjectSettings.set_setting(
			"layer_names/3d_physics/layer_%d" % layer_number,
			PHYSICS_3D_LAYERS[layer_number]
		)
