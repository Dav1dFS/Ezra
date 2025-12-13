extends Control


@onready var input_button_scene = preload("res://scenes/UI/input_button.tscn")
@onready var action_list = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList

var is_remapping: bool = false
var action_to_remap = null
var remapping_button = null

var input_actions = {
	"move_up" : "Move Up",
	"move_left" : "Move Left",
	"move_down" : "Move Down",
	"move_right" : "Move Right",
	"interact" : "Interact",
	"ability" : "Ability",
}

func _ready():
	_create_action_list()
	
func _create_action_list():
	InputMap.load_from_project_settings() #dá load às definições default
	for item in action_list.get_children():
		item.queue_free() 
	
	for action in input_actions:
		var button = input_button_scene.instantiate() #cria um botao novo para cada acao na lista
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
			
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))
		
func _on_input_button_pressed(button, action):
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."
		
func _input(event):	
	if is_remapping:
		var dup= false
		for b in action_list.get_children():
			var bAction=b.find_child("LabelInput").text
			if b != remapping_button and  bAction==event.as_text().trim_suffix(" (Physical)"):
				dup=true
		if (
			not dup and (
			event is InputEventKey ||
			(event is InputEventMouseButton && event.pressed))
		):
			
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
				
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			is_remapping = false
			action_to_remap = null
			remapping_button = null	
			accept_event()
			
func _update_action_list(button, event):
			
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" Physical")
	
	
	
func _on_reset_button_pressed():
	_create_action_list()
