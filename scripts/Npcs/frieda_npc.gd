extends "res://scripts/npcs/general_talkable_npc.gd"

@onready var ability_label: Label = $Label2
@onready var ability_progress: TextureProgressBar = $AbilityProgress
@onready var glowrect: ColorRect = $ColorRect
@onready var pointlight: PointLight2D = $PointLight2D

@export var ability_hold_time: float = 3.0
@export var fade_rect: ColorRect
@export var day_label: Label
@export var next_scene_path: String = "res://scenes/gameplay/pitch.tscn"

var ability_timer: float = 0.0
var ability_holding: bool = false
var all_collected_dialogue_shown: bool = false

func _ready():
	super._ready()

	if ability_label:
		ability_label.visible = false
	if ability_progress:
		ability_progress.visible = false
		ability_progress.min_value = 0.0
		ability_progress.max_value = ability_hold_time
		ability_progress.value = 0.0
	
	if glowrect:
		glowrect.visible = false
	if pointlight:
		pointlight.visible = false

func _process(delta: float):
	if not player_in_range:
		_reset_ability_charge()
		if ability_label:
			ability_label.visible = false
		return
	
	if Gamestate.is_talking or Gamestate.dialogue_locked:
		_reset_ability_charge()
		return
	
	var can_use_ability = _can_use_ability() and all_collected_dialogue_shown
	
	if can_use_ability:
		# Modo habilidade
		if interact_label:
			interact_label.visible = false
		if ability_label:
			ability_label.visible = true
		
		if Input.is_action_pressed("ability"):
			ability_holding = true
			ability_timer += delta
			if ability_progress:
				ability_progress.visible = true
				ability_progress.value = ability_timer
			if ability_timer >= ability_hold_time:
				_on_ability_fully_charged()
		else:
			if ability_holding:
				_reset_ability_charge()
	else:
		# Modo normal
		_reset_ability_charge()
		if ability_label:
			ability_label.visible = false
		if interact_label and not dialogue_is_on:
			interact_label.visible = true
		
		if Input.is_action_just_pressed("interact"):
			if not dialogue_is_on and not Gamestate.dialogue_locked:
				start_dialogue()

func _can_use_ability() -> bool:
	if all_collected_gamestate_flag.is_empty():
		return false

	if not all_collected_gamestate_flag in Gamestate:
		return false

	return Gamestate.get(all_collected_gamestate_flag) == true

func _on_body_entered(body: Node):
	super._on_body_entered(body)

func _on_body_exited(body: Node):
	super._on_body_exited(body)
	if body.name == "Player":
		_reset_ability_charge()
		if ability_label:
			ability_label.visible = false

func _reset_ability_charge():
	ability_holding = false
	ability_timer = 0.0
	if ability_progress:
		ability_progress.value = 0.0
		ability_progress.visible = false

func _on_ability_fully_charged():
	_reset_ability_charge()
	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true
	_start_day2_transition()

func _start_day2_transition():
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	day_label.visible = false
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	tween.finished.connect(_on_fade_to_black_done)

func _on_fade_to_black_done():
	day_label.text = "DAY 2"
	day_label.visible = true
	await get_tree().create_timer(3.0).timeout
	day_label.visible = false
	get_tree().change_scene_to_file(next_scene_path)
	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	super._on_dialogue_ended(npc_node, fully_completed)
	
	if npc_node != self:
		return
	
	var all_memories_collected = false
	if not all_collected_gamestate_flag.is_empty() and all_collected_gamestate_flag in Gamestate:
		all_memories_collected = Gamestate.get(all_collected_gamestate_flag) == true

	if all_memories_collected and fully_completed and not all_collected_dialogue_shown:
		all_collected_dialogue_shown = true
		
		if glowrect:
			glowrect.visible = true
		if pointlight:
			pointlight.visible = true
