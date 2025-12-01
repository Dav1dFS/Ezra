extends Node

var current: int = 0
@onready var  max_value= 0

@onready var label: Label = $CounterLabel

func _ready():
	var player = get_node("../../")
	max_value=player.max_value
	update_label()

func add_point():
	current += 1
	update_label()

func set_value(value: int):
	current = value
	update_label()

func update_label():
	label.text = str(current) + "/" + str(max_value)
