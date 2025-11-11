extends Node2D

@onready var pause_menu = $GUI/PauseMenu

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		Gamestate.toggle_pause()

		if Gamestate.game_is_paused:
			pause_menu.show_menu()
		else:
			pause_menu.hide_menu()

		get_tree().root.get_viewport().set_input_as_handled()
