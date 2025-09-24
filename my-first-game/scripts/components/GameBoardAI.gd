# GameBoardAI.gd
# AI System for the Game Board - Handles enemy AI logic

class_name GameBoardAI
extends Node

var parent_node = null
var grid_system = null
var piece_manager = null
var ui_manager = null

func _init():
	pass

func set_parent_node(node: Node2D):
	"""Set reference to the parent node"""
	parent_node = node

func set_grid_system(grid):
	"""Set reference to the grid system"""
	grid_system = grid

func set_piece_manager(pm):
	"""Set reference to the piece manager"""
	piece_manager = pm

func set_ui_manager(ui):
	"""Set reference to the UI manager"""
	ui_manager = ui

func process_enemy_turn(game_manager):
	"""Main AI function - processes one enemy action per turn"""
	if not game_manager or game_manager.get_current_team() != "enemy":
		return
		
	if not piece_manager:
		return
		
	# Get all enemy pieces
	var enemy_pieces = piece_manager.get_pieces_by_team("enemy")
	if enemy_pieces.is_empty():
		return
		
	# Try to find an attack opportunity first
	for piece_data in enemy_pieces:
		var attack_targets = get_adjacent_enemies(piece_data.position, "enemy")
		if not attack_targets.is_empty():
			# Found an attack opportunity
			perform_ai_attack(piece_data, attack_targets[0], game_manager)
			return
	
	# No attacks available, try to move towards player pieces
	var best_move = find_best_move(enemy_pieces)
	if best_move:
		perform_ai_move(best_move.piece, best_move.target_pos, game_manager)

func find_best_move(enemy_pieces: Array) -> Dictionary:
	"""Find the best move for AI - move towards closest player piece"""
	if not piece_manager or not grid_system:
		return {}
		
	var player_pieces = piece_manager.get_pieces_by_team("player")
	if player_pieces.is_empty():
		return {}
		
	var best_move = {}
	var best_distance = 999.0
	
	for enemy_piece in enemy_pieces:
		for player_piece in player_pieces:
			var distance = enemy_piece.position.distance_to(player_piece.position)
			
			# Try to move towards this player piece
			var target_pos = get_move_towards(enemy_piece.position, player_piece.position)
			if target_pos != Vector2(-1, -1) and distance < best_distance:
				best_distance = distance
				best_move = {
					"piece": enemy_piece,
					"target_pos": target_pos
				}
	
	return best_move

func get_move_towards(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	"""Find a valid adjacent position that moves towards the target"""
	if not grid_system or not piece_manager:
		return Vector2(-1, -1)
	
	var directions = [
		Vector2(0, 1),   # Down
		Vector2(0, -1),  # Up  
		Vector2(1, 0),   # Right
		Vector2(-1, 0),  # Left
		Vector2(1, 1),   # Down-Right
		Vector2(-1, 1),  # Down-Left
		Vector2(1, -1),  # Up-Right
		Vector2(-1, -1)  # Up-Left
	]
	
	var best_pos = Vector2(-1, -1)
	var best_distance = 999.0
	
	for direction in directions:
		var new_pos = from_pos + direction
		
		# Check if position is valid and empty
		if grid_system.is_valid_position(new_pos) and not piece_manager.is_position_occupied(new_pos):
			var distance = new_pos.distance_to(to_pos)
			if distance < best_distance:
				best_distance = distance
				best_pos = new_pos
	
	return best_pos

func perform_ai_move(piece_data: Dictionary, target_pos: Vector2, game_manager):
	"""Execute an AI move"""
	if not game_manager or not game_manager.can_perform_action("enemy"):
		return
	
	if not piece_manager:
		return
		
	var old_pos = piece_data.position
	
	# Update piece position using piece manager
	if piece_manager.move_piece(old_pos, target_pos):
		print("AI moved piece from ", old_pos, " to ", target_pos)
		
		# Use action
		game_manager.use_action()

func perform_ai_attack(attacker_data: Dictionary, target_data: Dictionary, game_manager):
	"""Execute an AI attack"""
	if not game_manager or not game_manager.can_perform_action("enemy"):
		return
		
	# Choose a random attack type for AI
	var attack_types = ["basic", "heavy", "quick"]
	var attack_type = attack_types[randi() % attack_types.size()]
	
	# Create attack data structure
	var attack_data = {
		"name": get_attack_name(attack_type),
		"type": attack_type,
		"damage": get_attack_damage(attack_type),
		"accuracy": get_attack_accuracy(attack_type)
	}
	
	print("AI attacking with ", attack_type, " attack")
	
	# Perform the attack using positions (delegate to parent)
	if parent_node and parent_node.has_method("perform_attack"):
		parent_node.perform_attack(attacker_data.position, target_data.position, attack_type)

func get_adjacent_enemies(pos: Vector2, attacker_team: String) -> Array:
	"""Get enemy pieces adjacent to the given position"""
	var adjacent_enemies = []
	
	if not grid_system or not piece_manager:
		return adjacent_enemies
	
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	for direction in directions:
		var check_pos = pos + direction
		
		if piece_manager.is_position_occupied(check_pos):
			var piece_data = piece_manager.get_piece_at_position(check_pos)
			if piece_data.team != attacker_team:
				# Add position information to the piece data
				var piece_with_pos = piece_data.duplicate()
				piece_with_pos.position = check_pos
				adjacent_enemies.append(piece_with_pos)
	
	return adjacent_enemies

func get_attack_damage(attack_type: String) -> int:
	"""Get base damage for an attack type"""
	match attack_type:
		"basic":
			return 25
		"heavy":
			return 40
		"quick":
			return 15
		_:
			return 25

func get_attack_accuracy(attack_type: String) -> float:
	"""Get accuracy for an attack type"""
	match attack_type:
		"basic":
			return 0.8
		"heavy":
			return 0.6
		"quick":
			return 0.9
		_:
			return 0.8

func get_attack_name(attack_type: String) -> String:
	"""Get display name for an attack type"""
	match attack_type:
		"basic":
			return "Basic Attack"
		"heavy":
			return "Heavy Strike"
		"quick":
			return "Quick Jab"
		_:
			return "Basic Attack"