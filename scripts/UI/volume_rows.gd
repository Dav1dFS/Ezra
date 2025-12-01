extends HBoxContainer

signal volume_changed(value: float)

@onready var slider = $DisplayRow/DisplayRow/HSlider
@onready var value_label = $DisplayRow/Value

func _ready():
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 100.0

	_update_label(slider.value)

	slider.value_changed.connect(_on_value_changed)
	slider.drag_ended.connect(_on_slider_released)

func _on_value_changed(value: float):
	_update_label(value)

func _on_slider_released(value_changed: bool):
	if value_changed:
		emit_signal("volume_changed", slider.value)

func _update_label(value: float):
	value_label.text = str(int(value)) + "%"

func get_value() -> float:
	return slider.value

func set_value(value: float):
	slider.value = clamp(value, slider.min_value, slider.max_value)
	_update_label(slider.value)
