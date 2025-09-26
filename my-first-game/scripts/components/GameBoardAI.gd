# GameBoardAI.gd
# AI System for the Game Board - Handles enemy AI logic

class_name GameBoardAI
extends Node

var parent_node = null
var grid_system = null
var piece_manager = null
var ui_manager = null
var difficulty_mode = "medium"  # "easy" or "medium"

func _init():
	pass

func set_difficulty_mode(mode: String):
	"""Set AI difficulty mode - 'easy' or 'medium'"""
	difficulty_mode = mode
	print("AI difficulty set to: ", difficulty_mode)

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
	print("AI process_enemy_turn called. Game manager exists: ", game_manager != null)
	if game_manager:
		print("Current team: ", game_manager.get_current_team())
	
	if not game_manager or game_manager.get_current_team() != "enemy":
		return
		
	if not piece_manager:
		print("AI: No piece manager!")
		return
		
	# Get all enemy pieces
	var enemy_pieces = piece_manager.get_pieces_by_team("enemy")
	if enemy_pieces.is_empty():
		print("AI: No enemy pieces found!")
		return
		
	# Get player pieces for aggression detection
	var player_pieces = piece_manager.get_pieces_by_team("player")
		
	# Enhanced AI decision making - detect player aggression and respond accordingly
	var immediate_king_attacks = []
	var regular_attacks = []
	
	# DETECT PLAYER AGGRESSION - is player rushing our king?
	var player_aggression_level = detect_player_aggression(enemy_pieces, player_pieces)
	print("AI detected player aggression level: ", player_aggression_level)
	
	# First, check for any immediate attack opportunities
	for piece_data in enemy_pieces:
		var attack_targets = get_adjacent_enemies(piece_data.position, "enemy")
		for target in attack_targets:
			var attack_option = {"attacker": piece_data, "target": target}
			
			if target.piece_node.piece_type == "king":
				immediate_king_attacks.append(attack_option)
			else:
				regular_attacks.append(attack_option)
	
	# PRIORITY 1: Always take king attacks if available
	if not immediate_king_attacks.is_empty():
		var selected_attack = immediate_king_attacks[randi() % immediate_king_attacks.size()]
		print("AI found immediate KING attack - executing!")
		perform_ai_attack(selected_attack.attacker, selected_attack.target, game_manager)
		return
	
	# PRIORITY 2: If player is being aggressive, respond with counter-aggression
	if player_aggression_level >= 3:  # High aggression detected
		print("AI responding to player aggression with counter-attack!")
		
		# Switch to aggressive mode - 80% attack/king rush, 20% positioning
		var should_counter_attack = randf() < 0.8
		
		if should_counter_attack:
			# Prioritize any attack available, even on regular pieces
			if not regular_attacks.is_empty():
				var selected_attack = regular_attacks[randi() % regular_attacks.size()]
				print("AI making aggressive counter-attack!")
				perform_ai_attack(selected_attack.attacker, selected_attack.target, game_manager)
				return
		
		# If no attacks available, rush toward player king aggressively
		var aggressive_move = find_most_aggressive_move(enemy_pieces)
		if aggressive_move:
			print("AI making aggressive rush toward player king!")
			perform_ai_move(aggressive_move.piece, aggressive_move.target_pos, game_manager)
			return
	
	# PRIORITY 3: Check if we can set up a king attack next turn
	var can_setup_king_attack = false
	if piece_manager:
		var player_pieces_check = piece_manager.get_pieces_by_team("player")
		var player_king = null
		
		for player_piece in player_pieces_check:
			if player_piece.piece_node.piece_type == "king":
				player_king = player_piece
				break
		
		if player_king:
			for piece_data in enemy_pieces:
				var valid_moves = get_valid_moves_for_piece(piece_data.position)
				for move_pos in valid_moves:
					if move_pos.distance_to(player_king.position) <= 1.5:
						can_setup_king_attack = true
						break
				if can_setup_king_attack:
					break
	
	# Adjust strategy based on situation and player aggression
	var should_prioritize_attack
	if player_aggression_level >= 2:  # Medium+ aggression
		# More aggressive response - 70% attack focus
		should_prioritize_attack = randf() < 0.7
		print("AI adopting aggressive stance due to player pressure")
	elif can_setup_king_attack:
		# If we can set up a king attack, focus on positioning (30% attack, 70% move)
		should_prioritize_attack = randf() < 0.3
		print("AI can set up king attack - prioritizing positioning")
	elif not regular_attacks.is_empty():
		# If regular attacks available, balance attack vs positioning (60% attack, 40% move)
		should_prioritize_attack = randf() < 0.6
	else:
		# No attacks available, focus on movement and army coordination
		should_prioritize_attack = false
		print("AI focusing on army coordination and positioning")
	
	if should_prioritize_attack and not regular_attacks.is_empty():
		# Execute regular attack
		var selected_attack = regular_attacks[randi() % regular_attacks.size()]
		perform_ai_attack(selected_attack.attacker, selected_attack.target, game_manager)
		return
	
	# Focus on strategic movement and army coordination
	var best_move = find_best_move(enemy_pieces)
	if best_move:
		perform_ai_move(best_move.piece, best_move.target_pos, game_manager)
		return
	
	# Fallback to any available attack if no moves possible
	if not regular_attacks.is_empty():
		var selected_attack = regular_attacks[randi() % regular_attacks.size()]
		perform_ai_attack(selected_attack.attacker, selected_attack.target, game_manager)

func find_best_move(enemy_pieces: Array) -> Dictionary:
	"""Find the best move for AI with king-targeting priority and army coordination"""
	if not piece_manager or not grid_system:
		return {}
		
	var player_pieces = piece_manager.get_pieces_by_team("player")
	if player_pieces.is_empty():
		return {}
	
	# Simple easy mode - just attack closest piece or move forward
	if difficulty_mode == "easy":
		print("AI using EASY mode - simple behavior")
		return find_easy_move(enemy_pieces, player_pieces)
	
	print("AI using MEDIUM mode - advanced tactics")
	
	# Find both kings for strategic considerations
	var player_king = null
	var enemy_king = null
	var other_player_pieces = []
	
	for player_piece in player_pieces:
		if player_piece.piece_node.piece_type == "king":
			player_king = player_piece
		else:
			other_player_pieces.append(player_piece)
	
	for enemy_piece in enemy_pieces:
		if enemy_piece.piece_node.piece_type == "king":
			enemy_king = enemy_piece
			break
	
	# Determine board layout - assume enemy starts at top (low Y), player at bottom (high Y)
	var board_center = Vector2(4, 4)  # Center of 8x8 board
	var enemy_side_y = 1  # Enemy's back rank
	var player_side_y = 6  # Player's back rank
	var center_y = 4
	
	# Collect all possible moves with their scores
	var possible_moves = []
	
	for enemy_piece in enemy_pieces:
		var is_enemy_king = (enemy_piece.piece_node.piece_type == "king")
		var valid_moves = get_valid_moves_for_piece(enemy_piece.position)
		
		for move_pos in valid_moves:
			var total_score = 0.0
			var move_type = "positioning"
			
			# PRIORITY 1: Direct king attack opportunity (check if move puts us adjacent to player king)
			if player_king:
				var distance_to_king_after_move = move_pos.distance_to(player_king.position)
				
				# If this move puts us adjacent to player king
				if distance_to_king_after_move <= 1.5 and not is_enemy_king:
					total_score += 1000.0  # Massive priority for setting up king attack
					move_type = "king_setup"
					print("AI found move that sets up king attack!")
			
			# PRIORITY 2: King Safety - Keep enemy king protected and in the back
			if is_enemy_king and enemy_king:
				# Kings should generally stay in the back - big penalty for advancing
				var king_advance_penalty = 0.0
				if move_pos.y > enemy_side_y + 1:  # Moving beyond second rank
					king_advance_penalty = -100.0  # Heavy penalty for king advancing
				
				# Only move forward if under serious threat
				var under_threat = false
				for player_piece in player_pieces:
					if player_piece.position.distance_to(enemy_piece.position) <= 2.0:
						under_threat = true
						break
				
				if under_threat:
					# When threatened, prefer corner retreats
					var corner_distances = [
						move_pos.distance_to(Vector2(0, 0)),  # Top-left corner
						move_pos.distance_to(Vector2(7, 0)),  # Top-right corner
					]
					var closest_corner_distance = corner_distances.min()
					total_score += (10.0 - closest_corner_distance) * 10  # Bonus for retreating to corners
					move_type = "king_retreat"
				else:
					# When safe, stay on back rank or second rank, prefer central files slightly
					if move_pos.y <= enemy_side_y + 1:  # First or second rank
						total_score += 50.0
					
					# Slight preference for center files (3-5) for king mobility, but not too strong
					var distance_from_center_file = abs(move_pos.x - 4)
					total_score += (4 - distance_from_center_file) * 3  # Small bonus only
					
					king_advance_penalty = 0.0  # No penalty when safe and staying back
				
				total_score += king_advance_penalty
				if move_type == "positioning":
					move_type = "king_safety"
				
			# PRIORITY 3: For non-king pieces - DIRECT ADVANCEMENT toward player pieces
			elif not is_enemy_king:
				# Find the closest player piece to determine best advancement direction
				var closest_player_piece = null
				var closest_distance = 999.0
				
				for player_piece in player_pieces:
					var distance = enemy_piece.position.distance_to(player_piece.position)
					if distance < closest_distance:
						closest_distance = distance
						closest_player_piece = player_piece
				
				if closest_player_piece:
					# Strong bonus for moving DIRECTLY toward closest player piece
					var current_distance = enemy_piece.position.distance_to(closest_player_piece.position)
					var new_distance = move_pos.distance_to(closest_player_piece.position)
					
					if new_distance < current_distance:
						# Moving closer - excellent!
						var approach_bonus = (current_distance - new_distance) * 40.0  # Big bonus
						total_score += approach_bonus
						move_type = "direct_advance"
				
				# STRONG bonus for Y-advancement toward player side (assuming player is at bottom)
				var current_y = enemy_piece.position.y
				var new_y = move_pos.y
				
				if new_y > current_y:
					# Moving toward player side - this is what we want!
					var y_advance_bonus = (new_y - current_y) * 60.0  # Very strong bonus
					total_score += y_advance_bonus
					print("AI piece advancing from Y:", current_y, " to Y:", new_y)
				
				# PENALTY for sideways movement when forward movement is possible
				if new_y == current_y:  # Sideways movement
					# Check if forward movement was possible
					var forward_pos = Vector2(current_y + 1, enemy_piece.position.x)
					var forward_moves = get_valid_moves_for_piece(enemy_piece.position)
					
					var could_move_forward = false
					for valid_move in forward_moves:
						if valid_move.y > current_y:
							could_move_forward = true
							break
					
					if could_move_forward:
						total_score -= 30.0  # Penalty for choosing sideways when forward available
				
				# Small bonus for center files, but much less than advancement
				var distance_from_center_file = abs(move_pos.x - 4)
				if distance_from_center_file <= 1:
					total_score += 5.0  # Small bonus only
				
				# King targeting - extra bonus for getting closer to player king specifically
				if player_king:
					var current_king_distance = enemy_piece.position.distance_to(player_king.position)
					var new_king_distance = move_pos.distance_to(player_king.position)
					
					if new_king_distance < current_king_distance:
						var king_approach_bonus = (current_king_distance - new_king_distance) * 25.0
						total_score += king_approach_bonus
						if move_type == "positioning":
							move_type = "king_hunt"
				
				# Small support bonus, but don't let it override advancement
				var support_score = 0.0
				for other_piece in enemy_pieces:
					if other_piece != enemy_piece:
						var distance_to_ally = move_pos.distance_to(other_piece.position)
						if distance_to_ally <= 2.0:
							support_score += 3.0  # Much smaller bonus
				
				total_score += support_score
				
				# Strong penalty for moving backward (toward enemy side)
				if new_y < current_y:
					total_score -= 50.0  # Heavy penalty for retreat
			
			possible_moves.append({
				"piece": enemy_piece,
				"target_pos": move_pos,
				"score": total_score,
				"type": move_type
			})
	
	if possible_moves.is_empty():
		return {}
	
	# Sort moves by score (best first)
	possible_moves.sort_custom(func(a, b): return a.score > b.score)
	
	# Decision making with strategic priorities
	var king_setup_moves = possible_moves.filter(func(move): return move.type == "king_setup")
	var king_retreat_moves = possible_moves.filter(func(move): return move.type == "king_retreat")
	var king_safety_moves = possible_moves.filter(func(move): return move.type == "king_safety")
	var direct_advance_moves = possible_moves.filter(func(move): return move.type == "direct_advance")
	var king_hunt_moves = possible_moves.filter(func(move): return move.type == "king_hunt")
	var positioning_moves = possible_moves.filter(func(move): return move.type == "positioning")
	
	var selected_move
	var rand_val = randf()
	
	# Always prioritize king setup moves
	if not king_setup_moves.is_empty():
		selected_move = king_setup_moves[0]
		print("AI setting up for king attack!")
	elif not king_retreat_moves.is_empty():
		# King needs to retreat when threatened
		selected_move = king_retreat_moves[0]
		print("AI king retreating to safety")
	elif not direct_advance_moves.is_empty() and rand_val < 0.8:
		# 80% chance to make direct advances when available
		selected_move = direct_advance_moves[0]
		print("AI making direct advance toward player pieces")
	elif not king_hunt_moves.is_empty() and rand_val < 0.9:
		# 90% chance to hunt player king when not making direct advances
		selected_move = king_hunt_moves[0] 
		print("AI hunting player king")
	elif not king_safety_moves.is_empty():
		# Keep own king safe
		selected_move = king_safety_moves[0]
		print("AI keeping own king safe")
	else:
		# Fallback to best positioning move
		if not positioning_moves.is_empty():
			selected_move = positioning_moves[0]
			print("AI making positioning move")
		else:
			selected_move = possible_moves[0]
	
	return {
		"piece": selected_move.piece,
		"target_pos": selected_move.target_pos
	}

func detect_player_aggression(enemy_pieces: Array, player_pieces: Array) -> int:
	"""Detect how aggressively the player is targeting our king"""
	var aggression_score = 0
	
	# Find our king
	var our_king = null
	for enemy_piece in enemy_pieces:
		if enemy_piece.piece_node.piece_type == "king":
			our_king = enemy_piece
			break
	
	if not our_king:
		return 0
	
	var king_pos = our_king.position
	var threats_nearby = 0
	var advancing_pieces = 0
	
	# Count player pieces threatening our king
	for player_piece in player_pieces:
		var distance_to_king = player_piece.position.distance_to(king_pos)
		
		# Immediate threats (very close)
		if distance_to_king <= 2.0:
			threats_nearby += 1
			aggression_score += 2
		elif distance_to_king <= 3.0:
			threats_nearby += 1
			aggression_score += 1
		
		# Check if player pieces are in our territory (advanced positions)
		# Assuming enemy king is in upper area (low Y values)
		if player_piece.position.y <= 3:  # Player pieces in enemy territory
			advancing_pieces += 1
			aggression_score += 1
	
	# Bonus aggression points for concentrated attacks
	if threats_nearby >= 3:
		aggression_score += 3  # Multiple pieces threatening king
	if advancing_pieces >= 2:
		aggression_score += 2  # Multiple pieces advancing
	
	print("King threats: ", threats_nearby, ", Advancing pieces: ", advancing_pieces, ", Total aggression: ", aggression_score)
	return aggression_score

func find_most_aggressive_move(enemy_pieces: Array) -> Dictionary:
	"""Find the most aggressive move - prioritizing king rush over defensive play"""
	if not piece_manager or not grid_system:
		return {}
		
	var player_pieces = piece_manager.get_pieces_by_team("player")
	if player_pieces.is_empty():
		return {}
	
	# Find player king for aggressive targeting
	var player_king = null
	for player_piece in player_pieces:
		if player_piece.piece_node.piece_type == "king":
			player_king = player_piece
			break
	
	if not player_king:
		return {}
	
	var aggressive_moves = []
	
	# Focus only on non-king pieces for the rush
	for enemy_piece in enemy_pieces:
		if enemy_piece.piece_node.piece_type == "king":
			continue  # Kings stay back even during aggressive play
			
		var valid_moves = get_valid_moves_for_piece(enemy_piece.position)
		
		for move_pos in valid_moves:
			var aggression_score = 0.0
			
			# MAXIMUM priority for getting closer to player king
			var current_distance = enemy_piece.position.distance_to(player_king.position)
			var new_distance = move_pos.distance_to(player_king.position)
			
			if new_distance < current_distance:
				aggression_score += (current_distance - new_distance) * 100.0  # Huge bonus
			
			# Extra bonus for getting very close to player king
			if new_distance <= 2.0:
				aggression_score += 200.0
			if new_distance <= 1.5:
				aggression_score += 500.0  # Almost adjacent to player king
			
			# Bonus for advancing toward player territory
			if move_pos.y > enemy_piece.position.y:  # Moving toward player side
				aggression_score += 50.0
			
			# Small penalty for sideways movement during aggression
			if move_pos.y == enemy_piece.position.y:
				aggression_score -= 20.0
			
			aggressive_moves.append({
				"piece": enemy_piece,
				"target_pos": move_pos,
				"score": aggression_score
			})
	
	if aggressive_moves.is_empty():
		return {}
	
	# Sort by most aggressive and pick the best
	aggressive_moves.sort_custom(func(a, b): return a.score > b.score)
	
	return {
		"piece": aggressive_moves[0].piece,
		"target_pos": aggressive_moves[0].target_pos
	}

func get_valid_moves_for_piece(piece_pos: Vector2) -> Array:
	"""Get all valid moves for a piece at the given position"""
	var valid_moves = []
	
	if not grid_system or not piece_manager:
		return valid_moves
	
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
	
	for direction in directions:
		var new_pos = piece_pos + direction
		
		# Check if position is valid and empty
		if grid_system.is_valid_position(new_pos) and not piece_manager.is_position_occupied(new_pos):
			valid_moves.append(new_pos)
	
	return valid_moves

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
		print("AI moved ", piece_data.get("piece_type", "piece"), " from ", old_pos, " to ", target_pos)		# Use action
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
	
	print("AI attacking with ", attack_type, " attack using ", attacker_data.get("piece_type", "piece"), " at ", attacker_data.position)
	
	# Perform the attack using positions (delegate to parent)
	# The attack will use an action automatically
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
			return 50
		"heavy":
			return 50
		"quick":
			return 50
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

func find_easy_move(enemy_pieces: Array, player_pieces: Array) -> Dictionary:
	"""Simple AI for easy mode - just move toward closest player piece"""
	var possible_moves = []
	
	for enemy_piece in enemy_pieces:
		var valid_moves = get_valid_moves_for_piece(enemy_piece.position)
		
		for move_pos in valid_moves:
			var score = 0.0
			
			# Find closest player piece
			var closest_distance = 999.0
			for player_piece in player_pieces:
				var distance = move_pos.distance_to(player_piece.position)
				if distance < closest_distance:
					closest_distance = distance
			
			# Simple scoring: closer to player = better
			score = 100.0 - closest_distance
			
			# Small bonus for moving forward (toward player)
			if move_pos.y > enemy_piece.position.y:
				score += 10.0
			
			possible_moves.append({
				"piece": enemy_piece,
				"position": move_pos,
				"score": score,
				"type": "simple_move"
			})
	
	if possible_moves.is_empty():
		return {}
	
	# Sort by score and pick the best
	possible_moves.sort_custom(func(a, b): return a.score > b.score)
	var best_move = possible_moves[0]
	
	print("Easy AI selected move: ", best_move.piece.position, " -> ", best_move.position, " (score: ", best_move.score, ")")
	
	return {
		"piece": best_move.piece,
		"target_pos": best_move.position,  # Use target_pos to match existing AI interface
		"move_type": best_move.type
	}