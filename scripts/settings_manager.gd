extends Node

const SETTINGS_FILE = "user://settings.cfg"

var config = ConfigFile.new()

func _ready():
	load_settings()

func load_settings():
	var err = config.load(SETTINGS_FILE)
	if err != OK:
		print("No settings file found, using defaults")
		return false
	return true

func save_settings():
	var err = config.save(SETTINGS_FILE)
	if err != OK:
		push_error("Failed to save settings: " + str(err))
		return false
	return true

func get_display_mode(default_value: String = "Windowed") -> String:
	return config.get_value("video", "display_mode", default_value)

func set_display_mode(value: String):
	config.set_value("video", "display_mode", value)

func get_resolution(default_value: String = "1152x648") -> String:
	return config.get_value("video", "resolution", default_value)

func set_resolution(value: String):
	config.set_value("video", "resolution", value)

func get_gamma(default_value: float = 1.0) -> float:
	return config.get_value("video", "gamma", default_value)

func set_gamma(value: float):
	config.set_value("video", "gamma", value)

func get_max_fps(default_value: int = 60) -> int:
	return config.get_value("video", "max_fps", default_value)

func set_max_fps(value: int):
	config.set_value("video", "max_fps", value)

func get_show_fps(default_value: bool = false) -> bool:
	return config.get_value("video", "show_fps", default_value)

func set_show_fps(value: bool):
	config.set_value("video", "show_fps", value)

func get_master_volume(default_value: float = 100.0) -> float:
	return config.get_value("audio", "master_volume", default_value)

func set_master_volume(value: float):
	config.set_value("audio", "master_volume", value)

func get_sfx_volume(default_value: float = 100.0) -> float:
	return config.get_value("audio", "sfx_volume", default_value)

func set_sfx_volume(value: float):
	config.set_value("audio", "sfx_volume", value)

func get_music_volume(default_value: float = 100.0) -> float:
	return config.get_value("audio", "music_volume", default_value)

func set_music_volume(value: float):
	config.set_value("audio", "music_volume", value)

func save_keybind(action_name: String, event: InputEvent):
	if event is InputEventKey:
		config.set_value("keybinds", action_name + "_type", "key")
		config.set_value("keybinds", action_name + "_keycode", event.physical_keycode)
	elif event is InputEventMouseButton:
		config.set_value("keybinds", action_name + "_type", "mouse")
		config.set_value("keybinds", action_name + "_button", event.button_index)

func load_keybind(action_name: String) -> InputEvent:
	var event_type = config.get_value("keybinds", action_name + "_type", "")

	if event_type == "key":
		var keycode = config.get_value("keybinds", action_name + "_keycode", 0)
		if keycode != 0:
			var ev = InputEventKey.new()
			ev.physical_keycode = keycode
			return ev
	elif event_type == "mouse":
		var button = config.get_value("keybinds", action_name + "_button", 0)
		if button != 0:
			var ev = InputEventMouseButton.new()
			ev.button_index = button
			return ev

	return null

func has_saved_keybind(action_name: String) -> bool:
	return config.has_section_key("keybinds", action_name + "_type")
