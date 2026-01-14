class_name EllenHideAbility
extends Ability

const SHAKE_TIME: float = 1.5
const AUTO_DEACTIVATE_TIME: float = 3.0

var time_active: float = 0.0
var shake_shown: bool = false
var is_restoring: bool = false
var restore_animation_name: String = ""
var sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var light_occluder: LightOccluder2D
var player_ref: CharacterBody2D
var current_direction: int = 3

var hide_anims = {
	0: "hideR",
	1: "hideL",
	2: "hideU",
	3: "hideD"
}
var shake_anims = {
	0: "shakeR",
	1: "shakeL",
	2: "shakeU",
	3: "shakeD"
}
var hide_back_anims = {
	0: "hideR_back",
	1: "hideL_back",
	2: "hideU_back",
	3: "hideD_back"
}


func _init():
	ability_name = "Hide"
	ability_icon = preload("res://assets/abilities/ellen_hide_ability.png")
	ability_sound = preload("res://assets/abilities/ellen_hide_ability.mp3")
	description = "Hide from guards sight"
	is_toggle = false
	cooldown_time = 3.0
	duration = AUTO_DEACTIVATE_TIME
	requires_hold = false


func execute(player: CharacterBody2D) -> void:
	player_ref = player
	sprite = player.get_node("Base") as AnimatedSprite2D
	collision_shape = player.get_node("CollisionShape2D") as CollisionShape2D
	light_occluder = player.get_node_or_null("LightOccluder2D") as LightOccluder2D
	current_direction = player.current_direction

	if not sprite or not collision_shape:
		push_error("HideAbility: Required nodes not found on player!")
		return

	_activate_hide()


func deactivate() -> void:
	if not is_restoring:
		is_active = false  # Prevent update() from calling deactivate() repeatedly
		_start_restore()
	else:
		super.deactivate()


func update(delta: float, player: CharacterBody2D) -> void:
	super.update(delta, player)

	if is_restoring:
		_update_restoration()
		return

	if is_active:
		time_active += delta

		if not shake_shown and time_active >= SHAKE_TIME:
			shake_shown = true
			_show_shake()


func _activate_hide() -> void:
	player_ref.is_ability_active = true
	sprite.modulate.a = 0.5
	collision_shape.disabled = true

	if light_occluder:
		light_occluder.visible = false

	if current_direction in hide_anims:
		sprite.play(hide_anims[current_direction])

	time_active = 0.0
	shake_shown = false


func _show_shake() -> void:
	if current_direction in shake_anims:
		sprite.play(shake_anims[current_direction])


func _start_restore() -> void:
	is_restoring = true

	sprite.modulate.a = 1.0
	collision_shape.disabled = false
	if light_occluder:
		light_occluder.visible = true

	if current_direction in hide_back_anims:
		restore_animation_name = hide_back_anims[current_direction]
		sprite.play(restore_animation_name)
	else:
		_finish_restore()


func _update_restoration() -> void:
	if not sprite.is_playing() or sprite.animation != restore_animation_name:
		_finish_restore()


func _finish_restore() -> void:
	player_ref.is_ability_active = false
	time_active = 0.0
	shake_shown = false
	restore_animation_name = ""

	deactivate()
	is_restoring = false

