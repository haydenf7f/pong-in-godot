extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var button_press := $ButtonPress


func _ready() -> void:
	animation_player.play("RESET")
	hide()
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and get_tree().paused == false:
		pause()
	elif event.is_action_pressed("pause") and get_tree().paused == true:
		resume()


func _await_play_button_sound():
	button_press.play()
	await button_press.finished
	

func resume() -> void:
	animation_player.play_backwards("blur")
	await animation_player.animation_finished
	get_tree().paused = false
	hide()


func pause() -> void:
	get_tree().paused = true
	animation_player.play("blur")
	show()


func _on_resume_pressed() -> void:
	_await_play_button_sound()
	resume()


func _on_restart_pressed() -> void:
	_await_play_button_sound()
	await resume()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	_await_play_button_sound()
	await resume()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
