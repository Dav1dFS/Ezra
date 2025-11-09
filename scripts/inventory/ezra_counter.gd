extends Node

var current: int = 0
@export var max_value: int = 10

@onready var label: Label = $CounterLabel

func _ready():
	update_label()

func add_point():
	current += 1
	update_label()

func update_label():
	label.text = str(current) + "/" + str(max_value)
