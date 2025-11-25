extends CanvasLayer

@onready var portrait = $TextureRect
@onready var player_portrait = $TextureRect2
@onready var name_label = $Label
@onready var text_label = $Label2
@onready var text_bg = $Panel

signal dialogue_ended(npc_node)

var lines : Array = []
var current_line = 0
var active: bool = false
var current_npc: Node = null

func changeImages(npc, player):
	self.portrait.texture = load(npc)
	self.player_portrait.texture=load(player)
	
func start(dialogue : Dictionary, npc: Node):
	Gamestate.is_talking = true
	Gamestate.dialogue_locked = true
	current_npc = npc
	visible = true
	active = true
	Gamestate.dialogue_locked = true
	
	lines = dialogue.get("lines", [])
	current_line = 0
	_show_line()
	
func _show_line():
	if current_line < lines.size():
		var line_data = lines [current_line]
		var text = line_data.get("text", "")
		var speaker = line_data.get("speaker")  # Can be null, string, or empty

		text_label.text = text

		# Handle different speaker types
		if speaker == null:
			# Null speaker = narration (no portrait, no name)
			name_label.text = ""
			portrait.visible = false
			player_portrait.visible = false
		elif speaker == "":
			# Empty speaker = also treat as narration
			name_label.text = ""
			portrait.visible = false
			player_portrait.visible = false
		elif speaker == "Player" or speaker == "Ezra" or speaker == "Ellen" or speaker == "Birras":
			# Player speaking
			name_label.text = speaker.capitalize()
			portrait.visible = false
			player_portrait.visible = true
		else:
			# NPC speaking
			name_label.text = speaker.capitalize()
			portrait.visible = true
			player_portrait.visible = false
	else:
		end_dialogue(true)
		
func _input(event):
	if not active:
		return

	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):

		if event is InputEventKey:
			var blocked_keys = [
				KEY_W, KEY_A, KEY_S, KEY_D,
				KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE
			]
			if event.physical_keycode in blocked_keys:
				return

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
