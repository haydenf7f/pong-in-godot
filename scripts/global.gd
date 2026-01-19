extends Node

enum Gamemode { EASY, NORMAL, HARD, NIGHTMARE, IMPOSSIBLE, PVP  }
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
		Gamemode.IMPOSSIBLE:
			return "Impossible"
		Gamemode.PVP:
			return "Player vs Player"
	return ""
