class_name PlayerController
extends CharacterBody2D

#  Movement config 
@export var walk_speed = 150.0
@export var run_speed = 250.0
@export_range(0, 1) var acceleration = 0.1
@export_range(0, 1) var deceleration = 0.1
@export var jump_force = -400
@export var wall_jump_force = -400
@export_range(0, 1) var decelerate_on_jump_release := 0.5
@export var wall_hug_slide_speed = 0.0
@export var wall_jump_lock_time = 0.0
@export var swing_boost_strength = 800.0  # Tweak this value to change boost power
#  Grapple config 
@export var max_rope_length := 200.0
var is_grappling = false
var grapple_point = Vector2.ZERO

#  Rope shoot animation 
var grapple_extending = false
var current_grapple_length = 0.0
var rope_extend_speed = 600.0

#  State 
var speed = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_climbing = false
var is_wall_hugging = false
var wall_jump_lock_timer = 0.0
var direction = 0.0
var is_crouching := false

#  Collision shapes 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var standing_shape: Shape2D
var crouching_shape: Shape2D

func _physics_process(delta: float) -> void:
	var on_wall = is_on_wall()
	var on_floor = is_on_floor()
	var wall_info = check_wall_collisions()

	# Apply gravity
	if not on_floor and not is_climbing:
		velocity.y += gravity * delta

	# Wall jump lock timer
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	# Climbing and wall hugging
	var climb_input := Input.get_axis("move_up", "move_down")
	is_climbing = on_wall and climb_input != 0
	is_wall_hugging = on_wall and not on_floor and climb_input == 0

	if is_climbing:
		velocity.y = climb_input * speed
	elif is_wall_hugging:
		velocity.y = wall_hug_slide_speed

	# Jump (disabled while crouching)
	if Input.is_action_just_pressed("jump") and not is_crouching:
		if on_floor:
			velocity.y = jump_force
		elif on_wall and not on_floor:
			velocity.y = wall_jump_force
			if wall_info["left"]:
				velocity.x = -wall_jump_force
			elif wall_info["right"]:
				velocity.x = wall_jump_force
			if Input.is_action_pressed("move_down"):
				velocity.y = wall_jump_force * -1
			wall_jump_lock_timer = wall_jump_lock_time

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Walking or running
	speed = run_speed if Input.is_action_pressed("run") else walk_speed

	# Movement
	if wall_jump_lock_timer <= 0.0:
		direction = Input.get_axis("move_left", "move_right")

		if is_crouching:
			velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)
		else:
			if direction != 0:
				velocity.x = move_toward(velocity.x, direction * speed, walk_speed * acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)

	
	# Rope Extend Animation
	
	if grapple_extending:
		var total_distance = global_position.distance_to(grapple_point)
		current_grapple_length += rope_extend_speed * delta
		current_grapple_length = clamp(current_grapple_length, 0.0, total_distance)

		if current_grapple_length > 0.0:
			var direction_to_target = (grapple_point - global_position).normalized()
			var rope_end_local = direction_to_target * current_grapple_length

			$GrappleLine.clear_points()
			$GrappleLine.add_point(Vector2.ZERO)
			$GrappleLine.add_point(rope_end_local)
			$GrappleLine.visible = true

			if $GrappleHook:
				$GrappleHook.visible = true
				$GrappleHook.position = rope_end_local
				$GrappleHook.rotation = direction_to_target.angle()

		if current_grapple_length >= total_distance:
			grapple_extending = false
			is_grappling = true

	
	# Grappling Physics
	
	if is_grappling and not grapple_extending:
		var to_grapple = grapple_point - global_position
		var dist_to_grapple = to_grapple.length()

		# Apply gravity
		velocity.y += gravity * delta

		# Apply rope constraint when too far
		if dist_to_grapple > max_rope_length:
			var rope_dir = to_grapple.normalized()
			var corrected_position = grapple_point - rope_dir * max_rope_length
			global_position = corrected_position

			# Preserve tangential velocity
			var tangent = Vector2(-rope_dir.y, rope_dir.x)
			var tangential_speed = velocity.dot(tangent)
			velocity = tangent * tangential_speed

		# Apply swing input boosts
		var input_dir = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			
			var tangent = Vector2(-to_grapple.normalized().y, to_grapple.normalized().x)
			velocity += tangent * input_dir * swing_boost_strength * delta

	
	# Rope Drawing While Swinging
	
	if is_grappling and not grapple_extending:
		var start_pos = Vector2.ZERO
		var end_pos_local = grapple_point - global_position

		$GrappleLine.clear_points()
		$GrappleLine.add_point(start_pos)
		$GrappleLine.add_point(end_pos_local)
		$GrappleLine.visible = true

		if $GrappleHook:
			$GrappleHook.visible = true
			$GrappleHook.position = end_pos_local
			$GrappleHook.rotation = (grapple_point - global_position).angle()
	else:
		if $GrappleLine:
			$GrappleLine.clear_points()
			$GrappleLine.visible = false
		if $GrappleHook:
			$GrappleHook.visible = false

	move_and_slide()


# Grapple input
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		start_grapple(get_global_mouse_position())
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		release_grapple()


func start_grapple(point: Vector2):
	is_grappling = false
	grapple_extending = true
	grapple_point = point
	current_grapple_length = 0.0


func release_grapple():
	is_grappling = false
	grapple_extending = false
	if $GrappleLine:
		$GrappleLine.clear_points()
		$GrappleLine.visible = false
	if $GrappleHook:
		$GrappleHook.visible = false


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
