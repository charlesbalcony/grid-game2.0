extends Node
class_name PieceFactory

# PieceFactory - Creates pieces from JSON data instead of hardcoded classes
# This replaces the individual piece type classes with data-driven approach

# Preload required classes
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const PieceType = preload("res://scripts/systems/PieceType.gd")
const AttackData = preload("res://scripts/systems/AttackData.gd")

var data_loader: DataLoader
var piece_definitions: Dictionary = {}
var movement_types: Dictionary = {}
var attack_types: Dictionary = {}

func _init():
	data_loader = DataLoader.new()
	load_piece_data()

func load_piece_data():
	"""Load piece definitions from JSON"""
	var data = data_loader.load_json_file("res://data/pieces.json")
	
	if data.has("pieces"):
		for piece_data in data.pieces:
			piece_definitions[piece_data.id] = piece_data
	
	if data.has("movement_types"):
		movement_types = data.movement_types
	
	if data.has("attack_types"):
		attack_types = data.attack_types
	
	print("PieceFactory: Loaded ", piece_definitions.size(), " piece definitions")

func create_piece_type(piece_id: String) -> PieceType:
	"""Create a PieceType instance from JSON data"""
	if not piece_definitions.has(piece_id):
		print("ERROR: Unknown piece type: ", piece_id)
		return create_default_piece_type()
	
	var piece_data = piece_definitions[piece_id]
	var piece_type = PieceType.new()
	
	# Set basic stats
	piece_type.type_name = piece_data.get("name", "Unknown")
	piece_type.max_health = piece_data.get("max_health", 100)
	piece_type.base_attack_power = piece_data.get("base_attack_power", 25)
	piece_type.base_defense = piece_data.get("base_defense", 5)
	piece_type.movement_range = piece_data.get("movement_range", 1)
	
	# Set movement type
	var movement_type_str = piece_data.get("movement_type", "walking")
	match movement_type_str:
		"walking":
			piece_type.movement_type = PieceType.MovementType.WALKING
		"flying":
			piece_type.movement_type = PieceType.MovementType.FLYING
		"teleport":
			piece_type.movement_type = PieceType.MovementType.TELEPORT
		_:
			piece_type.movement_type = PieceType.MovementType.WALKING
	
	# Create attacks from JSON data
	piece_type.available_attacks = []
	if piece_data.has("attacks"):
		for attack_data in piece_data.attacks:
			var attack = create_attack_from_data(attack_data)
			piece_type.available_attacks.append(attack)
	
	return piece_type

func create_attack_from_data(attack_data: Dictionary) -> AttackData:
	"""Create an AttackData instance from JSON data"""
	var attack = AttackData.new()
	
	attack.name = attack_data.get("name", "Unknown Attack")
	attack.damage = attack_data.get("damage", 25)
	attack.range = attack_data.get("range", 1)
	attack.accuracy = attack_data.get("accuracy", 0.8)
	attack.description = attack_data.get("description", "")
	attack.area_of_effect = attack_data.get("area_of_effect", false)
	
	# Set attack type
	var attack_type_str = attack_data.get("attack_type", "melee")
	match attack_type_str:
		"melee":
			attack.attack_type = AttackData.AttackType.MELEE
		"ranged":
			attack.attack_type = AttackData.AttackType.RANGED
		"magic":
			attack.attack_type = AttackData.AttackType.MAGIC
		"heal":
			attack.attack_type = AttackData.AttackType.HEAL
		_:
			attack.attack_type = AttackData.AttackType.MELEE
	
	return attack

func create_default_piece_type() -> PieceType:
	"""Create a default warrior piece type as fallback"""
	var piece_type = PieceType.new()
	piece_type.type_name = "Warrior"
	piece_type.max_health = 100
	piece_type.base_attack_power = 25
	piece_type.base_defense = 5
	piece_type.movement_range = 1
	piece_type.movement_type = PieceType.MovementType.WALKING
	
	# Add basic attack
	var basic_attack = AttackData.new()
	basic_attack.name = "Basic Attack"
	basic_attack.damage = 25
	basic_attack.range = 1
	basic_attack.accuracy = 0.8
	basic_attack.description = "Standard melee attack"
	basic_attack.attack_type = AttackData.AttackType.MELEE
	
	piece_type.available_attacks = [basic_attack]
	
	return piece_type

func get_piece_definition(piece_id: String) -> Dictionary:
	"""Get the raw JSON data for a piece type"""
	return piece_definitions.get(piece_id, {})

func get_available_piece_types() -> Array:
	"""Get list of all available piece type IDs"""
	return piece_definitions.keys()

func get_piece_icon(piece_id: String) -> String:
	"""Get the sprite icon for a piece type"""
	var piece_data = piece_definitions.get(piece_id, {})
	return piece_data.get("sprite_icon", "♗")

func get_piece_resistances(piece_id: String) -> Dictionary:
	"""Get damage resistances for a piece type"""
	var piece_data = piece_definitions.get(piece_id, {})
	return piece_data.get("resistances", {"melee": 0, "ranged": 0, "magic": 0})

func get_piece_passive_abilities(piece_id: String) -> Array:
	"""Get passive abilities for a piece type"""
	var piece_data = piece_definitions.get(piece_id, {})
	return piece_data.get("passive_abilities", [])

func reload_data():
	"""Reload piece data from JSON - useful for development"""
	data_loader.clear_cache()
	piece_definitions.clear()
	movement_types.clear()
	attack_types.clear()
	load_piece_data()
	print("PieceFactory: Data reloaded")