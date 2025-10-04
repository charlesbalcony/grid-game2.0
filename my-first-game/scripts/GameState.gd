# GameState.gd
# Singleton to store game state data between scenes and manage saves

extends Node

# Save manager reference
var save_manager = null
var current_save_name: String = "default"

# Game over data (session only)
var game_over_winner: String = ""
var game_over_reason: String = "elimination"
var game_over_glyphs_recovered: int = 0
var game_over_army_info: String = ""

# Current session data (syncs with save file)
var current_glyphs: int = 0
var purchased_items: Array = []  # Array of item IDs purchased in current run (temporary)
var permanent_items: Array = []  # Array of permanent items owned (persists across runs)

func _ready():
	# Create save manager
	save_manager = preload("res://scripts/systems/SaveManager.gd").new()
	add_child(save_manager)
	print("GameState: SaveManager initialized")
	
	# Try to load default save or create new one
	if save_manager.save_exists("default"):
		load_save("default")
	else:
		create_new_save("default")

# Save management
func create_new_save(save_name: String) -> bool:
	if save_manager.create_new_save(save_name):
		current_save_name = save_name
		sync_from_save()
		print("GameState: Created new save: ", save_name)
		return true
	return false

func load_save(save_name: String) -> bool:
	if save_manager.load_game(save_name):
		current_save_name = save_name
		sync_from_save()
		print("GameState: Loaded save: ", save_name)
		return true
	return false

func save_current() -> bool:
	sync_to_save()
	return save_manager.save_game(current_save_name)

func sync_from_save():
	# Load data from save manager into current session
	current_glyphs = save_manager.get_glyphs()
	permanent_items = save_manager.get_permanent_items().duplicate()
	print("GameState: Synced from save - Glyphs: ", current_glyphs, " Permanent Items: ", permanent_items.size())

func sync_to_save():
	# Save current session data to save manager
	save_manager.set_glyphs(current_glyphs)
	# Permanent items are added individually via add_permanent_item
	print("GameState: Synced to save - Glyphs: ", current_glyphs)

func set_game_over_data(winner: String, reason: String = "elimination", glyphs_recovered: int = 0, army_info: String = ""):
	# Store game over data for the GameOver scene
	game_over_winner = winner
	game_over_reason = reason
	game_over_glyphs_recovered = glyphs_recovered
	game_over_army_info = army_info
	print("GameState: Stored game over data - Winner: ", winner)

func get_game_over_data() -> Dictionary:
	# Get game over data
	return {
		"winner": game_over_winner,
		"reason": game_over_reason,
		"glyphs_recovered": game_over_glyphs_recovered,
		"army_info": game_over_army_info
	}

func clear_game_over_data():
	# Clear game over data
	game_over_winner = ""
	game_over_reason = "elimination"
	game_over_glyphs_recovered = 0
	game_over_army_info = ""

func add_purchased_item(item_id: String):
	# Add an item to the purchased items list (current run only)
	if not purchased_items.has(item_id):
		purchased_items.append(item_id)
		print("GameState: Added purchased item: ", item_id)

func add_permanent_item(item_id: String):
	# Add a permanent item (persists across runs)
	if not permanent_items.has(item_id):
		permanent_items.append(item_id)
		save_manager.add_permanent_item(item_id)
		print("GameState: Added permanent item: ", item_id)

func get_purchased_items() -> Array:
	# Get all purchased items (current run)
	return purchased_items

func get_permanent_items() -> Array:
	# Get all permanent items
	return permanent_items

func clear_purchased_items():
	# Clear purchased items (for new run)
	purchased_items.clear()
	print("GameState: Cleared purchased items")

func start_new_run():
	# Reset run-specific data but keep permanent progression
	clear_game_over_data()
	purchased_items.clear()
	# Keep current_glyphs and permanent_items
	print("GameState: Started new run")

func reset_all():
	# Reset all game state (but don't delete save file)
	clear_game_over_data()
	current_glyphs = 0
	purchased_items.clear()
	print("GameState: Reset session data")