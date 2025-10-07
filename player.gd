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
@onready var attack_cooldown = Timer.new()
@onready var slowtime_max_duration = Timer.new()

var slowtime_time_out = false

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

var direct_dash_vector: Vector2
var direction_side: direction_side_enum
enum direction_side_enum { LEFT = -1, RIGHT = 1 }

func _ready() -> void:
	register_timer(dash_cooldown, 0.9, on_dash_cooldown)
	register_timer(dash_timer, 0.05, on_dash_stop)
	register_timer(directed_dash_offset, 0.3, on_direct_dash_offset)
	register_timer(directed_dash_timer, 0.215, on_direct_dash_stop)
	register_timer(attack_cooldown, 0.15, null)
	register_timer(slowtime_max_duration, 0.5, slowtime_end)
	direction_side = direction_side_enum.RIGHT
	
func slowtime_end():
	slowtime_time_out = true
	
func register_timer(t: Timer, duration: float, callback):
	t.wait_time = duration
	t.one_shot = true
	if callback:
		t.timeout.connect(callback)
	add_child(t)
	
func on_direct_dash_offset():
	directed_dash_ready = true

func on_dash_stop():
	pass

func on_direct_dash_stop():
	directed_dash_ready = false
	velocity /= 10

func on_dash_cooldown():
	slowtime_time_out = false

func swing_anim_ended():
	return ($Sprite.sprite_frames as SpriteFrames).get_frame_count($Sprite.animation) == $Sprite.frame + 1

func get_input():
	direction.x = Input.get_axis("ui_left","ui_right")

	if not dash_cooldown.is_stopped():
		$Time_visu.visible = true
		$Time_visu.scale.x = ((dash_cooldown.wait_time - dash_cooldown.time_left) / dash_cooldown.wait_time)
	else:
		$Time_visu.visible = false

	if (direction.x == 0 and abs(velocity.x) < 20 and swing_anim_ended()) or swing_anim_ended():
		$Sprite.animation = "IDLE"
	
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y -= 500
		
	if Input.is_action_pressed("direct_dash") and not dashing and not slowtime_time_out and dash_ready:
		#set visuals
		Input.set_default_cursor_shape(Input.CursorShape.CURSOR_CROSS)
		Engine.time_scale = 0.2
		$screenshader.visible = true
		
		$Time_visu.visible = true
		$Time_visu.scale.x = (slowtime_max_duration.time_left / slowtime_max_duration.wait_time)
		
		$tracer.points[1] = get_local_mouse_position()
		
		if slowtime_max_duration.is_stopped() and not slowtime_time_out:
			slowtime_max_duration.start(slowtime_max_duration.wait_time)
		
		#freeze
		velocity = velocity.normalized()
	elif (Input.is_action_just_released("direct_dash") and not dashing) or (Input.is_action_pressed("direct_dash") and slowtime_time_out and not dashing) and dash_ready:
		# reset visuals
		$Time_visu.visible = false
		
		Input.set_default_cursor_shape(Input.CursorShape.CURSOR_ARROW)
		$screenshader.visible = false
		Engine.time_scale = 1
		#set logic
		direct_dash_vector = get_local_mouse_position().normalized()
		directed_dash_timer.start()
		dash_cooldown.start()
		slowtime_max_duration.stop()
		
		$tracer.points[1] = Vector2(0,0)
		
	elif Input.is_action_just_released("dash") and dash_ready:
		dash_timer.start()
		dash_cooldown.start()
	
	if Input.is_action_just_pressed("attack"):
		if attack_cooldown.is_stopped():
			if randi_range(0,100) > 50:
				$Sprite.play("SWING")
			else:
				$Sprite.play("SWING_REVERSE")
			attack_cooldown.start()
		
			var wea := $WeaponNode/Weapon as Area2D
			for b in wea.get_overlapping_bodies():
				var e = b as Enemy
				if e:
					if e.trying_to_hit_player:
						e.attack_parred = true
						e.delay -= 25
						camera.translate(Vector2(-10,0))
						camera.translate(Vector2(10,0))
						camera.translate(Vector2(0,0))
					else:
						e.kickbacked = true
						e.delay -= 10
						e.health -= 1
						if e.health == 0:
							b.queue_free()

func _exit_tree() -> void:
	#leave camera on after death
	var camera = Camera2D.new()
	camera.global_position = global_position
	
	get_tree().root.add_child(camera)
	print("GG")

func _physics_process(delta: float) -> void:
	get_input()
	#direction_side right
	if Input.is_action_pressed("ui_right"):
		$WeaponNode.scale.x = 1#0.261
		$Sprite.scale.x = 0.261
		direction_side = direction_side_enum.RIGHT
		if $Sprite.animation == "IDLE" or swing_anim_ended():
			$Sprite.animation = "RUN"
	#direction_side left
	if Input.is_action_pressed("ui_left"):
		$WeaponNode.scale.x = -1#0.261
		$Sprite.scale.x = -0.261
		direction_side = direction_side_enum.LEFT
		if $Sprite.animation == "IDLE" or swing_anim_ended():
			$Sprite.animation = "RUN"
	
	# Dash with quadric function acceleration
	if not dashing:
		velocity.x = lerpf(velocity.x + direction.x * speed, 0, 0.1)
	else:
		var t = dash_timer.wait_time
		var x = (t - dash_timer.time_left) * 2
		var y = -2.5*pow(x,2) + 1.3*x + 2
		if direct_dashing:
			velocity.y = direct_dash_vector.y * y * 10 * speed
			velocity.x = direct_dash_vector.x * y * 10 * speed
			# stopping dash on walls and floor
			if get_slide_collision_count() > 0 and directed_dash_timer.time_left < directed_dash_timer.wait_time / 2:
				velocity *= 0
		else:
			velocity.x = y * 12 * direction_side * speed
	
	if not is_on_floor():
		velocity.y += gravity
	
	velocity *= delta * 60.5 / Engine.time_scale
	
	
	move_and_slide()
	
