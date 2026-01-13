class_name EzraPossessAbility
extends Ability

func _init():
	ability_name = "Possess"
	# ability_icon = preload("res://assets/abilities/ezra_ability_possess.png")
	ability_icon = preload("res://assets/abilities/ezra_ability_track.png")
	# ability_sound = preload("res://assets/abilities/ezra_ability_possess.mp3")
	ability_sound = preload("res://assets/abilities/ezra_ability_track.mp3")
	description = "Possess and unlock new abilities"
	requires_hold = true
	hold_time = 3.0
	cooldown_time = 0.0
	duration = 0.0
	is_toggle = false


func execute(player: CharacterBody2D) -> void:
	if not Gamestate.can_control_frieda:
		return

	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true

	var frieda: Node = null

	if "target_npc" in player and player.target_npc:
		frieda = player.get_node_or_null(player.target_npc)

	if not frieda:
		var scene_root = player.get_tree().get_current_scene()
		for child in scene_root.get_children():
			if child.name.contains("Frieda") or child.name.contains("frieda"):
				frieda = child
				break

	if frieda and frieda.has_method("_start_day2_transition"):
		frieda._start_day2_transition()
	else:
		push_warning("PossessAbility: Could not find Frieda NPC or transition method")
		Gamestate.is_talking = false
		Gamestate.dialogue_locked = false
		return

	activate()
