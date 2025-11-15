extends "res://scripts/player/player.gd"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var counter: Control = $GUI/Counter
@onready var memories: Array[Node] =  self.get_tree().get_nodes_in_group("Memories")
@export var max_value: int = 10


var is_ability_active: bool = false
var max_zoom: float= 6.0
var min_zoom: float= 1.0
var close_mem: Node= null


var ellen_sprites = {
	Direction.DOWN: preload("res://assets/character sprites/ezra/ezra_base.png"),
	Direction.UP: preload("res://assets/character sprites/ezra/ezra_back.png"),
	Direction.LEFT: preload("res://assets/character sprites/ezra/ezra_left.png"),
	Direction.RIGHT: preload("res://assets/character sprites/ezra/ezra_right.png")
}

func _ready():
	character_name = "Ezra"
	super._ready()

func _update_sprite_for_direction():
	if ellen_sprites.has(current_direction):
		sprite.texture = ellen_sprites[current_direction]

func increment_item_counter():
	print("added counter")
	memories.erase(close_mem)
	counter.add_point()
	
func _process(delta: float) -> void:
	print(memories)
	var min_distance=10000000
	var dis=0
	for mem in memories:
		dis=self.global_position.distance_to(mem.global_position)
		if dis<min_distance:
			min_distance=dis
			close_mem=mem

	get_zoom_from_distance(min_distance)
	
func get_zoom_from_distance(distance):
	var zoom=0
	var min_dist=10
	var max_dist=200
	
	if distance<10:
		zoom=6
	elif distance>200:
		zoom=1
	else:
		var t = clamp((distance - min_dist) / (max_dist - min_dist), 0.0, 1.0)
		zoom = lerp(max_zoom,min_zoom , t)
	

	print(zoom)
	print(distance)
	if cam.zoom.x -zoom >0.01 :
		cam.zoom.x-=0.01
		cam.zoom.y-=0.01
	elif cam.zoom.x-zoom<-0.01:
		cam.zoom.x+=0.01
		cam.zoom.y+=0.01
	else:
		cam.zoom.x =zoom
		cam.zoom.y=zoom

		
	

		
	
