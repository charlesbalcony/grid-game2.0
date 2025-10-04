# SaveManager.gd
# Handles saving and loading game data to/from disk

extends Node

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".json"

# Save data structure
var current_save_data = {
	"save_name": "default",
	"last_played": "",
	"total_playtime": 0.0,
	"glyphs": 0,
	"permanent_items": [],
	"piece_loadouts": {},  # Store permanent equipment (only permanent slot)
	"high_scores": {
		"classic": 0,
		"endless": 0
	}
}

func _ready():
	# Ensure save directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

# Save current game state to a file
func save_game(save_name: String = "default") -> bool:
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	
	# Update metadata
	current_save_data["save_name"] = save_name
	current_save_data["last_played"] = Time.get_datetime_string_from_system()
	
	# Convert to JSON
	var json_string = JSON.stringify(current_save_data, "\t")
	
	# Write to file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("SaveManager: Failed to open file for writing: ", save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("SaveManager: Game saved to ", save_path)
	return true

# Load game state from a file
func load_game(save_name: String = "default") -> bool:
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	
	# Check if file exists
	if not FileAccess.file_exists(save_path):
		print("SaveManager: Save file not found: ", save_path)
		return false
	
	# Read file
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("SaveManager: Failed to open file for reading: ", save_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("SaveManager: Failed to parse JSON from save file")
		return false
	
	current_save_data = json.data
	print("SaveManager: Game loaded from ", save_path)
	return true

# Get list of all save files
func get_save_list() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir == null:
		print("SaveManager: Could not open save directory")
		return saves
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var save_name = file_name.replace(SAVE_EXTENSION, "")
			saves.append(save_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return saves

# Get save file metadata without loading the full save
func get_save_info(save_name: String) -> Dictionary:
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var data = json.data
	return {
		"save_name": data.get("save_name", save_name),
		"last_played": data.get("last_played", "Unknown"),
		"glyphs": data.get("glyphs", 0),
		"permanent_items": data.get("permanent_items", []).size(),
		"high_score": max(data.get("high_scores", {}).get("classic", 0), 
						  data.get("high_scores", {}).get("endless", 0))
	}

# Delete a save file
func delete_save(save_name: String) -> bool:
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		print("SaveManager: Save file not found for deletion: ", save_path)
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return false
	
	var error = dir.remove(save_name + SAVE_EXTENSION)
	if error == OK:
		print("SaveManager: Deleted save file: ", save_name)
		return true
	else:
		print("SaveManager: Failed to delete save file: ", save_name)
		return false

# Check if a save exists
func save_exists(save_name: String) -> bool:
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	return FileAccess.file_exists(save_path)

# Create a new save with default data
func create_new_save(save_name: String) -> bool:
	current_save_data = {
		"save_name": save_name,
		"last_played": Time.get_datetime_string_from_system(),
		"total_playtime": 0.0,
		"glyphs": 0,
		"permanent_items": [],
		"piece_loadouts": {},
		"high_scores": {
			"classic": 0,
			"endless": 0
		}
	}
	return save_game(save_name)

# Getters and setters for save data
func get_glyphs() -> int:
	return current_save_data.get("glyphs", 0)

func set_glyphs(amount: int):
	current_save_data["glyphs"] = amount

func get_permanent_items() -> Array:
	return current_save_data.get("permanent_items", [])

func add_permanent_item(item_id: String):
	if not current_save_data["permanent_items"].has(item_id):
		current_save_data["permanent_items"].append(item_id)

func get_high_score(mode: String = "classic") -> int:
	return current_save_data.get("high_scores", {}).get(mode, 0)

func set_high_score(mode: String, score: int):
	if not current_save_data.has("high_scores"):
		current_save_data["high_scores"] = {}
	current_save_data["high_scores"][mode] = score

func get_piece_loadouts() -> Dictionary:
	return current_save_data.get("piece_loadouts", {})

func set_piece_loadouts(loadouts: Dictionary):
	# Only save permanent equipment to the save file
	var permanent_loadouts = {}
	for piece_id in loadouts.keys():
		var piece_data = loadouts[piece_id]
		if piece_data.has("permanent") and piece_data["permanent"].size() > 0:
			# Only store pieces that have permanent items equipped
			permanent_loadouts[piece_id] = {
				"piece_type": piece_data.get("piece_type", ""),
				"grid_position": piece_data.get("grid_position", Vector2.ZERO),
				"permanent": piece_data["permanent"].duplicate()
			}
	current_save_data["piece_loadouts"] = permanent_loadouts
