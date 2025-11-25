extends Node2D

@export var npc_name: String = "NPC"
@export_file("*.json") var dialogue_file: String
@export_file("*.png") var npc_portrait: String
@export var player_portrait_ezra: String = "res://assets/character sprites/ezra/ezra_base.png"
@export var player_portrait_ellen: String = "res://assets/character sprites/ellen/ellen_base.png"
@export var triggers_player_dialogue: bool = false

# Node references
@onready var area = $PlayerInteractionArea
@onready var interact_label = $PlayerInteractionLabel

# State variables
var player_in_range: bool = false
var dialogue_data: Dictionary
var dialogue_is_on: bool = false
var current_dialogue_index: int = 0
var dialogue_completed: bool = false
var current_player: Node = null

func _ready():
	_load_dialogue_file()

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	_connect_to_dialogue_box()

	# if npc_name and not Gamestate.npc_dialogues_completed.has(npc_name):
	# 	Gamestate.npc_dialogues_completed[npc_name] = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialogue_is_on and not Gamestate.dialogue_locked:
			start_dialogue()

func _load_dialogue_file():
	if dialogue_file.is_empty():
		push_error("Dialogue file path is empty for NPC: " + npc_name)
		return

	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_text)

		if parse_result == OK:
			dialogue_data = json.data
		else:
			push_error("Failed to parse JSON for NPC %s: %s" % [npc_name, json.get_error_message()])
	else:
		push_error("Failed to load dialogue file: " + dialogue_file)

func _connect_to_dialogue_box():
	pass

func start_dialogue():
	var dialogue_to_use = _choose_dialogue()

	if dialogue_to_use.is_empty():
		print("No valid dialogue found for NPC: " + npc_name)
		return

	dialogue_is_on = true
	interact_label.visible = false
	Gamestate.dialogue_locked = true

	# Filter out mid_action lines
	var processed_dialogue = _process_dialogue(dialogue_to_use)

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_error("DialogueBox not found in scene!")
		dialogue_is_on = false
		interact_label.visible = true
		Gamestate.dialogue_locked = false
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	# Get player portrait safely
	var player_portrait = ""
	if current_player:
		var sprite = current_player.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			player_portrait = sprite.texture.resource_path

	# Use default if no portrait found
	if player_portrait == "":
		player_portrait = player_portrait_ezra  # Default to Ezra

	dialogue_box.changeImages(npc_portrait, player_portrait)
	dialogue_box.start(processed_dialogue, self)

func _choose_dialogue() -> Dictionary:
	var dialogues = dialogue_data.get("dialogues", [])

	var is_completed = Gamestate.npc_dialogues_completed.get(npc_name, false)

	for dialogue in dialogues:
		var condition = dialogue.get("condition", "default")

		if condition == "default" and not is_completed:
			return dialogue
		elif condition == "repetition" and is_completed:
			return dialogue
		elif condition != "default" and condition != "repetition":
			continue

	return {}


func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	dialogue_is_on = false
	Gamestate.dialogue_locked = false

	if player_in_range:
		interact_label.visible = true

	if fully_completed:
		Gamestate.npc_dialogues_completed[npc_name] = true
		dialogue_completed = true
		current_dialogue_index += 1

func _on_body_entered(body: Node):
	if body.name == "Player":
		player_in_range = true
		current_player = body
		if not dialogue_is_on:
			interact_label.visible = true

func _process_dialogue(dialogue: Dictionary) -> Dictionary:
	"""Filter out mid_action lines and process text replacements"""
	var processed = dialogue.duplicate(true)
	var filtered_lines = []

	for line in dialogue.get("lines", []):
		# Skip mid_action lines (for future cutscene implementation)
		if line.has("mid_action"):
			continue

		# Process regular dialogue lines
		if line.has("text"):
			var processed_line = line.duplicate()
			# Replace character name placeholder
			if "{character_name}" in processed_line["text"]:
				processed_line["text"] = processed_line["text"].replace("{character_name}", Gamestate.character_name)
			filtered_lines.append(processed_line)

	processed["lines"] = filtered_lines
	return processed

func _on_body_exited(body: Node):
	if body.name == "Player":
		player_in_range = false
		current_player = null
		interact_label.visible = false

		if dialogue_is_on:
			var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
			if dialogue_box and dialogue_box.active:
				dialogue_box.end_dialogue()
