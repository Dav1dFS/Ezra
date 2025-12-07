extends CharacterBody2D

const SPEED = 70.0


@export var inv: Inventory
@onready var cam: Camera2D = get_node("Camera2D")
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var pause_menu = $PauseLayer/PauseMenu

@export var character_name: String =""

enum Direction { RIGHT, LEFT, UP, DOWN }
var current_direction: Direction = Direction.DOWN
var last_movement_direction: Vector2 = Vector2.ZERO

@onready var slot= $GUI/Inv

func update_inv(item:Item):
	if not item:
		slot.update(null)
	else:
		slot.update(item)

func _ready():
	add_to_group("player")

	# Only set character_name if NOT loading a save (SaveManager will restore it)
	if not SaveManager.is_loading:
		print(character_name)
		Gamestate.character_name = character_name
	else:
		# When loading, use the character name from save data
		print("Loading save - using saved character_name:", Gamestate.character_name)

	slot.character(Gamestate.character_name)
	
	if inv:
		print("✅ Connected to inventory:", inv)
		inv.connect("inventory_changed", Callable(self, "update_inv"))
		update_inv(null)
		
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
	else:
		sprite.stop()
		return

func update_sprite_direction(movement_direction: Vector2):
	if !Gamestate.game_is_paused:
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
	if Input.is_action_just_pressed("pause") and not Gamestate.game_is_paused:
		Gamestate.toggle_pause()
		pause_menu.show_menu()
		get_tree().root.get_viewport().set_input_as_handled()

	if Gamestate.dialogue_locked:
		velocity = Vector2.ZERO
		sprite.stop()
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity = direction * SPEED

	# Smooth interpolation
	velocity = velocity.lerp(target_velocity, 0.2)
	
	if direction != Vector2.ZERO:
		update_sprite_direction(direction)
	else:
		if can_update_animations():
			sprite.stop()
	move_and_slide()

func can_update_animations() -> bool:
	return true
