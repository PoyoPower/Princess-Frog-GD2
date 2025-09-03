extends Node

var jump_force = -400
var decelerate_on_jump_release = 0.5


func apply_jump(velocity: Vector2, on_floor: bool, jump_pressed: bool, jump_released: bool) -> Vector2:
	if jump_pressed and on_floor:
		velocity.y = jump_force
	if jump_released and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
	return velocity
