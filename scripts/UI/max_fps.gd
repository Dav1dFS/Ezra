extends HBoxContainer

signal fps_changed(value: int)

@onready var slider = $DisplayRow/DisplayRow/HSlider
@onready var value_label = $DisplayRow/Value

var _min_value := 30
var _max_value := 240
var _max_unlimited := 10000
var _is_unlimited := false

func _ready():
	slider.min_value = _min_value
	slider.max_value = _max_value
	slider.step = 0.1
	slider.value = 60
	_update_label(slider.value)
	
	slider.value_changed.connect(_on_value_changed)

func get_value() -> int:
	if _is_unlimited:
		return 0 
	return int(slider.value)

func set_value(value: int):
	if value == 0:
		_is_unlimited = true
		slider.editable = false
		slider.value = _max_unlimited
		value_label.text = "∞"
	else:
		_is_unlimited = false
		slider.editable = true
		slider.value = clamp(value, slider.min_value, _max_value)
		value_label.text = str(int(value))
		

func _update_label(value: float):
	value_label.text = str(int(value))

func _on_value_changed(value: float):

	var int_val = int(value)
	_update_label(value)

	if int_val >= _max_value:
		_is_unlimited = true
		slider.value = _max_unlimited
		value_label.text = "∞"
		emit_signal("fps_changed", 0)
	else:
		if slider.value > _max_value:
			slider.value = _max_value
		_is_unlimited = false
		emit_signal("fps_changed", int_val)