class_name DialogueHandler
extends RefCounted

var dialogue_data: Dictionary = {}

func load_dialogue_file(path: String) -> bool:
	if path.is_empty():
		push_error("DialogueHandler: Dialogue file path is empty")
		print("err1")
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DialogueHandler: Failed to load dialogue file: " + path)
		print("err2")
		return false

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result == OK:
		dialogue_data = json.data
		return true
	else:
		push_error("DialogueHandler: Failed to parse JSON: %s" % json.get_error_message())
		print("err3")
		return false

func choose_dialogue(npc_name: String = "", custom_check: Callable = Callable(), expr_variables: Dictionary = {}) -> Dictionary:
	var dialogues = dialogue_data.get("dialogues", [])
	if dialogues.is_empty():
		print("err12")
		return {}

	var is_completed = Gamestate.npc_dialogues_completed.get(npc_name, false) if npc_name != "" else false

	if not expr_variables.is_empty():
		for dialogue in dialogues:
			var condition = dialogue.get("condition", "default")
			if condition == "default" or condition == "repetition":
				continue

			var expr = Expression.new()
			var parse_error = expr.parse(condition, expr_variables.keys())
			if parse_error == OK:
				var result = expr.execute(expr_variables.values())
				if typeof(result) == TYPE_BOOL and result:
					return dialogue

	if custom_check.is_valid():
		for dialogue in dialogues:
			var condition = dialogue.get("condition", "default")
			if condition != "default" and condition != "repetition":
				if custom_check.call(condition):
					return dialogue

	for dialogue in dialogues:
		var condition = dialogue.get("condition", "default")
		if condition == "default" and not is_completed:
			return dialogue
		elif condition == "repetition" and is_completed:
			print("err13")
			return dialogue

	return {}

func process_dialogue(dialogue: Dictionary) -> Dictionary:
	var processed = dialogue.duplicate(true)
	var lines = processed.get("lines", [])

	for i in range(lines.size()):
		var line = lines[i]
		if line.has("text"):
			line["text"] = line["text"].replace("{character_name}", Gamestate.character_name)
			lines[i] = line

	processed["lines"] = lines
	return processed

func mark_completed(npc_name: String):
	Gamestate.npc_dialogues_completed[npc_name] = true
