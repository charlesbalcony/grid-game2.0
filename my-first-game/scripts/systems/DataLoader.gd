extends Node
class_name DataLoader

# DataLoader - Loads JSON configuration files for items, pieces, abilities, etc.

# Cache loaded data to avoid re-parsing
var cached_data = {}

func load_json_file(file_path: String) -> Dictionary:
	"""Load and parse a JSON file, return the data as Dictionary"""
	
	# Check cache first
	if cached_data.has(file_path):
		print("Loading ", file_path, " from cache")
		return cached_data[file_path]
	
	# Check if file exists
	if not FileAccess.file_exists(file_path):
		print("ERROR: JSON file not found: ", file_path)
		return {}
	
	# Open and read file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open JSON file: ", file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Failed to parse JSON file: ", file_path)
		print("Parse error: ", json.get_error_message())
		return {}
	
	var data = json.data
	
	# Cache the result
	cached_data[file_path] = data
	print("Successfully loaded JSON file: ", file_path)
	
	return data

func load_items() -> Array:
	"""Load item definitions from JSON"""
	var data = load_json_file("res://data/items.json")
	return data.get("items", [])

func load_pieces() -> Array:
	"""Load piece definitions from JSON"""
	var data = load_json_file("res://data/pieces.json")
	return data.get("pieces", [])

func load_armies() -> Array:
	"""Load army definitions from JSON"""
	var data = load_json_file("res://data/armies.json")
	return data.get("armies", [])

func get_item_by_id(item_id: String) -> Dictionary:
	"""Get a specific item by its ID"""
	var items = load_items()
	for item in items:
		if item.get("id", "") == item_id:
			return item
	return {}

func get_piece_by_id(piece_id: String) -> Dictionary:
	"""Get a specific piece by its ID"""
	var pieces = load_pieces()
	for piece in pieces:
		if piece.get("id", "") == piece_id:
			return piece
	return {}

func get_army_by_id(army_id: String) -> Dictionary:
	"""Get a specific army by its ID"""
	var armies = load_armies()
	for army in armies:
		if army.get("id", "") == army_id:
			return army
	return {}

func clear_cache():
	"""Clear the data cache - useful for development/testing"""
	cached_data.clear()
	print("DataLoader cache cleared")