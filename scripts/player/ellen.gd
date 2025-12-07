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
var HideEllen_anims = {
	Direction.DOWN: "hideD",
	Direction.UP: "hideU",
	Direction.LEFT: "hideL",
	Direction.RIGHT: "hideR"
}
var ShakeEllen_anims = {
	Direction.DOWN: "shakeD",
	Direction.UP: "shakeU",
	Direction.LEFT: "shakeL",
	Direction.RIGHT: "shakeR"
}
var shakes

func get_is_ability_active() -> bool:
	return is_ability_active

func _ready():
	character_name = "Ellen"
	timer.wait_time = 1.5
	timer.one_shot=true
	shakes=false
	collision_shape.disabled=false
	timer.connect("timeout",  Callable(self, "_on_timer_timeout"))
	super._ready()

func changeObjective(text:String):
	counter.updateObjective(text)

func _update_sprite_for_direction():
	if is_ability_active:
		velocity = Vector2.ZERO
	else:
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
		manual_deactivate_transparency_ability()
	else:
		activate_transparency_ability()
		
func activate_transparency_ability():
	is_ability_active = true
	if HideEllen_anims.has(current_direction):
		print(HideEllen_anims[current_direction])
		sprite.play(HideEllen_anims[current_direction])

	
	velocity = Vector2.ZERO
	sprite.modulate.a = 0.5
	collision_shape.disabled = true
	$LightOccluder2D.visible=false
	
	timer.start()

func can_update_animations() -> bool:
	return not is_ability_active


func deactivate_transparency_ability():
	if shakes:
		sprite.modulate.a = 1.0
		collision_shape.disabled = false
		$LightOccluder2D.visible=true
		timer.stop()
		shakes=false
		if HideEllen_anims.has(current_direction):
			var anim=HideEllen_anims[current_direction] + "_back"
			sprite.play(anim)
			await sprite.animation_finished
			is_ability_active = false
			sprite.play(HideEllen_anims[current_direction])
	else:
		timer.stop()
		timer.start()
		shakes=true
		if ShakeEllen_anims.has(current_direction):
			sprite.play(ShakeEllen_anims[current_direction])
			
func manual_deactivate_transparency_ability():
	sprite.modulate.a = 1.0
	collision_shape.disabled = false
	$LightOccluder2D.visible=true
	timer.stop()
	shakes=false
	if HideEllen_anims.has(current_direction):
		var anim=HideEllen_anims[current_direction] + "_back"
		sprite.play(anim)
		await sprite.animation_finished
		is_ability_active = false
		sprite.play(HideEllen_anims[current_direction])


	
func _on_timer_timeout():
	deactivate_transparency_ability()
