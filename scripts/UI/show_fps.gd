extends HBoxContainer

signal toggled_show_fps(enabled: bool)

@onready var checkbox = $CheckBox

func _ready():
	checkbox.toggled.connect(_on_checkbox_toggled)

func _on_checkbox_toggled(button_pressed: bool):
	emit_signal("toggled_show_fps", button_pressed)

func get_checked() -> bool:
	return checkbox.button_pressed

func set_checked(value: bool):
	checkbox.button_pressed = value
