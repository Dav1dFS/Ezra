extends Node

var memories_collected: Dictionary = {}
var npc_dialogues_completed: Dictionary = {}
var character_name: String
var game_is_paused := false
var custom_cursor: Texture2D
var play_time:= 0.0
var is_talking: bool = false
var dialogue_locked := false
var memory_zoom_enabled := false
var can_control_frieda: bool = false

func _ready():
	var img = load("res://assets/character_sprites/ezra/ezra_base.png").get_image()
	img.resize(32, 32)
	custom_cursor = ImageTexture.create_from_image(img)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func toggle_pause():
	game_is_paused = !game_is_paused
	get_tree().paused = game_is_paused

	if game_is_paused:
		Input.set_custom_mouse_cursor(custom_cursor)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _process(delta):
	if not game_is_paused:
		play_time += delta
		
func get_formatted_play_time() -> String:
	return UIUtils.format_play_time(play_time)

const _EXCLUDED_PROPERTIES := [
	"custom_cursor",
	"game_is_paused",
	"is_talking",
	"dialogue_locked",
]

func get_save_data() -> Dictionary:
	var data := {}
	for property in get_property_list():
		var prop_name: String = property["name"]
		if prop_name.begins_with("_") or prop_name in _EXCLUDED_PROPERTIES:
			continue
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			data[prop_name] = get(prop_name)
	return data

func load_save_data(data: Dictionary) -> void:
	for key in data.keys():
		if key in _EXCLUDED_PROPERTIES:
			continue
		if key in self:
			set(key, data[key])
	game_is_paused = false
	is_talking = false
	dialogue_locked = false

func reset_to_defaults() -> void:
	memories_collected = {}
	npc_dialogues_completed = {}
	character_name = ""
	play_time = 0.0
	memory_zoom_enabled = false
	can_control_frieda = false
	game_is_paused = false
	is_talking = false
	dialogue_locked = false
