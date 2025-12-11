extends CanvasLayer

@onready var portrait = $TextureRect
@onready var name_label = $Label
@onready var text_label = $Label2
@onready var text_bg = $Panel

signal dialogue_ended(npc_node, fully_completed: bool)
signal mid_action_triggered(action_name: String)

var lines : Array = []
var current_line = 0
var active: bool = false
var waiting_for_action: bool = false
var current_npc: Node = null
var speaker_portraits: Dictionary = {}

func set_speaker_portraits(portraits: Dictionary):
	speaker_portraits = portraits
	
func start(dialogue : Dictionary, npc: Node):
	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true
	current_npc = npc
	visible = true
	active = true
	
	lines = dialogue.get("lines", [])
	current_line = 0
	_show_line()
	
func _show_line():
	if current_line < lines.size():
		var line_data = lines[current_line]

		# Check for mid_action
		if line_data.has("mid_action"):
			var action_name = line_data.get("mid_action")
			waiting_for_action = true
			visible = false
			emit_signal("mid_action_triggered", action_name)
			return

		var text = line_data.get("text", "")
		var speaker = line_data.get("speaker")

		visible = true
		text_label.text = text

		# Handle speaker and portrait
		if speaker == null:
			name_label.text = ""
			portrait.visible = false
		else:
			name_label.text = speaker.capitalize()
			# Get portrait texture from speaker_portraits dictionary
			if speaker_portraits.has(speaker):
				portrait.texture = speaker_portraits[speaker]
				portrait.visible = true
			else:
				portrait.visible = false
	else:
		end_dialogue(true)

func continue_after_action():
	waiting_for_action = false
	current_line += 1
	_show_line()
		
func _input(event):
	if not active or waiting_for_action:
		return

	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):

		if event is InputEventKey:
			if event.physical_keycode in [
				KEY_W, KEY_A, KEY_S, KEY_D,
				KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE
			]: return
			if event.physical_keycode == KEY_Z:
				current_line = max(current_line - 1, 0)
				_show_line()
				return

		current_line += 1
		_show_line()
		
func end_dialogue(fully_completed = false):
	visible = false
	active = false
	current_line = 0
	
	await get_tree().create_timer(0.1).timeout
	Gamestate.is_talking = false
	Gamestate.dialogue_locked = false
	
	if current_npc:
		emit_signal("dialogue_ended", current_npc, fully_completed)
		current_npc = null
