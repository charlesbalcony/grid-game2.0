extends Resource
class_name AttackData

# Data structure for attacks
# This allows easy creation of different attack types with various properties

@export var name: String = "Basic Attack"
@export var damage: int = 25
@export var range: int = 1
@export var accuracy: float = 0.8
@export var description: String = "Standard attack"
@export var attack_type: AttackType = AttackType.MELEE
@export var area_of_effect: bool = false
@export var status_effects: Array[String] = []

enum AttackType {
	MELEE,      # Close range attack
	RANGED,     # Long range attack
	MAGIC,      # Magical attack with special properties
	HEAL,       # Healing ability
	BUFF,       # Stat boosting ability
	DEBUFF      # Stat reducing ability
}

func _init():
	pass

func get_effective_damage(attacker_power: int, target_defense: int = 0) -> int:
	"""Calculate the effective damage considering attacker power and target defense"""
	var base_damage = damage + attacker_power
	var reduced_damage = max(1, base_damage - target_defense)  # Minimum 1 damage
	
	# Apply accuracy (for now, just return full damage - could add randomization later)
	return reduced_damage

func is_valid_target(attacker_pos: Vector2, target_pos: Vector2) -> bool:
	"""Check if a target position is valid for this attack"""
	var distance = attacker_pos.distance_to(target_pos)
	return distance <= range

func get_attack_pattern(center_pos: Vector2) -> Array[Vector2]:
	"""Get all positions this attack can hit from a center position"""
	var positions: Array[Vector2] = []
	
	if area_of_effect:
		# For AoE attacks, include adjacent positions
		var directions = [
			Vector2(0, 0),   # Center
			Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),  # Cardinal
			Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)  # Diagonal
		]
		
		for direction in directions:
			positions.append(center_pos + direction)
	else:
		# Single target
		positions.append(center_pos)
	
	return positions

func get_display_text() -> String:
	"""Get formatted display text for UI"""
	return name + " (" + str(damage) + " dmg)"

func apply_status_effects(target_piece) -> void:
	"""Apply any status effects this attack causes"""
	# This could be expanded to handle various status effects
	# For now, just a placeholder
	if status_effects.size() > 0:
		print("Applying status effects: ", status_effects, " to ", target_piece.piece_type)