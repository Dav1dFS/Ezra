class_name EzraTrackAbility
extends Ability


func _init():
	ability_name = "Track"
	ability_icon = preload("res://assets/abilities/ezra_ability_track.png")
	ability_sound = preload("res://assets/abilities/ezra_ability_track.mp3")
	description = "Reveals a path of footprints leading to your objective"
	cooldown_time = 10.0
	duration = 6.0
	is_toggle = false
	requires_hold = false


func execute(player: CharacterBody2D) -> void:
	var can_use = Gamestate.ezra_can_spawn_footprints and not Gamestate.dog_is_alerted
	if not can_use:
		return

	var is_penalized = player.get("is_penalized") if "is_penalized" in player else false

	if is_penalized:
		duration = 3.0
		cooldown_time = 20.0
	else:
		duration = 6.0
		cooldown_time = 10.0

	player.ability_active = true
	player.ability_ready = false
	player.ability_timer = duration

	activate()
