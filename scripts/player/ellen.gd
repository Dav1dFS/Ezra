extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var is_ability_active: bool = false

var ellen_sprites = {
	Direction.DOWN: preload("res://assets/sprites/ellen-20251025T173942Z-1-001/ellen/ellen_base.png"),
	Direction.UP: preload("res://assets/sprites/ellen-20251025T173942Z-1-001/ellen/ellen_back.png"),
	Direction.LEFT: preload("res://assets/sprites/ellen-20251025T173942Z-1-001/ellen/ellen_left.png"),
	Direction.RIGHT: preload("res://assets/sprites/ellen-20251025T173942Z-1-001/ellen/ellen_right.png")
}

func get_is_ability_active() -> bool:
	return is_ability_active

func _ready():
	character_name = "Ellen"
	super._ready()

func _update_sprite_for_direction():
	if ellen_sprites.has(current_direction):
		sprite.texture = ellen_sprites[current_direction]

func _input(event):
	if event.is_action_pressed("ability"):
		toggle_transparency_ability()

func input_handler():
	if is_ability_active:
		velocity = Vector2.ZERO
	else:
		super.input_handler()

func toggle_transparency_ability():
	is_ability_active = !is_ability_active

	if is_ability_active:
		sprite.modulate.a = 0.5
		velocity = Vector2.ZERO
		collision_shape.disabled = true
	else:
		sprite.modulate.a = 1.0
		collision_shape.disabled = false
