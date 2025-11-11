extends Control

@onready var left_column = $LeftColumn
@onready var middle_column = $MiddleColumn
@onready var video_column = $VideoSettingsColumn
@onready var audio_column = $AudioSettingsColumn
@onready var controls_column = $ControlsColumn
@onready var middle_color = $ColorRect2
@onready var right_color = $ColorRect3
@onready var play_duration = $PlayDuration

var _menu_tween : Tween

func _ready():
	for node in [middle_column, video_column, audio_column, controls_column, middle_color, right_color]:
		node.visible = false
		node.modulate.a = 0.0
	modulate.a = 0.0
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(_delta):
	if visible:
		play_duration.text = "Play duration: " + Gamestate.get_formatted_play_time()	

func fade_in(node: CanvasItem, duration := 0.3):
	node.visible = true
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(node, "modulate:a", 1.0, duration)

func fade_out(node: CanvasItem, duration := 0.3):
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.finished.connect(func(): node.visible = false)

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
	_menu_tween = create_tween()
	_menu_tween.set_ignore_time_scale(true)
	_menu_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_menu_tween.finished.connect(func(): visible = false)

func close_menu():
	hide_menu()
	Gamestate.toggle_pause()

func show_middle_column():
	fade_in(middle_column)
	fade_in(middle_color)

func hide_middle_column():
	fade_out(middle_column)
	fade_out(video_column)
	fade_out(controls_column)
	fade_out(middle_color)

func show_video_column():
	if audio_column.visible:
		fade_out(audio_column)
	if controls_column.visible:
		fade_out(controls_column)
	fade_in(video_column)
	fade_in(right_color)

func show_controls_column():
	if video_column.visible:
		fade_out(video_column)
	if audio_column.visible:
		fade_out(audio_column)
	fade_in(controls_column)
	fade_in(right_color)

func show_audio_column():
	if video_column.visible:
		fade_out(video_column)
	if controls_column.visible:
		fade_out(controls_column)
	fade_in(audio_column)
	fade_in(right_color)

func back_pressed():
	if video_column.visible:
		fade_out(video_column)
	elif controls_column.visible:
		fade_out(controls_column)
	elif audio_column.visible:
		fade_out(audio_column)
	else:
		fade_out(middle_column)
		fade_out(middle_color)
	fade_out(right_color)
