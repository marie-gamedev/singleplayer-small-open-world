class_name ItemResourcesDatabse
extends Resource

@export var entries: Array[ItemData] = []

'func get_sound(organselections: Array[OrganSelection]) -> Array[AudioStream]:
	var sounds : Array
	for organselection in organselections:
		for entry in entries:
			if (entry.octave_height == organselection.octave_height
			and entry.melody == organselection.melody
			and entry.sound_type == organselection.sound_type):
				sounds.append(entry.sound)
	if sounds:
		return sounds
		
	print("sound not found :(")
	return [null]'
