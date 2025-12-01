extends Control

signal action_completed(success: bool)

@onready var slot1 = $SaveSlot1
@onready var slot2 = $SaveSlot2
@onready var slot3 = $SaveSlot3
@onready var slot4 = $SaveSlot4
@onready var slot5 = $SaveSlot5
@onready var slot6 = $SaveSlot6
@onready var middle_color = $"ColorRect2"
@onready var right_color = $"ColorRect3"

@onready var slots = [slot1, slot2, slot3, slot4, slot5, slot6]
@onready var nodes = [slot1, slot2, slot3, slot4, slot5, slot6, middle_color, right_color]

@onready var current_action_type: int = action_types.CREATE

enum action_types {
	CREATE,
	SAVE,
	LOAD
}

func _ready():
	for node in nodes:
		node.visible = false
		node.modulate.a = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node in [middle_color, right_color]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect slot signals
	for slot in slots:
		slot.slot_selected.connect(_on_slot_selected)

func open_saving_options(action: int = action_types.CREATE):
	visible = true
	current_action_type = action

	# Refresh all slot info before displaying
	for slot in slots:
		slot.refresh_slot_info()

	for node in nodes:
		fade_in(node)

func close_saving_options():
	for node in nodes:
		fade_out(node)
	await get_tree().create_timer(0.3).timeout
	visible = false

func fade_in(node: CanvasItem, duration := 0.3):
	node.visible = true
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 1.0, duration)

func fade_out(node: CanvasItem, duration := 0.3):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	if node is not ColorRect:
		tween.finished.connect(func(): node.visible = false)

func _on_slot_selected(slot_index: int):
	var success = false
	var action = current_action_type

	match action:
		action_types.CREATE:
			# Scene will change, don't call close_saving_options after
			SaveManager.create_new_game(slot_index)
			return
		action_types.SAVE:
			success = SaveManager.save_game(slot_index)
			if success:
				# Refresh slot info to show updated data
				for slot in slots:
					slot.refresh_slot_info()
		action_types.LOAD:
			# Scene will change, don't call close_saving_options after
			SaveManager.load_game(slot_index)
			return

	action_completed.emit(success)

	# Only close for SAVE action (CREATE and LOAD change scenes)
	if success:
		close_saving_options()
