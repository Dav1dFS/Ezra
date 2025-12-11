extends Area2D

@export_group("Dialogue")
@export var dialogue_file_path: String = "res://dialogues/memories_night_1/night1_memories.json"
@export var level_id: String = "level1"
@export var triggers_player_dialogue: bool = false
@export var float_speed: float = 2.0
@export var float_amplitude: float = 6.0

var start_position: Vector2
var player: Node2D = null

var dialogue_data: Dictionary = {}
var dialogue_is_on: bool = false
var current_dialogue: int = 0

func _ready():
	start_position = global_position
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Procura o player na cena
	player = get_tree().get_current_scene().get_node_or_null("Player")
	if not player:
		push_warning("Player não encontrado! Partículas não irão funcionar.")

	# Carrega JSON de diálogos
	if dialogue_file_path == "":
		push_error("dialogue_file_path está vazio!")
		return

	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o ficheiro: %s" % dialogue_file_path)
		return

	var json = JSON.new()
	var parse_err = json.parse(file.get_as_text())
	file.close()
	if parse_err == OK:
		dialogue_data = json.data
	else:
		push_error("Falha a parsear JSON em %s: %s" % [dialogue_file_path, json.get_error_message()])

func _process(_delta: float) -> void:
	# Flutuação do item
	global_position.y = start_position.y + sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		_collect_item()

func _collect_item() -> void:
	# Notifica o player
	if player and player.has_method("increment_item_counter"):
		player.increment_item_counter()

	_increment_memories_count()
	start_dialogue()
	queue_free()

func _increment_memories_count() -> void:
	if not ("memories_collected" in Gamestate) or typeof(Gamestate.memories_collected) != TYPE_DICTIONARY:
		Gamestate.memories_collected = {}

	var current_count: int = 0
	if level_id in Gamestate.memories_collected:
		current_count = int(Gamestate.memories_collected[level_id])

	current_count += 1
	Gamestate.memories_collected[level_id] = current_count

func start_dialogue() -> void:
	dialogue_is_on = true
	var collected: int = 0
	if "memories_collected" in Gamestate and typeof(Gamestate.memories_collected) == TYPE_DICTIONARY and level_id in Gamestate.memories_collected:
		collected = int(Gamestate.memories_collected[level_id])
	var dialogue_to_use: Dictionary = _choose_dialogue_for_collected(collected)
	if dialogue_to_use == {}:
		dialogue_is_on = false
		return

	var lines_arr: Array = dialogue_to_use.get("lines", [])
	for i in range(lines_arr.size()):
		var line = lines_arr[i]
		if typeof(line) == TYPE_DICTIONARY and line.has("text"):
			line["text"] = str(line["text"]).replace("{character_name}", str(Gamestate.character_name))
			lines_arr[i] = line
	dialogue_to_use["lines"] = lines_arr

	var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
	if not dialogue_box:
		push_warning("DialogueBox não encontrado na cena.")
		dialogue_is_on = false
		return

	if not dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	dialogue_box.start(dialogue_to_use, self)

func _choose_dialogue_for_collected(collected: int) -> Dictionary:
	if dialogue_data == {} or not dialogue_data.has("dialogues"):
		return {}

	var dialogues: Array = dialogue_data.get("dialogues", [])
	for d in dialogues:
		var cond_text: String = str(d.get("condition", "default")).strip_edges()
		if cond_text == "" or cond_text == "default":
			continue
		var expr = Expression.new()
		var err = expr.parse(cond_text, ["collected", "Gamestate", "character_name"])
		if err != OK:
			push_warning("Erro a parsear condition '%s' : %s" % [cond_text, str(err)])
			continue
		var raw_result = expr.execute([collected, Gamestate, Gamestate.character_name])
		if bool(raw_result):
			return d
	for d in dialogues:
		var cond_text: String = str(d.get("condition", "default")).strip_edges()
		if cond_text == "default":
			return d
	return {}

func _on_dialogue_ended(npc_node: Node, fully_completed: bool = true) -> void:
	if npc_node != self:
		return
	dialogue_is_on = false
	if "npc_dialogues_completed" not in Gamestate:
		Gamestate.npc_dialogues_completed = {}
	if fully_completed:
		Gamestate.npc_dialogues_completed[self.name] = true
		current_dialogue += 1

		var dialogue_box = get_tree().get_current_scene().get_node_or_null("DialogueBox")
		if dialogue_box and dialogue_box.dialogue_ended.is_connected(_on_dialogue_ended):
			dialogue_box.dialogue_ended.disconnect(_on_dialogue_ended)
