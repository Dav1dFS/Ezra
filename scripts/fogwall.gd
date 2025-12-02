extends Node2D

@export var message: String = "I shouldn't go this way yet."
@export var only_once: bool = false
@export var player: CharacterBody2D
@export var pushback_distance: float = 50.0
@export var pushback_speed: float = 100.0

@onready var area: Area2D = $Area2D

var _already_shown: bool = false
var _dialogue_box: Node = null
var is_pushing_back: bool = false
var player_ref: Node = null


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

	player_ref = body
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

func _push_player_back(body: Node) -> void:
	if is_pushing_back:
		return
	
	is_pushing_back = true
	
	var opposite_direction = -body.last_movement_direction.normalized()
	
	_update_player_direction(body, opposite_direction)
	
	var start_pos = body.global_position
	var target_pos = start_pos + (opposite_direction * pushback_distance)
	
	var tween = create_tween()
	tween.tween_property(body, "global_position", target_pos, pushback_distance / pushback_speed)
	tween.finished.connect(func(): is_pushing_back = false)

func _update_player_direction(player_body: Node, direction: Vector2) -> void:
	# Atualiza a direção do sprite
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			player_body.current_direction = player_body.Direction.RIGHT
		else:
			player_body.current_direction = player_body.Direction.LEFT
	else:
		if direction.y < 0:
			player_body.current_direction = player_body.Direction.UP
		else:
			player_body.current_direction = player_body.Direction.DOWN
	
	player_body._update_sprite_for_direction()

func _on_dialogue_ended(npc_node: Node, fully_completed: bool) -> void:
	if npc_node != self:
		return
	
	Gamestate.is_talking = false
	
	if player_ref:
		_push_player_back(player_ref)
		player_ref = null
