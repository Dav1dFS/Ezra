extends CharacterBody2D

@export var vision_renderer: Polygon2D
@export var alert_color: Color

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_cone: Node2D = $VisionCone2D

@export_group("Movement")
@export var is_moving = false
@export var movement_speed = 50.0
@export var forward_distance = 100.0
@export var backward_distance = 50.0
@export_enum("Right", "Left", "Up", "Down") var initial_direction: int = 0

@onready var start_position = global_position
@onready var target_position = global_position
@onready var moving_forward = true

@onready var original_color = vision_renderer.color if vision_renderer else Color.WHITE
@onready var rot_start = rotation

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
		print("%s is seeing %s" % [self, body])
		vision_renderer.color = alert_color

func _on_vision_cone_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print("%s stopped seeing %s" % [self, body])
		vision_renderer.color = original_color

func _ready():
	current_direction = initial_direction as Direction

	animated_sprite.play("default")
	if is_moving:
		_calculate_target_position()

func _update_state():

	var actual_direction = current_direction

	if not moving_forward:
		match current_direction:
			Direction.RIGHT: actual_direction = Direction.LEFT
			Direction.LEFT: actual_direction = Direction.RIGHT
			Direction.UP: actual_direction = Direction.DOWN
			Direction.DOWN: actual_direction = Direction.UP

	animated_sprite.rotation = 0

	match actual_direction:
		Direction.RIGHT:
			animated_sprite.flip_h = false
			vision_cone.rotation = -PI/2
			# TODO: animated_sprite.play("moving_right")
		Direction.LEFT:
			animated_sprite.flip_h = true
			vision_cone.rotation = PI/2
			# TODO: animated_sprite.play("moving_left")
		Direction.UP:
			animated_sprite.flip_h = false
			vision_cone.rotation = PI
			# TODO: animated_sprite.play("moving_up")
		Direction.DOWN:
			animated_sprite.flip_h = false
			vision_cone.rotation = 0
			# TODO: animated_sprite.play("moving_down")

	if not animated_sprite.is_playing():
		animated_sprite.play("default")

func _calculate_target_position():
	var direction_vector = direction_vectors[current_direction]
	if moving_forward:
		target_position = start_position + direction_vector * forward_distance
	else:
		target_position = start_position + direction_vector * (-backward_distance)

func _physics_process(delta: float) -> void:
	if is_moving:
		var distance_to_target = global_position.distance_to(target_position)

		if distance_to_target < 5.0:
			moving_forward = !moving_forward
			_calculate_target_position()
		else:
			var direction = (target_position - global_position).normalized()
			velocity = direction * movement_speed * delta * 60.0
			move_and_slide()

	_update_state()
