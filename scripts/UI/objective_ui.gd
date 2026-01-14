extends Node

var current_objective: String = ""
var items_collected: int = 0
var total_items: int = 0
var show_counter: bool

var typewriter_speed := 0.03        
var _typewriter_playing := false 
@onready var label: Label = $ObjectiveLabel
@onready var counter: Label = $CounterLabel
@onready var item_display: TextureRect = $ItemDisplay
@onready var dialogue_box: CanvasLayer = get_tree().get_current_scene().get_node_or_null("DialogueBox")

var player_node: Node = null

func _ready():
	# Inicializa objetivo e contador
	# Traverse up: Objective -> GUI -> Player
	var gui = get_parent()
	if gui:
		player_node = gui.get_parent()

	if player_node:
		var counter_val = player_node.get("show_counter")
		if counter_val != null:
			show_counter = counter_val
	update_label()
	_apply_counter_visibility()
	await get_tree().process_frame
	total_items = get_tree().get_nodes_in_group("Memories").size()

	update_counter()
func _apply_counter_visibility():
	if counter:
		counter.visible = show_counter
	if item_display:
		item_display.visible = show_counter

func updateObjective(text: String):
	current_objective = text
	_typewriter_playing=true
	update_label()

func update_label():
	label.visible_ratio=0
	label.text = str(current_objective)
	while label.visible_ratio!=1 and _typewriter_playing:
		label.visible_ratio+=0.05
		await get_tree().create_timer(typewriter_speed).timeout
	_typewriter_playing = false

func update_counter():
	if show_counter and counter:
		counter.text = str(items_collected) + "/" + str(total_items)

func add_point():
	items_collected += 1
	update_counter()

	if items_collected >= total_items:
		var target_flag = ""
		if player_node:
			var flag_val = player_node.get("target_npc_gamestate_flag")
			if flag_val != null:
				target_flag = str(flag_val)

		# Ativa a flag configurada no Player
		if not target_flag.is_empty() and target_flag in Gamestate:
			Gamestate.set(target_flag, true)
		
		Gamestate.npc_dialogues_completed["EzraCounter"] = items_collected #problema provavelmente
		_trigger_found_all_dialogue()

func _trigger_found_all_dialogue():
	if dialogue_box == null:
		push_warning("DialogueBox não encontrado na cena!")
		return

	var dialogue_data := {
		"lines": [
			{"speaker": "Ezra", "text": "Now that i know more about her, i should go look for her...
		She has to be here somewhere."}
		]
	}

	dialogue_box.start(dialogue_data, self)

	# Conecta signal com uma função separada para evitar CONNECT_ONE_SHOT em lambda
	if not dialogue_box.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box.dialogue_ended.connect(_on_found_all_dialogue_ended)

func _on_found_all_dialogue_ended(npc_node: Node, _fully_completed):
	if npc_node != self:
		return

	# Remove a conexão para simular CONNECT_ONE_SHOT
	var dialogue_box_local = dialogue_box
	if dialogue_box_local != null and dialogue_box_local.dialogue_ended.is_connected(_on_found_all_dialogue_ended):
		dialogue_box_local.dialogue_ended.disconnect(_on_found_all_dialogue_ended)
