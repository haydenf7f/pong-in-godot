extends Area2D

var speed := 600
var direction := 0.0
var initial_position = Vector2(global_position.x, global_position.y)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var paddle_height := collision_shape.get_shape().get_rect().size.y

@onready var paddle_particle: CPUParticles2D = $PaddleParticle
@onready var bounce_particle: CPUParticles2D = $BounceParticle

@export var is_player_one := false
var input_enabled := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	
func _process(delta: float) -> void:
	if input_enabled == false: return
	
	# Checks whether the paddle should be moved with 'W' and 'A' or Arrow Keys
	if is_player_one:
		direction = Input.get_axis("move_up", "move_down")
	else:
		direction = Input.get_axis("move_up_p2", "move_down_p2")	
		
	position.y += direction * speed * delta

	# clamps the y position of the paddle to 20 pixels below the top of the screen
	# and 20 pixels above the bottom of the screen
	# I have to get the paddle height because the origin of the paddle is the top left corner
	position.y = clamp(position.y, paddle_height, get_viewport_rect().size.y - paddle_height)


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
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
	
