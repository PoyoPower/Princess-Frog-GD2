extends Node
@export var animation_player: AnimationPlayer
@export var walk_speed = 150.0
@export var run_speed = 250.0
@export var acceleration = 0.1
@export var deceleration = 0.1

func get_speed(is_running: bool) -> float:
	return run_speed if is_running else walk_speed

func calculate_velocity_x(velocity_x: float, direction: float, speed: float) -> float:
	if direction != 0:
		return move_toward(velocity_x, direction * speed, speed * acceleration)
	else:
		return move_toward(velocity_x, 0, speed * deceleration)
	
