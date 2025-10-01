class_name Enemy
extends CharacterBody2D

@export var gravity = 800
@export var speed = 200

@export var attack_speed = 20
var delay = 0

var can_go_left
var can_go_right

var trying_to_hit_player = false
var being_hit_by_player = false
var attack_parred = false
var kickbacked = false

@onready var jump_timer = Timer.new()
@onready var kickbacked_timer = Timer.new()
@onready var player = get_tree().get_first_node_in_group("player") as Player

var vectorToPlayer

enum State {
	IDLE,
	WALKING_LEFT,
	WALKING_RIGHT,
	CHASING,
	ATTACKING
}

var state = State.IDLE;

func _ready() -> void:
	jump_timer.one_shot = true
	jump_timer.wait_time = 1
	add_child(jump_timer)
	
	kickbacked_timer.one_shot = true
	kickbacked_timer.wait_time = 1
	add_child(kickbacked_timer)
		
func _process(delta: float) -> void:
	can_go_left = $AbyssCheckLeft.is_colliding() and kickbacked_timer.is_stopped()
	can_go_right = $AbyssCheckRight.is_colliding() and kickbacked_timer.is_stopped()
	
	if player:
		vectorToPlayer = (global_position - player.global_position)
	else:
		vectorToPlayer = position
		
		
	match state:
		State.IDLE:
			velocity.x = 0
			
		State.CHASING:
			if vectorToPlayer.length() > 30:
				chase_player(vectorToPlayer, delta)
			
		State.WALKING_LEFT:
			if can_go_left:
				velocity.x = -speed
				var can_jump = $WallCheckLeft.is_colliding() and not $CantJumpOverCheckLeft.is_colliding() and is_on_floor() and jump_timer.is_stopped()
				
				if can_jump:
					velocity.y -= 200
					jump_timer.start()
				
				move_and_slide()
				$rotating.scale.x = -1
				
		State.WALKING_RIGHT:
			if can_go_right:
				velocity.x = speed
				var can_jump = $WallCheckRight.is_colliding() and not $CantJumpOverCheckRight.is_colliding() and is_on_floor() and jump_timer.is_stopped()
				
				if can_jump:
					velocity.y -= 200
					jump_timer.start()
				
				move_and_slide()
				$rotating.scale.x = 1
				
		State.ATTACKING:
			# Attack with a delay
			if delay >= attack_speed:
				delay = 0
				
				$AnimationPlayerRes.queue("Swing")
			else:
				$rotating/Node2D/WeaponTestStprite.modulate = Color(1,0,0)
				$BodyTestSprite.modulate = Color(1,0,0)
				delay += 1
	
	# Changing states
	if delay == 0:
		if vectorToPlayer.length() < 150:
			state = State.CHASING
		else:
			if not (state == State.WALKING_LEFT and can_go_left) and not (state == State.WALKING_RIGHT and can_go_right):
				if is_on_floor():
					state = State.WALKING_LEFT if can_go_left else State.WALKING_RIGHT if can_go_right else State.IDLE
				else:
					if (state == State.WALKING_LEFT and not can_go_left) or (state == State.WALKING_RIGHT and not can_go_right):
						state = State.IDLE
					
		
		if vectorToPlayer.length() < 50:
			state = State.ATTACKING
			
	
	if kickbacked:
		kickbacked = false
		velocity.x += vectorToPlayer.x * 8
		velocity.y -= 100
		move_and_slide()
		
	var playerIgnorer = $IgnoreSomeFloors as Area2D
	if not is_on_floor() or len(playerIgnorer.get_overlapping_bodies()) > 0:
		velocity.y += gravity * delta
		move_and_slide()
	
	

func chase_player(vectorToPlayer: Vector2, delta: float):
	if vectorToPlayer.x > 0 and (can_go_left or ($CanJumpOffPlatformLeft.is_colliding() and not $AbyssCheckLeft.is_colliding())):
		$rotating.scale.x = -1
		velocity.x = -speed
		var can_jump = ($WallCheckLeft.is_colliding() 
			and not $CantJumpOverCheckLeft.is_colliding() 
			and is_on_floor() 
			or ($CanJumpOffPlatformLeft.is_colliding() and not $AbyssCheckLeft.is_colliding())
			and jump_timer.is_stopped())
				
		if can_jump:
			velocity.y -= 200
			jump_timer.start()
			
		move_and_slide()
		
	elif vectorToPlayer.x < 0 and (can_go_right or ($CanJumpOffPlatformRight.is_colliding() and not $AbyssCheckRight.is_colliding())):
		$rotating.scale.x = 1
		velocity.x = speed
		
		var can_jump = ($WallCheckRight.is_colliding() 
			and not $CantJumpOverCheckRight.is_colliding() 
			and is_on_floor() 
			or ($CanJumpOffPlatformRight.is_colliding() and not $AbyssCheckRight.is_colliding())
			and jump_timer.is_stopped())
				
		if can_jump:
			velocity.y -= 200
			jump_timer.start()
			
		move_and_slide()


func _on_animation_player_res_animation_started(anim_name: StringName) -> void:
	match anim_name:
		"Swing":
			trying_to_hit_player = true
		"RESET":
			$rotating/Node2D/WeaponTestStprite.modulate = Color(1,1,1)
			$BodyTestSprite.modulate = Color(1,1,1)




func _on_animation_player_res_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Swing":
			trying_to_hit_player = false
			if not attack_parred:
				var wea := $rotating/Weapon as Area2D
				for b in wea.get_overlapping_bodies():
					b.queue_free()
			else:
				kickbacked = true
				kickbacked_timer.start()
				move_and_slide()
			attack_parred = false
			$AnimationPlayerRes.queue("RESET")
