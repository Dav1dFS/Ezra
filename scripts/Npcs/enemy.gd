extends CharacterBody2D

@export var vision_renderer: Polygon2D
@export var alert_color: Color

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

#retirar no futuro
@onready var spriteChar: Sprite2D = $Base
#

@onready var vision_cone: Node2D = $VisionCone2D
@export_group("Dialogue")
@export var npc_name: String = "Guard"
@export_file("*.json") var dialogue_file: String = "res://dialogues/game_over_guard.json"
@export_file("*.png") var npc_portrait: String
@export var triggers_player_dialogue: bool = false
var player_portrait_ezra: String = "res://assets/character_sprites/ezra/ezra_base.png"
var player_in_range: bool = false
var dialogue_data: Dictionary
var dialogue_is_on: bool = false
var current_dialogue_index: int = 0
var dialogue_completed: bool = false
var current_player: Node = null
@export_group("Movement")
@export var is_moving = false
@export var movement_speed = 50.0
@export var forward_distance = 100.0
@export var backward_distance = 50.0
@export_enum("Right", "Left", "Up", "Down") var initial_direction: int = 0

@onready var start_position = global_position
@onready var target_position = global_position
@onready var moving_forward = true

var previous_position: Vector2
var stuck_timer: float = 0.0
var stuck_threshold: float = 1.0
var player_detected = false
@onready var original_color = vision_renderer.color if vision_renderer else Color.WHITE
@onready var rot_start = rotation

@onready var flashlight = $FlashlightBob  
var flashlight_bob = 0.0
var flashlight_bob_speed = 2.5
var flashlight_bob_amount = 1.0
var flashlight_base_y := 0.0   


# Direction system
enum Direction { RIGHT, LEFT, UP, DOWN }
var current_direction: Direction
var direction_vectors = {
	Direction.RIGHT: Vector2.RIGHT,
	Direction.LEFT: Vector2.LEFT,
	Direction.UP: Vector2.UP,
	Direction.DOWN: Vector2.DOWN
}

func _on_vision_cone_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if body.character_name == "Ellen" and body.has_method("get_is_ability_active") and body.get_is_ability_active():
			return
		
		vision_renderer.color = alert_color
		player_detected = true

		##Switch to face player if too close
		var to_player = body.global_position - global_position
		var angle = to_player.angle() 
		if abs(angle) < PI/4:
			current_direction=Direction.RIGHT
			spriteChar.frame=3
			vision_cone.rotation = -PI/2
		elif abs(angle - PI) < PI/4 or abs(angle + PI) < PI/4:
			current_direction=Direction.LEFT
			spriteChar.frame=2
			vision_cone.rotation = PI/2
		elif angle < 0:
			current_direction=Direction.UP
			spriteChar.frame=1
			vision_cone.rotation = PI
		else:
			current_direction=Direction.DOWN
			spriteChar.frame=0
			vision_cone.rotation = 0
		moving_forward=false
		is_moving=false

		# Slow motion effect
		start_dialogue()

func _on_vision_cone_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		vision_renderer.color = original_color

func _ready():
	flashlight_base_y = flashlight.position.y
	current_direction = initial_direction as Direction
	previous_position = global_position
	$DetectionArea.body_entered.connect(_on_vision_cone_area_body_entered)
	_load_dialogue_file()
	if "General" in self.name:
		self.vision_cone.angle_deg=100
		self.vision_cone._angle=deg_to_rad(100)
		self.vision_cone._angle_half=self.vision_cone._angle/2.
		self.vision_cone._angular_delta= self.vision_cone._angle / self.vision_cone.ray_count
		flashlight_bob_amount =3.0
	#animated_sprite.play("default")
	if is_moving:
		_calculate_target_position()


func _update_flashlight_bobbing(delta):
	if is_moving and (current_direction == Direction.RIGHT or current_direction == Direction.LEFT):
		flashlight_bob += delta * flashlight_bob_speed
		var offset = sin(flashlight_bob) * flashlight_bob_amount
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y + offset, delta * 10.0)
	else:
		flashlight.position.y = lerp(flashlight.position.y, flashlight_base_y, delta * 10.0)




func _update_state():

	var actual_direction = current_direction

	if not moving_forward and not player_detected:
		match current_direction:
			Direction.RIGHT: actual_direction = Direction.LEFT
			Direction.LEFT: actual_direction = Direction.RIGHT
			Direction.UP: actual_direction = Direction.DOWN
			Direction.DOWN: actual_direction = Direction.UP

	#animated_sprite.rotation = 0

	match actual_direction:
		Direction.RIGHT:
			#animated_sprite.flip_h = false
			spriteChar.frame=3
			vision_cone.rotation = -PI/2
			# TODO: animated_sprite.play("moving_right")
		Direction.LEFT:
			#animated_sprite.flip_h = true
			spriteChar.frame=2
			vision_cone.rotation = PI/2
			# TODO: animated_sprite.play("moving_left")
		Direction.UP:
			#animated_sprite.flip_h = false
			spriteChar.frame=1
			vision_cone.rotation = PI
			# TODO: animated_sprite.play("moving_up")
		Direction.DOWN:
			#animated_sprite.flip_h = false
			spriteChar.frame=0
			vision_cone.rotation = 0
			# TODO: animated_sprite.play("moving_down")

	#if not animated_sprite.is_playing():
	#	animated_sprite.play("default")

func _calculate_target_position():
	var direction_vector = direction_vectors[current_direction]
	if moving_forward:
		target_position = start_position + direction_vector * forward_distance
	else:
		target_position = start_position + direction_vector * (-backward_distance)

func _physics_process(delta: float) -> void:
	if !Gamestate.game_is_paused:
		check_detection_area()
		check_vision_cone()
		if is_moving:
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
		_update_state()
		flashlight.rotation = vision_cone.rotation
		_update_flashlight_bobbing(delta)
		
		
		
##dialogue
func _process_dialogue(dialogue: Dictionary) -> Dictionary:
	var processed = dialogue.duplicate(true)
	var filtered_lines = []

	for line in dialogue.get("lines", []):
		# Skip mid_action lines (for future cutscene implementation)
		if line.has("mid_action"):
			continue

		# Process regular dialogue lines
		if line.has("text"):
			var processed_line = line.duplicate()
			# Replace character name placeholder
			if "{character_name}" in processed_line["text"]:
				processed_line["text"] = processed_line["text"].replace("{character_name}", Gamestate.character_name)
			filtered_lines.append(processed_line)

	processed["lines"] = filtered_lines
	return processed
	
func _load_dialogue_file():
	if dialogue_file.is_empty():
		push_error("Dialogue file path is empty for NPC: " + npc_name)
		return

	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_text)

		if parse_result == OK:
			dialogue_data = json.data
		else:
			push_error("Failed to parse JSON for NPC %s: %s" % [npc_name, json.get_error_message()])
	else:
		push_error("Failed to load dialogue file: " + dialogue_file)
		
		
func start_dialogue():
	var dialogue_to_use = _choose_dialogue()

	if dialogue_to_use.is_empty():
		push_warning("No valid dialogue found for NPC: " + npc_name)
		return

	dialogue_is_on = true
	Gamestate.dialogue_locked = true

	# Filter out mid_action lines
	var processed_dialogue = _process_dialogue(dialogue_to_use)

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_error("DialogueBox not found in scene!")
		dialogue_is_on = false
		Gamestate.dialogue_locked = false
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	dialogue_box.changeImages(npc_portrait)
	dialogue_box.start(processed_dialogue, self)

func _choose_dialogue() -> Dictionary:
	var dialogues = dialogue_data.get("dialogues", [])

	var is_completed = Gamestate.npc_dialogues_completed.get(npc_name, false)

	for dialogue in dialogues:
		var condition = dialogue.get("condition", "default")

		if condition == "default" and not is_completed:
			return dialogue
		elif condition == "repetition" and is_completed:
			return dialogue
		elif condition != "default" and condition != "repetition":
			continue

	return {}
	
func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	dialogue_is_on = false
	Gamestate.dialogue_locked = false

	if fully_completed:
		Gamestate.npc_dialogues_completed[npc_name] = true
		dialogue_completed = true
		current_dialogue_index += 1
		

		get_tree().change_scene_to_file("res://scenes/gameplay/pitch.tscn")

func check_detection_area():
	var bodies = $DetectionArea.get_overlapping_bodies()

	for body in bodies:
		if body.name == "Player" and not player_detected:
			if body.character_name == "Ellen" and body.get_is_ability_active():
				continue
			vision_renderer.color = alert_color
			player_detected = true
			##Switch to face player if too close
			var to_player = body.global_position - global_position
			var angle = to_player.angle() 
			if abs(angle) < PI/4:
				current_direction=Direction.RIGHT
				spriteChar.frame=3
				vision_cone.rotation = -PI/2
			elif abs(angle - PI) < PI/4 or abs(angle + PI) < PI/4:
				current_direction=Direction.LEFT
				spriteChar.frame=2
				vision_cone.rotation = PI/2
			elif angle < 0:
				current_direction=Direction.UP
				spriteChar.frame=1
				vision_cone.rotation = PI
			else:
				current_direction=Direction.DOWN
				spriteChar.frame=0
				vision_cone.rotation = 0
			moving_forward=false
			is_moving=false

			# Slow motion effect
			start_dialogue()
			break



func check_vision_cone():
	var bodies = $VisionCone2D/VisionConeArea.get_overlapping_bodies()

	for body in bodies:
		if body.name == "Player" and not player_detected:
		
			if body.character_name == "Ellen" and body.get_is_ability_active():
				continue
			vision_renderer.color = alert_color
			player_detected = true
			##Switch to face player if too close
			var to_player = body.global_position - global_position
			var angle = to_player.angle() 
			if abs(angle) < PI/4:
				current_direction=Direction.RIGHT
				spriteChar.frame=3
				vision_cone.rotation = -PI/2
			elif abs(angle - PI) < PI/4 or abs(angle + PI) < PI/4:
				current_direction=Direction.LEFT
				spriteChar.frame=2
				vision_cone.rotation = PI/2
			elif angle < 0:
				current_direction=Direction.UP
				spriteChar.frame=1
				vision_cone.rotation = PI
			else:
				current_direction=Direction.DOWN
				spriteChar.frame=0
				vision_cone.rotation = 0
			moving_forward=false
			is_moving=false

			# Slow motion effect
			start_dialogue()
			break
