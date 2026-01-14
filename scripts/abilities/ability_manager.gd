class_name AbilityManager
extends Node

var primary_ability: Ability = null
var ability_stack: Array[Ability] = []

signal ability_changed(ability: Ability)
signal ability_activated(ability: Ability)
signal ability_deactivated(ability: Ability)
signal cooldown_updated(progress: float)
signal hold_updated(progress: float)

func _ready():
	set_process(true)
	set_physics_process(true)


func _process(delta: float):
	if not primary_ability:
		return

	var player = get_parent() as CharacterBody2D
	if player:
		primary_ability.update(delta, player)

		if primary_ability.cooldown_timer > 0:
			var progress = primary_ability.get_cooldown_progress()
			cooldown_updated.emit(progress)


func _input(event: InputEvent):
	if not primary_ability or not primary_ability.is_ready:
		return

	if Gamestate.dialogue_locked or Gamestate.game_is_paused:
		return

	if event.is_action_pressed("ability"):
		if primary_ability.requires_hold:
			pass
		else:
			_try_execute_ability()

	if event.is_action_released("ability"):
		if primary_ability.requires_hold:
			primary_ability.hold_progress = 0.0
			hold_updated.emit(0.0)


func _physics_process(delta: float):
	if not primary_ability or not primary_ability.is_ready:
		return

	if Gamestate.dialogue_locked or Gamestate.game_is_paused:
		return

	if Input.is_action_pressed("ability") and primary_ability.requires_hold:
		primary_ability.hold_progress += delta
		var progress = primary_ability.get_hold_progress()
		hold_updated.emit(progress)

		if primary_ability.hold_progress >= primary_ability.hold_time:
			_try_execute_ability()
			primary_ability.hold_progress = 0.0
			hold_updated.emit(0.0)


func _try_execute_ability():
	if not primary_ability or not primary_ability.is_ready:
		return

	var player = get_parent() as CharacterBody2D
	if not player:
		push_error("AbilityManager: Parent is not a CharacterBody2D!")
		return

	if primary_ability.is_toggle:
		if primary_ability.is_active:
			primary_ability.execute(player)
			primary_ability.deactivate()
			ability_deactivated.emit(primary_ability)
		else:
			primary_ability.execute(player)
			primary_ability.activate()
			ability_activated.emit(primary_ability)
	else:
		primary_ability.execute(player)
		primary_ability.activate()
		ability_activated.emit(primary_ability)

		if primary_ability.duration <= 0:
			primary_ability.deactivate()
			ability_deactivated.emit(primary_ability)


func set_primary_ability(ability: Ability):
	if primary_ability:
		if primary_ability.activated.is_connected(_on_ability_activated):
			primary_ability.activated.disconnect(_on_ability_activated)
		if primary_ability.deactivated.is_connected(_on_ability_deactivated):
			primary_ability.deactivated.disconnect(_on_ability_deactivated)
		if primary_ability.cooldown_finished.is_connected(_on_cooldown_finished):
			primary_ability.cooldown_finished.disconnect(_on_cooldown_finished)

	primary_ability = ability

	if primary_ability:
		primary_ability.activated.connect(_on_ability_activated)
		primary_ability.deactivated.connect(_on_ability_deactivated)
		primary_ability.cooldown_finished.connect(_on_cooldown_finished)

		primary_ability.reset()

	ability_changed.emit(primary_ability)


func push_ability(ability: Ability):
	if primary_ability:
		ability_stack.push_back(primary_ability)
	set_primary_ability(ability)


func pop_ability():
	if ability_stack.size() > 0:
		var previous = ability_stack.pop_back()
		set_primary_ability(previous)
	else:
		push_warning("AbilityManager: Attempted to pop ability but stack is empty")


func is_on_cooldown() -> bool:
	return primary_ability != null and not primary_ability.is_ready


func get_ability_name() -> String:
	return primary_ability.ability_name if primary_ability else ""


func get_ability_icon() -> Texture2D:
	return primary_ability.ability_icon if primary_ability else null


func _on_ability_activated():
	pass


func _on_ability_deactivated():
	pass


func _on_cooldown_finished():
	cooldown_updated.emit(1.0)
