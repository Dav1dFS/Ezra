extends "res://scripts/main.gd"

@onready var memories = $Player/GUI/Objective/ItemDisplay
@onready var counter_label = $Player/GUI/Objective/CounterLabel

func _ready():
	Gamestate.npc_dialogues_completed["Frieda"]=false
	$Player.changeObjective("Collect all Memories")
	memories.visible = true
	counter_label.visible = true

func _process(_delta: float) -> void:
	if Gamestate.can_control_frieda:
		$Player.changeObjective("Find Frieda")
		memories.visible = false
		counter_label.visible = false
