extends VBoxContainer

@onready var display_mode_row = $TopGroup/DisplayRow
@onready var resolution_row = $TopGroup/ResolutionRow
@onready var gamma_row = $TopGroup/GammaRow
@onready var max_fps_row = $TopGroup/FpsRow
@onready var show_fps_row = $TopGroup/ShowFpsRow
@onready var buttons_row = $BottomGroup/ResetApplyRow
@onready var gamma_overlay = get_tree().get_root().find_child("GammaRect", true, false)
@onready var fps_label = get_tree().get_root().find_child("FPSLabel", true, false)

var display_modes = ["Windowed", "Fullscreen", "Borderless"]
var resolutions = ["1152x648", "1280x720", "1600x900", "1920x1080"]

const DEFAULT_DISPLAY_MODE = "Windowed"
const DEFAULT_RESOLUTION = "1152x648"
const DEFAULT_GAMMA = 1.0
const DEFAULT_FPS = 60
const DEFAULT_SHOW_FPS = false

var _applied_display_mode := DEFAULT_DISPLAY_MODE
var _applied_resolution   := DEFAULT_RESOLUTION
var _applied_gamma        := DEFAULT_GAMMA
var _applied_fps          := DEFAULT_FPS
var _applied_show_fps     := DEFAULT_SHOW_FPS

var _pending_display_mode := _applied_display_mode
var _pending_resolution   := _applied_resolution
var _pending_gamma        := _applied_gamma
var _pending_fps          := _applied_fps
var _pending_show_fps     := _applied_show_fps

func _ready():
	display_mode_row.set_options(display_modes)
	display_mode_row.value_changed.connect(_on_display_mode_changed)

	resolution_row.set_options(resolutions)
	resolution_row.value_changed.connect(_on_resolution_changed)

	gamma_row.gamma_changed.connect(_on_gamma_changed)
	max_fps_row.fps_changed.connect(_on_fps_changed)
	show_fps_row.toggled_show_fps.connect(_on_toggled_show_fps)

	set_process(true)

func _on_display_mode_changed(value: String):
	_pending_display_mode = value

	var left_arrow = resolution_row.get_node("DisplayRow/LeftArrow")
	var right_arrow = resolution_row.get_node("DisplayRow/RightArrow")
	var label = resolution_row.get_node("DisplayRow/DisplayRow/ScreenMode")

	if value == "Fullscreen":
		
		left_arrow.disabled = true
		right_arrow.disabled = true

		var screen_size = DisplayServer.screen_get_size()
		label.text = str(screen_size.x) + "x" + str(screen_size.y)
		label.modulate = Color(0.5, 0.5, 0.5)
	else:
		left_arrow.disabled = false
		right_arrow.disabled = false
		label.modulate = Color(1, 1, 1)

		label.text = _pending_resolution

func _on_resolution_changed(value: String):
	_pending_resolution = value

func _on_gamma_changed(value: float):
	_pending_gamma = clamp(value, 0.7, 2.0)

func _on_fps_changed(value: int):
	_pending_fps = value

func _on_toggled_show_fps(enabled: bool):
	_pending_show_fps = enabled

func _process(_delta: float):
	UIUtils.update_fps_label(fps_label)

func _on_apply_pressed():
	_apply_settings(
		_pending_display_mode,
		_pending_resolution,
		_pending_gamma,
		_pending_fps,
		_pending_show_fps
	)

func _on_reset_pressed():
	display_mode_row.set_value(DEFAULT_DISPLAY_MODE)
	resolution_row.set_value(DEFAULT_RESOLUTION)
	gamma_row.set_value(DEFAULT_GAMMA)
	max_fps_row.set_value(DEFAULT_FPS)
	show_fps_row.set_checked(DEFAULT_SHOW_FPS)

	_pending_display_mode = DEFAULT_DISPLAY_MODE
	_pending_resolution   = DEFAULT_RESOLUTION
	_pending_gamma        = DEFAULT_GAMMA
	_pending_fps          = DEFAULT_FPS
	_pending_show_fps     = DEFAULT_SHOW_FPS

	_apply_settings(
		DEFAULT_DISPLAY_MODE,
		DEFAULT_RESOLUTION,
		DEFAULT_GAMMA,
		DEFAULT_FPS,
		DEFAULT_SHOW_FPS
	)
	_on_display_mode_changed(DEFAULT_DISPLAY_MODE)

func _apply_settings(display_mode: String, resolution: String, gamma: float, fps: int, show_fps: bool):
	match display_mode:
		"Windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		"Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"Borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())

	_apply_resolution_string(resolution)
	
	if gamma_overlay:
		var mat: ShaderMaterial = gamma_overlay.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("gamma", float(gamma))
			
	Engine.max_fps = fps
	if fps_label:
		fps_label.visible = show_fps

	_applied_display_mode = display_mode
	_applied_resolution   = resolution
	_applied_gamma        = gamma
	_applied_fps          = fps
	_applied_show_fps     = show_fps

	_pending_display_mode = display_mode
	_pending_resolution   = resolution
	_pending_gamma        = gamma
	_pending_fps          = fps
	_pending_show_fps     = show_fps
	
	if display_mode == "Fullscreen":
		var screen_size = DisplayServer.screen_get_size()
		resolution_row.get_node("ScreenMode").text = str(screen_size.x) + "x" + str(screen_size.y)
	else:
		resolution_row.get_node("ScreenMode").text = resolution
		
func _apply_resolution_string(value: String):
	var parts = value.split("x")
	if parts.size() == 2:
		var win_size = Vector2i(parts[0].to_int(), parts[1].to_int())
		DisplayServer.window_set_size(win_size)
		var screen_center = DisplayServer.screen_get_size() / 2 - win_size / 2
		DisplayServer.window_set_position(screen_center)
