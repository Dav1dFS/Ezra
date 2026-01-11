class_name AbilityUI
extends Control

@onready var ability_circle: TextureRect = $AbilityCircle
@onready var ability_icon: TextureRect = $AbilityCircle/AbilityIcon
@onready var cooldown_overlay: TextureProgressBar = $AbilityCircle/CooldownOverlay
@onready var hold_progress: TextureProgressBar = $AbilityCircle/HoldProgress
@onready var ability_label: Label = $AbilityLabel

var ability_manager: AbilityManager = null
var icon_tween: Tween
var should_show_ui: bool = true


func _ready():
	await get_tree().process_frame
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("AbilityManager"):
		ability_manager = player.get_node("AbilityManager")
		_connect_signals()

	_reset_ui()


func _process(_delta: float):
	var in_dialogue = Gamestate.is_talking or Gamestate.dialogue_locked
	var should_hide = in_dialogue or Gamestate.game_is_paused

	if should_hide and visible:
		visible = false


func _connect_signals():
	if not ability_manager:
		return

	ability_manager.ability_changed.connect(_on_ability_changed)
	ability_manager.cooldown_updated.connect(_on_cooldown_updated)
	ability_manager.hold_updated.connect(_on_hold_updated)

	if ability_manager.primary_ability:
		_on_ability_changed(ability_manager.primary_ability)


func _reset_ui():
	if cooldown_overlay:
		cooldown_overlay.value = 100
	if hold_progress:
		hold_progress.value = 0
		hold_progress.visible = false


func _on_ability_changed(ability: Ability):
	if not ability:
		should_show_ui = false
		visible = false
		return

	should_show_ui = true

	var in_dialogue = Gamestate.is_talking or Gamestate.dialogue_locked
	if not in_dialogue and not Gamestate.game_is_paused:
		visible = true

	if ability_icon and ability.ability_icon:
		_animate_icon_change(ability.ability_icon)

	if ability_label:
		ability_label.text = ability.ability_name

	_reset_ui()

	if hold_progress:
		hold_progress.visible = ability.requires_hold


func _animate_icon_change(new_icon: Texture2D):
	if icon_tween:
		icon_tween.kill()

	icon_tween = create_tween()
	icon_tween.set_parallel(true)

	icon_tween.tween_property(ability_icon, "modulate:a", 0.0, 0.15)

	icon_tween.chain().tween_callback(func(): ability_icon.texture = new_icon)
	icon_tween.tween_property(ability_icon, "modulate:a", 1.0, 0.15)


func _on_cooldown_updated(progress: float):
	if not cooldown_overlay:
		return

	cooldown_overlay.value = progress * 100


func _on_hold_updated(progress: float):
	if not hold_progress:
		return

	hold_progress.value = progress * 100

	if progress > 0:
		hold_progress.visible = true
	elif not ability_manager or not ability_manager.primary_ability or not ability_manager.primary_ability.requires_hold:
		hold_progress.visible = false


func _exit_tree():
	if icon_tween:
		icon_tween.kill()
