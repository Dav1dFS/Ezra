extends Node2D

@onready var player: Node2D = $Player
@onready var ellen_character: Node2D = $"EllenNPC"
@onready var frieda_character: Node2D = $"FriedaNPC"
@onready var general_character: Node2D = $"General"
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var cutscene_camera: Camera2D = $CutsceneController/CutsceneCamera2D

# Store initial positions
var ellen_initial_pos: Vector2
var frieda_initial_pos: Vector2
var ezra_initial_pos: Vector2

# Animation settings
const SLIDE_DURATION: float = 1.0
const CAMERA_MOVE_DURATION: float = 0.8
const FADE_DURATION: float = 0.5
const SHAKE_DURATION: float = 0.3
const SHAKE_STRENGTH: float = 5.0

func _ready():
	player.changeObjective("Talk to Ellen")

	# Store initial positions
	ellen_initial_pos = ellen_character.global_position
	frieda_initial_pos = frieda_character.global_position
	ezra_initial_pos = player.global_position

	# Hide characters initially
	player.visible = false
	frieda_character.visible = false
	general_character.visible = false

	# Connect to dialogue box mid_action signal
	dialogue_box.mid_action_triggered.connect(_on_mid_action)

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

# Helper: Move camera to position
func _move_camera_to(target_pos: Vector2, duration: float = CAMERA_MOVE_DURATION) -> Tween:
	var tween = create_tween()
	tween.tween_property(cutscene_camera, "global_position", target_pos, duration)
	return tween

# Helper: Slide character to position
func _slide_character(character: Node2D, target_pos: Vector2, duration: float = SLIDE_DURATION) -> Tween:
	var tween = create_tween()
	tween.tween_property(character, "global_position", target_pos, duration)
	return tween

# Helper: Fade character visibility
func _fade_character(character: Node2D, fade_in: bool, duration: float = FADE_DURATION) -> Tween:
	var tween = create_tween()
	if fade_in:
		character.modulate.a = 0.0
		character.visible = true
		tween.tween_property(character, "modulate:a", 1.0, duration)
	else:
		tween.tween_property(character, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): character.visible = false)
	return tween

# Helper: Shake camera
func _shake_camera(duration: float = SHAKE_DURATION, strength: float = SHAKE_STRENGTH):
	var original_pos = cutscene_camera.global_position
	var tween = create_tween()
	var shake_count = 6
	for i in range(shake_count):
		var offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(cutscene_camera, "global_position", original_pos + offset, duration / shake_count)
	tween.tween_property(cutscene_camera, "global_position", original_pos, duration / shake_count)
	return tween

# Action: Ezra appears
func _action_ezra_appears():
	_fade_character(player, true)
	# Move camera to Frieda's X (middle of Ellen and Ezra)
	var target_pos = Vector2(frieda_initial_pos.x, cutscene_camera.global_position.y)
	var tween = _move_camera_to(target_pos)
	await tween.finished
	dialogue_box.continue_after_action()

# Action: Frieda at the door
func _action_frieda_at_door():
	var tween = _move_camera_to(frieda_character.global_position)
	await tween.finished
	await _shake_camera().finished
	frieda_character.visible = true
	dialogue_box.continue_after_action()

# Action: Frieda gets closer
func _action_frieda_gets_closer():
	var target_pos = Vector2(frieda_character.global_position.x, ellen_character.global_position.y)
	var slide_tween = _slide_character(frieda_character, target_pos)
	_move_camera_to(frieda_character.global_position + (target_pos - frieda_character.global_position) / 2)
	await slide_tween.finished
	_move_camera_to(frieda_character.global_position)
	await get_tree().create_timer(CAMERA_MOVE_DURATION).timeout
	dialogue_box.continue_after_action()

# Action: Guards searching
func _action_guards_searching():
	var tween = _move_camera_to(frieda_initial_pos)
	await tween.finished
	await _shake_camera().finished
	await get_tree().create_timer(0.5).timeout
	var return_tween = _move_camera_to(frieda_character.global_position)
	await return_tween.finished
	dialogue_box.continue_after_action()

# Action: Ezra possesses Ellen
func _action_ezra_possesses_ellen():
	var ellen_hide_pos = Vector2(4912, 2079)

	# Ezra moves to Ellen and fades out
	var ezra_tween = create_tween()
	ezra_tween.set_parallel(true)
	ezra_tween.tween_property(player, "global_position", ellen_initial_pos, SLIDE_DURATION)
	ezra_tween.tween_property(player, "modulate:a", 0.0, SLIDE_DURATION)

	await ezra_tween.finished
	player.visible = false

	# Ellen slides to hide position
	var ellen_tween = _slide_character(ellen_character, ellen_hide_pos)
	await ellen_tween.finished

	# Frieda slides to Ellen's initial position
	var frieda_tween = _slide_character(frieda_character, ellen_initial_pos)
	await frieda_tween.finished

	# General appears and slides to Ezra's initial position
	general_character.visible = true
	general_character.modulate.a = 1.0
	var general_tween = _slide_character(general_character, ezra_initial_pos)
	await general_tween.finished

	# Center camera on the scene
	var target_pos = Vector2(frieda_initial_pos.x, cutscene_camera.global_position.y)
	await _move_camera_to(target_pos).finished

	dialogue_box.continue_after_action()

func _action_next_scene():
	await get_tree().create_timer(0.5).timeout

	get_tree().change_scene_to_file("res://scenes/gameplay/level_1/day_1_puzzle_1.tscn")
