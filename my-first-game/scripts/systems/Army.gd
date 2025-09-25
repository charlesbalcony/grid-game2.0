extends Resource
class_name Army

# Army defines the composition and difficulty of enemy forces for each level

@export var army_name: String = "Basic Army"
@export var level: int = 1
@export var description: String = "A basic enemy force"

# Army composition - what pieces to spawn and where
@export var enemy_composition: Dictionary = {}

# Army-wide stat modifiers
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var defense_bonus: int = 0

# Special army abilities or behaviors
@export var special_abilities: Array[String] = []

func _init():
	pass

# Define the default army layouts
static func create_basic_army():
	var army = new()
	army.army_name = "Militia"
	army.level = 1
	army.description = "A basic militia force with standard warriors"
	army.health_multiplier = 1.0
	army.damage_multiplier = 1.0
	army.defense_bonus = 0
	
	# Standard layout: mostly warriors, 1 king
	army.enemy_composition = {
		"warrior": 15,  # 15 warriors
		"king": 1       # 1 king
	}
	
	return army

static func create_veteran_army():
	var army = new()
	army.army_name = "Veterans"
	army.level = 2
	army.description = "Experienced soldiers with enhanced abilities"
	army.health_multiplier = 1.2
	army.damage_multiplier = 1.15
	army.defense_bonus = 2
	
	army.enemy_composition = {
		"warrior": 15,
		"king": 1
	}
	
	return army

static func create_elite_army():
	var army = new()
	army.army_name = "Elite Guard"
	army.level = 3
	army.description = "Elite warriors with superior training and equipment"
	army.health_multiplier = 1.4
	army.damage_multiplier = 1.3
	army.defense_bonus = 5
	
	army.enemy_composition = {
		"warrior": 15,
		"king": 1
	}
	
	return army

static func create_royal_army():
	var army = new()
	army.army_name = "Royal Army"
	army.level = 4
	army.description = "The king's personal army - formidable and dangerous"
	army.health_multiplier = 1.6
	army.damage_multiplier = 1.5
	army.defense_bonus = 8
	
	army.enemy_composition = {
		"warrior": 15,
		"king": 1
	}
	
	return army