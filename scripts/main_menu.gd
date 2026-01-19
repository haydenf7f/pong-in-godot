extends Control

@onready var button_press := $ButtonPress

func _load_game_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	

func _on_play_pressed() -> void:
	button_press.play()
	$Main.visible = false
	$PlayContainer.visible = true
	

func _on_quit_pressed() -> void:
	button_press.play()
	get_tree().quit()

func _on_back_pressed() -> void:
	$PlayContainer.visible = false
	button_press.play()
	$Main.visible = true
	

func _on_pvp_pressed() -> void:
	button_press.play()
	Global.current_mode = Global.Gamemode.PVP
	_load_game_scene()

func _on_pvp_mouse_entered() -> void:
	$PlayContainer/Tooltips/PVPTooltip.visible = true

func _on_pvp_mouse_exited() -> void:
	$PlayContainer/Tooltips/PVPTooltip.visible = false



func _on_easy_pressed() -> void:
	button_press.play()
	Global.current_mode = Global.Gamemode.EASY
	_load_game_scene()

func _on_easy_mouse_entered() -> void:
	$PlayContainer/Tooltips/EasyTooltip.visible = true

func _on_easy_mouse_exited() -> void:
	$PlayContainer/Tooltips/EasyTooltip.visible = false



func _on_normal_pressed() -> void:
	button_press.play()
	Global.current_mode = Global.Gamemode.NORMAL
	_load_game_scene()

func _on_normal_mouse_entered() -> void:
	$PlayContainer/Tooltips/NormalTooltip.visible = true

func _on_normal_mouse_exited() -> void:
	$PlayContainer/Tooltips/NormalTooltip.visible = false



func _on_hard_pressed() -> void:
	button_press.play()
	Global.current_mode = Global.Gamemode.HARD	
	_load_game_scene()
	
func _on_hard_mouse_entered() -> void:
	$PlayContainer/Tooltips/HardTooltip.visible = true

func _on_hard_mouse_exited() -> void:
	$PlayContainer/Tooltips/HardTooltip.visible = false



func _on_nightmare_pressed() -> void:
	button_press.play()
	Global.current_mode = Global.Gamemode.NIGHTMARE
	_load_game_scene()
	
func _on_nightmare_mouse_entered() -> void:
	$PlayContainer/Tooltips/NightmareTooltip.visible = true

func _on_nightmare_mouse_exited() -> void:
	$PlayContainer/Tooltips/NightmareTooltip.visible = false



func _on_impossible_pressed() -> void:
	Global.current_mode = Global.Gamemode.IMPOSSIBLE
	_load_game_scene()

func _on_impossible_mouse_entered() -> void:
	$PlayContainer/Tooltips/ImpossibleTooltip.visible = true

func _on_impossible_mouse_exited() -> void:
	$PlayContainer/Tooltips/ImpossibleTooltip.visible = false
