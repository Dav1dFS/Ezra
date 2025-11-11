extends Button

var _saved_icon: Texture2D

func _ready():
	_saved_icon = icon
	icon = null
	connect("mouse_entered", _on_hover_entered)
	connect("mouse_exited", _on_hover_exited)

func _on_hover_entered():
	icon = _saved_icon

func _on_hover_exited():
	icon = null
