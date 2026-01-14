extends Label

func _ready():
	_update_character_name()

func _process(_delta):
	if visible and text != Gamestate.character_name:
		_update_character_name()
	
func _update_character_name():
	if Gamestate.character_name != "":
		text = Gamestate.character_name
		if text == "Ezra":
			add_theme_color_override("font_color", Color("#00E594"))
		elif text == "Ellen":
			add_theme_color_override("font_color", Color("ffff4bff"))
	else:
		text = "Character"
