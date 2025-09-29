extends Node
class_name ShopManager

# ShopManager - Handles shop functionality and item purchasing

signal item_purchased(item_id, cost)
signal shop_closed()

const DataLoader = preload("res://scripts/systems/DataLoader.gd")

var data_loader: DataLoader
var player_inventory: Array = []

func _init():
	data_loader = DataLoader.new()
	add_child(data_loader)

func _ready():
	print("ShopManager initialized")

func get_shop_items() -> Array:
	"""Get all items available for purchase, sorted by cost"""
	var items = data_loader.load_items()
	
	# Add costs based on rarity if not present
	for item in items:
		if not item.has("cost"):
			match item.get("rarity", "common"):
				"common":
					item["cost"] = 5
				"uncommon":
					item["cost"] = 10
				"rare":
					item["cost"] = 20
				"epic":
					item["cost"] = 35
				"legendary":
					item["cost"] = 50
				_:
					item["cost"] = 10
	
	# Sort by cost (ascending) and rarity
	items.sort_custom(func(a, b): 
		var cost_a = a.get("cost", 999)
		var cost_b = b.get("cost", 999)
		
		# First sort by rarity tier
		var rarity_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
		var rarity_a = rarity_order.get(a.get("rarity", "common"), 0)
		var rarity_b = rarity_order.get(b.get("rarity", "common"), 0)
		
		if rarity_a != rarity_b:
			return rarity_a < rarity_b
		else:
			return cost_a < cost_b
	)
	
	return items

func can_afford_item(item: Dictionary, current_glyphs: int) -> bool:
	"""Check if player can afford an item"""
	var cost = item.get("cost", 999)
	return current_glyphs >= cost

func purchase_item(item_id: String, current_glyphs: int) -> Dictionary:
	"""Attempt to purchase an item. Returns result with success status and remaining glyphs"""
	var item = data_loader.get_item_by_id(item_id)
	
	if item.is_empty():
		return {"success": false, "error": "Item not found", "remaining_glyphs": current_glyphs}
	
	var cost = item.get("cost", 999)
	
	if current_glyphs < cost:
		return {"success": false, "error": "Not enough glyphs", "remaining_glyphs": current_glyphs}
	
	# Add to inventory
	player_inventory.append(item)
	var remaining_glyphs = current_glyphs - cost
	
	print("Purchased: ", item.get("name", item_id), " for ", cost, " glyphs")
	item_purchased.emit(item_id, cost)
	
	return {"success": true, "item": item, "cost": cost, "remaining_glyphs": remaining_glyphs}

func get_inventory() -> Array:
	"""Get player's current inventory"""
	return player_inventory

func get_rarity_color(rarity: String) -> Color:
	"""Get color for item rarity"""
	match rarity:
		"common":
			return Color.WHITE
		"rare":
			return Color.BLUE
		"epic":
			return Color.PURPLE
		"legendary":
			return Color.GOLD
		_:
			return Color.GRAY