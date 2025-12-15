extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var flashlight: Node2D = $Flashlight

enum GuardState { SLEEP, WAKE, ALERT, ALERT_ENDING }
enum FacingDirection { DOWN, LEFT, RIGHT }

@export var facing_direction: FacingDirection = FacingDirection.DOWN
@export var alert_end_delay: float = 2.0  # Tempo que fica parado antes de dormir

var state: GuardState = GuardState.SLEEP
var is_alerting: bool = false
var alert_end_timer: float = 0.0
var should_end_alert: bool = false

# Rotações da lanterna baseadas nas frames das animações
var flashlight_rotations := {
	"alert_down": {
		0: 0.0,           # Frente (baixo)
		1: -PI/2,          # Vira para direta (90°)
		2: 0.0,           # Volta ao centro
		3: PI/2,         # Vira para esquerda (90°)
		4: 0.0            # Volta ao centro
	},
	"alert_left": {
		0: PI/2,         
		1: 0.0,       
		2: PI/2,        
		3: PI,   
		4: PI/2       
	},
	"alert_right": {
		0: -PI/2,        
		1: 0.0,       
		2: -PI/2,         
		3: -PI,        
		4: -PI/2          
	}
}

func _ready():
	_update_flashlight_initial()
	_play_sleep()

func _process(delta):
	# Atualiza rotação da lanterna durante animação de alerta
	if state == GuardState.ALERT:
		_update_flashlight_during_alert()
		
		if should_end_alert and sprite.frame == sprite.sprite_frames.get_frame_count(sprite.animation) - 1:
			_transition_to_alert_ending()
	
	elif state == GuardState.ALERT_ENDING:
		alert_end_timer -= delta
		if alert_end_timer <= 0:
			_play_sleep()

func _play_sleep():
	state = GuardState.SLEEP
	is_alerting = false
	should_end_alert = false
	sprite.animation = "sleep_%s" % _dir_to_string(facing_direction)
	sprite.play()
	flashlight.visible = false

func _play_wake():
	state = GuardState.WAKE
	sprite.animation = "wake_%s" % _dir_to_string(facing_direction)
	sprite.play()
	flashlight.visible = true
	_update_flashlight_initial()
	
	if not sprite.animation_finished.is_connected(_on_wake_finished):
		sprite.animation_finished.connect(_on_wake_finished)

func _on_wake_finished():
	if sprite.animation_finished.is_connected(_on_wake_finished):
		sprite.animation_finished.disconnect(_on_wake_finished)
	_play_alert()

func _play_alert():
	state = GuardState.ALERT
	is_alerting = true
	should_end_alert = false 
	sprite.animation = "alert_%s" % _dir_to_string(facing_direction)
	sprite.play()
	flashlight.visible = true

func _transition_to_alert_ending():
	state = GuardState.ALERT_ENDING
	is_alerting = false
	should_end_alert = false
	
	sprite.stop()
	sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1
	
	alert_end_timer = alert_end_delay

func _update_flashlight_initial():
	match facing_direction:
		FacingDirection.DOWN:
			flashlight.rotation = 0
		FacingDirection.LEFT:
			flashlight.rotation = PI / 2
		FacingDirection.RIGHT:
			flashlight.rotation = -PI / 2

func _update_flashlight_during_alert():
	var anim_name = sprite.animation
	var current_frame = sprite.frame
	
	if not anim_name in flashlight_rotations:
		return
	
	var frame_map = flashlight_rotations[anim_name]
	
	if current_frame in frame_map:
		flashlight.rotation = frame_map[current_frame]
		return
	
	var prev_frame = -1
	var next_frame = -1
	
	# Encontra frames anterior e posterior
	for frame_key in frame_map.keys():
		if frame_key < current_frame:
			if prev_frame == -1 or frame_key > prev_frame:
				prev_frame = frame_key
		elif frame_key > current_frame:
			if next_frame == -1 or frame_key < next_frame:
				next_frame = frame_key
	
	# Interpola entre frames
	if prev_frame != -1 and next_frame != -1:
		var t = float(current_frame - prev_frame) / float(next_frame - prev_frame)
		var prev_rot = frame_map[prev_frame]
		var next_rot = frame_map[next_frame]
		flashlight.rotation = lerp_angle(prev_rot, next_rot, t)
	elif prev_frame != -1:
		flashlight.rotation = frame_map[prev_frame]

func _dir_to_string(dir: FacingDirection) -> String:
	match dir:
		FacingDirection.DOWN: return "down"
		FacingDirection.LEFT: return "left"
		FacingDirection.RIGHT: return "right"
	return "down"

func on_dog_alert_started():
	should_end_alert = false
	
	if state == GuardState.SLEEP:
		_play_wake()
	elif state == GuardState.ALERT_ENDING:
		# Se estava a acabar o alerta mas o cão alertou de novo, volta ao alerta
		state = GuardState.ALERT
		is_alerting = true
		sprite.play() 

func on_dog_alert_ended():
	if state == GuardState.ALERT:
		should_end_alert = true
	elif state == GuardState.ALERT_ENDING:
		pass
