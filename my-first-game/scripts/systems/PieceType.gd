extends Resource
class_name PieceType

# Base class for different piece types
# This allows easy creation of different units like Warriors, Archers, Mages, etc.

@export var type_name: String = "Warrior"
@export var max_health: int = 100
@export var base_attack_power: int = 25
@export var base_defense: int = 5
@export var movement_range: int = 1
@export var movement_type: MovementType = MovementType.WALKING

enum MovementType {
	WALKING,    # Normal movement, blocked by other pieces
	FLYING,     # Can move over other pieces
	TELEPORT,   # Can move to any valid position within range
}

# Available attacks for this piece type
@export var available_attacks: Array[AttackData] = []

func _init():
	# Default warrior attacks
	if available_attacks.is_empty():
		available_attacks = [
			create_attack("Basic Attack", 25, 1, "Standard melee attack"),
			create_attack("Heavy Strike", 40, 1, "Powerful attack with high damage"),
			create_attack("Quick Jab", 15, 1, "Fast attack with low damage")
		]

func create_attack(attack_name: String, damage: int, range: int, description: String) -> AttackData:
	var attack = AttackData.new()
	attack.name = attack_name
	attack.damage = damage
	attack.range = range
	attack.description = description
	return attack

func get_display_name() -> String:
	return type_name

func get_movement_positions(from_pos: Vector2, board_size: int, occupied_positions: Dictionary) -> Array[Vector2]:
	"""Get all valid movement positions for this piece type"""
	var valid_positions: Array[Vector2] = []
	
	match movement_type:
		MovementType.WALKING:
			valid_positions = _get_walking_positions(from_pos, board_size, occupied_positions)
		MovementType.FLYING:
			valid_positions = _get_flying_positions(from_pos, board_size, occupied_positions)
		MovementType.TELEPORT:
			valid_positions = _get_teleport_positions(from_pos, board_size, occupied_positions)
	
	return valid_positions

func _get_walking_positions(from_pos: Vector2, board_size: int, occupied_positions: Dictionary) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	# Check all adjacent positions within movement range
	for dx in range(-movement_range, movement_range + 1):
		for dy in range(-movement_range, movement_range + 1):
			if dx == 0 and dy == 0:
				continue
				
			var new_pos = from_pos + Vector2(dx, dy)
			
			# Check bounds
			if new_pos.x < 0 or new_pos.x >= board_size or new_pos.y < 0 or new_pos.y >= board_size:
				continue
				
			# Check if position is occupied
			if not occupied_positions.has(new_pos):
				positions.append(new_pos)
	
	return positions

func _get_flying_positions(from_pos: Vector2, board_size: int, occupied_positions: Dictionary) -> Array[Vector2]:
	# Flying pieces can move over other pieces
	var positions: Array[Vector2] = []
	
	for dx in range(-movement_range, movement_range + 1):
		for dy in range(-movement_range, movement_range + 1):
			if dx == 0 and dy == 0:
				continue
				
			var new_pos = from_pos + Vector2(dx, dy)
			
			# Check bounds
			if new_pos.x < 0 or new_pos.x >= board_size or new_pos.y < 0 or new_pos.y >= board_size:
				continue
				
			# Flying pieces can land on empty spaces
			if not occupied_positions.has(new_pos):
				positions.append(new_pos)
	
	return positions

func _get_teleport_positions(from_pos: Vector2, board_size: int, occupied_positions: Dictionary) -> Array[Vector2]:
	# Teleport pieces can move to any empty position within range
	var positions: Array[Vector2] = []
	
	for x in range(board_size):
		for y in range(board_size):
			var new_pos = Vector2(x, y)
			
			if new_pos == from_pos:
				continue
				
			if from_pos.distance_to(new_pos) <= movement_range and not occupied_positions.has(new_pos):
				positions.append(new_pos)
	
	return positions