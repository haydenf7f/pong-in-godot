extends Node2D

@onready var ceiling: StaticBody2D = $Ceiling
@onready var ball: CharacterBody2D = $Ball
@onready var paddle_one: Area2D = $Paddle_P1
@onready var paddle_two: Area2D = $Paddle_P2
@onready var goal_left: Area2D = $Goal_Left
@onready var goal_right: Area2D = $Goal_Right

@onready var p1_score: Label = $CanvasLayer/P1_Score
@onready var p2_score: Label = $CanvasLayer/P2_Score
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var winner_label: Label = $CanvasLayer/WinnerLabel

@onready var break_timer: Timer = $Break_Timer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var game_over_particles: CPUParticles2D = $GameOverParticles

@export var sound_effect_volume: float = -12.0
@export var win_score := 11

var is_recent_goal_left: bool = false
var winner: String = ""
var score := Vector2i(0, 0)



func _ready() -> void:
	goal_left.connect("goal", _goal_handler)
	goal_right.connect("goal", _goal_handler)
	
	game_over_timer.timeout.connect(_on_game_over_timer_timeout)
	
	break_timer.timeout.connect(_on_break_timer_timeout)
	break_timer.start()
	
	var sound_effects: Array = get_tree().get_nodes_in_group("Sound Effects")
	for sound_effect in sound_effects:
		if sound_effect is AudioStreamPlayer:
			sound_effect.volume_db = sound_effect_volume


func _process(_delta: float) -> void:
	if break_timer.time_left == 0: return
	timer_label.text = str("%.2f" % break_timer.time_left)
		
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		ball.debug_mode = !ball.debug_mode
		paddle_one.input_enabled = !paddle_one.input_enabled
	elif event.is_action_pressed("reset"):
		_reset()


func _draw() -> void:
	# draw the dashed line through the middle of the screen
	var viewport_center_x := get_viewport_rect().size.x / 2
	var viewport_height := get_viewport_rect().size.y
	draw_dashed_line(Vector2(viewport_center_x, 0), Vector2(viewport_center_x, viewport_height), Color.GRAY, 5, 8, false) 


func _goal_handler(is_player_one_goal: bool) -> void:
	is_recent_goal_left = is_player_one_goal
	
	if is_player_one_goal:
		score.y += 1
		p2_score.text = str(score.y)
	else:
		score.x += 1
		p1_score.text = str(score.x)
	
	if score.x == win_score:
		winner = "paddle_one"
		_game_over_routine()
		return
	elif score.y == win_score:
		winner = "paddle_two"
		_game_over_routine()
		return
		
	_reset()
	

func _reset() -> void:
	ball.break_time = true
	ball.reset(is_recent_goal_left)
	
	paddle_one.input_enabled = false
	paddle_two.input_enabled = false
	paddle_one.reset()
	paddle_two.reset()
	
	break_timer.start()
	timer_label.visible = true
	

func _game_over_routine() -> void:
	game_over_timer.start()
	winner_label.visible = true
	
	if winner == "paddle_one":
		winner_label.text = "Player One Wins!"
	elif winner == "paddle_two":
		winner_label.text = "Player Two Wins!"
	
	game_over_particles.emitting = true
	
	var tween = create_tween()
	winner_label.label_settings.font_size = 1
	tween.tween_property(winner_label, "label_settings:font_size", 36, 0.8).set_trans(Tween.TRANS_SINE)
	

func _on_break_timer_timeout():
	paddle_one.input_enabled = true
	paddle_two.input_enabled = true
	timer_label.visible = false
	ball.break_time = false
	ball.particle_trail.emitting = true


func _on_game_over_timer_timeout():
	score.x = 0
	p1_score.text = str(score.x)
	
	score.y = 0
	p2_score.text = str(score.y)
	
	var tween = create_tween()
	tween.tween_property(winner_label, "label_settings:font_size", 1, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished

	winner_label.visible = false
	
	game_over_particles.emitting = false
	_reset()
