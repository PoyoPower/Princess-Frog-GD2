extends Node2D

@export var player_controller: PlayerController
@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D

func _process(delta):
	if player_controller == null or animation_player == null or sprite == null:
		return

	var velocity = player_controller.velocity

	# Handle horizontal flipping
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

	# Prioritize vertical movement (jump/fall)
	if velocity.y < -1:
		animation_player.play("jump")
	elif velocity.y > 1:
		animation_player.play("fall")
		
	elif abs(velocity.x) > 1:
		animation_player.play("move")
	else:
		animation_player.play("idle")
		
	if player_controller.is_wall_hugging:
		animation_player.play("wall hug")
		
		
