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

func open_settings():
	visible = true
	for node in middle_nodes + [right_color]:
		UIUtils.fade_in(node)

func close_settings():
	for node in middle_nodes + right_nodes:
		UIUtils.fade_out(node)
	
	if is_inside_tree():
		await get_tree().create_timer(0.3).timeout
		if is_inside_tree():
			visible = false

func _on_video_settings_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			UIUtils.fade_out(node)
	UIUtils.fade_in(video_column)
	UIUtils.fade_in(right_color)

func _on_controls_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			UIUtils.fade_out(node)
	UIUtils.fade_in(controls_column)
	UIUtils.fade_in(right_color)

func _on_audio_settings_pressed() -> void:
	for node in right_nodes:
		if node.visible:
			UIUtils.fade_out(node)
	UIUtils.fade_in(audio_column)
	UIUtils.fade_in(right_color)
