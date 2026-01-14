extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var frieda_npc: Node2D = $"FriedaNPC"
@onready var miss_ruth_npc: Node2D = $"MissRuthNPC"
@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var next_scene_npc: Node2D = $NextSceneNPC
@onready var cutscene: Node2D = $CutsceneController

func _ready():
	Gamestate.dog_is_alerted = false
	for npc in Gamestate.npc_dialogues_completed.keys():
		Gamestate.npc_dialogues_completed[npc]=false
	_set_npc_interactable(next_scene_npc, false)
	player.update_inventory(null)
	var music_index = AudioServer.get_bus_index("Music") 
	AudioServer.set_bus_mute(music_index, false)
	await cutscene.scene_fade_in()
	player.changeObjective("Find Miss Ruth")
	dialogue_box.mid_action_triggered.connect(_on_mid_action)



		
# TODO: Mover isto daqui para CutsceneManager.gd ou outro script mais apropriado
func _set_npc_interactable(npc: Node2D, enabled: bool):
	npc.visible = enabled
	npc.set_process(enabled)
	npc.set_physics_process(enabled)
	npc.deactivate_Collisions(enabled)
	for child in npc.get_children():
		if child is Area2D:
			child.monitoring = enabled
			child.monitorable = enabled


func _on_mid_action(action_name: String):
	match action_name:
		"checkpoint":
			on_checkpoint()
		"next_scene":
			_action_next_scene()
		"next_cut":
			_next_cut()

		
		_:
			push_warning("Unknown mid_action: " + action_name)
			dialogue_box.continue_after_action()
			
func _next_cut():
	cutscene.target_npc=$death

func on_checkpoint():
	_set_npc_interactable(frieda_npc, false)
	_set_npc_interactable(next_scene_npc, true)
	player.changeObjective("Go hide in the dorms")
	player.update_inventory(load("res://items/Cookie.tres"))
	
	dialogue_box.continue_after_action()

func _action_next_scene():
	await get_tree().create_timer(0.5).timeout
	Gamestate.dialogue_locked = false
	Gamestate.is_talking = false
	await cutscene.scene_fade_out("res://scenes/gameplay/level_1/night_1.tscn")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name=="Player":
		player.visible = false
		print("here cut")
		cutscene.runCutscene()
		player.visible = true
		cutscene.target_npc=$FriedaNPC
		$death.queue_free()
		$Guard1.queue_free()
		$Guard2.queue_free()
		
