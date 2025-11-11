extends HBoxContainer

signal gamma_changed(value: float)

@onready var slider = $HSlider
@onready var value_label = $Value

func _ready():
	slider.min_value = 0.7  
	slider.max_value = 2.0
	slider.step = 0.1         
	slider.value = 1.0
	value_label.text = str(round(slider.value * 100) / 100.0)

	slider.value_changed.connect(_on_value_changed)
	slider.drag_ended.connect(_on_slider_released)

func _on_value_changed(value: float):
	value_label.text = str(round(value * 100) / 100.0)

func _on_slider_released(value_changed: bool):
	if value_changed:
		emit_signal("gamma_changed", slider.value)

func get_value() -> float:
	return slider.value

func set_value(value: float):
	slider.value = clamp(value, slider.min_value, slider.max_value)
	value_label.text = str(round(slider.value * 100) / 100.0)
