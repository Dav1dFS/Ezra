extends HBoxContainer

signal fps_changed(value: int)

@onready var slider = $HSlider
@onready var value_label = $Value
@onready var infinity_label = $Infinite
@onready var unlimited_box = $CheckBox

var _max_normal := 200
var _max_unlimited := 10000
var _is_unlimited := false

func _ready():
	slider.min_value = 30
	slider.max_value = _max_normal
	slider.step = 1
	slider.value = 60
	_update_label(slider.value)
	
	slider.value_changed.connect(_on_value_changed)
	unlimited_box.toggled.connect(_on_unlimited_toggled)

func get_value() -> int:
	if _is_unlimited:
		return 0 
	return int(slider.value)

func set_value(value: int):
	if value == 0:
		_is_unlimited = true
		unlimited_box.button_pressed = true
		slider.editable = false
		slider.value = _max_unlimited
		value_label.text = "∞"
		infinity_label.visible = true
	else:
		_is_unlimited = false
		unlimited_box.button_pressed = false
		slider.editable = true
		slider.max_value = _max_normal
		slider.value = clamp(value, slider.min_value, _max_normal)
		_update_label(slider.value)
		infinity_label.visible = slider.value >= _max_normal

func _update_label(value: float):
	value_label.text = str(int(value))

func _on_value_changed(value: float):
	if _is_unlimited:
		return 

	var int_val = int(value)
	_update_label(value)

	if int_val >= _max_normal:
		infinity_label.visible = true
		unlimited_box.visible = true
	else:
		infinity_label.visible = false
		unlimited_box.visible = false
		unlimited_box.button_pressed = false
		_is_unlimited = false
		slider.max_value = _max_normal

	emit_signal("fps_changed", int_val)

func _on_unlimited_toggled(pressed: bool):
	_is_unlimited = pressed
	
	if pressed:
		slider.editable = false
		slider.max_value = _max_unlimited
		slider.value = _max_unlimited
		value_label.text = "∞"
		infinity_label.visible = true
		emit_signal("fps_changed", 0)
	else:
		slider.editable = true
		slider.max_value = _max_normal
		if slider.value > _max_normal:
			slider.value = _max_normal
		_update_label(slider.value)
		infinity_label.visible = slider.value >= _max_normal
		emit_signal("fps_changed", int(slider.value))
