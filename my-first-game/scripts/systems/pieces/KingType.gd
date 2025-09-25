extends PieceType
class_name KingType

# King piece type - powerful but crucial leader unit

func _init():
	type_name = "King"
	max_health = 120  # More health than warriors
	base_attack_power = 35  # Stronger attacks
	base_defense = 10  # Better defense
	movement_range = 1  # Same movement as warriors
	movement_type = MovementType.WALKING
	
	# King attacks - more powerful versions
	available_attacks = [
		create_royal_strike(),
		create_commanding_blow(),
		create_defensive_strike()
	]

func create_royal_strike() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Royal Strike"
	attack.damage = 35
	attack.range = 1
	attack.accuracy = 0.85
	attack.description = "Majestic attack with moderate damage"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack

func create_commanding_blow() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Commanding Blow"
	attack.damage = 45
	attack.range = 1
	attack.accuracy = 0.7
	attack.description = "Powerful royal attack"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack

func create_defensive_strike() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Defensive Strike"
	attack.damage = 25
	attack.range = 1
	attack.accuracy = 0.95
	attack.description = "Careful attack with high accuracy"
	attack.attack_type = AttackData.AttackType.MELEE
	return attack