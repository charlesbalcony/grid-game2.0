extends PieceType
class_name MageType

# Mage piece type - magical attacks with special abilities

func _init():
	type_name = "Mage"
	max_health = 70
	base_attack_power = 30
	base_defense = 2
	movement_range = 1
	movement_type = MovementType.WALKING
	
	# Mage attacks
	available_attacks = [
		create_magic_missile(),
		create_fireball(),
		create_heal()
	]

func create_magic_missile() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Magic Missile"
	attack.damage = 20
	attack.range = 2
	attack.accuracy = 0.95
	attack.description = "Magical projectile that never misses"
	attack.attack_type = AttackData.AttackType.MAGIC
	return attack

func create_fireball() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Fireball"
	attack.damage = 30
	attack.range = 2
	attack.accuracy = 0.8
	attack.description = "Explosive magical attack"
	attack.attack_type = AttackData.AttackType.MAGIC
	attack.area_of_effect = true
	return attack

func create_heal() -> AttackData:
	var attack = AttackData.new()
	attack.name = "Heal"
	attack.damage = -25  # Negative damage = healing
	attack.range = 2
	attack.accuracy = 1.0
	attack.description = "Restore ally health"
	attack.attack_type = AttackData.AttackType.HEAL
	return attack