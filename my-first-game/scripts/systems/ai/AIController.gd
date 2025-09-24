extends Node
class_name AIController

# Base AI controller class for different AI difficulty levels and behaviors

@export var ai_name: String = "Basic AI"
@export var difficulty_level: DifficultyLevel = DifficultyLevel.EASY
@export var thinking_time: float = 1.0  # Delay before AI makes moves

enum DifficultyLevel {
	EASY,      # Simple AI, prioritizes attacks over movement
	MEDIUM,    # Smarter AI, considers positioning and tactics
	HARD,      # Advanced AI, uses complex strategies
	EXPERT     # Maximum difficulty with perfect play
}

signal ai_move_complete(success: bool)
signal ai_thinking_started()
signal ai_thinking_complete()

func _init():
	pass

# Override this in subclasses for different AI behaviors
func process_turn(board_state: Dictionary, team: String) -> void:
	"""Main AI decision-making function"""
	ai_thinking_started.emit()
	await get_tree().create_timer(thinking_time).timeout
	
	var decision = make_decision(board_state, team)
	execute_decision(decision, board_state)
	
	ai_thinking_complete.emit()

# Override this in subclasses
func make_decision(board_state: Dictionary, team: String) -> Dictionary:
	"""Analyze board state and return a decision"""
	return {"type": "pass", "success": false}

func execute_decision(decision: Dictionary, board_state: Dictionary) -> void:
	"""Execute the AI's decision"""
	match decision.type:
		"attack":
			execute_attack(decision)
		"move":
			execute_move(decision)
		"ability":
			execute_ability(decision)
		_:
			print("AI passes turn")
	
	ai_move_complete.emit(decision.get("success", false))

func execute_attack(decision: Dictionary) -> void:
	"""Execute an attack decision"""
	# This will be implemented by connecting to the game board
	pass

func execute_move(decision: Dictionary) -> void:
	"""Execute a movement decision"""
	# This will be implemented by connecting to the game board
	pass

func execute_ability(decision: Dictionary) -> void:
	"""Execute a special ability decision"""
	# This will be implemented by connecting to the game board
	pass

func get_piece_value(piece_data: Dictionary, board_state: Dictionary) -> float:
	"""Calculate the strategic value of a piece"""
	var value = 0.0
	
	# Base value from health and attack power
	if piece_data.has("piece_node"):
		var piece = piece_data.piece_node
		value += piece.current_health * 0.5
		value += piece.attack_power * 1.0
	
	# Positional value (could be enhanced with board analysis)
	if piece_data.has("position"):
		var pos = piece_data.position
		# Pieces closer to center are generally more valuable
		var center_distance = pos.distance_to(Vector2(4, 4))
		value += (8 - center_distance) * 2
	
	return value

func get_threat_level(piece_data: Dictionary, enemy_pieces: Array, board_state: Dictionary) -> float:
	"""Calculate how threatened a piece is"""
	var threat = 0.0
	var piece_pos = piece_data.get("position", Vector2(-1, -1))
	
	if piece_pos == Vector2(-1, -1):
		return 0.0
	
	# Check threats from enemy pieces
	for enemy in enemy_pieces:
		var enemy_pos = enemy.get("position", Vector2(-1, -1))
		if enemy_pos == Vector2(-1, -1):
			continue
			
		var distance = piece_pos.distance_to(enemy_pos)
		if distance <= 1.5:  # Adjacent or close
			threat += 10.0
		elif distance <= 3.0:  # Within potential movement + attack range
			threat += 3.0
	
	return threat

func find_safe_positions(piece_data: Dictionary, enemy_pieces: Array, board_state: Dictionary) -> Array:
	"""Find positions where the piece would be safer"""
	var safe_positions = []
	var current_pos = piece_data.get("position", Vector2(-1, -1))
	
	if current_pos == Vector2(-1, -1):
		return safe_positions
	
	# Check adjacent positions
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	for direction in directions:
		var new_pos = current_pos + direction
		
		# Check if position is valid and empty
		if is_valid_board_position(new_pos, board_state) and not board_state.get("pieces", {}).has(new_pos):
			var threat_at_pos = calculate_position_threat(new_pos, enemy_pieces)
			var current_threat = get_threat_level(piece_data, enemy_pieces, board_state)
			
			if threat_at_pos < current_threat:
				safe_positions.append({"position": new_pos, "safety": current_threat - threat_at_pos})
	
	# Sort by safety level
	safe_positions.sort_custom(func(a, b): return a.safety > b.safety)
	
	return safe_positions

func calculate_position_threat(pos: Vector2, enemy_pieces: Array) -> float:
	"""Calculate threat level at a specific position"""
	var threat = 0.0
	
	for enemy in enemy_pieces:
		var enemy_pos = enemy.get("position", Vector2(-1, -1))
		if enemy_pos == Vector2(-1, -1):
			continue
		
		var distance = pos.distance_to(enemy_pos)
		if distance <= 1.5:  # Adjacent
			threat += 10.0
		elif distance <= 3.0:  # Within range
			threat += 3.0
	
	return threat

func is_valid_board_position(pos: Vector2, board_state: Dictionary) -> bool:
	"""Check if a position is valid on the board"""
	var board_size = board_state.get("board_size", 8)
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size