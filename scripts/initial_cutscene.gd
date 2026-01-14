extends Node2D


func _ready() -> void:
	$CanvasLayer/VideoStreamPlayer.play()

func _input(event):
	if event is InputEventKey and event.pressed:
		_on_video_stream_player_finished()

func _on_video_stream_player_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/level_1/day_1_intro.tscn")
