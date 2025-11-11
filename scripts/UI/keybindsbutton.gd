extends Button

@onready var label_action = $MarginContainer/HBoxContainer/Label_Action
@onready var label_input = $MarginContainer/HBoxContainer/Label_Input

@export var action_name: String = "" # definir no inspector
var is_remapping := false

static var all_buttons: Array = []

const DEFAULT_KEYS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"ability": KEY_SPACE
}

func _ready():
	if not all_buttons.has(self):
		all_buttons.append(self)
	_update_label_text()

func _pressed():
	if is_remapping:
		return
	is_remapping = true
	label_input.text = "Press key to bind..."

func _input(event):
	if not is_remapping:
		return

	if event is InputEventKey or (event is InputEventMouseButton and event.pressed):
		if event is InputEventMouseButton and event.double_click:
			event.double_click = false

		var new_key = event.as_text().trim_suffix(" (Physical)")
		if _is_duplicate(new_key):
			label_input.text = "Already used!"
			await get_tree().create_timer(0.7).timeout
			_update_label_text()
			is_remapping = false
			return

		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)

		_update_label_text()
		is_remapping = false
		accept_event()

func _update_label_text():
	label_action.text = _get_action_display_name(action_name)

	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		label_input.text = events[0].as_text().trim_suffix(" (Physical)")
	else:
		label_input.text = "Unbound"

func _get_action_display_name(action: String) -> String:
	match action:
		"move_up": return "Move Forward"
		"move_down": return "Move Backward"
		"move_left": return "Move Left"
		"move_right": return "Move Right"
		"interact": return "Interact"
		"ability": return "Invisibility"
		_: return "Action"

func _is_duplicate(key_text: String) -> bool:
	for b in all_buttons:
		if b == self:
			continue
		var other_text = b.label_input.text
		if other_text == key_text:
			return true
	return false
	
static func reset_to_defaults():
	for action in DEFAULT_KEYS.keys():
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = DEFAULT_KEYS[action]
		InputMap.action_add_event(action, ev)

	for b in all_buttons:
		b._update_label_text()
