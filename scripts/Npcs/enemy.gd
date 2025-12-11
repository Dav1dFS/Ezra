extends CharacterBody2D

@export var vision_renderer: Polygon2D
@export var alert_color: Color

@onready var spriteChar: Sprite2D = $Base
@onready var vision_cone: Node2D = $VisionCone2D

@export var npc_name: String = "Guard"
@export_file("*.json") var dialogue_file: String = "res://dialogues/game_over_guard.json"
@export_file("*.png") var npc_portrait: String

@export var is_moving = false
@export var movement_speed = 50.0
@export var forward_distance = 100.0
@export var backward_distance = 50.0
@export_enum("Right", "Left", "Up", "Down") var initial_direction: int = 0

@onready var start_position = global_position
@onready var target_position = global_position
@onready var moving_forward = true
@onready var original_color = vision_renderer.color if vision_renderer else Color.WHITE
@onready var flashlight = $FlashlightBob

var previous_position: Vector2
var stuck_timer: float = 0.0
var stuck_threshold: float = 1.0
var player_detected = false
var flashlight_bob = 0.0
var flashlight_bob_speed = 2.5
var flashlight_bob_amount = 1.0
var flashlight_base_y := 0.0
var dialogue_is_on: bool = false
var dialogue_handler := DialogueHandler.new()

# Direction system
enum Direction { RIGHT, LEFT, UP, DOWN }
var current_direction: Direction
var direction_vectors = {
	Direction.RIGHT: Vector2.RIGHT,
	Direction.LEFT: Vector2.LEFT,
	Direction.UP: Vector2.UP,
	Direction.DOWN: Vector2.DOWN
}

func _ready():
	flashlight_base_y = flashlight.position.y
	current_direction = initial_direction as Direction
	previous_position = global_position
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)

	dialogue_handler.load_dialogue_file(dialogue_file)

	if "General" in self.name:
		vision_cone.angle_deg = 100
		vision_cone._angle = deg_to_rad(100)
		vision_cone._angle_half = vision_cone._angle / 2.0
		vision_cone._angular_delta = vision_cone._angle / vision_cone.ray_count
		flashlight_bob_amount = 3.0

	if is_moving:
		_calculate_target_position()

func _physics_process(delta: float) -> void:
	if Gamestate.game_is_paused:
		return

	_check_for_player()

	if is_moving:
		_process_movement(delta)

	_update_state()
	flashlight.rotation = vision_cone.rotation
	_update_flashlight_bobbing(delta)

func _check_for_player():
	if player_detected:
		return

	# Check detection area
	for body in $DetectionArea.get_overlapping_bodies():
		if _handle_player_detected(body):
			return

	# Check vision cone
	for body in $VisionCone2D/VisionConeArea.get_overlapping_bodies():
		if _handle_player_detected(body):
			return

func _handle_player_detected(body: Node) -> bool:
	if body.name != "Player":
		return false

	# Check Ellen's invisibility ability
	if body.character_name == "Ellen" and body.has_method("get_is_ability_active"):
		if body.get_is_ability_active():
			return false

	vision_renderer.color = alert_color
	player_detected = true
	_face_player(body)
	moving_forward = false
	is_moving = false
	start_dialogue()
	return true

func _face_player(body: Node):
	var to_player = body.global_position - global_position
	var angle = to_player.angle()

	if abs(angle) < PI / 4:
		_set_direction(Direction.RIGHT)
	elif abs(angle - PI) < PI / 4 or abs(angle + PI) < PI / 4:
		_set_direction(Direction.LEFT)
	elif angle < 0:
		_set_direction(Direction.UP)
	else:
		_set_direction(Direction.DOWN)

func _set_direction(dir: Direction):
	current_direction = dir
	match dir:
		Direction.RIGHT:
			spriteChar.frame = 3
			vision_cone.rotation = -PI / 2
		Direction.LEFT:
			spriteChar.frame = 2
			vision_cone.rotation = PI / 2
		Direction.UP:
			spriteChar.frame = 1
			vision_cone.rotation = PI
		Direction.DOWN:
			spriteChar.frame = 0
			vision_cone.rotation = 0

func _on_detection_area_body_entered(body: Node2D) -> void:
	_handle_player_detected(body)

func _process_movement(delta: float):
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target < 5.0:
		moving_forward = !moving_forward
		await get_tree().create_timer(2.0).timeout
		_calculate_target_position()
		stuck_timer = 0.0
	else:
		var direction = (target_position - global_position).normalized()
		velocity = direction * movement_speed * delta * 60.0
		move_and_slide()

		var movement_distance = global_position.distance_to(previous_position)
		if movement_distance < 0.5:
			stuck_timer += delta
			if stuck_timer >= stuck_threshold:
				moving_forward = !moving_forward
				_calculate_target_position()
				stuck_timer = 0.0
		else:
			stuck_timer = 0.0

	previous_position = global_position

func _calculate_target_position():
	var direction_vector = direction_vectors[current_direction]
	if moving_forward:
		target_position = start_position + direction_vector * forward_distance
	else:
		target_position = start_position + direction_vector * (-backward_distance)

func _update_state():
	var actual_direction = current_direction

	if not moving_forward and not player_detected:
		match current_direction:
			Direction.RIGHT: actual_direction = Direction.LEFT
			Direction.LEFT: actual_direction = Direction.RIGHT
			Direction.UP: actual_direction = Direction.DOWN
			Direction.DOWN: actual_direction = Direction.UP

	_set_direction(actual_direction)

func _update_flashlight_bobbing(delta):
	if is_moving and (current_direction == Direction.RIGHT or current_direction == Direction.LEFT):
		flashlight_bob += delta * flashlight_bob_speed
		var offset = sin(flashlight_bob) * flashlight_bob_amount
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y + offset, delta * 10.0)
	else:
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y, delta * 10.0)

func start_dialogue():
	var dialogue_to_use = dialogue_handler.choose_dialogue(npc_name)

	if dialogue_to_use.is_empty():
		push_warning("No valid dialogue found for NPC: " + npc_name)
		return

	dialogue_is_on = true

	var processed_dialogue = dialogue_handler.process_dialogue(dialogue_to_use)

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_error("DialogueBox not found in scene!")
		dialogue_is_on = false
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	dialogue_box.set_speaker_portraits({
			"Guard": load(npc_portrait),
			"General": load(npc_portrait),
			"Ezra": preload("res://assets/character_sprites/ezra/ezra_base.png"),
		})
	dialogue_box.start(processed_dialogue, self)

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	# Disconnect signal
	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.disconnect(_on_dialogue_ended)

	dialogue_is_on = false

	if fully_completed:
		dialogue_handler.mark_completed(npc_name)
		get_tree().change_scene_to_file("res://scenes/gameplay/pitch.tscn")
