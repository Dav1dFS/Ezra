class_name BaseSliderRow
extends HBoxContainer

signal value_committed(value: float)

@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var step: float = 1.0
@export var default_value: float = 100.0

@onready var slider: HSlider = $DisplayRow/DisplayRow/HSlider
@onready var value_label: Label = $DisplayRow/Value

func _ready():
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = default_value
	_update_label(slider.value)

	slider.value_changed.connect(_on_value_changed)
	slider.drag_ended.connect(_on_slider_released)

func _on_value_changed(value: float):
	_update_label(value)

func _on_slider_released(value_changed: bool):
	if value_changed:
		value_committed.emit(slider.value)

func _update_label(value: float):
	value_label.text = _format_value(value)

# Virtual method - override in child classes for custom formatting
func _format_value(value: float) -> String:
	return str(int(value))

func get_value() -> float:
	return slider.value

func set_value(value: float):
	slider.value = clamp(value, min_value, max_value)
	_update_label(slider.value)
