extends Node2D

@onready var ceiling: StaticBody2D = $Ceiling
@onready var ball: CharacterBody2D = $Ball
@onready var ball_path: Line2D = $BallPath
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

@export var win_score := 11

var is_recent_goal_left: bool = false
var winner: String = ""
var score := Vector2i(0, 0)
var is_ai_enabled := false

@onready var ball_projection_pos: Label = $CanvasLayer/BallProjectionPos
@onready var ball_global_pos: Label = $CanvasLayer/BallGlobalPos


func _ready() -> void:
	goal_left.connect("goal", _goal_handler)
	goal_right.connect("goal", _goal_handler)
	game_over_timer.timeout.connect(_on_game_over_timer_timeout)
	ball.bounced.connect(_on_ball_bounced)
	
	break_timer.timeout.connect(_on_break_timer_timeout)
	break_timer.start()
	
	if Global.current_mode != Global.Gamemode.PVP:
		is_ai_enabled = true
		
	var sound_effects: Array = get_tree().get_nodes_in_group("Sound Effects")
	for sound_effect in sound_effects:
		if sound_effect is AudioStreamPlayer:
			sound_effect.volume_db = Global.sound_effect_volume_db
			
	
func _process(_delta: float) -> void:
	if break_timer.time_left == 0: return
	timer_label.text = str("%.2f" % break_timer.time_left)
		
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		ball.debug_mode = !ball.debug_mode
		paddle_one.input_enabled = !paddle_one.input_enabled
	elif event.is_action_pressed("reset"):
		_reset()
	elif event.is_action_pressed("show_lines"):
		ball_path.visible = !ball_path.visible
		
	
func _draw() -> void:
	# draw the dashed line through the middle of the screen
	var viewport_center_x := get_viewport_rect().size.x / 2
	var viewport_height := get_viewport_rect().size.y
	draw_dashed_line(Vector2(viewport_center_x, 0), Vector2(viewport_center_x, viewport_height), Color.GRAY, 5, 8, false) 


func _on_ball_bounced() -> void:
	_simulate_ball_movement()


func _update_ball_path(points: Array[Vector2]):
	ball_path.clear_points()
	ball_path.global_position = ball.global_position
	
	for point in points:
		var localized_point = ball_path.to_local(point)
		ball_path.add_point(localized_point) # add a the point as a local point because lines are drawn using local pos not global pos
		

func _simulate_ball_movement(seconds: float = 3.0):
	var ball_pos = ball.global_position
	var ball_dir = ball.direction
	var ball_size = ball.get_size()
	
	var ball_radius: float = ball_size.y/2
	var top_limit: float = 0 + ball_radius/2
	var bottom_limit: float = get_viewport_rect().size.y - ball_radius/2
	var left_limit: float = paddle_one.global_position.x + ball_radius
	var right_limit: float = paddle_two.global_position.x - ball_radius
	
	var points: Array[Vector2] = [ball_pos]
	var dt = get_physics_process_delta_time()
	
	# the physics process runs 60 times per second
	for i in range(0, 60 * seconds):
		ball_pos += ball_dir * ball.speed * dt
		ball_projection_pos.text = str(ball_pos)
		ball_global_pos.text = str(ball.global_position)
		
		# If ball_pos is calculated to be beyond the x position of either paddle
		if ball_pos.x <= left_limit or ball_pos.x >= right_limit:
			if ball_pos.x <= left_limit and ball_dir.x > 0: # This can happen if the ball hits the paddle from the top
				# The ball_pos is less than the limit but is moving right (no goal is scored)
				pass
			elif ball_pos.x >= right_limit and ball_dir.x < 0:
				# The ball_pos is greater than the right limit but is moving left (no goal is scored)
				pass
			else:
				break
		
		# If the projected path moves outside of the y limit then "bounce" the ball by flipping the y direction
		if ball_pos.y <= top_limit or ball_pos.y >= bottom_limit:
			ball_pos.y = clamp(ball_pos.y, top_limit, bottom_limit)
			ball_dir.y *= -1
			points.append(ball_pos)
			
		#if ball_pos.y < top_limit:
			#var overshoot: float = top_limit - ball_pos.y
			#ball_pos.y = top_limit + overshoot
			#ball_dir.y = abs(ball_dir.y)
			#points.append(ball_pos)
		#elif ball_pos.y > bottom_limit:
			#var overshoot: float= ball_pos.y - bottom_limit
			#ball_pos.y = bottom_limit - overshoot
			#ball_dir.y = -abs(ball_dir.y)
			#points.append(ball_pos)
	
	points.append(ball_pos)
	
	if Global.current_mode == Global.Gamemode.NIGHTMARE or Global.current_mode == Global.Gamemode.IMPOSSIBLE:
		if paddle_one.is_ai:
			paddle_one.ai_target_ypos = ball_pos.y
			
		if paddle_two.is_ai:
			paddle_two.ai_target_ypos = ball_pos.y
		
	_update_ball_path(points)


func _is_win_by_two() -> bool:
	return abs(score.x - score.y) >= 2


func _tie_break_handler() -> void:
	win_score += 1
	_reset()
	
	
func _goal_handler(is_player_one_goal: bool) -> void:
	is_recent_goal_left = is_player_one_goal
	
	if is_player_one_goal:
		score.y += 1
		p2_score.text = str(score.y)
	else:
		score.x += 1
		p1_score.text = str(score.x)
	
	if score.x == win_score:
		# win by 2 check
		if !_is_win_by_two():
			_tie_break_handler()
			return
			
		winner = "paddle_one"
		_game_over_routine()
		return
	elif score.y == win_score:
		# win by 2 check
		if !_is_win_by_two():
			_tie_break_handler()
			return
			
		winner = "paddle_two"
		_game_over_routine()
		return
		
	_reset()
	

func _reset() -> void:
	ball_path.clear_points()
	
	ball.break_time = true
	ball.reset(is_recent_goal_left)
	
	paddle_one.input_enabled = false
	paddle_two.input_enabled = false
	paddle_one.reset()
	paddle_two.reset()
	
	break_timer.start()
	timer_label.visible = true
	

func _on_break_timer_timeout():
	paddle_one.input_enabled = true
	paddle_two.input_enabled = true
	timer_label.visible = false
	ball.break_time = false
	ball.particle_trail.emitting = true
	# Serve sound effect would go here if there was one
	_simulate_ball_movement()



func _game_over_routine() -> void:
	game_over_timer.start()
	winner_label.visible = true
	
	var current_gamemode_string := Global.gamemode_to_string(Global.current_mode)
	
	if winner == "paddle_one":
		if paddle_two.is_ai:
			winner_label.text = "You Defeated The %s Robot!" % current_gamemode_string
		else:
			winner_label.text = "Player One Wins!"
	elif winner == "paddle_two":
		if paddle_two.is_ai:
			winner_label.text = "The %s Robot Defeated You!" % current_gamemode_string
		else:
			winner_label.text = "Player Two Wins!"
		
	
	game_over_particles.emitting = true
	$Twinkle.play()
	
	var tween = create_tween()
	winner_label.label_settings.font_size = 1
	tween.tween_property(winner_label, "label_settings:font_size", 36, 0.8).set_trans(Tween.TRANS_SINE)
	
	
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
