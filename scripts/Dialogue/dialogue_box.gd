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
	current_npc = npc
	visible = true
	active = true
	
	lines = dialogue.get("lines", [])
	current_line = 0
	_show_line()
	
func _show_line():
	if current_line < lines.size():
		var line_data = lines [current_line]
		var text = line_data.get("text", "")
		var speaker = line_data.get("speaker", "")
		
		text_label.text = text
		name_label.text = speaker.capitalize()
		
		if speaker == "Ezra":
			portrait.visible = false
			player_portrait.visible = true
		else:
			portrait.visible = true
			player_portrait.visible = false
	else:
		end_dialogue(true)
		
func _process(delta):
	if active and Input.is_action_just_pressed("interact"):
		_show_line()
		current_line += 1
	
func end_dialogue(fully_completed = false):
	visible = false
	active = false
	current_line = 0
	
	if current_npc:
		emit_signal("dialogue_ended", current_npc, fully_completed)
		current_npc = null
