extends Node

# Item ID -> quantity
var items: Dictionary[String, int] = {}

func add_item(item_id: String, amount: int = 1):
	if item_id.is_empty() or amount <= 0:
		return
	
	items[item_id] = items.get(item_id, 0) + amount
	Events.player_inventory_changed.emit(item_id, items[item_id])

func has_item(item_id: String, amount: int = 1) -> bool:
	return items.get(item_id, 0) >= amount

func remove_item(item_id: String, amount: int = 1):
	if amount <= 0 or not has_item(item_id, amount):
		return
	
	items[item_id] -= amount
	
	if items[item_id] == 0:
		items.erase(item_id)
	
	Events.player_inventory_changed.emit(item_id, items.get(item_id, 0))
	return true
