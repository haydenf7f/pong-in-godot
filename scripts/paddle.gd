extends Area2D

const DEFAULT_SPEED: float = 600
var speed := 600.0
var direction := 0.0
var initial_position = Vector2(global_position.x, global_position.y)
var ai_target_ypos := 360.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var paddle_height := collision_shape.get_shape().get_rect().size.y

@onready var paddle_particle: CPUParticles2D = $PaddleParticle
@onready var bounce_particle: CPUParticles2D = $BounceParticle

@export var is_ai := false
var ai_accuracy: float = 0 # lower number is more accurate
@export var ai_acc_lower: float = 2 # the lower bound on ai_accuracy
@export var ai_acc_upper: float = 35 # the upper bound on ai_accuracy

@export var is_player_one := false
var input_enabled := true

var num_collisions: int = 0

func _ready() -> void:
	if Global.current_mode == Global.Gamemode.PVP:
		is_ai = false
	elif Global.current_mode == Global.Gamemode.EASY and is_ai:
		speed = 0.7 * DEFAULT_SPEED
		ai_acc_lower = 5
		ai_acc_upper = 75
	elif Global.current_mode == Global.Gamemode.NORMAL and is_ai:
		speed = 0.8 * DEFAULT_SPEED
		ai_acc_lower = 2
		ai_acc_upper = 65
	elif Global.current_mode == Global.Gamemode.HARD and is_ai:
		speed = 0.95 * DEFAULT_SPEED
		ai_acc_lower = 2
		ai_acc_upper = 35
	elif Global.current_mode == Global.Gamemode.NIGHTMARE and is_ai:
		speed = DEFAULT_SPEED
		ai_acc_lower = 2
		ai_acc_upper = 30
	elif Global.current_mode == Global.Gamemode.IMPOSSIBLE and is_ai:
		speed = 1.5 * DEFAULT_SPEED
		ai_accuracy = 0
	
	body_entered.connect(_on_body_entered)
	
	
func _process(delta: float) -> void:
	if input_enabled == false: return
	
	# Checks whether the paddle should be moved with 'W' and 'A' or Arrow Keys
	if is_player_one:
		direction = Input.get_axis("move_up", "move_down")
	elif is_ai:
		direction = _get_ai_direction()
	else:
		direction = Input.get_axis("move_up_p2", "move_down_p2")	
		
	position.y += direction * speed * delta
	
	# The IMPOSSIBLE AI gets to cheat by using the entire screen space
	if Global.current_mode == Global.Gamemode.IMPOSSIBLE and is_ai: return
	
	# clamps the y position of the paddle to 20 pixels below the top of the screen
	# and 20 pixels above the bottom of the screen
	# I have to get the paddle height because the origin of the paddle is the top left corner
	position.y = clamp(position.y, paddle_height, get_viewport_rect().size.y - paddle_height)


func _get_ai_direction() -> float:
	var pos_diff: float = abs(ai_target_ypos - global_position.y)
	  # Lower number is more accurate
	
	if Global.current_mode == Global.Gamemode.EASY or Global.current_mode == Global.Gamemode.NORMAL or Global.current_mode == Global.Gamemode.HARD:
		var ball: CharacterBody2D = get_tree().get_first_node_in_group("Ball")
		
		if ball.direction.x >= 0:
			ai_target_ypos = ball.global_position.y
		else:
			ai_target_ypos = get_viewport_rect().size.y/2
		
	if pos_diff >= ai_accuracy:
		if global_position.y > ai_target_ypos:
			return -1
		elif global_position.y < ai_target_ypos:
			return 1
	elif pos_diff < ai_accuracy:
		if num_collisions % 2 == 0:
			return -1
		else:
			return 1
	
	return 0
	
func _on_body_entered(body: Node2D) -> void:
	if is_ai:
		ai_accuracy = randf_range(ai_acc_lower, ai_acc_upper)
		
	if body is Ball:
		num_collisions += 1
		body.bounce_off_paddle(global_position.y, paddle_height)
		_play_hit_effects(body.global_position.y)
		

func _play_hit_effects(ball_position_y: float) -> void:
	# Sound Effect
	$Bounce.play()
	
	# Particle effect
	paddle_particle.emitting = false
	paddle_particle.restart()
	
	if is_player_one:
		paddle_particle.gravity.x = -100
		bounce_particle.gravity.x = 300
	else:
		paddle_particle.gravity.x = 100
		bounce_particle.gravity.x = -300
		
	bounce_particle.global_position.y = ball_position_y
	
	bounce_particle.emitting = true
	paddle_particle.emitting = true
	
	# Hit effect parameters
	var darken_color := Color(0.70, 0.70, 0.70, 1.0)  # 75% brightness
	var press_scale := Vector2(0.98, 0.98)            # subtle squash
	var in_time := 0.06
	var out_time := 0.10
	
	# Tween parameters
	var _hit_tween: Tween = create_tween()
	_hit_tween.set_trans(Tween.TRANS_QUAD)
	_hit_tween.set_ease(Tween.EASE_OUT)
	
	# Press in: darken + squash + recoil
	_hit_tween.tween_property(self, "modulate", darken_color, in_time)
	_hit_tween.parallel().tween_property(self, "scale", press_scale, in_time)
	
	if is_player_one:
		_hit_tween.parallel().tween_property(self, "position:x", position.x - 3, in_time/2)
	else:
		_hit_tween.parallel().tween_property(self, "position:x", position.x + 3, in_time/2)
		
	# Release: back to normal
	_hit_tween.tween_property(self, "modulate", Color.WHITE, out_time)
	_hit_tween.parallel().tween_property(self, "scale", Vector2.ONE, out_time)
	
	if is_player_one:
		_hit_tween.tween_property(self, "position:x", position.x + 3, out_time)
	else:
		_hit_tween.tween_property(self, "position:x", position.x - 3, out_time)

	
func reset() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", initial_position, 0.4).set_trans(Tween.TRANS_QUAD)
	
