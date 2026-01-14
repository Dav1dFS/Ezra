extends "res://scripts/player/player.gd"


func _ready():
	super._ready()
	character_name = "Ellen"
	SPEED = 50


func setup_abilities():
	var hide_ability = EllenHideAbility.new()
	ability_manager.set_primary_ability(hide_ability)


func _update_sprite_for_direction():
	if is_ability_active:
		velocity = Vector2.ZERO
	else:
		if base_anims.has(current_direction):
			sprite.play(base_anims[current_direction])


func input_handler():
	if is_ability_active:
		velocity = Vector2.ZERO
	else:
		super.input_handler()


func can_update_animations() -> bool:
	return not is_ability_active
