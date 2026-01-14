extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var memories: Array[Node] = get_tree().get_nodes_in_group("Memories")

@export var max_value: int = 3
@export var footprint_scene: PackedScene
@export var footprints_step_distance: float = 30.0
@export var footprints_per_second: float = 6.0
@export var max_path_length: float = 2000.0
@export var path_update_distance: float = 24.0
@export var direction_change_threshold: float = 0.25
@export var target_npc: NodePath
@export var target_npc_gamestate_flag: String = "can_control_frieda"
@export var footprint_side_offset: float = 3.0

@export var ability_duration_normal: float = 6.0
@export var ability_cooldown_normal: float = 10.0
@export var ability_duration_penalized: float = 3.0
@export var ability_cooldown_penalized: float = 20.0
@export var dog_alert_penalty_duration: float = 60.0 

var ability_timer: float = 0.0
var cooldown_timer: float = 0.0
var ability_active: bool = false
var ability_ready: bool = true
var footprints_instances: Array = []
var _last_path_player_pos: Vector2
var _current_path_target: Node2D = null
var _last_dir_vector: Vector2 = Vector2.ZERO
var _prev_player_pos: Vector2 = Vector2.ZERO

var max_zoom: float = 5.0
var min_zoom: float = 2.0
var close_mem: Node = null
var collected_memories: int = 0
var original_zoom: float
var final_zoom_done: bool = false
var zoom_speed: float = 0.02
var _tracking_npc: bool = false

var is_penalized: bool = false
var penalty_timer: float = 0.0
var was_dog_alerted_last_frame: bool = false

func _ready():
	super._ready()
	character_name = "Ezra"
	original_zoom = cam.zoom.x
	_last_path_player_pos = global_position
	_prev_player_pos = global_position


func setup_abilities():
	var track_ability = EzraTrackAbility.new()
	ability_manager.set_primary_ability(track_ability)


func increment_item_counter():
	memories.erase(close_mem)
	objective.add_point()
	collected_memories += 1

func _process(delta: float):
	var in_dialogue = Gamestate.is_talking or Gamestate.dialogue_locked

	_update_penalty_timer(delta)
	_check_dog_alert_triggered()
	
	if in_dialogue:
		_prev_player_pos = global_position
		_process_ability_timers(delta)
		return
	
	if not Gamestate.memory_zoom_enabled:
		_prev_player_pos = global_position
		return
	
	var can_use_footprint_ability = Gamestate.ezra_can_spawn_footprints and not Gamestate.dog_is_alerted

	var should_track_npc = _should_track_target_npc()
	if should_track_npc:
		_tracking_npc = true
		var npc = get_node_or_null(target_npc)
		if npc:
			var dist_to_npc = global_position.distance_to(npc.global_position)
			get_zoom_from_distance(dist_to_npc, delta)
			
			if can_use_footprint_ability:
				_update_footprint_path_to_target(npc)
			else:
				if footprints_instances.size() > 0:
					_clear_footprint_path()
		else:
			push_warning("Target NPC not found at path: " + str(target_npc))
		
		_process_ability_timers(delta)
		_prev_player_pos = global_position
		return
	
	if _tracking_npc and not should_track_npc:
		_tracking_npc = false
		final_zoom_done = false
		_clear_footprint_path()
	
	if collected_memories >= max_value and memories.is_empty():
		_apply_final_zoom(delta)
		_process_ability_timers(delta)
		_prev_player_pos = global_position
		return
	
	var min_distance = 1e9
	for mem in memories:
		var dis = global_position.distance_to(mem.global_position)
		if dis < min_distance:
			min_distance = dis
			close_mem = mem
	
	get_zoom_from_distance(min_distance, delta)
	_process_ability_timers(delta)
	
	if not memories.is_empty():
		_update_footprint_path_if_needed()
	
	_prev_player_pos = global_position

func _check_dog_alert_triggered():
	var dog_alerted_now = Gamestate.dog_is_alerted
	
	if dog_alerted_now and not was_dog_alerted_last_frame:
		_on_dog_alert_triggered()
	
	was_dog_alerted_last_frame = dog_alerted_now

func _on_dog_alert_triggered():
	is_penalized = true
	penalty_timer = dog_alert_penalty_duration
	
	if ability_active:
		ability_active = false
		ability_timer = 0
		_clear_footprint_path()
		
		# Inicia cooldown penalizado
		cooldown_timer = ability_cooldown_penalized
		ability_ready = false

func _update_penalty_timer(delta: float):
	if is_penalized:
		penalty_timer -= delta
		if penalty_timer <= 0:
			penalty_timer = 0
			is_penalized = false

func get_current_ability_duration() -> float:
	return ability_duration_penalized if is_penalized else ability_duration_normal

func get_current_ability_cooldown() -> float:
	return ability_cooldown_penalized if is_penalized else ability_cooldown_normal


func _process_ability_timers(delta: float):
	if ability_active:
		ability_timer -= delta

		if ability_timer <= 0:
			ability_active = false
			ability_timer = 0
			_clear_footprint_path()
			cooldown_timer = get_current_ability_cooldown()

	elif not ability_ready:
		cooldown_timer -= delta

		if cooldown_timer <= 0:
			cooldown_timer = 0
			ability_ready = true


func _should_track_target_npc() -> bool:
	if collected_memories < max_value or not memories.is_empty():
		return false
	
	if target_npc_gamestate_flag.is_empty():
		return false
	
	if not target_npc_gamestate_flag in Gamestate:
		return false
	
	return Gamestate.get(target_npc_gamestate_flag) == true

func _update_footprint_path_to_target(npc: Node2D):
	if !ability_active:
		return
	
	if Gamestate.dog_is_alerted:
		if footprints_instances.size() > 0:
			_clear_footprint_path()
		return
	
	var can_spawn = Gamestate.ezra_can_spawn_footprints
	if not can_spawn:
		if footprints_instances.size() > 0:
			_clear_footprint_path()
		return
	
	if Gamestate.is_being_pushed_back:
		return
	
	if not npc or not npc.is_inside_tree():
		_clear_footprint_path()
		return
	
	if npc != _current_path_target:
		_spawn_footprint_path_to(npc)
		return
	
	if not _last_path_player_pos:
		_spawn_footprint_path_to(npc)
		return
	
	var dist_since_last = global_position.distance_to(_last_path_player_pos)
	if dist_since_last >= path_update_distance:
		_spawn_footprint_path_to(npc)
		return
	
	var current_dir = _compute_current_direction()
	if current_dir == _last_dir_vector or current_dir.length() == 0.0:
		return
	
	var angle_diff = abs(_last_dir_vector.angle_to(current_dir)) if _last_dir_vector.length() > 0 else PI
	if angle_diff >= direction_change_threshold:
		_spawn_footprint_path_to(npc)
		return

func get_zoom_from_distance(distance: float, _delta: float):
	var target_zoom: float
	var min_dist = 150.0
	var max_dist = 500.0
	
	if distance < min_dist:
		target_zoom = max_zoom
	elif distance > max_dist:
		target_zoom = min_zoom
	else:
		var t = (distance - min_dist) / (max_dist - min_dist)
		t = ease(t, 0.5)
		target_zoom = lerp(max_zoom, min_zoom, t)
	
	var adaptive_speed = zoom_speed * 3.0
	var zoom_diff = abs(cam.zoom.x - target_zoom)
	
	if zoom_diff > 1.0:
		adaptive_speed *= 2.0
	elif zoom_diff < 0.3:
		adaptive_speed *= 0.5
	
	cam.zoom.x = lerp(cam.zoom.x, target_zoom, adaptive_speed)
	cam.zoom.y = cam.zoom.x

func _apply_final_zoom(delta: float):
	if final_zoom_done:
		return
	
	var target_zoom = original_zoom
	var t := 3.0 * delta
	
	cam.zoom.x = lerp(cam.zoom.x, target_zoom, t)
	cam.zoom.y = cam.zoom.x
	
	if abs(cam.zoom.x - target_zoom) < 0.01:
		cam.zoom.x = target_zoom
		cam.zoom.y = target_zoom
		final_zoom_done = true

func _get_nearest_memory_to_position(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := 1e9
	
	for mem in get_tree().get_nodes_in_group("Memories"):
		if not mem or not mem.is_inside_tree():
			continue
		
		var d = pos.distance_to(mem.global_position)
		if d < best_dist:
			best_dist = d
			best = mem
	
	return best

func _clear_footprint_path():
	for fp in footprints_instances:
		if fp and is_instance_valid(fp) and fp.is_inside_tree():
			if fp.has_method("set_fade_duration"):
				fp.set_fade_duration(0.12)
			if fp.has_method("start_fadeout"):
				fp.start_fadeout()
	
	footprints_instances.clear()
	_current_path_target = null

func _spawn_footprint_path_to(target_node: Node2D):
	if not footprint_scene or not target_node:
		return
	
	_clear_footprint_path()
	
	var start_pos = global_position
	var end_pos = target_node.global_position
	var total_dist = start_pos.distance_to(end_pos)
	var direction = (end_pos - start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	var step_dist = footprints_step_distance * 0.5
	var num_steps = int(ceil(total_dist / step_dist))
	num_steps = clamp(num_steps, 1, int(max_path_length / step_dist))
	
	for i in range(num_steps + 1):
		var t = float(i) / float(num_steps)
		var center_pos = start_pos.lerp(end_pos, t)
		
		var foot_side = 1 if (i % 2) == 0 else 2
		var lateral_offset = -footprint_side_offset if foot_side == 1 else footprint_side_offset
		var footprint_pos = center_pos + (perpendicular * lateral_offset)
		
		_spawn_single_footprint(footprint_pos, target_node, foot_side, direction)
	
	_current_path_target = target_node
	_last_path_player_pos = global_position
	_last_dir_vector = direction

func _spawn_single_footprint(pos: Vector2, target_node: Node2D, side: int, _move_direction: Vector2):
	var fp = footprint_scene.instantiate()
	get_tree().get_current_scene().add_child(fp)
	fp.global_position = pos
	fp.target = target_node
	fp.origin = target_node
	
	if fp.has_method("set_fade_duration"):
		fp.set_fade_duration(0.12)
	
	if fp.has_method("show_side"):
		fp.show_side(side)
		if fp.has_method("apply_visuals_now"):
			fp.apply_visuals_now()
	
	await get_tree().process_frame
	
	if fp and is_instance_valid(fp) and fp.is_inside_tree():
		if fp.has_method("apply_visuals_now"):
			fp.apply_visuals_now()
		footprints_instances.append(fp)

func _compute_current_direction() -> Vector2:
	if Gamestate.is_being_pushed_back:
		return _last_dir_vector
	
	var mv = global_position - _prev_player_pos
	if mv.length() < 0.01:
		return _last_dir_vector
	
	return mv.normalized()

func _update_footprint_path_if_needed():
	if Gamestate.is_being_pushed_back or !ability_active:
		return
	
	if Gamestate.dog_is_alerted:
		if footprints_instances.size() > 0:
			_clear_footprint_path()
		return
	
	var can_spawn = Gamestate.ezra_can_spawn_footprints
	if not can_spawn:
		if footprints_instances.size() > 0:
			_clear_footprint_path()
		return
	
	var nearest = _get_nearest_memory_to_position(global_position)
	if not nearest:
		_clear_footprint_path()
		return
	
	if nearest != _current_path_target:
		_spawn_footprint_path_to(nearest)
		return
	
	if not _last_path_player_pos:
		_spawn_footprint_path_to(nearest)
		return
	
	var dist_since_last = global_position.distance_to(_last_path_player_pos)
	if dist_since_last >= path_update_distance:
		_spawn_footprint_path_to(nearest)
		return
	
	var current_dir = _compute_current_direction()
	if current_dir == _last_dir_vector or current_dir.length() == 0.0:
		return
	
	var angle_diff = abs(_last_dir_vector.angle_to(current_dir)) if _last_dir_vector.length() > 0 else PI
	if angle_diff >= direction_change_threshold:
		_spawn_footprint_path_to(nearest)
		return
