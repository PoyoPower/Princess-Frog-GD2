extends Node

var wall_jump_force = -400
var wall_jump_lock_time = 0.0
var wall_jump_acceleration = 0.5
var wall_jump_deceleration = 0.5

var wall_jump_lock_timer = 0.0

func process_wall_jump(velocity: Vector2, on_wall: bool, on_floor: bool, wall_info: Dictionary, direction: float, is_climbing: bool, is_wall_hugging: bool, input_down: bool) -> Vector2:
	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= get_process_delta_time()

	if wall_jump_lock_timer <= 0 and Input.is_action_just_pressed("jump") and on_wall and not on_floor:
		velocity.y = wall_jump_force
		if wall_info["left"]:
			velocity.x = -wall_jump_force
		elif wall_info["right"]:
			velocity.x = wall_jump_force
		
		if input_down:
			velocity.y = wall_jump_force * -1
		
		if not is_climbing and is_wall_hugging:
			velocity.y = 0
			velocity.x = move_toward(velocity.x, direction * abs(wall_jump_force), wall_jump_force * wall_jump_acceleration)
		else:
			velocity.x = move_toward(velocity.x, direction * abs(wall_jump_force), wall_jump_force * wall_jump_deceleration)
		
		wall_jump_lock_timer = wall_jump_lock_time

	return velocity

func get_lock_timer() -> float:
	return wall_jump_lock_timer
