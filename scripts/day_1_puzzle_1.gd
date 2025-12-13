extends Node2D

@onready var cutscene: Node2D = $CutsceneController
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var player: CharacterBody2D = $Player

func _ready():
	await cutscene.scene_fade_in()
	player.changeObjective("Escape the dorms")
	dialogue_box.mid_action_triggered.connect(_on_mid_action)

func _on_mid_action(action_name: String):
	match action_name:
		"next_scene":
			_action_next_scene()
		_:
			push_warning("Unknown mid_action: " + action_name)
			dialogue_box.continue_after_action()

func _action_next_scene():
	await get_tree().create_timer(0.5).timeout
	Gamestate.dialogue_locked = false
	Gamestate.is_talking = false
	await cutscene.scene_fade_out("res://scenes/gameplay/level_1/day_1_puzzle_2.tscn")
