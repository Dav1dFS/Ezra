extends Node2D

#Settings Alteráveis no inspector
@export_group("Cutscene Targets")
@export var target_npc: Node2D       
@export var dialogue_box: CanvasLayer

@export_group("UI Elements")
@export var fade_rect: ColorRect
@export var transition_label: Label
@export var transition_text: String = "Night 1"

@export_group("Camera Settings")
@export var initial_zoom: Vector2 = Vector2(2.0, 2.0)
@export var final_zoom: Vector2 = Vector2(5.0, 5.0)
@export var zoom_duration: float = 1.5

@export_group("Timing")
@export var fade_in_duration: float = 0.8
@export var fade_out_duration: float = 0.8
@export var label_display_time: float = 3.0

@export_group("Gamestate Flags")
@export var cutscene_flag_name: String = "night1_intro_done"

@export_group("GUI Elements to Hide")
@export var hide_objective: bool = true
@export var hide_green_aura: bool = true
@export var disable_memory_zoom: bool = true

@onready var player = $"../Player"
@onready var player_camera: Camera2D = $"../Player/Camera2D"
@onready var objective: Control = $"../Player/GUI/Objective"
@onready var green_aura: ColorRect = $"../Player/GUI/ColorRect"
@onready var white_aura: ColorRect = $"../Player/GUI/ColorRect2"
@onready var cutscene_camera: Camera2D = $CutsceneCamera2D

var running := false
var previous_camera: Camera2D = null

func _ready():
	if target_npc == null:
		target_npc = get_parent().get_node("Ellen") # fallback
		if target_npc == null:
			push_error("Cutscene: No target NPC found!")
			return
			
	if dialogue_box:
		if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
			dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	var cutscene_done = Gamestate.get(cutscene_flag_name) if cutscene_flag_name in Gamestate else false
	
	if not cutscene_done:
		_start_intro()
	else:
		_skip_cutscene()

func _start_intro():
	running = true
	previous_camera = player_camera

	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true

	if disable_memory_zoom:
		Gamestate.memory_zoom_enabled = false

	# Hide UI elements
	if hide_objective and objective:
		objective.visible = false
	if hide_green_aura and green_aura:
		green_aura.visible = false

	# Setup fade - start fully black
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	# Show transition label on black screen
	if transition_label and not transition_text.is_empty():
		transition_label.text = transition_text
		transition_label.visible = true
		await get_tree().create_timer(label_display_time).timeout
		transition_label.visible = false

	# Setup cutscene camera while still black
	cutscene_camera.global_position = target_npc.global_position
	cutscene_camera.zoom = initial_zoom
	cutscene_camera.make_current()

	# Fade in to cutscene
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	tween.finished.connect(_on_initial_fade_in_finished)


func _on_initial_fade_in_finished():
	_start_camera_zoom()


func _start_camera_zoom():
	var tween = get_tree().create_tween()
	tween.tween_property(cutscene_camera, "zoom", final_zoom, zoom_duration)
	tween.finished.connect(_on_zoom_finished)


func _on_zoom_finished():
	dialogue_box.visible = true
	
	# Start NPC dialogue via cutscene method
	if target_npc.has_method("start_dialogue_from_cutscene"):
		target_npc.start_dialogue_from_cutscene(player)
	else:
		push_error("Target NPC doesn't have start_dialogue_from_cutscene method!")

func _on_dialogue_ended(npc_node: Node, fully_completed: bool = true):
	if not running:
		return
	
	if npc_node != target_npc:
		return
	
	# Set completion flag
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
