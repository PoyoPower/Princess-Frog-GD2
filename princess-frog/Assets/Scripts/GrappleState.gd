extends Node
class_name Grapple

# Config (can be adjusted externally from player)
var max_rope_length := 125.0
var grapple_collision_mask := 1
var grapple_jump_boost_multiplier := 1.2
var min_grapple_jump_strength := 300.0
var max_grapple_jump_strength := 800.0
var tension_threshold := 0.8
var rope_extend_speed := 600.0
var swing_boost_strength := 800.0

# Grapple State
var is_grappling = false
var grapple_extending = false
var grapple_points: Array = []
var current_grapple_length = 0.0

func start_grapple(point: Vector2):
	is_grappling = false
	grapple_extending = true
	grapple_points = [point]
	current_grapple_length = 0.0

func release_grapple(player):
	if is_grappling:
		var swing_velocity = player.velocity.length()
		var jump_strength = clamp(
			swing_velocity * grapple_jump_boost_multiplier,
			min_grapple_jump_strength,
			max_grapple_jump_strength
		)
		if swing_velocity > 0:
			var launch_direction = player.velocity.normalized()
			player.velocity = launch_direction * jump_strength

	is_grappling = false
	grapple_extending = false
	grapple_points.clear()

	if player.has_node("GrappleLine"):
		var line = player.get_node("GrappleLine")
		line.clear_points()
		line.visible = false
	if player.has_node("GrappleHook"):
		player.get_node("GrappleHook").visible = false

func process_grapple(player, delta):
	var space_state = player.get_world_2d().direct_space_state

	if grapple_extending:
		if grapple_points.size() == 0:
			release_grapple(player)
			return

		var total_distance = player.global_position.distance_to(grapple_points[0])
		current_grapple_length += rope_extend_speed * delta
		current_grapple_length = clamp(current_grapple_length, 0.0, total_distance)

		var direction_to_target = (grapple_points[0] - player.global_position).normalized()
		var ray_end = player.global_position + direction_to_target * current_grapple_length

		var query = PhysicsRayQueryParameters2D.create(player.global_position, ray_end)
		query.exclude = [player]
		query.collision_mask = grapple_collision_mask

		var result = space_state.intersect_ray(query)

		var hit_position = ray_end
		var valid_hit = false

		if result:
			hit_position = result.position
			valid_hit = true
			grapple_points[0] = hit_position
			current_grapple_length = player.global_position.distance_to(grapple_points[0])
			grapple_extending = false
			is_grappling = true

		var rope_end_local = direction_to_target * current_grapple_length

		if player.has_node("GrappleLine"):
			var line = player.get_node("GrappleLine")
			line.clear_points()
			line.add_point(Vector2.ZERO)
			line.add_point(rope_end_local)
			line.visible = true

		if player.has_node("GrappleHook"):
			var hook = player.get_node("GrappleHook")
			hook.visible = true
			hook.position = rope_end_local
			hook.rotation = direction_to_target.angle()

		if current_grapple_length >= total_distance and not valid_hit:
			release_grapple(player)

	elif is_grappling and not grapple_extending:
		update_grapple_wrap_points(player, space_state)
		apply_grapple_physics(player, delta)
		draw_rope(player)

	else:
		if player.has_node("GrappleLine"):
			var line = player.get_node("GrappleLine")
			line.clear_points()
			line.visible = false
		if player.has_node("GrappleHook"):
			player.get_node("GrappleHook").visible = false

func update_grapple_wrap_points(player, space_state):
	if grapple_points.size() == 0:
		return

	var from_pos = player.global_position
	var next_point = grapple_points[0]

	var query = PhysicsRayQueryParameters2D.create(from_pos, next_point)
	query.exclude = [player]
	query.collision_mask = grapple_collision_mask

	var result = space_state.intersect_ray(query)

	if result:
		var collision_point = result.position
		if grapple_points.size() == 0 or collision_point.distance_to(grapple_points[0]) > 1.0:
			grapple_points.insert(0, collision_point)
	else:
		if grapple_points.size() > 1:
			var second_point = grapple_points[1]
			var query2 = PhysicsRayQueryParameters2D.create(player.global_position, second_point)
			query2.exclude = [player]
			query2.collision_mask = grapple_collision_mask

			var result2 = space_state.intersect_ray(query2)
			if not result2:
				grapple_points.remove_at(0)

func apply_grapple_physics(player, delta):
	if grapple_points.size() == 0:
		release_grapple(player)
		return

	player.velocity.y += player.gravity * delta

	var to_grapple = grapple_points[0] - player.global_position
	var dist_to_grapple = to_grapple.length()

	if dist_to_grapple > max_rope_length:
		var rope_dir = to_grapple.normalized()
		var corrected_position = grapple_points[0] - rope_dir * max_rope_length
		player.global_position = corrected_position

		var tangent = Vector2(-rope_dir.y, rope_dir.x)
		var tangential_speed = player.velocity.dot(tangent)
		player.velocity = tangent * tangential_speed

	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		var tangent = Vector2(-to_grapple.normalized().y, to_grapple.normalized().x)
		player.velocity += tangent * input_dir * swing_boost_strength * delta

func draw_rope(player):
	if grapple_points.size() == 0:
		if player.has_node("GrappleLine"):
			var line = player.get_node("GrappleLine")
			line.clear_points()
			line.visible = false
		if player.has_node("GrappleHook"):
			player.get_node("GrappleHook").visible = false
		return

	var line = player.get_node("GrappleLine")
	line.clear_points()
	line.add_point(Vector2.ZERO)

	for point in grapple_points:
		var local_point = point - player.global_position
		line.add_point(local_point)

	line.visible = true

	if player.has_node("GrappleHook"):
		var hook = player.get_node("GrappleHook")
		hook.visible = true
		hook.position = grapple_points[-1] - player.global_position

		var last_segment_dir = Vector2.ZERO
		if grapple_points.size() > 1:
			last_segment_dir = (grapple_points[-1] - grapple_points[-2]).normalized()
		else:
			last_segment_dir = (grapple_points[-1] - player.global_position).normalized()
		hook.rotation = last_segment_dir.angle()
