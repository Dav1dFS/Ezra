extends Node2D

signal alert_started
signal alert_ended

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growl_area: Area2D = $Growl_Area
@onready var alert_area: Area2D = $Alert_Area

@export var guard_to_alert: NodePath
@export var facing_direction: int = 0  # 0=DOWN, 1=LEFT, 2=RIGHT

enum DogState { IDLE, GROWL, ALERT }
enum FacingDirection { DOWN, LEFT, RIGHT }

var state := DogState.IDLE
var player_in_alert := false
var player_in_growl := false

func _ready():
	growl_area.body_entered.connect(_on_growl_body_entered)
	growl_area.body_exited.connect(_on_growl_body_exited)
	alert_area.body_entered.connect(_on_alert_body_entered)
	alert_area.body_exited.connect(_on_alert_body_exited)
	
	# Conecta sinais ao guarda específico deste cão
	_connect_to_guard()
	
	_play_anim("idle")

func _connect_to_guard():
	if guard_to_alert.is_empty():
		return
	
	var guard = get_node_or_null(guard_to_alert)
	if guard and guard.has_method("on_dog_alert_started"):
		alert_started.connect(guard.on_dog_alert_started)
		alert_ended.connect(guard.on_dog_alert_ended)

func _play_anim(base_name: String):
	var dir: String
	if facing_direction == FacingDirection.DOWN:
		dir = "down"
	elif facing_direction == FacingDirection.LEFT:
		dir = "left"
	else:
		dir = "right"
	sprite.play("%s_%s" % [base_name, dir])

func _set_state(new_state: DogState):
	if state == new_state:
		return
	
	state = new_state
	
	match state:
		DogState.IDLE:
			_play_anim("idle")
			emit_signal("alert_ended")
			Gamestate.dog_is_alerted = false
		
		DogState.GROWL:
			_play_anim("growl")
		
		DogState.ALERT:
			_play_anim("alert")
			emit_signal("alert_started")
			Gamestate.dog_is_alerted = true

func _on_growl_body_entered(body):
	if body.name == "Player":
		player_in_growl = true
		if state != DogState.ALERT:
			_set_state(DogState.GROWL)

func _on_growl_body_exited(body):
	if body.name == "Player":
		player_in_growl = false
		if not player_in_alert:
			_set_state(DogState.IDLE)

func _on_alert_body_entered(body):
	if body.name == "Player":
		player_in_alert = true
		_set_state(DogState.ALERT)

func _on_alert_body_exited(body):
	if body.name == "Player":
		player_in_alert = false
		if player_in_growl:
			_set_state(DogState.GROWL)
		else:
			_set_state(DogState.IDLE)
