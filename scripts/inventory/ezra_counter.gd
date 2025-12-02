extends Node

var current_objective: String = ""
var items_collected: int = 0
var total_items: int = 0

@onready var label: Label = $ObjectiveLabel
@onready var counter: Label = $CounterLabel
@onready var dialogue_box: CanvasLayer = get_tree().get_current_scene().get_node_or_null("DialogueBox")

var player_node: Node = null

func _ready():
	# Inicializa objetivo e contador
	update_label()
	await get_tree().process_frame

	player_node = get_tree().get_first_node_in_group("Player")
	if player_node and "max_value" in player_node:
		total_items = player_node.max_value

	update_counter()

# Atualiza o texto do objetivo
func updateObjective(text: String) -> void:
	current_objective = text
	update_label()

func update_label() -> void:
	label.text = str(current_objective)

# Atualiza o contador de itens recolhidos
func update_counter() -> void:
	counter.text = str(items_collected) + "/" + str(total_items)

# Chamado quando se recolhe um item
func add_point() -> void:
	items_collected += 1
	update_counter()

	if items_collected >= total_items:
		Gamestate.can_control_frieda = true
		Gamestate.npc_dialogues_completed["EzraCounter"] = items_collected
		_trigger_found_all_dialogue()

# Dispara o diálogo de "encontrei todos" quando recolhidos todos os itens
func _trigger_found_all_dialogue() -> void:
	if dialogue_box == null:
		push_warning("DialogueBox não encontrado na cena!")
		return

	var dialogue_data := {
		"lines": [
			{"speaker": "Player", "text": "Ahh — I found them all. I need to go back to Frieda."}
		]
	}

	# Inicia diálogo
	dialogue_box.start(dialogue_data, self)

	# Conecta signal com uma função separada para evitar CONNECT_ONE_SHOT em lambda
	if not dialogue_box.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_found_all_dialogue_ended)

# Handler do signal
func _on_found_all_dialogue_ended(npc_node: Node, fully_completed: bool) -> void:
	if npc_node != self:
		return
	print("Found all dialogue completed!")
	Gamestate.can_control_frieda = true

	# Remove a conexão para simular CONNECT_ONE_SHOT
	var dialogue_box_local = dialogue_box
	if dialogue_box_local != null and dialogue_box_local.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box_local.dialogue_ended.disconnect(_on_found_all_dialogue_ended)
