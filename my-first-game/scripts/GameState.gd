# GameState.gd
# Singleton to store game state data between scenes

extends Node

# Game over data
var game_over_winner: String = ""
var game_over_reason: String = "elimination"
var game_over_glyphs_recovered: int = 0
var game_over_army_info: String = ""

# Shop/inventory data
var current_glyphs: int = 0
var purchased_items: Array = []  # Array of item IDs that have been purchased

func set_game_over_data(winner: String, reason: String = "elimination", glyphs_recovered: int = 0, army_info: String = ""):
	"""Store game over data for the GameOver scene"""
	game_over_winner = winner
	game_over_reason = reason
	game_over_glyphs_recovered = glyphs_recovered
	game_over_army_info = army_info
	print("GameState: Stored game over data - Winner: ", winner)

func get_game_over_data() -> Dictionary:
	"""Get game over data"""
	return {
		"winner": game_over_winner,
		"reason": game_over_reason,
		"glyphs_recovered": game_over_glyphs_recovered,
		"army_info": game_over_army_info
	}

func clear_game_over_data():
	"""Clear game over data"""
	game_over_winner = ""
	game_over_reason = "elimination"
	game_over_glyphs_recovered = 0
	game_over_army_info = ""

func add_purchased_item(item_id: String):
	"""Add an item to the purchased items list"""
	if not purchased_items.has(item_id):
		purchased_items.append(item_id)
		print("GameState: Added purchased item: ", item_id)

func get_purchased_items() -> Array:
	"""Get all purchased items"""
	return purchased_items

func clear_purchased_items():
	"""Clear purchased items (for new run)"""
	purchased_items.clear()
	print("GameState: Cleared purchased items")

func reset_all():
	"""Reset all game state"""
	clear_game_over_data()
	current_glyphs = 0
	purchased_items.clear()
	print("GameState: Reset all data")