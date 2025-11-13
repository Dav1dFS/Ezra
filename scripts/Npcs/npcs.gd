extends Node2D

@export_group("Dialogue")
@export var dialogue_file_path: String = "res://DialoguesJSON/"
@export var triggers_player_dialogue: bool = false
@onready var interact_label = $Label
@onready var area = $Area2D

var player_in_range: bool = false
var dialogue_data : Dictionary
var dialogue_is_on: bool = false
var current_dialogue: int = 0
var waiting_for_player: bool = false

func _ready():
	print(dialogue_file_path)
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if file:
		dialogue_data = JSON.parse_string(file.get_as_text())
		
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)
	
	var dialogue_box = get_tree().get_current_scene().get_node("DialogueBox")
	dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	
func on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		interact_label.visible = true
	
func on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		interact_label.visible = false
		
		var dialogue_box = get_tree().get_current_scene().get_node("DialogueBox")
		if dialogue_box.active:
			dialogue_box.end_dialogue()
		
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if !dialogue_is_on and not Gamestate.dialogue_locked:
			start_dialogue()
		
func start_dialogue():
	dialogue_is_on = true
	interact_label.visible = false
	var dialogue_to_use = _choose_dialogue()
	
	if dialogue_to_use == null:
		dialogue_is_on = false
		return
	print(dialogue_to_use)
	for line in dialogue_to_use["lines"]:
		if "text" in line:
			line["text"] = line["text"].replace("{character_name}", Gamestate.character_name)

	var dialogue_box = get_tree().get_current_scene().get_node("DialogueBox")
	
	var portraitNpc= dialogue_data["portrait"]
	var portraitPlayer= dialogue_data["portraitPlayer"]
	dialogue_box.changeImages(portraitNpc, portraitPlayer)
	dialogue_box.start(dialogue_to_use, self)
	


func _choose_dialogue() -> Dictionary:
	if not dialogue_data.has("dialogues"):
		print("not found dialogue with conditions right")
		return {}

	for d in dialogue_data["dialogues"]:
		var condition = d.get("condition", "false")

		var expr = Expression.new()
		var parse_error = expr.parse(condition, ["current_dialogue", "Gamestate", "character_name"])
		if parse_error == OK:
			var result = expr.execute([current_dialogue, Gamestate, Gamestate.character_name])
			if result:
				return d
		else:
			push_warning("Erro a interpretar a condicao: %s" % condition)

	return {}


func _on_dialogue_ended(npc_node, fully_completed):
	
	if npc_node != self:
		return

	dialogue_is_on = false
	interact_label.visible = true

	if fully_completed:
		var dialogue_to_use=_choose_dialogue()
		if dialogue_to_use.has("effect"):
			for effect in dialogue_to_use["effect"]:
				var action=effect.split("_")[0]
				var path= effect.split("_")[1]
				if action=="addItem":
					self.get_node("../Player").inv.add_item(path)
		Gamestate.npc_dialogues_completed[self.name] = true
		current_dialogue += 1
