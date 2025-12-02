extends CPUParticles2D

@export var speed: float = 200.0          
@export var fade_duration: float = 1.0     
@export var forced_life: float = 6.0      
var target: Node2D = null                  
var origin: Node2D = null                 
var fading: bool = false

var _spawn_ms: int = 0

func _ready() -> void:
	_spawn_ms = Time.get_ticks_msec()

func _process(delta: float) -> void:
	# Se já estivermos em fade, nada a fazer aqui
	if fading:
		return

	# Move em direção ao player se houver target
	if target:
		global_position = global_position.move_toward(target.global_position, speed * delta)

	# Inicia fade se chegarmos perto do player
	if target and global_position.distance_to(target.global_position) < 10:
		start_fadeout()
		return

	# Se origin foi definida e saiu da árvore, força fade
	if origin and not origin.is_inside_tree():
		start_fadeout()
		return

	# Força fade se passou demasiado tempo desde spawn
	var elapsed := float(Time.get_ticks_msec() - _spawn_ms) / 1000.0
	if elapsed >= forced_life:
		start_fadeout()
		return

func start_fadeout() -> void:
	if fading:
		return
	fading = true

	# Para de emitir novas partículas imediatamente
	emitting = false

	# Guarda alpha inicial (se 0, força 1)
	var initial_a := modulate.a
	if initial_a <= 0.0:
		initial_a = 1.0

	# Faz o fade ao longo de fade_duration
	var start_ms := Time.get_ticks_msec()
	while true:
		var elapsed := float(Time.get_ticks_msec() - start_ms) / 1000.0
		if elapsed >= fade_duration:
			break
		modulate.a = lerp(initial_a, 0.0, elapsed / fade_duration)
		# espera um frame
		await get_tree().process_frame

	# garante 0 e remove
	modulate.a = 0.0
	queue_free()
