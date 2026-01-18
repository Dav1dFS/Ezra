extends Node2D

var changing_scene := false

func _ready() -> void:
	$CanvasLayer/VideoStreamPlayer.play()
	$CanvasLayer/VideoStreamPlayer.finished.connect(_on_video_finished)

func _input(event):
	if event is InputEventKey and event.pressed and not changing_scene:
		go_to_next_scene()

func _on_video_finished() -> void:
	go_to_next_scene()

func go_to_next_scene():
	if changing_scene:
		return
	changing_scene = true
	$CanvasLayer/VideoStreamPlayer.stop()
	get_tree().change_scene_to_file("res://scenes/gameplay/level_1/day_1_intro.tscn")
