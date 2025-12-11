extends BaseSliderRow

signal gamma_changed(value: float)

func _ready():
	min_value = 0.7
	max_value = 2.0
	step = 0.1
	default_value = 1.0
	super._ready()

func _on_slider_released(value_changed: bool):
	if value_changed:
		gamma_changed.emit(slider.value)

func _format_value(value: float) -> String:
	return str(round(value * 100) / 100.0)
