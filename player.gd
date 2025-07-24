class_name Player
extends CharacterBody2D

@export var speed = 250
var direction
var dash_smoothing = 1
@onready var dash_timer = Timer.new()
var dash_ready = true

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
		dash_smoothing = 16
		direction *= dash_smoothing
		dash_ready = false
		dash_timer.start()
	
	if Input.is_action_just_pressed("attack"):
		$AnimationPlayer.play("Swing")
		$AnimationPlayer.queue("RESET")
		
		var wea := $rotating/Weapon as Area2D
		for b in wea.get_overlapping_bodies():
			b.queue_free()

func _exit_tree() -> void:
	var camera = Camera2D.new()
	camera.global_position = global_position
	
	get_tree().root.add_child(camera)
	print("GG")

func _physics_process(delta: float) -> void:
	get_input()
	
	if Input.is_action_just_pressed("ui_right"):
		$rotating.scale.x = 1
	
	if Input.is_action_just_pressed("ui_left"):
		$rotating.scale.x = -1
	
	if !dash_timer.is_stopped():
		var t = dash_timer.wait_time
		var x = (t - dash_timer.time_left) * 2
		var y = -2.5*pow(x,2) + 1.3*x + 2
		direction *= y
		print(velocity.x)
		#print(t)
		#var a = -4
		#var sqr = pow(x, a)
		#var slope = sqr / (sqr + pow(1 - x, a)) * 3
		#direction *= slope
		#print(slope)
	
	if not is_on_floor():
		velocity.y += 800 * delta * 1.3 
		velocity.x = lerpf(velocity.x, speed * (int(dash_ready) + 1) * direction, 0.2)
	else:
		velocity.x = lerpf(velocity.x, speed * direction, 0.2)
		
	velocity.x = lerpf(velocity.x, 0, 0.01)
	
	move_and_slide()
	
