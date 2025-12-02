extends Control


@onready var middle_column = $MiddleColumn
@onready var video_column = $VideoSettingsColumn
@onready var audio_column = $AudioSettingsColumn
@onready var controls_column = $ControlsColumn
@onready var middle_color = $"ColorRect2"
@onready var right_color = $"ColorRect3"

@onready var middle_nodes = [middle_column, middle_color]
@onready var right_nodes = [right_color, video_column, audio_column, controls_column]
@onready var colour_nodes = [middle_color, right_color]

func _ready():
	for node in middle_nodes + right_nodes:
		node.visible = false
		node.modulate.a = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node in colour_nodes:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# process_mode = Node.PROCESS_MODE_ALWAYS

func fade_in(node: CanvasItem, duration := 0.3):
	node.visible = true
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 1.0, duration)

func fade_out(node: CanvasItem, duration := 0.3):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	if node is not ColorRect:
		tween.finished.connect(func(): node.visible = false)

func open_settings():
	visible = true
	for node in middle_nodes + [right_color]:
		fade_in(node)

func close_settings():
	for node in middle_nodes + right_nodes:
		fade_out(node)
	# Check if node is still valid before awaiting
	if is_inside_tree():
		await get_tree().create_timer(0.3).timeout
		if is_inside_tree():
			visible = false

func _on_video_settings_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			fade_out(node)
	fade_in(video_column)
	fade_in(right_color)

func _on_controls_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			fade_out(node)
	fade_in(controls_column)
	fade_in(right_color)

func _on_audio_settings_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			fade_out(node)
	fade_in(audio_column)
	fade_in(right_color)
