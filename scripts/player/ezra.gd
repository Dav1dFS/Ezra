extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var memories: Array[Node] = self.get_tree().get_nodes_in_group("Memories")
@onready var objective: Control = $GUI/Objective
@export var max_value: int = 3

var is_ability_active: bool = false
var max_zoom: float = 5.0
var min_zoom: float = 2.0
var close_mem: Node = null
var collected_memories: int = 0
var original_zoom: float
var final_zoom_done: bool = false
var zoom_speed: float = 0.02

var ellen_anims = {
	Direction.DOWN: "down",
	Direction.UP: "up",
	Direction.LEFT: "left",
	Direction.RIGHT: "right"
}

func _ready():
	character_name = "Ezra"
	super._ready()
	original_zoom = cam.zoom.x

func _update_sprite_for_direction():
	if ellen_anims.has(current_direction):
		sprite.play(ellen_anims[current_direction])

func increment_item_counter():
	print("added counter")
	memories.erase(close_mem)
	objective.add_point()
	collected_memories += 1
	
func _process(delta: float) -> void:
	if Gamestate.is_talking or Gamestate.dialogue_locked:
		return
	if not Gamestate.memory_zoom_enabled:
		return
		
	if collected_memories >= max_value:
		Gamestate.can_control_frieda = true
		
		if memories.is_empty():
			_apply_final_zoom(delta)
			return
			
	var min_distance = 10000000
	var dis = 0
	for mem in memories:
		dis = self.global_position.distance_to(mem.global_position)
		if dis < min_distance:
			min_distance = dis
			close_mem = mem
	
	get_zoom_from_distance(min_distance, delta)
	
func get_zoom_from_distance(distance: float, delta: float):
	var target_zoom: float
	var min_dist = 50.0
	var max_dist = 300.0
	
	if distance < min_dist:
		target_zoom = max_zoom
	elif distance > max_dist:
		target_zoom = min_zoom
	else:
		var t = (distance - min_dist) / (max_dist - min_dist)
		t = ease(t, 0.5)
		target_zoom = lerp(max_zoom, min_zoom, t)
	
	var adaptive_speed = zoom_speed
	var zoom_diff = abs(cam.zoom.x - target_zoom)
	if zoom_diff > 1.0:
		adaptive_speed *= 2.0
	elif zoom_diff < 0.3:
		adaptive_speed *= 0.5
	
	cam.zoom.x = lerp(cam.zoom.x, target_zoom, adaptive_speed)
	cam.zoom.y = cam.zoom.x

func _apply_final_zoom(delta: float) -> void:
	if final_zoom_done:
		return
	
	var target_zoom = original_zoom * 1.0
	var t := 3.0 * delta 
	cam.zoom.x = lerp(cam.zoom.x, target_zoom, t)
	cam.zoom.y = cam.zoom.x
	
	if abs(cam.zoom.x - target_zoom) < 0.01:
		cam.zoom.x = target_zoom
		cam.zoom.y = target_zoom
		final_zoom_done = true
	
func changeObjective(text: String):
	objective.updateObjective(text)
