extends Resource

class_name	Inventory
signal inventory_changed
var max_size = 1
@export var current_items:  Array[Item] = []

func add_item(item):
	if current_items.size() >= max_size:
		remove_item()
	current_items.append(load(item))
	emit_signal("inventory_changed")
	
	
func remove_item():
	current_items.clear()
	emit_signal("inventory_changed")
	
func get_inventory():
	return current_items
	
func check_item(item_to_check):
	var current_item=current_items[0]
	if current_item.name == item_to_check.name:
		return true
	return false
