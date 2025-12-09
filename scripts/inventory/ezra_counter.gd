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

func updateObjective(text: String):
	current_objective = text
	update_label()

func update_label():
	label.text = str(current_objective)

func update_counter():
	counter.text = str(items_collected) + "/" + str(total_items)

func add_point():
	items_collected += 1
	update_counter()

	if items_collected >= total_items:
		var target_flag = ""
		if player_node and "target_npc_gamestate_flag" in player_node:
			target_flag = player_node.target_npc_gamestate_flag
		
		# Ativa a flag configurada no Player
		if not target_flag.is_empty() and target_flag in Gamestate:
			Gamestate.set(target_flag, true)
			print("Activated flag: ", target_flag)
		
		Gamestate.npc_dialogues_completed["EzraCounter"] = items_collected
		_trigger_found_all_dialogue()

func _trigger_found_all_dialogue():
	if dialogue_box == null:
		push_warning("DialogueBox não encontrado na cena!")
		return

	var dialogue_data := {
		"lines": [
			{"speaker": "Player", "text": "Ahh — I found them all. I need to go back to Frieda."}
		]
	}

	dialogue_box.start(dialogue_data, self)

	# Conecta signal com uma função separada para evitar CONNECT_ONE_SHOT em lambda
	if not dialogue_box.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_found_all_dialogue_ended)

func _on_found_all_dialogue_ended(npc_node: Node, fully_completed: bool):
	if npc_node != self:
		return
	print("Found all dialogue completed!")

	# Remove a conexão para simular CONNECT_ONE_SHOT
	var dialogue_box_local = dialogue_box
	if dialogue_box_local != null and dialogue_box_local.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box_local.dialogue_ended.disconnect(_on_found_all_dialogue_ended)
