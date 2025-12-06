extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var is_ability_active: bool = false
@onready var counter: Control = $GUI/Objective

@onready var timer: Timer = $Timer

var ellen_anims = {
	Direction.DOWN: "down",
	Direction.UP: "up",
	Direction.LEFT: "left",
	Direction.RIGHT: "right"
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
	if ellen_anims.has(current_direction):
		sprite.play(ellen_anims[current_direction])

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
