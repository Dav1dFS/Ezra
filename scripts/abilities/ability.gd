class_name Ability
extends Resource

@export var ability_name: String = ""
@export var ability_icon: Texture2D
@export var description: String = ""
@export var cooldown_time: float = 0.0
@export var duration: float = 0.0
@export var is_toggle: bool = false
@export var requires_hold: bool = false
@export var hold_time: float = 0.0

var is_ready: bool = true
var is_active: bool = false
var cooldown_timer: float = 0.0
var active_timer: float = 0.0
var hold_progress: float = 0.0


signal activated
signal deactivated
signal cooldown_started(cooldown_duration: float)
signal cooldown_finished
signal hold_progress_updated(progress: float)


func update(delta: float, player: CharacterBody2D) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			cooldown_timer = 0
			is_ready = true
			cooldown_finished.emit()

	if is_active and duration > 0:
		active_timer -= delta
		if active_timer <= 0:
			deactivate()


func activate() -> void:
	if not is_ready:
		return

	is_active = true
	is_ready = false
	active_timer = duration
	activated.emit()


func deactivate() -> void:
	is_active = false
	cooldown_timer = cooldown_time
	deactivated.emit()

	if cooldown_time > 0:
		cooldown_started.emit(cooldown_time)


func execute(player: CharacterBody2D) -> void:
	push_warning("Ability.execute() not implemented for: " + ability_name)


func get_cooldown_progress() -> float:
	if cooldown_time <= 0:
		return 1.0
	return 1.0 - (cooldown_timer / cooldown_time)


func get_hold_progress() -> float:
	if hold_time <= 0:
		return 1.0
	return hold_progress / hold_time


func reset() -> void:
	is_ready = true
	is_active = false
	cooldown_timer = 0.0
	active_timer = 0.0
	hold_progress = 0.0
