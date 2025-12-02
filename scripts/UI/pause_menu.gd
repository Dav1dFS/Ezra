extends Control

@onready var play_duration = $PlayDuration
@onready var settings = $Settings
@onready var saving_options = $SavingOptions

var _menu_tween : Tween

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	if visible:
		play_duration.text = "Play duration: " + Gamestate.get_formatted_play_time()

func _close_submenus():
	if settings.visible:
		settings.close_settings()
	if saving_options.visible:
		saving_options.close_saving_options()

func _unhandled_input(event):
	if visible and event.is_action_pressed("pause"):
		if settings.visible:
			settings.close_settings()
		elif saving_options.visible:
			saving_options.close_saving_options()
		else:
			hide_menu()
		get_viewport().set_input_as_handled()

func show_menu():
	visible = true
	if _menu_tween and _menu_tween.is_running():
		_menu_tween.kill()
	_menu_tween = create_tween()
	_menu_tween.set_ignore_time_scale(true)
	_menu_tween.tween_property(self, "modulate:a", 1.0, 0.25)

func hide_menu():
	if _menu_tween and _menu_tween.is_running():
		_menu_tween.kill()
	_menu_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_menu_tween.finished.connect(func():
		visible = false
		Gamestate.toggle_pause()
		_close_submenus()
	)

func _on_resume_game_pressed() -> void:
	hide_menu()


func _on_save_game_pressed() -> void:
	if !saving_options.visible:
		_close_submenus()
		await get_tree().create_timer(0.1).timeout
		saving_options.open_saving_options(saving_options.action_types.SAVE)
	else:
		saving_options.close_saving_options()


func _on_load_game_pressed() -> void:
	if !saving_options.visible:
		_close_submenus()
		await get_tree().create_timer(0.1).timeout
		saving_options.open_saving_options(saving_options.action_types.LOAD)
	else:
		saving_options.close_saving_options()


func _on_options_pressed() -> void:
	if !settings.visible:
		_close_submenus()
		await get_tree().create_timer(0.1).timeout
		settings.open_settings()
	else:
		settings.close_settings()


func _on_exit_menu_pressed() -> void:
	get_tree().paused = false
	Gamestate.game_is_paused = false
	get_tree().change_scene_to_file("res://scenes/UI/MainMenu.tscn")


func _on_exit_desktop_pressed() -> void:
	get_tree().quit()
