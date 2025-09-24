extends PieceType
class_name WarriorType

# Warrior piece type - balanced melee fighter

func _init():
	type_name = "Warrior"
	max_health = 100
	base_attack_power = 25
	base_defense = 5
	movement_range = 1
	movement_type = MovementType.WALKING
	
	# Warrior attacks
	available_attacks = [
		create_basic_attack(),
		create_heavy_strike(),
		create_quick_jab()
	]

func create_basic_attack() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Basic Attack"
	attack.damage = 25
	attack.range = 1
	attack.accuracy = 0.8
	attack.description = "Standard melee attack"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack

func create_heavy_strike() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Heavy Strike"
	attack.damage = 40
	attack.range = 1
	attack.accuracy = 0.6
	attack.description = "Powerful attack with high damage"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack

func create_quick_jab() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Quick Jab"
	attack.damage = 15
	attack.range = 1
	attack.accuracy = 0.9
	attack.description = "Fast attack with low damage"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack