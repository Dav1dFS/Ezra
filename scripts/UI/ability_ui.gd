class_name AbilityUI
extends Control

@onready var ability_circle: TextureRect = $AbilityCircle
@onready var ability_icon: TextureRect = $AbilityCircle/AbilityIcon
@onready var cooldown_overlay: TextureProgressBar = $AbilityCircle/CooldownOverlay
@onready var hold_progress: TextureProgressBar = $AbilityCircle/HoldProgress
@onready var ability_label: Label = $AbilityLabel
@onready var ability_sound: AudioStreamPlayer = $AbilitySoundEffect

var ability_manager: AbilityManager = null
var icon_tween: Tween
var should_show_ui: bool = true


func _ready():
	var player = owner
	if not player:
		return

	player.child_entered_tree.connect(_on_player_child_entered)
	_find_ability_manager()
	_reset_ui()


func _on_player_child_entered(child: Node):
	if child is AbilityManager and not ability_manager:
		_find_ability_manager()


func _find_ability_manager():
	if ability_manager:
		return

	var player = owner
	if not player:
		return

	for child in player.get_children():
		if child is AbilityManager:
			ability_manager = child
			_connect_signals()
			break


func _process(_delta: float):
	var in_dialogue = Gamestate.is_talking or Gamestate.dialogue_locked
	var should_hide = in_dialogue or Gamestate.game_is_paused

	if should_hide and visible:
		visible = false
	elif not should_hide and should_show_ui and not visible:
		visible = true


func _connect_signals():
	ability_manager.ability_changed.connect(_on_ability_changed)
	ability_manager.ability_activated.connect(_on_ability_activated)
	ability_manager.cooldown_updated.connect(_on_cooldown_updated)
	ability_manager.hold_updated.connect(_on_hold_updated)

	if ability_manager.primary_ability:
		_on_ability_changed(ability_manager.primary_ability)


func _reset_ui():
	cooldown_overlay.value = 100
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

	ability_icon.texture = ability.ability_icon
	ability_label.text = ability.ability_name

	_reset_ui()

	hold_progress.visible = ability.requires_hold


func _on_ability_activated(ability: Ability):
	if ability.ability_sound:
		ability_sound.stream = ability.ability_sound
		ability_sound.play()


func _animate_icon_change(new_icon: Texture2D):
	if icon_tween:
		icon_tween.kill()

	icon_tween = create_tween()
	icon_tween.tween_property(ability_icon, "modulate:a", 0.0, 0.15)
	icon_tween.tween_callback(func(): ability_icon.texture = new_icon)
	icon_tween.tween_property(ability_icon, "modulate:a", 1.0, 0.15)


func _on_cooldown_updated(progress: float):
	cooldown_overlay.value = progress * 100


func _on_hold_updated(progress: float):
	hold_progress.value = progress * 100

	if progress > 0:
		hold_progress.visible = true
	elif ability_manager.primary_ability and not ability_manager.primary_ability.requires_hold:
		hold_progress.visible = false


func _exit_tree():
	if icon_tween:
		icon_tween.kill()
