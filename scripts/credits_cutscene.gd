extends Node2D

@onready var video_player = $CanvasLayer/VideoStreamPlayer

func _ready() -> void:
	video_player.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_go_to_main_menu()

func _on_video_stream_player_finished() -> void:
	_go_to_main_menu()

func _go_to_main_menu():
	if not is_inside_tree():
		return

	video_player.stop()
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
