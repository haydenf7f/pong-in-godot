extends Node

@export var sound_effect_volume_db: float = -13.0

enum Gamemode { EASY, NORMAL, HARD, NIGHTMARE, PVP  }
@export var current_mode: Gamemode = Gamemode.NORMAL

func gamemode_to_string(gamemode: Gamemode) -> String:
	match gamemode:
		Gamemode.EASY:
			return "Easy"
		Gamemode.NORMAL:
			return "Normal"
		Gamemode.HARD:
			return "Hard"
		Gamemode.NIGHTMARE:
			return "Nightmare"
		Gamemode.PVP:
			return "Player vs Player"
	return ""
