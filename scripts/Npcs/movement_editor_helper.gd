@tool
extends Node2D

@export var forw_line_color = Color.BLUE
@export var back_line_color = Color.YELLOW
@export var line_width = 1.0
@export var point_color = Color.RED
@export var point_size = 2.0

@onready var enemy: CharacterBody2D = get_parent()

func _draw():
	if not Engine.is_editor_hint() or not enemy:
		return

	if not enemy.has_method("get") or not enemy.get("is_moving"):
		return

	var forward_distance = enemy.get("forward_distance")
	var backward_distance = enemy.get("backward_distance")
	var initial_direction = enemy.get("initial_direction")

	var direction = Vector2.ZERO
	match initial_direction:
		0: direction = Vector2.RIGHT
		1: direction = Vector2.LEFT
		2: direction = Vector2.UP
		3: direction = Vector2.DOWN

	var start_pos = Vector2.ZERO
	var forward_pos = direction * forward_distance
	var backward_pos = direction * (-backward_distance)

	draw_line(start_pos, forward_pos, forw_line_color, line_width)
	draw_line(start_pos, backward_pos, back_line_color, line_width)

	draw_circle(start_pos, point_size, point_color)  # Starting position
	draw_circle(forward_pos, point_size, forw_line_color)  # Forward target
	draw_circle(backward_pos, point_size, back_line_color)  # Backward target


func _draw_arrow(from: Vector2, to: Vector2, color: Color):
	var direction = (to - from).normalized()
	var arrow_length = 15.0
	var arrow_angle = PI / 6  # 30 degrees

	var arrow_point1 = to - direction.rotated(arrow_angle) * arrow_length
	var arrow_point2 = to - direction.rotated(-arrow_angle) * arrow_length

	draw_line(to, arrow_point1, color, 2.0)
	draw_line(to, arrow_point2, color, 2.0)
