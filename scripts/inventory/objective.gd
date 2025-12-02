extends Node

var current: String = ""
@onready var label: Label = $CounterLabel

func _ready():
	update_label()

func updateObjective(text:String):
	current=text
	update_label()
	
func update_label():
	label.text = str(current) 
	
	
