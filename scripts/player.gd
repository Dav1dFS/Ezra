extends CharacterBody2D

const SPEED = 100.0

@onready var cam: Camera2D = get_node("Camera2D")

func _ready():
	
	await get_tree().process_frame

	var bottomLeft = get_tree().get_current_scene().get_node_or_null("downLeftLimit")
	var topRight = get_tree().get_current_scene().get_node_or_null("topRightLimit")

	if bottomLeft and topRight:
		var pos1 = bottomLeft.global_position
		var pos2 = topRight.global_position
		
		cam.limit_left = int(pos1.x-10)
		cam.limit_right = int(pos2.x+10)
		cam.limit_top = int(pos2.y-20)
		cam.limit_bottom = int(pos1.y)
	else:
		push_warning("Limit1 or Limit2 not found in scene!")

func input_handler():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	
func _physics_process(_delta):
	input_handler()	
	move_and_slide()
