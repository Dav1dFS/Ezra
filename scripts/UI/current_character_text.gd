extends Label

func _ready():
	_update_character_name()

func _process(_delta):
	if visible and text != Gamestate.character_name:
		_update_character_name()

func _update_character_name():
	if Gamestate.character_name != "":
		text = Gamestate.character_name
	else:
		text = "Character"
