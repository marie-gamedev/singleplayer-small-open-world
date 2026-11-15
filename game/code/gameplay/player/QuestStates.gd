extends Node

var flags: Dictionary[String, bool] = {}

func set_flag(flag_id: String, value: bool):
	flags[flag_id] = value

func has_flag(flag_id: String) -> bool:
	return flags.has(flag_id)

func is_flag(flag_id: String) -> bool:
	return flags.get(flag_id, false)
