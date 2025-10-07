extends Node

# LoadoutManager - Handles item loadouts and equipping for pieces

signal loadout_changed(piece_type: String, slot_type: String)
signal item_equipped(piece_type: String, item_id: String, slot_type: String)
signal item_unequipped(piece_type: String, item_id: String, slot_type: String)

const SAVE_FILE_PATH = "user://loadouts.save"

# Item slot types
enum SlotType {
	PERMANENT,  # Persist across all runs
	RUN,       # Last for entire run
	LEVEL,     # Last for current level only
	USE        # Consumable items that can be activated
}

# Loadout structure: 
# { 
#   "piece_instance_id": { 
#     "piece_type": "warrior",
#     "grid_position": Vector2(1, 2),
#     "permanent": ["warrior_ironclad_plate"], 
#     "run": ["warrior_berserker_helm"], 
#     "level": [], 
#     "use": ["warrior_warcry_horn"] 
#   }
# }
var piece_loadouts = {}

# Available items from inventory (what player has purchased)
var available_items = []

func _init():
	# Initialize empty loadouts for known piece types
	initialize_piece_loadouts()

func _ready():
	print("LoadoutManager initialized")
	load_loadouts()

func initialize_piece_loadouts():
	"""Initialize will now be called when pieces are created on the board"""
	pass  # Loadouts are now created per instance, not per type

func set_available_items(items: Array):
	"""Set the items available from the player's inventory"""
	available_items = items.duplicate()

func add_available_item(item_id: String):
	"""Add an item to the available inventory - allows duplicates"""
	available_items.append(item_id)

func get_available_items() -> Array:
	"""Get all items available for loadout"""
	return available_items.duplicate()

func get_available_items_for_piece(piece_type: String, data_loader) -> Array:
	"""Get items available for a specific piece type and filter by what's owned"""
	var filtered_items = []
	
	for item_id in available_items:
		var item_data = data_loader.get_item_by_id(item_id)
		if item_data and item_data.get("piece", "").to_lower() == piece_type.to_lower():
			filtered_items.append(item_data)
	
	return filtered_items

func register_piece_instance(instance_id: String, piece_type: String, grid_pos: Vector2):
	"""Register a new piece instance for loadout tracking"""
	if not piece_loadouts.has(instance_id):
		piece_loadouts[instance_id] = {
			"piece_type": piece_type,
			"grid_position": grid_pos,
			"permanent": [],
			"run": [],
			"level": [],
			"use": []
		}
		print("Registered piece instance: ", instance_id, " (", piece_type, ") at ", grid_pos)

func equip_item(instance_id: String, item_id: String, slot_type: String) -> bool:
	"""Equip an item to a specific piece instance and slot"""
	print("DEBUG LoadoutManager: Attempting to equip ", item_id, " to instance ", instance_id, " in slot ", slot_type)
	
	if not piece_loadouts.has(instance_id):
		print("Error: Unknown piece instance: ", instance_id)
		print("DEBUG: Available instances: ", piece_loadouts.keys())
		return false
	
	if not available_items.has(item_id):
		print("Error: Item not available in loadout inventory: ", item_id)
		print("DEBUG: Available items: ", available_items)
		return false
	
	var loadout = piece_loadouts[instance_id]
	if not loadout.has(slot_type):
		print("Error: Unknown slot type: ", slot_type)
		return false
	
	# Remove item from available pool (it's being assigned to a specific piece)
	available_items.erase(item_id)
	
	# For permanent, run, and level slots, only allow one item
	if slot_type in ["permanent", "run", "level"]:
		if loadout[slot_type].size() > 0:
			# Unequip existing item (return to available pool)
			var old_item = loadout[slot_type][0]
			loadout[slot_type].clear()
			available_items.append(old_item)
			item_unequipped.emit(loadout.piece_type, old_item, slot_type)
		loadout[slot_type].append(item_id)
	else:
		# Use items can stack
		if not loadout[slot_type].has(item_id):
			loadout[slot_type].append(item_id)
	
	print("SUCCESS LoadoutManager: Equipped ", item_id, " to ", instance_id, " in ", slot_type)
	item_equipped.emit(loadout.piece_type, item_id, slot_type)
	loadout_changed.emit(loadout.piece_type, slot_type)
	save_loadouts()
	return true

func unequip_item(instance_id: String, item_id: String, slot_type: String) -> bool:
	"""Unequip an item from a specific piece instance and slot"""
	if not piece_loadouts.has(instance_id):
		return false
	
	var loadout = piece_loadouts[instance_id]
	if not loadout.has(slot_type):
		return false
	
	if loadout[slot_type].has(item_id):
		loadout[slot_type].erase(item_id)
		# Return item to available pool
		available_items.append(item_id)
		item_unequipped.emit(loadout.piece_type, item_id, slot_type)
		loadout_changed.emit(loadout.piece_type, slot_type)
		save_loadouts()
		return true
	
	return false

func get_equipped_items(instance_id: String, slot_type: String = "") -> Array:
	"""Get equipped items for a piece instance, optionally filtered by slot type"""
	if not piece_loadouts.has(instance_id):
		return []
	
	var loadout = piece_loadouts[instance_id]
	
	if slot_type != "":
		return loadout.get(slot_type, []).duplicate()
	else:
		# Return all equipped items for this piece
		var all_items = []
		for slot_key in ["permanent", "run", "level", "use"]:
			if loadout.has(slot_key):
				all_items.append_array(loadout[slot_key])
		return all_items

func get_piece_loadout(instance_id: String) -> Dictionary:
	"""Get the complete loadout for a piece instance"""
	return piece_loadouts.get(instance_id, {}).duplicate()

func get_all_instances_of_type(piece_type: String) -> Array:
	"""Get all instance IDs for pieces of a specific type"""
	var instances = []
	for instance_id in piece_loadouts.keys():
		var loadout = piece_loadouts[instance_id]
		if loadout.get("piece_type", "") == piece_type:
			instances.append(instance_id)
	return instances

func clear_level_items():
	"""Clear all level-specific items (called at end of level)"""
	for instance_id in piece_loadouts.keys():
		piece_loadouts[instance_id]["level"].clear()
	
	save_loadouts()
	print("Cleared all level-specific items")

func clear_run_items():
	"""Clear all run-specific items (called at end of run)"""
	for instance_id in piece_loadouts.keys():
		piece_loadouts[instance_id]["run"].clear()
		piece_loadouts[instance_id]["level"].clear()
		piece_loadouts[instance_id]["use"].clear()
	
	save_loadouts()
	print("Cleared all run-specific items")

func use_item(instance_id: String, item_id: String) -> bool:
	"""Consume a use item (remove from loadout)"""
	if not piece_loadouts.has(instance_id):
		return false
	
	var loadout = piece_loadouts[instance_id]
	var use_items = loadout["use"]
	if use_items.has(item_id):
		use_items.erase(item_id)
		print("Used item: ", item_id, " for instance ", instance_id, " (", loadout.piece_type, ")")
		save_loadouts()
		return true
	
	return false

func save_loadouts():
	"""Save loadouts to file"""
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {
			"loadouts": piece_loadouts,
			"available_items": available_items
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_loadouts():
	"""Load loadouts from file"""
	print("=== LOADING LOADOUTS FROM DISK ===")
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var save_data = json.data
				
				if save_data.has("loadouts"):
					var loaded_loadouts = save_data["loadouts"]
					piece_loadouts = {}
					
					# Migrate old random IDs to new deterministic IDs
					print("Migrating loadout IDs...")
					for old_piece_id in loaded_loadouts.keys():
						var loadout_data = loaded_loadouts[old_piece_id]
						var piece_type = loadout_data.get("piece_type", "")
						var grid_pos = loadout_data.get("grid_position", Vector2.ZERO)
						
						# Check if this is an old random ID (contains a decimal point)
						if "." in old_piece_id:
							# Extract team from old ID
							var team = "player" if old_piece_id.begins_with("player_") else "enemy"
							# Create new deterministic ID
							var new_piece_id = team + "_" + piece_type + "_" + str(grid_pos.x) + "_" + str(grid_pos.y)
							print("  Migrating: ", old_piece_id, " -> ", new_piece_id)
							piece_loadouts[new_piece_id] = loadout_data
						else:
							# Already has new format
							piece_loadouts[old_piece_id] = loadout_data
					
					print("Loaded piece loadouts: ", piece_loadouts.keys().size(), " pieces")
					for piece_id in piece_loadouts.keys():
						var loadout = piece_loadouts[piece_id]
						var permanent_items = loadout.get("permanent", [])
						if permanent_items.size() > 0:
							print("  - ", piece_id, " (", loadout.get("piece_type", "unknown"), "): ", permanent_items.size(), " permanent items: ", permanent_items)
				
				if save_data.has("available_items"):
					available_items = save_data["available_items"]
					print("Loaded available items: ", available_items)
				
				print("Loadouts loaded successfully")
				
				# Save the migrated data
				save_loadouts()
			else:
				print("Error parsing loadout save file")
	else:
		print("No loadout save file found - starting fresh")
	print("=== LOADOUT LOADING COMPLETE ===")

func get_item_effects_for_piece(instance_id: String, data_loader) -> Dictionary:
	"""Get all active item effects for a piece instance (for applying to stats)"""
	var effects = {
		"permanent": [],
		"run": [],
		"level": [],
		"use": []
	}
	
	if not piece_loadouts.has(instance_id):
		return effects
	
	var loadout = piece_loadouts[instance_id]
	
	for slot_type in effects.keys():
		for item_id in loadout.get(slot_type, []):
			var item_data = data_loader.get_item_by_id(item_id)
			if item_data:
				effects[slot_type].append(item_data)
	
	return effects