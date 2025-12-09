extends Node2D

@export var max_distance: float = 800.0
@export var min_alpha: float = 0.2
@export var max_alpha: float = 1.0
@export var arrive_distance: float = 12.0
@export var fade_duration: float = 0.12
@export var fade_in_duration: float = 0.0
@export var rotate_sprite_offset_degrees: float = -90.0
@export var invert_direction: bool = false
@export var player_influence_range: float = 200.0
@export var start_side: int = 0
@export var update_alpha_every_frame: bool = true 

@onready var left_sprite: Sprite2D = $Leftfoot
@onready var right_sprite: Sprite2D = $Rightfoot

var target: Node2D = null
var origin: Node2D = null
var _fading: bool = false
var _spawn_ms: int = 0
var _player: Node2D = null
var _alpha_initialized: bool = false

func _ready():
	_spawn_ms = Time.get_ticks_msec()
	_update_player_reference()
	_update_alpha_based_on_player_distance()
	_alpha_initialized = true

	if start_side == 1:
		show_side(1)
	elif start_side == 2:
		show_side(2)
	else:
		show_side(1)

func _process(delta: float):
	if _fading:
		return

	if not target or not target.is_inside_tree():
		start_fadeout()
		return

	_rotate_towards_target()
	
	if update_alpha_every_frame:
		_update_alpha_based_on_player_distance()

	if global_position.distance_to(target.global_position) <= arrive_distance:
		start_fadeout()

func _update_player_reference():
	if _player and _player.is_inside_tree():
		return
	var arr = get_tree().get_nodes_in_group("Player")
	if arr.size() > 0:
		_player = arr[0]

func _rotate_towards_target():
	if not target:
		return
	var dir: Vector2 = (target.global_position - global_position)
	if dir.length() == 0.0:
		return
	dir = dir.normalized()
	if invert_direction:
		dir = -dir
	var desired_angle = dir.angle() + deg_to_rad(rotate_sprite_offset_degrees)
	rotation = desired_angle

func _update_alpha_based_on_player_distance():
	_update_player_reference()
	if not _player or not target:
		return

	var player_to_mem_dist = _player.global_position.distance_to(target.global_position)
	var t = clamp(player_to_mem_dist / max(0.0001, player_influence_range), 0.0, 1.0)
	
	var calculated_alpha = lerp(max_alpha, min_alpha, t)
	var final_alpha = max(calculated_alpha, min_alpha)
	
	# Aplica a ambos os sprites
	if left_sprite:
		var m = left_sprite.modulate
		m.a = final_alpha
		left_sprite.modulate = m
	if right_sprite:
		var mr = right_sprite.modulate
		mr.a = final_alpha
		right_sprite.modulate = mr

func apply_visuals_now():
	if target and target.is_inside_tree():
		_rotate_towards_target()
		_update_alpha_based_on_player_distance()
		_alpha_initialized = true

func set_fade_duration(seconds: float):
	fade_duration = seconds

func start_fadeout():
	if _fading:
		return
	_fading = true

	if not left_sprite and not right_sprite:
		queue_free()
		return

	var tween = create_tween()
	if left_sprite:
		tween.tween_property(left_sprite, "modulate:a", 0.0, fade_duration)
	if right_sprite:
		tween.tween_property(right_sprite, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(self.queue_free)

func show_side(side: int):
	if side == 1:
		if left_sprite:
			left_sprite.visible = true
		if right_sprite:
			right_sprite.visible = false
	elif side == 2:
		if right_sprite:
			right_sprite.visible = true
		if left_sprite:
			left_sprite.visible = false
	else:
		if left_sprite:
			left_sprite.visible = true
		if right_sprite:
			right_sprite.visible = true

func toggle_side():
	if left_sprite and right_sprite:
		if left_sprite.visible:
			show_side(2)
		else:
			show_side(1)
