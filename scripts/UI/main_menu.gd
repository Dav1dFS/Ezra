extends Control

@onready var fps_label = get_tree().get_root().find_child("FPSLabel", true, false)
@onready var settings = $Settings
@onready var saving_options = $SavingOptions

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$AnimatedSprite2D.play()

func _close_menus():
	if settings.visible:
		settings.close_settings()
	if saving_options.visible:
		saving_options.close_saving_options()
	await get_tree().create_timer(0.3).timeout

func _process(_delta: float):
	UIUtils.update_fps_label(fps_label)


func _on_resume_game_pressed() -> void:
	if SaveManager.has_any_save() and SaveManager.current_slot > 0:
		SaveManager.load_game(SaveManager.current_slot)
	else:
		_on_load_game_pressed()


func _on_new_game_pressed() -> void:
	if !saving_options.visible or saving_options.current_action_type != saving_options.action_types.CREATE:
		_close_menus()
		await get_tree().create_timer(0.3).timeout
		saving_options.open_saving_options(saving_options.action_types.CREATE)
	else:
		saving_options.close_saving_options()


func _on_load_game_pressed() -> void:
	if !saving_options.visible or saving_options.current_action_type != saving_options.action_types.LOAD:
		_close_menus()
		await get_tree().create_timer(0.3).timeout
		saving_options.open_saving_options(saving_options.action_types.LOAD)
	else:
		saving_options.close_saving_options()


func _on_options_pressed() -> void:
	if !settings.visible:
		_close_menus()
		await get_tree().create_timer(0.3).timeout
		settings.open_settings()
	else:
		settings.close_settings()


func _on_exit_desktop_pressed() -> void:
	get_tree().quit()
