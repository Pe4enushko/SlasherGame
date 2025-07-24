class_name Player
extends CharacterBody2D

@export var gravity = 800
@export var speed = 250

var direction
var dash_smoothing = 1
@onready var dash_timer = Timer.new()
var dash_ready = true

@onready var camera = self.find_child("Camera2D") as Camera2D


func _ready() -> void:
	dash_timer.wait_time = 0.4
	dash_timer.one_shot = true
	dash_timer.timeout.connect(on_dash_timeout)
	add_child(dash_timer)
	
	

func on_dash_timeout():
	dash_ready = true

func get_input():
	direction = Input.get_axis("ui_left","ui_right")
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y -= 400
	
	if Input.is_action_just_pressed("dash") and dash_ready:
		#16 is to sharpen dash at the start
		direction *= 16
		dash_ready = false
		dash_timer.start()
	
	if Input.is_action_just_pressed("attack"):
		$AnimationPlayer.play("Swing")
		$AnimationPlayer.queue("RESET")
		
		var wea := $rotating/Weapon as Area2D
		for b in wea.get_overlapping_bodies():
			var e = b as Enemy
			if e and e.trying_to_hit_player:
				e.attack_parred = true
				camera.translate(Vector2(-10,0))
				camera.translate(Vector2(10,0))
				camera.translate(Vector2(0,0))
			else:
				b.queue_free()

func _exit_tree() -> void:
	#leave camera on after death
	var camera = Camera2D.new()
	camera.global_position = global_position
	
	get_tree().root.add_child(camera)
	print("GG")

func _physics_process(delta: float) -> void:
	get_input()
	#turn right
	if Input.is_action_just_pressed("ui_right"):
		$rotating.scale.x = 1
	#turn left
	if Input.is_action_just_pressed("ui_left"):
		$rotating.scale.x = -1
	
	# Dash with quadric function acceleration
	if !dash_timer.is_stopped():
		var t = dash_timer.wait_time
		var x = (t - dash_timer.time_left) * 2
		var y = -2.5*pow(x,2) + 1.3*x + 2
		direction *= y
	
	# lerp used for smooth 
	if not is_on_floor():
		velocity.y += 800 * delta * 1.3 
		velocity.x = lerpf(velocity.x, speed * (int(dash_ready) + 1) * direction, 0.2)
	else:
		velocity.x = lerpf(velocity.x, speed * direction, 0.2)
		
	velocity.x = lerpf(velocity.x, 0, 0.01)
	
	move_and_slide()
	
