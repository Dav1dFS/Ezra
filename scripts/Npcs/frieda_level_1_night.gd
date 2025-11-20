extends "res://scripts/Npcs/npcs.gd"

@onready var ability_label: Label = $Label2
@onready var ability_progress: TextureProgressBar = $AbilityProgress

@export var ability_hold_time: float = 3.0
@export var fade_rect: ColorRect
@export var day_label: Label
@export var next_scene_path: String = "res://scenes/gameplay/pitch.tscn"

var ability_timer: float = 0.0
var ability_holding: bool = false

func _ready():
	super._ready()
	
	if ability_label:
		ability_label.visible = false

	if ability_progress:
		ability_progress.visible = false
		ability_progress.min_value = 0.0
		ability_progress.max_value = ability_hold_time
		ability_progress.value = 0.0


func _process(delta: float) -> void:
	if not Gamestate.can_control_frieda or not Gamestate.frieda_control_line_shown:
		super._process(delta)
		return

	if not player_in_range:
		_reset_ability_charge()
		return

	if Gamestate.is_talking or Gamestate.dialogue_locked:
		_reset_ability_charge()
		return

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

func on_body_entered(body):
	super.on_body_entered(body)
	
	if body.name == "Player":
		_update_labels_for_state()

func on_body_exited(body):
	super.on_body_exited(body)

	if body.name == "Player":
		_reset_ability_charge()
		if ability_label:
			ability_label.visible = false 


func _update_labels_for_state():
	if not player_in_range:
		return

	if not Gamestate.can_control_frieda or not Gamestate.frieda_control_line_shown:
		if interact_label:
			interact_label.visible = true
		if ability_label:
			ability_label.visible = false
	else:
		if interact_label:
			interact_label.visible = false
		if ability_label:
			ability_label.visible = true

func _reset_ability_charge():
	ability_holding = false
	ability_timer = 0.0

	if ability_progress:
		ability_progress.value = 0.0
		ability_progress.visible = false


func _on_ability_fully_charged():
	_reset_ability_charge()
	print("Frieda ability activated!")
	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true

	_start_day2_transition()


func _start_day2_transition() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	day_label.visible = false

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8) 
	tween.finished.connect(_on_fade_to_black_done)


func _on_fade_to_black_done() -> void:
	day_label.visible = true

	await get_tree().create_timer(3.0).timeout
	day_label.visible = false
	get_tree().change_scene_to_file(next_scene_path)
	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false
