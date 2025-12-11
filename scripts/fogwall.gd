extends Node2D

@export var message: String = "I shouldn't go this way yet."
@export var only_once: bool = false
@export var pushback_distance: float = 50.0
@export var pushback_speed: float = 100.0

@onready var left_wall: Area2D = $LeftWall/Area2D
@onready var right_wall: Area2D = $RightWall/Area2D
@onready var top_wall: Area2D = $TopWall/Area2D
@onready var bottom_wall: Area2D = $DownWall/Area2D

@onready var dialogue_box: Node = get_tree().get_current_scene().get_node("DialogueBox")

var _already_shown: bool = false
var _is_pushing_back: bool = false
var _player_ref: Node = null
var _push_direction: Vector2 = Vector2.ZERO

func _ready():
	# Conecta cada parede ao mesmo handler mas com direção correspondente
	left_wall.body_entered.connect(func(body): _on_body_entered(body, Vector2.RIGHT))
	right_wall.body_entered.connect(func(body): _on_body_entered(body, Vector2.LEFT))
	top_wall.body_entered.connect(func(body): _on_body_entered(body, Vector2.DOWN))
	bottom_wall.body_entered.connect(func(body): _on_body_entered(body, Vector2.UP))

	if dialogue_box and not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)

func _on_body_entered(body: Node, push_direction: Vector2):
	if body.name != "Player":
		return
	if only_once and _already_shown:
		return

	_player_ref = body
	_push_direction = push_direction
	_show_dialogue()
	_already_shown = true

func _show_dialogue():
	if dialogue_box == null:
		push_warning("FogWall: DialogueBox não encontrado.")
		return
	var dialogue := {
		"id": "fog_wall_block",
		"lines": [{"text": message, "speaker": Gamestate.character_name}]
	}
	Gamestate.is_talking = true
	dialogue_box.start(dialogue, self)

func _on_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return

	Gamestate.is_talking = false

	if _player_ref:
		_push_player(_player_ref, _push_direction)
		_player_ref = null
		_push_direction = Vector2.ZERO

func _push_player(player: Node, direction: Vector2):
	if _is_pushing_back:
		return
	_is_pushing_back = true

	_update_player_direction(player, direction)

	var target_pos = player.global_position + direction.normalized() * pushback_distance

	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, pushback_distance / pushback_speed)
	tween.finished.connect(func(): _is_pushing_back = false)

func _update_player_direction(player_body: Node, direction: Vector2):
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
