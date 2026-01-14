extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "savegame_"
const SAVE_FILE_EXT = ".save"
const MAX_SLOTS = 6

var _pending_load_data = null
var current_slot: int = -1
var is_loading: bool = false

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func _get_save_path(slot_index: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot_index) + SAVE_FILE_EXT

func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot_index))

func has_any_save() -> bool:
	for i in range(1, MAX_SLOTS + 1):
		if has_save(i):
			return true
	return false

func get_slot_info(slot_index: int) -> Dictionary:
	if not has_save(slot_index):
		return {"empty": true}

	var file = FileAccess.open(_get_save_path(slot_index), FileAccess.READ)
	if file == null:
		return {"empty": true}

	var save_data = file.get_var()
	file.close()

	if save_data == null:
		return {"empty": true}

	var gamestate_data = save_data.get("gamestate", {})
	return {
		"empty": false,
		"character_name": gamestate_data.get("character_name", "Unknown"),
		"play_time": gamestate_data.get("play_time", 0.0),
		"timestamp": save_data.get("timestamp", 0),
		"current_scene": save_data.get("current_scene", "")
	}

func format_play_time(play_time: float) -> String:
	return UIUtils.format_play_time(play_time)

func format_timestamp(timestamp: int) -> String:
	if timestamp == 0:
		return ""
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d/%02d/%02d" % [datetime.year, datetime.month, datetime.day]

func save_game(slot_index: int) -> bool:
	var save_data = {
		"version": 1,
		"timestamp": int(Time.get_unix_time_from_system()),
		"gamestate": Gamestate.get_save_data(),
		"current_scene": _get_current_scene_path(),
		"player_position": _get_player_position(),
		"collected_memories": _get_collected_memories(),
		"inventory_items": _get_inventory_items()
	}

	var file = FileAccess.open(_get_save_path(slot_index), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing")
		return false

	file.store_var(save_data)
	file.close()

	current_slot = slot_index
	return true

func create_new_game(slot_index: int) -> bool:
	Gamestate.reset_to_defaults()
	get_tree().paused = false

	current_slot = slot_index

	get_tree().change_scene_to_file("res://scenes/gameplay/level_1/day_1_intro.tscn")

	return true

func load_game(slot_index: int) -> bool:
	if not has_save(slot_index):
		push_error("SaveManager: No save found in slot ", slot_index)
		return false

	var file = FileAccess.open(_get_save_path(slot_index), FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading")
		return false

	var save_data = file.get_var()
	file.close()

	if save_data == null:
		push_error("SaveManager: Failed to parse save data")
		return false

	is_loading = true

	var gamestate_data = save_data.get("gamestate", {})
	Gamestate.load_save_data(gamestate_data)

	get_tree().paused = false

	_pending_load_data = save_data
	current_slot = slot_index

	var scene_path = save_data.get("current_scene", "res://scenes/gameplay/level_1/night_1.tscn")
	get_tree().change_scene_to_file(scene_path)

	get_tree().node_added.connect(_on_node_added_after_load)

	return true

func _get_current_scene_path() -> String:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.scene_file_path
	return ""

func _get_player_position() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return {"x": player.global_position.x, "y": player.global_position.y}
	return {"x": 0, "y": 0}

func _get_collected_memories() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if player and "collected_memories" in player:
		return player.collected_memories
	return 0

func _get_inventory_items() -> Array:
	var player = get_tree().get_first_node_in_group("player")
	if player and "inv" in player and player.inv:
		var items = []
		for item in player.inv.current_items:
			items.append({
				"name": item.name,
				"path": item.resource_path
			})
		return items
	return []

func _on_node_added_after_load(node: Node):
	if node.is_in_group("player") and _pending_load_data:
		if get_tree().node_added.is_connected(_on_node_added_after_load):
			get_tree().node_added.disconnect(_on_node_added_after_load)

		var player_node = node
		var save_data = _pending_load_data
		_pending_load_data = null

		await get_tree().process_frame

		_restore_player_state(player_node, save_data)

func _restore_player_state(node: Node, save_data: Dictionary):
	var pos = save_data.get("player_position", {})
	node.global_position = Vector2(pos.get("x", 0), pos.get("y", 0))

	if "collected_memories" in node:
		var memories = save_data.get("collected_memories", 0)
		node.collected_memories = memories
		var counter = node.get_node_or_null("GUI/Counter")
		if counter and counter.has_method("set_value"):
			counter.set_value(memories)

	if "inv" in node and node.inv:
		node.inv.current_items.clear()
		var saved_items = save_data.get("inventory_items", [])
		for item_data in saved_items:
			var item_path = item_data.get("path", "")
			if item_path != "" and ResourceLoader.exists(item_path):
				var item = load(item_path)
				if item:
					node.inv.current_items.append(item)
		node.inv.inventory_changed.emit()
		
	is_loading = false

func delete_save(slot_index: int) -> bool:
	var path = _get_save_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return true
	return false
