extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var counter: Control = $GUI/Counter

var is_ability_active: bool = false


var ellen_sprites = {
	Direction.DOWN: preload("res://assets/character sprites/ezra/ezra_base.png"),
	Direction.UP: preload("res://assets/character sprites/ezra/ezra_back.png"),
	Direction.LEFT: preload("res://assets/character sprites/ezra/ezra_left.png"),
	Direction.RIGHT: preload("res://assets/character sprites/ezra/ezra_right.png")
}

func _ready():
	character_name = "Ezra"
	super._ready()

func _update_sprite_for_direction():
	if ellen_sprites.has(current_direction):
		sprite.texture = ellen_sprites[current_direction]

func increment_item_counter():
	print("added counter")
	counter.add_point()

		
	
