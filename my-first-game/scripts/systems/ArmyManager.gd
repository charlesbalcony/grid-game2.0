extends Node
class_name ArmyManager

# Load Army type
const Army = preload("res://scripts/systems/Army.gd")

# Manages the current army level and progression

signal army_changed(new_army: Army)
signal level_completed(army: Army)

var current_army: Army
var current_level: int = 1
var available_armies: Array = []

func _init():
	initialize_armies()
	set_current_army(1)

func initialize_armies():
	"""Initialize the available armies"""
	available_armies = [
		Army.create_basic_army(),
		Army.create_veteran_army(),
		Army.create_elite_army(),
		Army.create_royal_army()
	]

func set_current_army(level: int):
	"""Set the current army based on level"""
	current_level = level
	if level <= available_armies.size():
		current_army = available_armies[level - 1]
	else:
		# For levels beyond defined armies, scale the highest army
		current_army = create_scaled_army(level)
	
	print("Army set to level ", current_level, ": ", current_army.army_name)
	army_changed.emit(current_army)

func advance_to_next_army():
	"""Progress to the next army level"""
	level_completed.emit(current_army)
	set_current_army(current_level + 1)

func create_scaled_army(level: int) -> Army:
	"""Create a scaled version of the highest army for levels beyond the defined ones"""
	var base_army = available_armies[-1]  # Get the highest level army
	var scaled_army = Army.new()
	
	scaled_army.army_name = "Legendary Force " + str(level - available_armies.size())
	scaled_army.level = level
	scaled_army.description = "An impossibly powerful force that grows stronger with each encounter"
	
	# Scale stats exponentially for higher levels
	var scale_factor = 1.0 + (level - available_armies.size()) * 0.25
	scaled_army.health_multiplier = base_army.health_multiplier * scale_factor
	scaled_army.damage_multiplier = base_army.damage_multiplier * scale_factor
	scaled_army.defense_bonus = base_army.defense_bonus + (level - available_armies.size()) * 3
	
	scaled_army.enemy_composition = base_army.enemy_composition
	
	return scaled_army

func get_current_army() -> Army:
	return current_army

func get_current_level() -> int:
	return current_level

func reset_to_first_army():
	"""Reset progression back to the first army"""
	set_current_army(1)