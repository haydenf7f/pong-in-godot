extends CharacterBody2D
class_name Ball


var debug_mode := false
var break_time := true

@export var speed_increase : float = 30
@export var initial_speed: float = 500.0
var speed: float = initial_speed
var num_collisions: int = 0

var direction := Vector2(-1, 0)
var initial_position = Vector2(global_position.x, global_position.y)

@onready var bounce_particle: CPUParticles2D = $BounceParticle
@onready var particle_trail: CPUParticles2D = $ParticleTrail
var min_particle_velocity: float = 0
var max_particle_velocity: float = 50

@onready var cshape: CollisionShape2D = $CollisionShape2D

signal bounced


func _ready() -> void:
	particle_trail.emitting = false
	particle_trail.initial_velocity_min = min_particle_velocity
	particle_trail.initial_velocity_max = max_particle_velocity
	

func _physics_process(_delta: float) -> void:
	if break_time: return
	
	if debug_mode:
		var vertical_direction := Input.get_axis("ball_up", "ball_down")
		var horizontal_direction := Input.get_axis("ball_left", "ball_right")
		direction = Vector2(horizontal_direction, vertical_direction)
		velocity = direction * speed
		direction = Vector2(-1, 0)
		speed = initial_speed
	else:
		velocity = direction * speed
		
	var collision = move_and_slide()
	
	if collision:
		var collider: KinematicCollision2D = get_last_slide_collision()
		
		# Checks if the object collided with is the ceiling, which is the only StaticBody2D in the game
		if collider.get_collider() is StaticBody2D:
			$CeilingBounce.play()
			
			if collider.get_normal().y == 1: # if the normal points down, we hit the top ceiling
				bounce_particle.position = Vector2(0, -15)
				bounce_particle.gravity = Vector2(0, 300)
			else:
				bounce_particle.position = Vector2(0, 15)
				bounce_particle.gravity = Vector2(0, -300)
			bounce_particle.emitting = true
		
		# Update the direction of the ball
		direction = direction.bounce(collider.get_normal())
		
	particle_trail.direction = direction*-1


func _update_ball_particles():
	# This function is called whenever the ball collides with a paddle. It updates the speed of the particles
	particle_trail.initial_velocity_min = min_particle_velocity + (speed_increase * num_collisions)
	particle_trail.initial_velocity_max = max_particle_velocity + (speed_increase * num_collisions)


func bounce_off_paddle(paddle_y, paddle_height) -> void:
	var ball_y := global_position.y
	speed += speed_increase
	num_collisions += 1
	direction = Vector2(direction.x*-1, (ball_y - paddle_y) / (paddle_height/2))
	
	bounced.emit()
	
	_update_ball_particles()
	

func reset(is_goal_left: bool) -> void:
	position = initial_position
	speed = initial_speed
	
	if is_goal_left:
		direction = Vector2(1, 0)
	else:
		direction = Vector2(-1, 0)
	
	num_collisions = 0
	
	particle_trail.emitting = false
	particle_trail.restart()
	
	particle_trail.initial_velocity_min = min_particle_velocity
	particle_trail.initial_velocity_max = max_particle_velocity
	

func get_size() -> Vector2:
	return cshape.shape.get_rect().size
	
