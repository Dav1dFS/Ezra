extends Node2D

@export var npc_name: String = "NPC"
@export_file("*.json") var dialogue_file: String
@export var speaker_portraits: Dictionary[String, Texture2D] = {
	"Ezra": preload("res://assets/character_sprites/ezra/ezra_base.png"),
}
@export var override_base_sprite: Texture2D = null
@export var all_collected_gamestate_flag: String = ""

@onready var sprite = $Base
@onready var area = $PlayerInteractionArea
@onready var interact_label = $PlayerInteractionLabel

var player_in_range: bool = false
var dialogue_is_on: bool = false
var is_cutscene_dialogue: bool = false
var dialogue_handler := DialogueHandler.new()

func _ready():
	if override_base_sprite != null and sprite:
		sprite.texture = override_base_sprite
	if npc_name == "Frieda" or npc_name=="Ruth" or npc_name=="Ellen": ##change this, just hotfix
		$Base.visible=false
		$Base2.visible=true
		$Base2.play()
	if dialogue_file != "":
		dialogue_handler.load_dialogue_file(dialogue_file)
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func deactivate_Collisions(enabled: bool):
	$PlayerInteractionArea/CollisionShape2D.disabled=not enabled
	$Area2D/CollisionShape2D.disabled=not enabled

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialogue_is_on and not Gamestate.dialogue_locked:
		
			start_dialogue()

func start_dialogue_from_cutscene(_player_node: Node = null):
	if dialogue_file == "":
		return
	is_cutscene_dialogue = true

	start_dialogue()

func start_dialogue():
	var dialogue_to_use = _choose_dialogue()

	if dialogue_to_use.is_empty():
		push_warning("No valid dialogue found for NPC: " + npc_name)
		return

	dialogue_is_on = true
	if interact_label:
		interact_label.visible = false

	var processed_dialogue = dialogue_handler.process_dialogue(dialogue_to_use)

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_error("DialogueBox not found in scene!")
		dialogue_is_on = false
		if interact_label:
			interact_label.visible = true
		Gamestate.dialogue_locked = false
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

	dialogue_box.set_speaker_portraits(speaker_portraits)
	dialogue_box.start(processed_dialogue, self)

func _choose_dialogue() -> Dictionary:
	var custom_check = func(condition: String) -> bool:
		if condition == "all_collected":
			if not all_collected_gamestate_flag.is_empty() and all_collected_gamestate_flag in Gamestate:
				return Gamestate.get(all_collected_gamestate_flag) == true
		return false

	return dialogue_handler.choose_dialogue(npc_name, custom_check)

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.disconnect(_on_dialogue_ended)

	dialogue_is_on = false

	if player_in_range and not is_cutscene_dialogue and interact_label:
		interact_label.visible = true

	if fully_completed:
		var all_memories_collected = false
		if not all_collected_gamestate_flag.is_empty() and all_collected_gamestate_flag in Gamestate:
			all_memories_collected = Gamestate.get(all_collected_gamestate_flag) == true

		if not all_memories_collected:
			dialogue_handler.mark_completed(npc_name)

func _on_body_entered(body: Node):
	if body.name == "Player":
		player_in_range = true
		if not dialogue_is_on and interact_label:
			interact_label.visible = true

func _on_body_exited(body: Node):
	if body.name == "Player":
		player_in_range = false
		if interact_label:
			interact_label.visible = false

		if dialogue_is_on and not is_cutscene_dialogue:
			var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
			if dialogue_box and dialogue_box.active:
				dialogue_box.end_dialogue()
