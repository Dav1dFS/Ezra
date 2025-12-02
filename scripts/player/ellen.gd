extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var is_ability_active: bool = false
@onready var counter: Control = $GUI/Objective

@onready var timer: Timer = $Timer

var ellen_sprites = {
	Direction.DOWN: preload("res://assets/character sprites/ellen/ellen_base.png"),
	Direction.UP: preload("res://assets/character sprites/ellen/ellen_back.png"),
	Direction.LEFT: preload("res://assets/character sprites/ellen/ellen_left.png"),
	Direction.RIGHT: preload("res://assets/character sprites/ellen/ellen_right.png")
}

func get_is_ability_active() -> bool:
	return is_ability_active

func _ready():
	character_name = "Ellen"
	timer.wait_time = 3.0
	timer.one_shot=true
	collision_shape.disabled=false
	timer.connect("timeout",  Callable(self, "_on_timer_timeout"))
	super._ready()

func changeObjective(text:String):
	counter.updateObjective(text)

func _update_sprite_for_direction():
	if ellen_sprites.has(current_direction):
		sprite.texture = ellen_sprites[current_direction]

func _input(event):
	if !Gamestate.dialogue_locked:
		if event.is_action_pressed("ability"):
			toggle_transparency_ability()

func input_handler():
	if is_ability_active:
		velocity = Vector2.ZERO
	else:
		super.input_handler()

func toggle_transparency_ability():
	if is_ability_active:
		deactivate_transparency_ability()
	else:
		activate_transparency_ability()
		
func activate_transparency_ability():
	is_ability_active = true
	sprite.modulate.a = 0.5
	velocity = Vector2.ZERO
	collision_shape.disabled = true
	timer.start()

func deactivate_transparency_ability():
	is_ability_active = false
	sprite.modulate.a = 1.0
	collision_shape.disabled = false
	timer.stop()
	
	
func _on_timer_timeout():
	deactivate_transparency_ability()
