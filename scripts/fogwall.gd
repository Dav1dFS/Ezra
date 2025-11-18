extends Node2D

@export var message: String = "I shouldn't go this way yet."
@export var only_once: bool = false

@onready var area: Area2D = $Area2D

var _already_shown: bool = false
var _dialogue_box: Node = null


func _ready():
	area.body_entered.connect(_on_body_entered)

	_dialogue_box = get_tree().get_current_scene().get_node("DialogueBox")
	if _dialogue_box and not _dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_box.dialogue_ended.connect(_on_dialogue_ended)


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	if only_once and _already_shown:
		return

	_show_wall_dialogue(body)
	_already_shown = true


func _show_wall_dialogue(player: Node) -> void:
	if Gamestate.dialogue_locked:
		return
	if Gamestate.is_talking:
		return

	if _dialogue_box == null:
		push_warning("FogWall: DialogueBox não encontrado.")
		return

	var dialogue := {
		"id": "fog_wall_block",
		"lines": [
			{
				"text": message,
				"speaker": Gamestate.character_name
			}
		]
	}

	Gamestate.is_talking = true
	_dialogue_box.start(dialogue, self)


func _on_dialogue_ended(npc_node: Node, fully_completed: bool) -> void:
	# só reage se o diálogo que acabou foi o desta parede
	if npc_node != self:
		return

	Gamestate.is_talking = false
