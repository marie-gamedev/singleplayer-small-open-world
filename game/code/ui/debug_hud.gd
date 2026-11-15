extends Control

@onready var inventory_contents_lbl = $PlayerInventory/InventoryContentsLbl

func _ready():
	Events.player_inventory_changed.connect(_update_player_inventory)
	_update_player_inventory()

func _update_player_inventory(item_id: String = "", amount: int = 0):
	var text = ""
	for item in PlayerInventory.items:
		text += item + " ," + str(PlayerInventory.items.get(item, 0)) + "\n"
	inventory_contents_lbl.text = text
