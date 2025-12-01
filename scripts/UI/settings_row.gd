extends HBoxContainer

var options: Array[String] = []
var current_index := 0

@onready var value_label = $DisplayRow/DisplayRow/ScreenMode
@onready var left_arrow  = $DisplayRow/LeftArrow
@onready var right_arrow = $DisplayRow/RightArrow

signal value_changed(value: String)

func _ready():
	_update_display()

func set_options(values: Array):
	options = []
	for v in values:
		options.append(str(v))
	current_index = clamp(current_index, 0, options.size() - 1)
	_update_display()

func get_value() -> String:
	if options.is_empty():
		return ""
	return options[current_index]

func set_value(value: String):
	if options.is_empty():
		return
	var index = options.find(value)
	if index != -1:
		current_index = index
		_update_display(false) # não emitir sinal

func _on_left_pressed():
	if options.is_empty():
		return
	current_index = (current_index - 1 + options.size()) % options.size()
	_update_display(true)

func _on_right_pressed():
	if options.is_empty():
		return
	current_index = (current_index + 1) % options.size()
	_update_display(true)

func _update_display(emit := true):
	if options.is_empty():
		value_label.text = "-"
		return
	value_label.text = options[current_index]
	if emit:
		emit_signal("value_changed", options[current_index])
