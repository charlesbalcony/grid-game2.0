# GameState.gd
# Singleton to store game state data between scenes and manage saves

extends Node

# Save manager reference
var save_manager = null
var current_save_name: String = ""

# Game over data (session only)
var game_over_winner: String = ""
var game_over_reason: String = "elimination"
var game_over_glyphs_recovered: int = 0
var game_over_army_info: String = ""

# Current session data (syncs with save file)
var current_glyphs: int = 0
var stuck_glyphs: int = 0  # Glyphs stuck at a level from defeat
var stuck_at_level: int = 0  # The level where glyphs are stuck
var purchased_items: Array = []  # Array of item IDs purchased in current run (temporary)
var permanent_items: Array = []  # Array of permanent items owned (persists across runs)
var current_level: int = 1  # Current level in this run (session only, always starts at 1 each run)
var piece_loadouts: Dictionary = {}  # Equipment assignments per piece (persists across levels in a run)

func _ready():
	# Create save manager
	save_manager = preload("res://scripts/systems/SaveManager.gd").new()
	add_child(save_manager)
	print("GameState: SaveManager initialized")
	
	# Don't auto-create or auto-load any save
	# Let the player choose from the main menu
	print("GameState: Ready - no save loaded. Use New Game or Load Game from menu.")

# Save management
func create_new_save(save_name: String) -> bool:
	if save_manager.create_new_save(save_name):
		current_save_name = save_name
		# Clear all session data before syncing from the new empty save
		current_glyphs = 0
		purchased_items.clear()
		permanent_items.clear()
		piece_loadouts.clear()
		current_level = 1
		# Now sync from the fresh save file
		sync_from_save()
		print("GameState: Created new save: ", save_name, " - all data cleared")
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
	stuck_glyphs = save_manager.get_stuck_glyphs()
	stuck_at_level = save_manager.get_stuck_at_level()
	permanent_items = save_manager.get_permanent_items().duplicate()
	
	# Load permanent equipment from save
	var saved_loadouts = save_manager.get_piece_loadouts()
	if saved_loadouts.size() > 0:
		# Restore permanent equipment, initialize empty run/level/use slots
		piece_loadouts.clear()
		for piece_id in saved_loadouts.keys():
			var saved_piece = saved_loadouts[piece_id]
			piece_loadouts[piece_id] = {
				"piece_type": saved_piece.get("piece_type", ""),
				"grid_position": saved_piece.get("grid_position", Vector2.ZERO),
				"permanent": saved_piece.get("permanent", []).duplicate(),
				"run": [],
				"level": [],
				"use": []
			}
		print("GameState: Loaded ", piece_loadouts.size(), " piece loadouts from save")
	
	print("GameState: Synced from save - Glyphs: ", current_glyphs, " Stuck: ", stuck_glyphs, " at Level ", stuck_at_level, " Permanent Items: ", permanent_items.size())

func sync_to_save():
	# Save current session data to save manager
	save_manager.set_glyphs(current_glyphs)
	save_manager.set_stuck_glyphs(stuck_glyphs)
	save_manager.set_stuck_at_level(stuck_at_level)
	save_manager.set_piece_loadouts(piece_loadouts)  # Save permanent equipment
	
	# Sync permanent items array to save
	save_manager.current_save_data["permanent_items"] = permanent_items.duplicate()
	
	print("GameState: Synced to save - Glyphs: ", current_glyphs, " Stuck: ", stuck_glyphs, " at Level ", stuck_at_level, " Permanent Items: ", permanent_items.size(), " Equipment pieces: ", piece_loadouts.size())

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
	# Allow duplicates so you can own multiple of the same item
	purchased_items.append(item_id)
	print("GameState: Added purchased item: ", item_id)

func add_permanent_item(item_id: String):
	# Add a permanent item (persists across runs)
	# Allow duplicates so you can own multiple of the same item
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
	current_level = 1
	
	# Clear only run-specific equipment, keep permanent items
	for piece_id in piece_loadouts.keys():
		if piece_loadouts[piece_id].has("run"):
			piece_loadouts[piece_id]["run"].clear()
		if piece_loadouts[piece_id].has("level"):
			piece_loadouts[piece_id]["level"].clear()
		if piece_loadouts[piece_id].has("use"):
			piece_loadouts[piece_id]["use"].clear()
		# Keep "permanent" slot intact
	
	# Keep current_glyphs and permanent_items
	print("GameState: Started new run (kept permanent equipment)")

func reset_all():
	# Reset all game state (but don't delete save file)
	clear_game_over_data()
	current_glyphs = 0
	purchased_items.clear()
	print("GameState: Reset session data")