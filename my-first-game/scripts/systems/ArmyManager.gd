extends Node
class_name ArmyManager

# Load Army type and ArmyFactory
const Army = preload("res://scripts/systems/Army.gd")
const ArmyFactory = preload("res://scripts/factories/ArmyFactory.gd")

# Manages the current army level and progression

signal army_changed(new_army: Army)
signal level_completed(army: Army)

var current_army: Army
var current_level: int = 1
var army_factory: ArmyFactory
# var available_armies: Array = []  # No longer needed with factory

func _init():
	army_factory = ArmyFactory.new()
	print("ArmyManager: Initialized ArmyFactory")
	set_current_army(1)

func set_current_army(level: int):
	"""Set the current army based on level"""
	current_level = level
	current_army = army_factory.create_army_by_level(level)
	army_changed.emit(current_army)
	print("Set army for level ", level, ": ", current_army.army_name)

func advance_to_next_army():
	"""Progress to the next army level"""
	level_completed.emit(current_army)
	set_current_army(current_level + 1)

func get_current_army() -> Army:
	return current_army

func get_current_level() -> int:
	return current_level

func reset_to_first_army():
	"""Reset progression back to the first army"""
	set_current_army(1)