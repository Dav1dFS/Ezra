extends Control

@onready var item_display: TextureRect = $ItemDisplay
@onready var pocket_Up: TextureRect = $uiUp
@onready var pocket_Down: TextureRect = $uiDow

func update(item: Item):
	item_display.visible = item != null
	if item:
		item_display.texture = item.icon
		
func update_pocket(character_name: String):
	if character_name=="Ellen":
		pocket_Up.texture=load("res://assets/items_sprites/ellenUp.png")
		pocket_Down.texture=load("res://assets/items_sprites/ellenDown.png")
	else:
		pocket_Up.texture=load("res://assets/items_sprites/pocketUp.png")
		pocket_Down.texture=load("res://assets/items_sprites/pocketDown.png")
		
