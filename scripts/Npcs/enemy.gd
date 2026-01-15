extends CharacterBody2D

@export var vision_renderer: Polygon2D
@export var alert_color: Color

@onready var spriteChar: AnimatedSprite2D = $Base
@onready var vision_cone: Node2D = $VisionCone2D
@onready var steps = $AudioStreamPlayer2D

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
@onready var flashlight_light: PointLight2D = $FlashlightBob/PointLight2D

var previous_position: Vector2
var stuck_timer: float = 0.0
var stuck_threshold: float = 1.0
var player_detected = false
var is_turning: bool = false
var flashlight_bob = 0.0
var flashlight_bob_speed = 5
var flashlight_bob_amount = 1.0
var flashlight_base_y := 0.0
var dialogue_is_on: bool = false
var dialogue_handler := DialogueHandler.new()

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
	player_detected=false
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)

	dialogue_handler.load_dialogue_file(dialogue_file)

	if "Director" in self.name:
		vision_cone.angle_deg = 100
		vision_cone._angle = deg_to_rad(100)
		vision_cone._angle_half = vision_cone._angle / 2.0
		vision_cone._angular_delta = vision_cone._angle / vision_cone.ray_count
		flashlight_bob_amount = 3.0
		self.npc_name="Director"
		self.npc_portrait = "res://assets/character_sprites/guards_static/guard_biggg.png"

	_setup_cone_light()

	if "Director" not in self.name:
		if not is_moving:
			match current_direction:
				Direction.RIGHT:
					spriteChar.play("iR")
				Direction.LEFT:
					spriteChar.play("iL")	
				Direction.UP:
					spriteChar.play("iU")
				Direction.DOWN:
					spriteChar.play("iD")
	if is_moving:
		_calculate_target_position()
	else:
		spriteChar.stop()

func play_steps():
	if steps.playing:
		pass
	else:
		steps.play()

func stop_steps():
	steps.stop()
	
func _physics_process(delta: float) -> void:
	if Gamestate.game_is_paused:
		return

	_check_for_player()

	if is_moving:
		_process_movement(delta)
		play_steps()
	
	else:
		stop_steps()

	if not is_turning:
		_update_state()
	flashlight.rotation = vision_cone.rotation
	_update_flashlight_bobbing(delta)

func _check_for_player():
	if player_detected:
		return

	for body in $DetectionArea.get_overlapping_bodies():
		if _handle_player_detected(body):
			return

	for body in $VisionCone2D/VisionConeArea.get_overlapping_bodies():
		if _handle_player_detected(body):
			return

func _handle_player_detected(body: Node) -> bool:
	if body.name != "Player":
		return false

	if body.character_name == "Ellen" and body.has_method("get_is_ability_active"):
		if body.get_is_ability_active():
			return false

	vision_renderer.color = alert_color
	player_detected = true
	play_whistle()
	_face_player(body)
	moving_forward = false
	is_moving = false
	spriteChar.stop()
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
	_apply_visual_direction(dir)

func _apply_visual_direction(dir: Direction):
	spriteChar.light_mask = ~(1 << 0)

	if is_moving:
		match dir:
			Direction.RIGHT:
				spriteChar.play("wR")
				vision_cone.rotation = -PI / 2
			Direction.LEFT:
				spriteChar.play("wL")
				vision_cone.rotation = PI / 2
			Direction.UP:
				spriteChar.play("wU")
				vision_cone.rotation = PI
			Direction.DOWN:
				spriteChar.play("wD")
				vision_cone.rotation = 0
	else:
		match dir:
			Direction.RIGHT:
				spriteChar.play("iR")
				vision_cone.rotation = -PI / 2
			Direction.LEFT:
				spriteChar.play("iL")
				vision_cone.rotation = PI / 2
			Direction.UP:
				spriteChar.play("iU")
				vision_cone.rotation = PI
			Direction.DOWN:
				spriteChar.play("iD")
				vision_cone.rotation = 0
			

func _get_opposite_direction(dir: Direction) -> Direction:
	match dir:
		Direction.RIGHT: return Direction.LEFT
		Direction.LEFT: return Direction.RIGHT
		Direction.UP: return Direction.DOWN
		Direction.DOWN: return Direction.UP
	return dir

func _get_next_direction_clockwise(dir: Direction) -> Direction:
	match dir:
		Direction.DOWN: return Direction.LEFT
		Direction.LEFT: return Direction.UP
		Direction.UP: return Direction.RIGHT
		Direction.RIGHT: return Direction.DOWN
	return dir

func _rotate_in_place():
	var start_dir = current_direction
	var end_dir = _get_opposite_direction(current_direction)
	var rotation_time := 0.3

	var intermediate_dir = _get_next_direction_clockwise(start_dir)

	_apply_visual_direction(intermediate_dir)
	await get_tree().create_timer(rotation_time).timeout

	_apply_visual_direction(end_dir)
	await get_tree().create_timer(rotation_time).timeout

func _on_detection_area_body_entered(body: Node2D) -> void:
	_handle_player_detected(body)

func _process_movement(delta: float):
	if is_turning:
		return

	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target < 5.0:
		is_turning = true
		moving_forward = !moving_forward
		spriteChar.stop()
		await _rotate_in_place()
		_calculate_target_position()
		stuck_timer = 0.0
		is_turning = false
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
	var visual_direction = current_direction

	if not moving_forward and not player_detected:
		match current_direction:
			Direction.RIGHT: visual_direction = Direction.LEFT
			Direction.LEFT: visual_direction = Direction.RIGHT
			Direction.UP: visual_direction = Direction.DOWN
			Direction.DOWN: visual_direction = Direction.UP
	
	_apply_visual_direction(visual_direction)

func _update_flashlight_bobbing(delta):
	if is_moving and (current_direction == Direction.RIGHT or current_direction == Direction.LEFT):
		flashlight_bob += delta * flashlight_bob_speed
		var offset = sin(flashlight_bob) * flashlight_bob_amount
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y + offset, delta * 10.0)
	else:
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y, delta * 10.0)


func play_whistle():
	var music_index = AudioServer.get_bus_index("Music") 
	AudioServer.set_bus_mute(music_index, true)
	$Whistle.play()
	
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
			"Director": load(npc_portrait),
			"Ezra": preload("res://assets/character_sprites/ezra/ezra_base.png"),
		})
	dialogue_box.start(processed_dialogue, self)

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.disconnect(_on_dialogue_ended)

	dialogue_is_on = false

	if fully_completed:
		dialogue_handler.mark_completed(npc_name)
		_restart_level()


func _restart_level():
	var current_scene = get_tree().get_current_scene()
	var cutscene_controller = current_scene.get_node_or_null("CutsceneController")

	if cutscene_controller and cutscene_controller.has_method("scene_fade_out"):
		await cutscene_controller.scene_fade_out()

	get_tree().reload_current_scene()

func _setup_cone_light():
	if not flashlight_light:
		return
	var cone_angle_deg := vision_cone.angle_deg as float
	var cone_texture := _generate_cone_texture(128, 128, cone_angle_deg)
	if cone_texture:
		flashlight_light.texture = cone_texture
	var scale_factor : float = vision_cone.max_distance / 64.0
	flashlight_light.texture_scale = scale_factor
	flashlight_light.offset = Vector2(0, vision_cone.max_distance / 2.0)
	flashlight_light.rotation = 0.0
	flashlight_light.position = Vector2.ZERO
	flashlight_light.scale = Vector2(1.0, 1.0)

func _generate_cone_texture(width: int, height: int, angle_deg: float) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var half_angle := deg_to_rad(angle_deg) / 2.0
	var center_x := width / 2.0
	# Cone apex at top center, pointing down
	var apex_y := 0.0

	for y in range(height):
		for x in range(width):
			var dx := x - center_x
			var dy := float(y) - apex_y

			var dist := sqrt(dx * dx + dy * dy)
			var max_dist := float(height)
			var dist_factor: float = clamp(dist / max_dist, 0.0, 1.0)

			var pixel_angle: float = abs(atan2(dx, dy))

			var edge_softness := 0.15
			var angular_factor := 1.0
			if pixel_angle > half_angle:
				angular_factor = 0.0
			elif pixel_angle > half_angle - edge_softness:
				angular_factor = 1.0 - (pixel_angle - (half_angle - edge_softness)) / edge_softness

			var radial_factor := 1.0 - smoothstep(0.3, 1.0, dist_factor)

			var intensity := angular_factor * radial_factor

			var color := Color(1.0, 1.0, 1.0, intensity)
			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
