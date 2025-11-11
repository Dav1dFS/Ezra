extends Area2D

@export_group("Dialogue")
@export var dialogue_file_path: String = "res://DialoguesJSON/"
@export var triggers_player_dialogue: bool = false
@export var float_speed: float = 2.0  
@export var float_amplitude: float =6.0  

var start_position: Vector2
var player: Node = null

var dialogue_data : Dictionary
var dialogue_is_on: bool = false
var current_dialogue: int = 0
var waiting_for_player: bool = false

func _ready():
	start_position = global_position
	connect("body_entered", Callable(self, "_on_body_entered"))
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	if file:
		dialogue_data = JSON.parse_string(file.get_as_text())


func _process(delta):
	var time_ms=Time.get_ticks_msec()
	var time_s=time_ms/1000.0
	global_position.y = start_position.y + sin(time_s * float_speed) * float_amplitude

func _on_body_entered(body):
	if body.is_in_group("Player"): 
		player = body
		_collect_item()

func _collect_item():
	if player.has_method("increment_item_counter"):
		player.increment_item_counter()
		start_dialogue()
	else:
		print("Player missing 'increment_item_counter' method!")

	queue_free()


# Example of start_dialogue() from your snippet
func start_dialogue():
	var dialogue_is_on = true
	var dialogue_to_use = _choose_dialogue()
	
	if dialogue_to_use == null:
		dialogue_is_on = false
		return

	print(dialogue_to_use)
	for line in dialogue_to_use["lines"]:
		if "text" in line:
			line["text"] = line["text"].replace("{character_name}", Gamestate.character_name)

	var dialogue_box = get_tree().get_current_scene().get_node("DialogueBox")
	
	var portraitNpc = dialogue_data["portrait"]
	var portraitPlayer = dialogue_data["portraitPlayer"]
	dialogue_box.changeImages(portraitNpc, portraitPlayer)
	dialogue_box.start(dialogue_to_use, self)

func _choose_dialogue() -> Dictionary:
	if not dialogue_data.has("dialogues"):
		print("not found dialogue with conditions right")
		return {}

	for d in dialogue_data["dialogues"]:
		var condition = d.get("condition", "false")

		var expr = Expression.new()
		var parse_error = expr.parse(condition, ["current_dialogue", "Gamestate", "character_name"])
		if parse_error == OK:
			var result = expr.execute([current_dialogue, Gamestate, Gamestate.character_name])
			if result:
				return d
		else:
			push_warning("Erro a interpretar a condicao: %s" % condition)

	return {}

func _on_dialogue_ended(npc_node, fully_completed):
	if npc_node != self:
		return

	dialogue_is_on = false

	if fully_completed:
		var dialogue_to_use = _choose_dialogue()
		if dialogue_to_use.has("effect"):
			for effect in dialogue_to_use["effect"]:
				var action = effect.split("_")[0]
				var path = effect.split("_")[1]
				if action == "addItem":
					self.get_node("../Player").inv.add_item(path)
		Gamestate.npc_dialogues_completed[self.name] = true
		current_dialogue += 1
