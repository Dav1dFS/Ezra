extends Node2D

@export_group("Phasing Settings")
@export var phasing_alpha: float = 0.3
@export var fade_speed: float = 5.0
@export var target_player_path: NodePath

@export_group("Visual Effects")
@export var enable_color_tint: bool = false
@export var tint_color: Color = Color(0.5, 0.8, 1.0, 1.0)
@export var enable_scale_effect: bool = false
@export var scale_factor: float = 0.95

var player: Node2D
var player_sprite: CanvasItem

var original_color: Color
var original_scale: Vector2

var target_color: Color
var target_scale: Vector2

var is_player_inside := false
var area_count := 0


func _ready():
	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_area_entered)
			child.body_exited.connect(_on_area_exited)
	
	if not target_player_path.is_empty():
		player = get_node_or_null(target_player_path)
		if player:
			_find_player_sprite()


func _find_player_sprite():
	player_sprite = player.find_child("AnimatedSprite2D", true, false)
	if not player_sprite:
		player_sprite = player.find_child("Sprite2D", true, false)
	if not player_sprite and player is CanvasItem:
		player_sprite = player
	
	if player_sprite:
		original_color = player_sprite.modulate
		original_scale = player_sprite.scale


func _process(delta):
	if not player_sprite:
		return
	
	if is_player_inside:
		target_color = tint_color if enable_color_tint else original_color
		target_color.a = phasing_alpha
		target_scale = original_scale * scale_factor if enable_scale_effect else original_scale
	else:
		target_color = original_color
		target_scale = original_scale
	
	player_sprite.modulate = player_sprite.modulate.lerp(
		target_color,
		fade_speed * delta
	)
	
	if enable_scale_effect:
		player_sprite.scale = player_sprite.scale.lerp(
			target_scale,
			fade_speed * delta
		)


func _on_area_entered(body: Node2D):
	if body != player:
		return
	
	area_count += 1
	is_player_inside = true


func _on_area_exited(body: Node2D):
	if body != player:
		return
	
	area_count -= 1
	
	if area_count <= 0:
		area_count = 0
		is_player_inside = false
