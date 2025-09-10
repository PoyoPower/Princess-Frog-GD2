extends Node

@export var wall_hug_slide_speed = 0.0
@export var wall_run = 2

func process_climbing_and_wall_hugging(on_wall: bool, on_floor: bool, climb_input: float) -> Dictionary:
	var is_climbing = on_wall and climb_input != 0
	var is_wall_hugging = on_wall and not on_floor and climb_input == 0
	return {
		"is_climbing": is_climbing,
		"is_wall_hugging": is_wall_hugging
	}

func get_velocity_y(is_climbing: bool, is_wall_hugging: bool, climb_input: float) -> float:
	if is_climbing:
		return climb_input
	elif is_wall_hugging:
		return wall_hug_slide_speed
	return 0
