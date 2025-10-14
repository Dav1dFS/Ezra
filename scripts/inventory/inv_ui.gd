extends Control

@onready var item_icon: TextureRect = $ItemDisplay


func update(item: Item):
	if !item:
		item_icon.visible=false
	else:
		item_icon.visible=true
		item_icon.texture = item.icon
		
		
