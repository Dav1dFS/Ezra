extends CharacterBody2D

var SPEED = 70.0

@export var character_name: String =""
@export var show_counter: bool = true
@export var inv: Inventory
@export var camera_lookahead_distance: float = 24.0
@export var camera_lookahead_speed: float = 1.0

@onready var cam: Camera2D = get_node("Camera2D")
@onready var sprite: AnimatedSprite2D = $Base
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var objective: Control = $GUI/Objective
@onready var inventory = $GUI/Inventory

enum Direction { RIGHT, LEFT, UP, DOWN }
var camera_offset: Vector2 = Vector2.ZERO
var current_direction: Direction = Direction.DOWN
var last_movement_direction: Vector2 = Vector2.ZERO
var is_ability_active: bool = false
var ability_manager: AbilityManager

var base_anims = {
	Direction.DOWN: "down",
	Direction.UP: "up",
	Direction.LEFT: "left",
	Direction.RIGHT: "right"
}
var def_anims = {
	Direction.DOWN: "defaultD",
	Direction.UP: "defaultU",
	Direction.LEFT: "defaultL",
	Direction.RIGHT: "defaultR"
}

func get_is_ability_active() -> bool:
	return is_ability_active


func update_inventory(item: Item):
	inventory.update(item)

func _ready():
	add_to_group("player")

	if not SaveManager.is_loading:
		Gamestate.character_name = character_name

	inventory.update_pocket(Gamestate.character_name)

	if inv:
		inv.connect("inventory_changed", Callable(self, "update_inventory"))
		update_inventory(null)

	ability_manager = AbilityManager.new()
	add_child(ability_manager)

	setup_abilities()

	await get_tree().process_frame

	var bottomLeft = get_tree().get_current_scene().get_node_or_null("DownLeftLimit")
	var topRight = get_tree().get_current_scene().get_node_or_null("TopRightLimit")

	if bottomLeft and topRight:
		var pos1 = bottomLeft.global_position
		var pos2 = topRight.global_position

		cam.limit_left = int(pos1.x-10)
		cam.limit_right = int(pos2.x+10)
		cam.limit_top = int(pos2.y-20)
		cam.limit_bottom = int(pos1.y)
	else:
		push_warning("Limit1 or Limit2 not found in scene!")

func changeObjective(text: String):
	objective.updateObjective(text)

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
	if !Gamestate.game_is_paused and !Gamestate.is_being_pushed_back:
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

func _update_sprite_for_direction():
	if base_anims.has(current_direction):
		sprite.play(base_anims[current_direction])
	
func _physics_process(_delta):
	if Input.is_action_just_pressed("pause") and not Gamestate.game_is_paused:
		Gamestate.toggle_pause()
		pause_menu.show_menu()
		get_tree().root.get_viewport().set_input_as_handled()

	if Gamestate.dialogue_locked or Gamestate.is_being_pushed_back:
		velocity = Vector2.ZERO
		if base_anims.has(current_direction):
			sprite.play(def_anims[current_direction])
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity = direction * SPEED

	velocity = velocity.lerp(target_velocity, 0.2)

	if direction != Vector2.ZERO:
		update_sprite_direction(direction)
	else:
		if can_update_animations():
			if base_anims.has(current_direction):
				sprite.play(def_anims[current_direction])
	move_and_slide()

	update_camera_lookahead(direction, _delta)

func update_camera_lookahead(direction: Vector2, delta: float):
	var target_offset = Vector2.ZERO
	if direction != Vector2.ZERO:
		target_offset = direction.normalized() * camera_lookahead_distance

	camera_offset = camera_offset.lerp(target_offset, camera_lookahead_speed * delta)

	cam.position = camera_offset

func can_update_animations() -> bool:
	return true


func setup_abilities():
	pass
