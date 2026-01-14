extends Node2D

@onready var player: Node2D = $Player
@onready var ellen_character: Node2D = $"EllenNPC"
@onready var frieda_character: Node2D = $"FriedaNPC"
@onready var general_character: Node2D = $"General"
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var cutscene: Node2D = $CutsceneController

var ellen_initial_pos: Vector2
var frieda_initial_pos: Vector2
var ezra_initial_pos: Vector2

func _ready():
	player.get_node("GUI").get_node("Objective").visible = false
	player.get_node("GUI").get_node("AbilityUI").visible = false

	ellen_initial_pos = ellen_character.global_position
	frieda_initial_pos = frieda_character.global_position
	ezra_initial_pos = player.global_position

	player.visible = false
	frieda_character.visible = false
	general_character.visible = false

	cutscene.mid_action_requested.connect(_on_mid_action)

func _on_mid_action(action_name: String):
	match action_name:
		"erza_appears":
			_action_ezra_appears()
		"frieda_at_the_door":
			_action_frieda_at_door()
		"frieda_gets_closer":
			_action_frieda_gets_closer()
		"guards_searching_ellen":
			_action_guards_searching()
		"ezra_possesses_ellen":
			_action_ezra_possesses_ellen()
		"next_scene":
			_action_next_scene()
		_:
			push_warning("Unknown mid_action: " + action_name)
			dialogue_box.continue_after_action()


func _action_ezra_appears():
	cutscene.fade_character(player, true)
	var target_pos = Vector2(frieda_initial_pos.x, cutscene.cutscene_camera.global_position.y)
	var tween = cutscene.move_camera_to(target_pos)
	await tween.finished
	dialogue_box.continue_after_action()


func _action_frieda_at_door():
	var tween = cutscene.move_camera_to(frieda_character.global_position)
	await tween.finished
	await cutscene.shake_camera().finished
	frieda_character.visible = true
	dialogue_box.continue_after_action()


func _action_frieda_gets_closer():
	var target_pos = Vector2(frieda_character.global_position.x, ellen_character.global_position.y)
	var slide_tween = cutscene.slide_character(frieda_character, target_pos)
	cutscene.move_camera_to(frieda_character.global_position + (target_pos - frieda_character.global_position) / 2)
	await slide_tween.finished
	cutscene.move_camera_to(frieda_character.global_position)
	await get_tree().create_timer(0.8).timeout
	dialogue_box.continue_after_action()


func _action_guards_searching():
	var tween = cutscene.move_camera_to(frieda_initial_pos)
	var music_index = AudioServer.get_bus_index("Music") 
	AudioServer.set_bus_mute(music_index, true)
	$Whistle.play()
	await tween.finished
	await cutscene.shake_camera().finished
	await get_tree().create_timer(0.5).timeout
	var return_tween = cutscene.move_camera_to(frieda_character.global_position)
	await return_tween.finished
	dialogue_box.continue_after_action()


func _action_ezra_possesses_ellen():
	var ellen_hide_pos = Vector2(4912, 2079)

	var ezra_tween = create_tween()
	ezra_tween.set_parallel(true)
	ezra_tween.tween_property(player, "global_position", ellen_initial_pos, 1.0)
	ezra_tween.tween_property(player, "modulate:a", 0.0, 1.0)
	await ezra_tween.finished
	player.visible = false

	await cutscene.slide_character(ellen_character, ellen_hide_pos).finished
	await cutscene.slide_character(frieda_character, ellen_initial_pos).finished

	general_character.visible = true
	general_character.modulate.a = 1.0
	await cutscene.slide_character(general_character, ezra_initial_pos).finished

	var target_pos = Vector2(frieda_initial_pos.x, cutscene.cutscene_camera.global_position.y)
	await cutscene.move_camera_to(target_pos).finished

	dialogue_box.continue_after_action()

func _action_next_scene():
	await get_tree().create_timer(0.5).timeout
	Gamestate.dialogue_locked = false
	Gamestate.is_talking = false
	await cutscene.scene_fade_out("res://scenes/gameplay/level_1/day_1_puzzle_1.tscn")
