extends Node
class_name ArmyFactory

# ArmyFactory - Creates armies from JSON data instead of hardcoded classes
# This replaces the static army creation methods with data-driven approach

# Preload required classes
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const Army = preload("res://scripts/systems/Army.gd")

var data_loader: DataLoader
var army_definitions: Dictionary = {}
var army_abilities: Dictionary = {}
var scaling_rules: Dictionary = {}

func _init():
	data_loader = DataLoader.new()
	load_army_data()

func load_army_data():
	"""Load army definitions from JSON"""
	var data = data_loader.load_json_file("res://data/armies.json")
	
	if data.has("armies"):
		for army_data in data.armies:
			army_definitions[army_data.id] = army_data
	
	if data.has("army_abilities"):
		army_abilities = data.army_abilities
	
	if data.has("scaling_rules"):
		scaling_rules = data.scaling_rules
	
	print("ArmyFactory: Loaded ", army_definitions.size(), " army definitions")

func create_army_by_id(army_id: String) -> Army:
	"""Create an army by its ID"""
	if not army_definitions.has(army_id):
		print("ERROR: Unknown army ID: ", army_id)
		return create_default_army()
	
	var army_data = army_definitions[army_id]
	return create_army_from_data(army_data)

func create_army_by_level(level: int) -> Army:
	"""Create an army appropriate for the given level"""
	# Find army with matching level or closest lower level
	var best_army_data = null
	var best_level = 0
	
	for army_id in army_definitions.keys():
		var army_data = army_definitions[army_id]
		var army_level = army_data.get("level", 1)
		
		if army_level <= level and army_level > best_level:
			best_army_data = army_data
			best_level = army_level
	
	if best_army_data == null:
		print("No army found for level ", level, ", creating scaled army")
		return create_scaled_army(level)
	
	var army = create_army_from_data(best_army_data)
	
	# Apply level scaling if needed
	if level > best_level:
		apply_level_scaling(army, level - best_level)
	
	return army

func create_army_from_data(army_data: Dictionary) -> Army:
	"""Create an Army instance from JSON data"""
	var army = Army.new()
	
	army.army_name = army_data.get("name", "Unknown Army")
	army.level = army_data.get("level", 1)
	army.description = army_data.get("description", "")
	army.health_multiplier = army_data.get("health_multiplier", 1.0)
	army.damage_multiplier = army_data.get("damage_multiplier", 1.0)
	army.defense_bonus = army_data.get("defense_bonus", 0)
	
	# Set enemy composition
	if army_data.has("composition"):
		army.enemy_composition = army_data.composition.duplicate()
	
	# Set special abilities
	if army_data.has("special_abilities"):
		army.special_abilities = army_data.special_abilities.duplicate()
	
	return army

func create_scaled_army(level: int) -> Army:
	"""Create a scaled army for high levels"""
	# Start with the highest level army as base
	var base_army_data = null
	var max_level = 0
	
	for army_id in army_definitions.keys():
		var army_data = army_definitions[army_id]
		var army_level = army_data.get("level", 1)
		if army_level > max_level:
			base_army_data = army_data
			max_level = army_level
	
	if base_army_data == null:
		return create_default_army()
	
	var army = create_army_from_data(base_army_data)
	
	# Apply scaling for levels beyond the highest defined army
	var extra_levels = level - max_level
	apply_level_scaling(army, extra_levels)
	
	army.army_name = "Scaled " + army.army_name + " (Level " + str(level) + ")"
	army.level = level
	
	return army

func apply_level_scaling(army: Army, extra_levels: int):
	"""Apply scaling rules to make an army stronger"""
	if extra_levels <= 0:
		return
	
	var health_per_level = scaling_rules.get("health_per_level", 0.1)
	var damage_per_level = scaling_rules.get("damage_per_level", 0.08)
	var defense_per_level = scaling_rules.get("defense_per_level", 1)
	var max_multiplier = scaling_rules.get("max_level_multiplier", 3.0)
	
	# Apply health scaling
	var health_increase = health_per_level * extra_levels
	army.health_multiplier = min(max_multiplier, army.health_multiplier + health_increase)
	
	# Apply damage scaling
	var damage_increase = damage_per_level * extra_levels
	army.damage_multiplier = min(max_multiplier, army.damage_multiplier + damage_increase)
	
	# Apply defense scaling
	var defense_increase = defense_per_level * extra_levels
	army.defense_bonus += defense_increase
	
	print("Applied level scaling to army: +", extra_levels, " levels")
	print("New stats - Health: ", army.health_multiplier, " Damage: ", army.damage_multiplier, " Defense: +", army.defense_bonus)

func create_default_army() -> Army:
	"""Create a basic default army as fallback"""
	var army = Army.new()
	army.army_name = "Default Army"
	army.level = 1
	army.description = "Basic default army"
	army.health_multiplier = 1.0
	army.damage_multiplier = 1.0
	army.defense_bonus = 0
	army.enemy_composition = {"warrior": 15, "king": 1}
	army.special_abilities = []
	
	return army

func get_army_definition(army_id: String) -> Dictionary:
	"""Get the raw JSON data for an army"""
	return army_definitions.get(army_id, {})

func get_available_armies() -> Array:
	"""Get list of all available army IDs"""
	return army_definitions.keys()

func get_army_ability_definition(ability_id: String) -> Dictionary:
	"""Get the definition for an army ability"""
	return army_abilities.get(ability_id, {})

func get_army_formation_data(army_id: String) -> Dictionary:
	"""Get formation data for an army"""
	var army_data = army_definitions.get(army_id, {})
	return army_data.get("formation", {})

func create_custom_army(composition: Dictionary, level: int = 1, modifiers: Dictionary = {}) -> Army:
	"""Create a custom army with specified composition and modifiers"""
	var army = Army.new()
	
	army.army_name = modifiers.get("name", "Custom Army")
	army.level = level
	army.description = modifiers.get("description", "Custom army composition")
	army.health_multiplier = modifiers.get("health_multiplier", 1.0)
	army.damage_multiplier = modifiers.get("damage_multiplier", 1.0)
	army.defense_bonus = modifiers.get("defense_bonus", 0)
	army.enemy_composition = composition.duplicate()
	army.special_abilities = modifiers.get("special_abilities", [])
	
	return army

func reload_data():
	"""Reload army data from JSON - useful for development"""
	data_loader.clear_cache()
	army_definitions.clear()
	army_abilities.clear()
	scaling_rules.clear()
	load_army_data()
	print("ArmyFactory: Data reloaded")