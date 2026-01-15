extends "res://scripts/npcs/general_talkable_npc.gd"

@onready var ability_label: Label = $PlayerAbilityLabel
@onready var ability_progress: TextureProgressBar = $AbilityProgress

var glowrect: ColorRect
var pointlight: PointLight2D

@export var ability_hold_time: float = 3.0

var fade_rect: ColorRect
var day_label: Label
var ability_timer: float = 0.0
var ability_holding: bool = false
var all_collected_dialogue_shown: bool = false

func _ready():
	super._ready()
	if all_collected_gamestate_flag.is_empty():
		all_collected_gamestate_flag = "can_control_frieda"
		
	var cutscene_controller = get_tree().get_current_scene().get_node_or_null("CutsceneController")
	if cutscene_controller:
		fade_rect = cutscene_controller.get_node_or_null("CutsceneUI/FadeRect") as ColorRect
		day_label = cutscene_controller.get_node_or_null("CutsceneUI/TransitionLabel") as Label
	else:
		push_warning("CutsceneController não encontrado na cena!")
		
	glowrect = find_child("GlowRect", true, false) as ColorRect
	if not glowrect:
		glowrect = get_node_or_null("ColorRect") as ColorRect

	pointlight = find_child("PointLight2D", true, false) as PointLight2D

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

func _process(_delta: float):
	if not player_in_range:
		if ability_label:
			ability_label.visible = false
		return

	if Gamestate.is_talking or Gamestate.dialogue_locked:
		return

	var can_use_ability = _can_use_ability() and all_collected_dialogue_shown

	if can_use_ability:
		if interact_label:
			interact_label.visible = false
	else:
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

func _try_push_possess_ability():
	if not player_in_range:
		return

	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	Gamestate.ezra_can_spawn_footprints = false

	var ability_manager = player.get("ability_manager")
	if ability_manager:
		var possess_ability = EzraPossessAbility.new()
		ability_manager.push_ability(possess_ability)


func _on_body_entered(body: Node):
	super._on_body_entered(body)
	if body.name == "Player" and Gamestate.can_control_frieda:
		Gamestate.ezra_can_spawn_footprints = false

		var ability_manager = body.get("ability_manager")
		if ability_manager:
			var possess_ability = EzraPossessAbility.new()
			ability_manager.push_ability(possess_ability)

func _on_body_exited(body: Node):
	super._on_body_exited(body)
	if body.name == "Player":
		Gamestate.ezra_can_spawn_footprints = true
		if ability_label:
			ability_label.visible = false

		var ability_manager = body.get("ability_manager")
		if ability_manager:
			ability_manager.pop_ability()

func _start_day2_transition():
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	day_label.visible = false
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	tween.finished.connect(_on_fade_to_black_done)

func _on_fade_to_black_done():
	day_label.text = "TO BE\nCONTINUED..."
	day_label.visible = true
	await get_tree().create_timer(3.0).timeout
	day_label.visible = false
	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false
	await fade_to_black(0.6)
	get_tree().change_scene_to_file("res://scenes/UI/credits_cutscene.tscn")

func fade_to_black(duration := 0.5) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

	


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

		# Push possess ability if player is still in range
		_try_push_possess_ability()
