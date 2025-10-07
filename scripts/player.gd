extends CharacterBody2D

const SPEED = 100.0

func input_handler():
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	
func _physics_process(delta):
	input_handler()	
	move_and_slide()
