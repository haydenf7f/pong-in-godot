extends Area2D

@onready var goal_explosion: CPUParticles2D = $GoalExplosion
@export var is_player_one_goal: bool = false

signal goal(is_player_one_goal: bool)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	
func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		_goal_particles(body.global_position.y)
		goal.emit(is_player_one_goal)
		$GoalSound.play()
		

func _goal_particles(ball_position: float) -> void:
	goal_explosion.global_position.y = ball_position
	
	var screen_center: Vector2 = get_viewport_rect().size * 0.5
	var emit_direction: Vector2 = Vector2.ZERO
	var toward_center: Vector2 = (screen_center - goal_explosion.global_position).normalized()
	
	if is_player_one_goal:
		emit_direction = toward_center
	else:
		emit_direction = -1 * toward_center
		
	goal_explosion.direction = emit_direction
	goal_explosion.emitting = true
	
