extends Control

signal slot_selected(slot_index: int)

@onready var button = $Button
@onready var character_label = $CharacterLabel
@onready var playtime_label = $PlaytimeLabel
@onready var date_label = $DateLabel

@export var save_slot_index: int = 0

var is_empty: bool = true

func _ready():
	button.pressed.connect(_on_button_pressed)
	refresh_slot_info()

func refresh_slot_info():
	var slot_info = SaveManager.get_slot_info(save_slot_index)
	is_empty = slot_info.get("empty", true)

	if is_empty:
		button.text = "Empty Slot"
		if character_label:
			character_label.text = ""
		if playtime_label:
			playtime_label.text = ""
		if date_label:
			date_label.text = ""
	else:
		button.text = "Slot " + str(save_slot_index)
		if character_label:
			character_label.text = slot_info.get("character_name", "Unknown")
		if playtime_label:
			var play_time = slot_info.get("play_time", 0.0)
			playtime_label.text = SaveManager.format_play_time(play_time)
		if date_label:
			var timestamp = slot_info.get("timestamp", 0)
			date_label.text = SaveManager.format_timestamp(timestamp)

func _on_button_pressed() -> void:
	slot_selected.emit(save_slot_index)
