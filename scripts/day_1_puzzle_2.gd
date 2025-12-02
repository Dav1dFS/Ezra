extends Node2D



func _ready():
	$Player.changeObjective("Find Miss Ruth")
	$Checkpoint.body_entered.connect(checkpoint)
	$"Frieda NPC2".checkpoint.connect( on_checkpoint)
	
	
func checkpoint(body: Node2D):
	if body.name == "Player":
		Engine.time_scale = 0.3
		await get_tree().create_timer(1.0).timeout
		Engine.time_scale = 1.0

		get_tree().change_scene_to_file("res://scenes/gameplay/pitch.tscn")

func on_checkpoint():
	$"Frieda NPC".visible=false
	$Checkpoint/CollisionShape2D.disabled=false
	$Player.changeObjective("Go hide in the dorms")
