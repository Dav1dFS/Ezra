extends Node2D

@export var target_npc: Node2D       
@export var dialogue_box: CanvasLayer
@export var fade_rect: ColorRect
@export var night_label: Label

@onready var player = $"../Player"
@onready var player_camera: Camera2D = $"../Player/Camera2D"
@onready var counter: Control = $"../Player/GUI/Counter"
@onready var green_aura: ColorRect = $"../Player/GUI/ColorRect"
@onready var white_aura: ColorRect = $"../Player/GUI/ColorRect2"
@onready var cutscene_camera: Camera2D = $CutsceneCamera2D

var running := false
var previous_camera: Camera2D = null

func _ready():
	if target_npc == null:
		target_npc = get_parent().get_node("Ellen") # fallback

	dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	if not Gamestate.ellen_night1_intro_done:
		_start_intro()
	else:
		
		if fade_rect:
			fade_rect.visible = false

func _start_intro():
	running = true
	previous_camera = player_camera

	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true
	Gamestate.memory_zoom_enabled = false
	
	if counter:
		counter.visible = false
	if green_aura:
		green_aura.visible = false

	cutscene_camera.global_position = target_npc.global_position
	cutscene_camera.zoom = Vector2(2.0, 2.0) 
	cutscene_camera.make_current()

	dialogue_box.visible = false

	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	night_label.visible = false

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	tween.finished.connect(_on_initial_fade_in_finished)

func _on_initial_fade_in_finished():
	start_cutscene()

func start_cutscene():
	
	var tween = get_tree().create_tween()

	var target_zoom = Vector2(5.0, 5.0)
	tween.tween_property(cutscene_camera, "zoom", target_zoom, 1.5)
	tween.finished.connect(_on_zoom_in_finished)

func _on_zoom_in_finished():
	var ellen = target_npc
	ellen.from_cutscene = true
	dialogue_box.visible = true
	ellen.start_dialogue()

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if not running:
		return
	if npc_node != target_npc:
		return

	Gamestate.ellen_night1_intro_done = true
	_start_fade_sequence()

func _start_fade_sequence() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	night_label.visible = false

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	tween.finished.connect(_on_fade_to_black_done)


func _on_fade_to_black_done() -> void:	
	if previous_camera:
		previous_camera.make_current()

	cutscene_camera.enabled = false
	
	night_label.visible = true
	await get_tree().create_timer(3.0).timeout
	night_label.visible = false
	
	if green_aura:
		green_aura.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	tween.finished.connect(_on_fade_in_finished)

func _on_fade_in_finished() -> void:
	fade_rect.visible = false
	
	if counter:
		counter.visible = true

	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false
	Gamestate.memory_zoom_enabled = true
	running = false
