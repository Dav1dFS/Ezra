extends Node2D

@onready var pause_menu = $GUI/InputSettings

var game_is_paused: bool = false

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		game_is_paused = !game_is_paused
		if game_is_paused:
			Engine.time_scale = 0
			pause_menu.visible = true
		else:
			Engine.time_scale = 1
			pause_menu.visible = false
		get_tree().root.get_viewport().set_input_as_handled()
