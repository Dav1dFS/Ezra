extends CharacterBody2D

const SPEED = 70.0


@export var inv: Inventory
@onready var cam: Camera2D = get_node("Camera2D")

# For now, randomly decides which character is on, change later 

var character_name: String ="Ezra"


@onready var slot= $CanvasLayer/Inv

func update_inv():
	var current_item = inv.get_inventory()
	if current_item.size()>0:
		print("updating")
		slot.update(current_item[0])

	

func _ready():	
	
	print (character_name)
	Gamestate.character_name = character_name
	
	
	if inv:
		print("✅ Connected to inventory:", inv)
		inv.connect("inventory_changed", Callable(self, "update_inv"))
		
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
