extends CharacterBody2D

@export var speed = 200

@export var attack_speed = 30
var delay = 0

var canGoLeft
var canGoRight

@onready var player = get_tree().get_first_node_in_group("player") as Player

enum State {
	IDLE,
	WALKING_LEFT,
	WALKING_RIGHT,
	CHASING,
	ATTACKING
}

var state = State.IDLE;
	
func _process(delta: float) -> void:
	canGoLeft = $AbyssCheckLeft.is_colliding()
	canGoRight = $AbyssCheckRight.is_colliding()
	
	var vectorToPlayer
	
	if player:
		vectorToPlayer = (global_position - player.global_position)
	else:
		vectorToPlayer = position
		
	match state:
		State.IDLE:
			velocity = Vector2(0, 0)
			$BodyTestSprite.modulate = Color(1,1,1)
			$rotating/Node2D/WeaponTestStprite.modulate = Color(1,1,1)
			
		State.CHASING:
			chase_player(vectorToPlayer, delta)
			
		State.WALKING_LEFT:
			if canGoLeft:
				move_and_collide(Vector2(-speed * delta, 0))
				$rotating.scale.x = -1
				
		State.WALKING_RIGHT:
			if canGoRight:
				move_and_collide(Vector2(speed * delta, 0))	
				$rotating.scale.x = 1
				
		State.ATTACKING:
			# Attack with a delay
			if delay >= attack_speed:
				delay = 0
				var wea := $rotating/Weapon as Area2D
				
				$AnimationPlayerRes.queue("Swing")
				$rotating/Node2D/WeaponTestStprite.modulate = Color(1,1,1)
				$BodyTestSprite.modulate = Color(1,1,1)
				
				for b in wea.get_overlapping_bodies():
					b.queue_free()
				
			else:
				$rotating/Node2D/WeaponTestStprite.modulate = Color(1,0,0)
				$BodyTestSprite.modulate = Color(1,0,0)
				delay += 1
	
	# Changing states
	if vectorToPlayer.length() < 150:
		state = State.CHASING
	else:
		if not (state == State.WALKING_LEFT and canGoLeft) and not (state == State.WALKING_RIGHT and canGoRight):
			state = State.WALKING_LEFT if canGoLeft else State.WALKING_RIGHT if canGoRight else State.IDLE
			$BodyTestSprite.modulate = Color(1,1,1)
			$rotating/Node2D/WeaponTestStprite.modulate = Color(1,1,1)
		
	if vectorToPlayer.length() < 50:
		state = State.ATTACKING
		
	if not is_on_floor():
		velocity.y += 300 * delta

func chase_player(vectorToPlayer: Vector2, delta: float):
	if vectorToPlayer.x > 0 and canGoLeft:
		$rotating.scale.x = -1
		move_local_x(-speed * delta)
	elif vectorToPlayer.x < 0 and canGoRight:
		$rotating.scale.x = 1
		move_local_x(speed * delta)
