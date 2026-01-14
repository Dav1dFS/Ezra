extends Node2D

@export_group("Cutscene Intro")
@export var auto_start_cutscene: bool = false
@export var target_npc: Node2D
@export var dialogue_box: CanvasLayer

@export_group("Transition Settings")
@export var transition_text: String

@export_group("Camera Settings")
@export var initial_zoom: Vector2 = Vector2(2.0, 2.0)
@export var final_zoom: Vector2 = Vector2(5.0, 5.0)
@export var zoom_duration: float = 1.5

@export_group("Timing")
@export var fade_in_duration: float = 0.8
@export var fade_out_duration: float = 0.8
@export var label_display_time: float = 3.0

@export_group("Animation Defaults")
@export var default_slide_duration: float = 1.0
@export var default_camera_move_duration: float = 0.8
@export var default_fade_duration: float = 0.5
@export var default_shake_duration: float = 0.3
@export var default_shake_strength: float = 5.0

@export_group("Gamestate Flags")
@export var cutscene_flag_name: String

@export_group("GUI Elements to Hide")
@export var hide_objective: bool = true
@export var hide_green_aura: bool = true
@export var disable_memory_zoom: bool = true

signal mid_action_requested(action_name: String)
signal scene_fade_in_completed
signal scene_fade_out_completed

@onready var cutscene_camera: Camera2D = $CutsceneCamera2D
@onready var fade_rect: ColorRect = $CutsceneUI/FadeRect
@onready var transition_label: Label = $CutsceneUI/TransitionLabel

var player: Node2D
var player_camera: Camera2D
var objective: Control
var green_aura: ColorRect

var running := false
var previous_camera: Camera2D = null

func _ready():
	_find_player_references()
	_find_dialogue_box()

	if auto_start_cutscene and target_npc and dialogue_box:
		_connect_dialogue_signals()

		var cutscene_done = Gamestate.get(cutscene_flag_name) if cutscene_flag_name in Gamestate else false

		if not cutscene_done:
			_start_intro()
		else:
			_skip_cutscene()
			
func runCutscene():
		_connect_dialogue_signals()

		var cutscene_done = Gamestate.get(cutscene_flag_name) if cutscene_flag_name in Gamestate else false

		if not cutscene_done:
			print("starting")
			_start_intro()
		else:
			_skip_cutscene()


func _find_dialogue_box():
	if dialogue_box:
		return
	dialogue_box = get_parent().get_node_or_null("DialogueBox")


func _connect_dialogue_signals():
	if not dialogue_box:
		return
	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	if dialogue_box.has_signal("mid_action_triggered"):
		if not dialogue_box.mid_action_triggered.is_connected(_on_mid_action):
			dialogue_box.mid_action_triggered.connect(_on_mid_action)

func _find_player_references():
	player = get_parent().get_node_or_null("Player")
	if player:
		player_camera = player.get_node_or_null("Camera2D")
		var gui = player.get_node_or_null("GUI")
		if gui:
			objective = gui.get_node_or_null("Objective")
			green_aura = gui.get_node_or_null("ColorRect")

func _start_intro():
	running = true
	previous_camera = player_camera

	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true

	if disable_memory_zoom:
		Gamestate.memory_zoom_enabled = false

	if hide_objective and objective:
		objective.visible = false
	if hide_green_aura and green_aura:
		green_aura.visible = false

	if dialogue_box:
		dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	if transition_label and not transition_text.is_empty():
		transition_label.text = transition_text
		transition_label.visible = true
		await get_tree().create_timer(label_display_time).timeout
		transition_label.visible = false

	cutscene_camera.global_position = target_npc.global_position
	cutscene_camera.zoom = initial_zoom
	cutscene_camera.make_current()

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	tween.finished.connect(_on_initial_fade_in_finished)


func _on_initial_fade_in_finished():
	var tween = get_tree().create_tween()
	tween.tween_property(cutscene_camera, "zoom", final_zoom, zoom_duration)
	tween.finished.connect(_on_zoom_finished)


func _on_zoom_finished():
	if dialogue_box:
		dialogue_box.visible = true

	if target_npc and target_npc.has_method("start_dialogue_from_cutscene"):
		target_npc.start_dialogue_from_cutscene(player)
	elif target_npc:
		push_error("Target NPC doesn't have start_dialogue_from_cutscene method!")

func _on_dialogue_ended(npc_node: Node, fully_completed: bool = true):
	if not running:
		return
	
	if npc_node != target_npc:
		return
	
	if fully_completed:
		if cutscene_flag_name in Gamestate:
			Gamestate.set(cutscene_flag_name, true)
	
		_start_fade_sequence()

func _start_fade_sequence() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	
	if transition_label:
		transition_label.visible = false
	
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	tween.finished.connect(_on_fade_to_black_done)

func _on_fade_to_black_done() -> void:
	if previous_camera:
		previous_camera.make_current()
	cutscene_camera.enabled = false

	if hide_green_aura and green_aura:
		green_aura.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	tween.finished.connect(_on_fade_in_finished)

func _on_fade_in_finished() -> void:
	fade_rect.visible = false
	
	if hide_objective and objective:
		objective.visible = true
	
	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false
	
	if disable_memory_zoom:
		Gamestate.memory_zoom_enabled = true
	
	running = false

func _skip_cutscene():
	if fade_rect:
		fade_rect.visible = false
	if transition_label:
		transition_label.visible = false

func _on_mid_action(action_name: String):
	mid_action_requested.emit(action_name)

func move_camera_to(target_pos: Vector2, duration: float = -1.0) -> Tween:
	if duration < 0:
		duration = default_camera_move_duration
	var tween = create_tween()
	tween.tween_property(cutscene_camera, "global_position", target_pos, duration)
	return tween

func slide_character(character: Node2D, target_pos: Vector2, duration: float = -1.0) -> Tween:
	if duration < 0:
		duration = default_slide_duration
	var tween = create_tween()
	tween.tween_property(character, "global_position", target_pos, duration)
	return tween

func fade_character(character: Node2D, fade_in: bool, duration: float = -1.0) -> Tween:
	if duration < 0:
		duration = default_fade_duration
	var tween = create_tween()
	if fade_in:
		character.modulate.a = 0.0
		character.visible = true
		tween.tween_property(character, "modulate:a", 1.0, duration)
	else:
		tween.tween_property(character, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): character.visible = false)
	return tween

func shake_camera(duration: float = -1.0, strength: float = -1.0) -> Tween:
	if duration < 0:
		duration = default_shake_duration
	if strength < 0:
		strength = default_shake_strength
	var original_pos = cutscene_camera.global_position
	var tween = create_tween()
	var shake_count = 6
	for i in range(shake_count):
		var offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(cutscene_camera, "global_position", original_pos + offset, duration / shake_count)
	tween.tween_property(cutscene_camera, "global_position", original_pos, duration / shake_count)
	return tween

func scene_fade_in(label_text: String = "", duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_in_duration

	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	if transition_label and not label_text.is_empty():
		transition_label.text = label_text
		transition_label.visible = true
		await get_tree().create_timer(label_display_time).timeout
		transition_label.visible = false

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

	fade_rect.visible = false
	scene_fade_in_completed.emit()


func scene_fade_out(next_scene_path: String = "", duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_out_duration

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	if transition_label:
		transition_label.visible = false

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

	scene_fade_out_completed.emit()

	if not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)
