extends Control

@onready var item_icon: TextureRect = $ItemDisplay
@onready var pocket_Up: TextureRect = $uiUp
@onready var pocket_Down: TextureRect = $uiDow

func update(item: Item):
	if !item:
		item_icon.visible=false
	else:
		item_icon.visible=true
		item_icon.texture = item.icon
		
func character(character_name: String):
	if character_name=="Ellen":
		pocket_Up.texture=load("res://assets/items_sprites/ellenUp.png")
		pocket_Down.texture=load("res://assets/items_sprites/ellenDown.png")
	else:
		pocket_Up.texture=load("res://assets/items_sprites/pocketUp.png")
		pocket_Down.texture=load("res://assets/items_sprites/pocketDown.png")
		
