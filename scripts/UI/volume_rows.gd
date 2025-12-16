extends BaseSliderRow

signal volume_changed(value: float)

func _ready():
	min_value = 0.0
	max_value = 100.0
	step = 1.0
	default_value = 100.0
	super._ready()

func _on_slider_released(value_changed: bool):
	if value_changed:
		volume_changed.emit(slider.value)

func _format_value(value: float) -> String:
	return str(int(value)) + "%"
