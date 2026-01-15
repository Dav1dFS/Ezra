extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var flashlight: Node2D = $Flashlight
@onready var flashlight_light: PointLight2D = $Flashlight/PointLight2D

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
	_setup_cone_light()
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

func _setup_cone_light():
	var cone_texture := _generate_cone_texture(128, 128, 30.0)
	flashlight_light.texture = cone_texture
	var max_distance := 75.0
	var scale_factor := max_distance / 64.0
	flashlight_light.texture_scale = scale_factor
	flashlight_light.offset = Vector2(0, max_distance / 2.0)
	flashlight_light.rotation = 0.0
	flashlight_light.position = Vector2.ZERO
	flashlight_light.scale = Vector2(1.0, 1.0)

func _generate_cone_texture(width: int, height: int, angle_deg: float) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var half_angle := deg_to_rad(angle_deg) / 2.0
	var center_x := width / 2.0
	var apex_y := 0.0

	for y in range(height):
		for x in range(width):
			var dx := x - center_x
			var dy := float(y) - apex_y

			var dist := sqrt(dx * dx + dy * dy)
			var max_dist := float(height)
			var dist_factor: float = clamp(dist / max_dist, 0.0, 1.0)

			var pixel_angle: float = abs(atan2(dx, dy))

			var edge_softness := 0.15
			var angular_factor := 1.0
			if pixel_angle > half_angle:
				angular_factor = 0.0
			elif pixel_angle > half_angle - edge_softness:
				angular_factor = 1.0 - (pixel_angle - (half_angle - edge_softness)) / edge_softness

			var radial_factor := 1.0 - _smoothstep(0.3, 1.0, dist_factor)
			var intensity := angular_factor * radial_factor
			var color := Color(1.0, 1.0, 1.0, intensity)
			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
