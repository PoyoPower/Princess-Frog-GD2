class_name PlayerController
extends CharacterBody2D

# State
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0.0

# Load Grapple script and create instance
var Grapple = preload("res://Assets/Scripts/GrappleState.gd")  # Adjust path as needed
var grapple = null

func _ready():
	grapple = Grapple.new()

func _physics_process(delta: float) -> void:
	var on_wall = is_on_wall()
	var on_floor = is_on_floor()
	var wall_info = check_wall_collisions()

	# Apply gravity
	if not on_floor and not ClimbManager.process_climbing_and_wall_hugging(on_wall, on_floor, Input.get_axis("move_up", "move_down"))["is_climbing"]:
		velocity.y += gravity * delta

	# Wall jump lock timer
	var wall_jump_lock_timer = WallJumpManager.get_lock_timer()

	# Climbing and wall hugging state
	var climb_input = Input.get_axis("move_up", "move_down")
	var climb_state = ClimbManager.process_climbing_and_wall_hugging(on_wall, on_floor, climb_input)
	var is_climbing = climb_state["is_climbing"]
	var is_wall_hugging = climb_state["is_wall_hugging"]

	# Adjust vertical velocity
	if is_climbing:
		velocity.y = climb_input * MovementManager.get_speed(false)  # Use walk speed for climbing speed
	elif is_wall_hugging:
		velocity.y = ClimbManager.wall_hug_slide_speed

	# Wall jump processing
	velocity = WallJumpManager.process_wall_jump(velocity, on_wall, on_floor, wall_info, direction, is_climbing, is_wall_hugging, Input.is_action_pressed("move_down"))

	# Jump processing for floor jumps
	velocity = JumpManager.apply_jump(velocity, on_floor, Input.is_action_just_pressed("jump"), Input.is_action_just_released("jump"))

	# Walking or running speed
	var speed = MovementManager.get_speed(Input.is_action_pressed("run"))

	# Movement input and velocity.x adjustment only if wall jump lock is over
	if wall_jump_lock_timer <= 0.0:
		direction = Input.get_axis("move_left", "move_right")
		velocity.x = MovementManager.calculate_velocity_x(velocity.x, direction, speed)

	# Delegate grapple processing to Grapple module
	grapple.process_grapple(self, delta)

	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if grapple.is_grappling or grapple.grapple_extending:
			grapple.release_grapple(self)
		else:
			grapple.start_grapple(get_global_mouse_position())

func release_grapple():
	grapple.release_grapple(self)

func start_grapple(point: Vector2):
	grapple.start_grapple(point)

func check_wall_collisions() -> Dictionary:
	var wall_collision = {
		"left": false,
		"right": false
	}
	var margin = 1.0
	if test_move(global_transform, Vector2(margin, 0)):
		wall_collision["right"] = true
	if test_move(global_transform, Vector2(-margin, 0)):
		wall_collision["left"] = true
	return wall_collision
	
# In PlayerController.gd, add:

func get_is_wall_hugging() -> bool:
	var on_wall = is_on_wall()
	var on_floor = is_on_floor()
	var climb_input = Input.get_axis("move_up", "move_down")
	var climb_state = ClimbManager.process_climbing_and_wall_hugging(on_wall, on_floor, climb_input)
	return climb_state["is_wall_hugging"]
