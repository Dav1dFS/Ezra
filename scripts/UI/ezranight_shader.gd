extends ColorRect

@export var vignette_material: ShaderMaterial  

@export var normal_darkness: float = 1.0 
@export var alert_darkness: float = 0.6       
@export var darkness_transition_speed: float = 3.0

@export var normal_speed: float = 1.0          
@export var alert_speed: float = 2.5       
@export var speed_transition_speed: float = 5.0

var current_darkness: float = 1.0
var current_speed: float = 1.0

func _ready():
	if not vignette_material:
		vignette_material = material as ShaderMaterial
	
	if vignette_material:
		vignette_material.set_shader_parameter("darkness_multiplier", normal_darkness)
		vignette_material.set_shader_parameter("speed_multiplier_extra", normal_speed)
		current_darkness = normal_darkness
		current_speed = normal_speed

func _process(delta):
	if not vignette_material:
		return
	
	var target_darkness = alert_darkness if Gamestate.dog_is_alerted else normal_darkness
	var target_speed = alert_speed if Gamestate.dog_is_alerted else normal_speed
	
	current_darkness = lerp(current_darkness, target_darkness, darkness_transition_speed * delta)
	vignette_material.set_shader_parameter("darkness_multiplier", current_darkness)
	
	current_speed = lerp(current_speed, target_speed, speed_transition_speed * delta)
	vignette_material.set_shader_parameter("speed_multiplier_extra", current_speed)
