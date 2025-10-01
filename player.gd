class_name Player
extends CharacterBody2D

@export var gravity = 22
@export var speed = 75

var direction: Vector2;
var dash_smoothing = 1
@onready var dash_timer = Timer.new()
@onready var dash_cooldown = Timer.new()
@onready var directed_dash_offset = Timer.new()
@onready var directed_dash_timer = Timer.new()

var dash_ready: 
	get: return dash_cooldown.is_stopped()
var preparing_directed_dash: 
	get: return not directed_dash_offset.is_stopped()
var dashing:
	get: return not dash_timer.is_stopped() or direct_dashing
var direct_dashing:
	get: return not directed_dash_timer.is_stopped()

var directed_dash_ready = false

@onready var camera = self.find_child("Camera2D") as Camera2D

var direction_side: direction_side_enum
enum direction_side_enum { LEFT = -1, RIGHT = 1 }


func _ready() -> void:
	dash_cooldown.wait_time = 0.3
	dash_cooldown.one_shot = true
	dash_cooldown.timeout.connect(on_dash_cooldown)
	add_child(dash_cooldown)
	
	dash_timer.wait_time = 0.015
	dash_timer.one_shot = true
	dash_timer.timeout.connect(on_dash_stop)
	add_child(dash_timer)
	
	directed_dash_offset.wait_time = 0.3
	directed_dash_offset.one_shot = true
	directed_dash_offset.timeout.connect(on_direct_dash_offset)
	add_child(directed_dash_offset)
	
	directed_dash_timer.wait_time = 0.015
	directed_dash_timer.one_shot = true
	directed_dash_timer.timeout.connect(on_direct_dash_stop)
	add_child(directed_dash_timer)
	
	
	direction_side = direction_side_enum.RIGHT
	
func on_direct_dash_offset():
	directed_dash_ready = true

func on_dash_stop():
	pass

func on_direct_dash_stop():
	directed_dash_ready = false

func on_dash_cooldown():
	pass

func get_input():
	direction.x = Input.get_axis("ui_left","ui_right")
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y -= 500
	
	if Input.is_action_pressed("dash") and not dashing:
		if directed_dash_offset.is_stopped() and !directed_dash_ready:
			directed_dash_offset.start()
		$Direct_dash_loader.size.x = lerp(0, 70, (directed_dash_offset.wait_time - directed_dash_offset.time_left) * 2)
	elif Input.is_action_just_released("dash") and dash_ready:
		#16 is to sharpen dash at the start
		print(directed_dash_ready)
		if directed_dash_ready:
			$Direct_dash_loader.size.x = 0
			
			directed_dash_timer.start()
			print("direct dashing")
		
		dash_timer.start()
		
		if not directed_dash_offset.is_stopped() and not directed_dash_ready:
			directed_dash_offset.stop()
			directed_dash_offset.wait_time = 0.3
			directed_dash_ready = false
			$Direct_dash_loader.size.x = 0
			
		dash_cooldown.start()
	
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
	
	if Input.is_action_just_pressed("slow_time"):
		Engine.time_scale = 0.2
		$screenshader.visible = true
		speed *= 2
	if Input.is_action_just_released("slow_time"):
		Engine.time_scale = 1
		$screenshader.visible = false
		speed /= 2

func _exit_tree() -> void:
	#leave camera on after death
	var camera = Camera2D.new()
	camera.global_position = global_position
	
	get_tree().root.add_child(camera)
	print("GG")

func _physics_process(delta: float) -> void:
	get_input()
	#direction_side right
	if Input.is_action_just_pressed("ui_right"):
		$rotating.scale.x = 1
		direction_side = direction_side_enum.RIGHT
	#direction_side left
	if Input.is_action_just_pressed("ui_left"):
		$rotating.scale.x = -1
		direction_side = direction_side_enum.LEFT
	
	# Dash with quadric function acceleration
	if not dashing:
		velocity.x = lerpf(velocity.x + direction.x * speed, 0, 0.1)
	else:
		var t = dash_timer.wait_time
		var x = (t - dash_timer.time_left) * 2
		var y = -2.5*pow(x,2) + 1.3*x + 2
		if direct_dashing:
			print("direct dashing")
			velocity.y = get_local_mouse_position().normalized().y * y * 6 * speed
			velocity.x = get_local_mouse_position().normalized().x * y * 12 * speed
			print(get_local_mouse_position().normalized())
		else:
			velocity.x = y * 12 * direction_side * speed
	
	if not is_on_floor():
		velocity.y += gravity
	
	velocity *= delta * 60.5 / Engine.time_scale
	
	move_and_slide()
	
