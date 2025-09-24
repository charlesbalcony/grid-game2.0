extends PieceType
class_name ArcherType

# Archer piece type - ranged fighter with higher mobility

func _init():
	type_name = "Archer"
	max_health = 80
	base_attack_power = 20
	base_defense = 3
	movement_range = 2
	movement_type = MovementType.WALKING
	
	# Archer attacks
	available_attacks = [
		create_bow_shot(),
		create_power_shot(),
		create_quick_shot()
	]

func create_bow_shot() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Bow Shot"
	attack.damage = 25
	attack.range = 3
	attack.accuracy = 0.85
	attack.description = "Standard ranged attack"
	attack.attack_type = AttackData.AttackType.RANGED
	return attack

func create_power_shot() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Power Shot"
	attack.damage = 35
	attack.range = 4
	attack.accuracy = 0.7
	attack.description = "Powerful long-range shot"
	attack.attack_type = AttackData.AttackType.RANGED
	return attack

func create_quick_shot() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Quick Shot"
	attack.damage = 18
	attack.range = 2
	attack.accuracy = 0.9
	attack.description = "Fast, accurate shot"
	attack.attack_type = AttackData.AttackType.RANGED
	return attack