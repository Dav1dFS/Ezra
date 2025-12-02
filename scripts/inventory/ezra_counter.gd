extends Node

var currentVal: int=0
@onready var  max_value= 0
@onready var label: Label = $CounterLabel

func _ready():
	update_label()
	
func add_point():
	currentVal+=1

func set_value(value: int):
	currentVal = value
	update_label()

func update_label():

	label.text = str(currentVal) + "/" + str(max_value)
	
