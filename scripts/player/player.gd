extends CharacterBody2D

const SPEED = 70.0


@export var inv: Inventory
@onready var cam: Camera2D = get_node("Camera2D")
@onready var sprite: Sprite2D = $Sprite2D

@export var character_name: String =""

enum Direction { RIGHT, LEFT, UP, DOWN }
var current_direction: Direction = Direction.DOWN
var last_movement_direction: Vector2 = Vector2.ZERO

@onready var slot= $GUI/Inv
@onready var pause_menu = $GUI/InputSettings

var game_is_paused: bool = false

func update_inv():
	var current_item = inv.get_inventory()
	if current_item.size()>0:
		print("updating")
		slot.update(current_item[0])

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		game_is_paused = !game_is_paused
		if game_is_paused:
			Engine.time_scale = 0
			pause_menu.visible = true
		else:
			Engine.time_scale = 1
			pause_menu.visible = false
		get_tree().root.get_viewport().set_input_as_handled()
	

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

	if direction != Vector2.ZERO:
		last_movement_direction = direction
		update_sprite_direction(direction)

func update_sprite_direction(movement_direction: Vector2):
	if abs(movement_direction.x) > abs(movement_direction.y):
		if movement_direction.x > 0:
			current_direction = Direction.RIGHT
		else:
			current_direction = Direction.LEFT
	else:
		if movement_direction.y < 0:
			current_direction = Direction.UP
		else:
			current_direction = Direction.DOWN

	_update_sprite_for_direction()

# Virtual method for child classes to override
func _update_sprite_for_direction():
	pass
	
func _physics_process(_delta):
	input_handler()	
	move_and_slide()
