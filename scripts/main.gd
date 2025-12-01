extends Node2D

var pause_menu: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _get_pause_menu() -> Control:
	if pause_menu == null or not is_instance_valid(pause_menu):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			pause_menu = player.get_node_or_null("PauseLayer/PauseMenu")
	return pause_menu

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		var menu = _get_pause_menu()
		if menu == null:
			return

		if !Gamestate.game_is_paused:
			Gamestate.toggle_pause()
			menu.show_menu()
		else:
			menu.hide_menu()

		get_tree().root.get_viewport().set_input_as_handled()
