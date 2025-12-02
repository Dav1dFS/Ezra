extends Node

var memories_collected: Dictionary = {}
var npc_dialogues_completed = {}
var character_name: String
var game_is_paused := false
var custom_cursor: Texture2D
var play_time:= 0.0
var is_talking: bool = false
var dialogue_locked:= false
var ellen_night1_intro_done: bool = false
var memory_zoom_enabled := false
var can_control_frieda: bool = false
var frieda_control_line_shown: bool = false

func _ready():
	var img = load("res://assets/character sprites/ezra/ezra_base.png").get_image()
	img.resize(32, 32)
	custom_cursor = ImageTexture.create_from_image(img)

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func toggle_pause():
	game_is_paused = !game_is_paused
	get_tree().paused = game_is_paused

	if game_is_paused:
		Input.set_custom_mouse_cursor(custom_cursor)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _process(delta):
	if not game_is_paused:
		play_time += delta
		
func get_formatted_play_time() -> String:
	var total_seconds = int(play_time)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%02dh %02dm %02ds" % [hours, minutes, seconds]
