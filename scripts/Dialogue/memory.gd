extends Area2D

@export_group("Dialogue")
@export var dialogue_file_path: String = "res://dialogues/memories_night_1/night1_memories.json"
@export var level_id: String = "level1"
@export var float_speed: float = 2.0
@export var float_amplitude: float = 6.0

var start_position: Vector2
var player: Node2D = null

# Dialogue handler for shared logic
var dialogue_handler := DialogueHandler.new()

func _ready():
	start_position = global_position
	body_entered.connect(_on_body_entered)

	player = get_tree().get_current_scene().get_node_or_null("Player")
	if not player:
		push_warning("Player not found!")

	if dialogue_file_path != "":
		dialogue_handler.load_dialogue_file(dialogue_file_path)

func _process(_delta: float) -> void:
	# Floating animation
	global_position.y = start_position.y + sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		_collect_item()

func _collect_item() -> void:
	if player and player.has_method("increment_item_counter"):
		player.increment_item_counter()

	_increment_memories_count()
	start_dialogue()

func _increment_memories_count() -> void:
	if not ("memories_collected" in Gamestate) or typeof(Gamestate.memories_collected) != TYPE_DICTIONARY:
		Gamestate.memories_collected = {}

	var current_count: int = 0
	if level_id in Gamestate.memories_collected:
		current_count = int(Gamestate.memories_collected[level_id])

	current_count += 1
	Gamestate.memories_collected[level_id] = current_count

func start_dialogue() -> void:
	# Get collected count for this level
	var collected: int = 0
	if "memories_collected" in Gamestate and typeof(Gamestate.memories_collected) == TYPE_DICTIONARY:
		if level_id in Gamestate.memories_collected:
			collected = int(Gamestate.memories_collected[level_id])

	# Use expression-based dialogue selection with collected count
	var variables = {
		"collected": collected,
		"Gamestate": Gamestate,
		"character_name": Gamestate.character_name
	}
	var dialogue_to_use = dialogue_handler.choose_dialogue("", Callable(), variables)

	if dialogue_to_use.is_empty():
		return

	var processed_dialogue = dialogue_handler.process_dialogue(dialogue_to_use)

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_warning("DialogueBox not found in scene.")
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	dialogue_box.start(processed_dialogue, self)

func _on_dialogue_ended(npc_node: Node, fully_completed: bool = true) -> void:
	if npc_node != self:
		return

	# Disconnect signal
	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.disconnect(_on_dialogue_ended)

	if fully_completed:
		dialogue_handler.mark_completed(self.name)

	queue_free()
