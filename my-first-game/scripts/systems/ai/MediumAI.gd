extends AIController
class_name MediumAI

# Medium AI - Balanced tactical AI that considers positioning and safety

func _init():
	ai_name = "Medium AI"
	difficulty_level = DifficultyLevel.MEDIUM
	thinking_time = 1.2

func make_decision(board_state: Dictionary, team: String) -> Dictionary:
	"""Tactical AI decision making - considers safety, positioning, and objectives"""
	var pieces = board_state.get("pieces", {})
	var friendly_pieces = get_team_pieces(pieces, team)
	var enemy_pieces = get_team_pieces(pieces, get_enemy_team(team))
	
	if friendly_pieces.is_empty():
		return {"type": "pass", "success": false}
	
	# Analyze board state
	var board_analysis = analyze_board_state(friendly_pieces, enemy_pieces, board_state)
	
	# Decision priority based on board state
	# 1. High-value attack opportunities
	var attack_decision = find_tactical_attack(friendly_pieces, enemy_pieces, board_state, board_analysis)
	if attack_decision.has("type") and attack_decision.type == "attack":
		return attack_decision
	
	# 2. Rescue endangered pieces
	var rescue_decision = find_rescue_move(friendly_pieces, enemy_pieces, board_state, board_analysis)
	if rescue_decision.has("type") and rescue_decision.type == "move":
		return rescue_decision
	
	# 3. Tactical positioning
	var position_decision = find_tactical_move(friendly_pieces, enemy_pieces, board_state, board_analysis)
	if position_decision.has("type") and position_decision.type == "move":
		return position_decision
	
	# 4. Fallback to aggressive move
	return find_aggressive_move(friendly_pieces, enemy_pieces, board_state)

func analyze_board_state(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Dictionary:
	"""Analyze the current board state for tactical decisions"""
	var analysis = {
		"material_balance": calculate_material_balance(friendly_pieces, enemy_pieces),
		"threatened_pieces": find_threatened_pieces(friendly_pieces, enemy_pieces, board_state),
		"attack_opportunities": find_all_attack_opportunities(friendly_pieces, enemy_pieces, board_state),
		"control_zones": calculate_control_zones(friendly_pieces, enemy_pieces, board_state)
	}
	
	return analysis

func calculate_material_balance(friendly_pieces: Array, enemy_pieces: Array) -> float:
	"""Calculate the material advantage/disadvantage"""
	var friendly_value = 0.0
	var enemy_value = 0.0
	
	for piece in friendly_pieces:
		friendly_value += get_piece_value(piece, {})
	
	for piece in enemy_pieces:
		enemy_value += get_piece_value(piece, {})
	
	return friendly_value - enemy_value

func find_threatened_pieces(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Array:
	"""Find friendly pieces that are in immediate danger"""
	var threatened = []
	
	for piece in friendly_pieces:
		var threat_level = get_threat_level(piece, enemy_pieces, board_state)
		if threat_level > 8.0:  # High threat threshold
			threatened.append({"piece": piece, "threat": threat_level})
	
	# Sort by threat level
	threatened.sort_custom(func(a, b): return a.threat > b.threat)
	
	return threatened

func find_tactical_attack(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary, analysis: Dictionary) -> Dictionary:
	"""Find the best tactical attack considering value and safety"""
	var best_attack = {}
	var best_score = -999.0
	
	for piece_data in friendly_pieces:
		var attacks = find_piece_attack_opportunities(piece_data, enemy_pieces, board_state)
		
		for attack in attacks:
			var score = evaluate_attack_opportunity(attack, analysis, board_state)
			if score > best_score:
				best_score = score
				best_attack = attack
	
	return best_attack if best_score > 0 else {}

func evaluate_attack_opportunity(attack: Dictionary, analysis: Dictionary, board_state: Dictionary) -> float:
	"""Evaluate the value of an attack opportunity"""
	var score = 0.0
	
	# Base value from target's health and position
	var target = attack.get("target", {})
	var target_health = get_piece_health(target)
	var target_max_health = get_piece_max_health(target)
	
	# Prefer attacking damaged enemies (easier kills)
	var damage_ratio = 1.0 - (float(target_health) / float(target_max_health))
	score += damage_ratio * 20.0
	
	# Consider if this attack would eliminate the target
	var attack_damage = get_attack_damage(attack.get("attack_type", "basic"))
	if attack_damage >= target_health:
		score += 30.0  # Big bonus for eliminating a piece
	
	# Consider safety of attacking piece after attack
	var attacker = attack.get("attacker", {})
	var attacker_threat = get_threat_level(attacker, [target], board_state)
	score -= attacker_threat * 2.0  # Penalty for risky attacks
	
	return score

func find_rescue_move(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary, analysis: Dictionary) -> Dictionary:
	"""Find moves to rescue threatened pieces"""
	var threatened = analysis.get("threatened_pieces", [])
	
	if threatened.is_empty():
		return {}
	
	# Try to move the most threatened piece to safety
	var most_threatened = threatened[0]
	var piece_data = most_threatened.piece
	
	var safe_positions = find_safe_positions(piece_data, enemy_pieces, board_state)
	if not safe_positions.is_empty():
		var safest_pos = safe_positions[0].position
		
		return {
			"type": "move",
			"piece": piece_data,
			"from": piece_data.get("position"),
			"to": safest_pos,
			"success": true
		}
	
	return {}

func find_tactical_move(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary, analysis: Dictionary) -> Dictionary:
	"""Find the best tactical positioning move"""
	var best_move = {}
	var best_score = -999.0
	
	for piece_data in friendly_pieces:
		var moves = find_piece_movement_options(piece_data, board_state)
		
		for move in moves:
			var score = evaluate_position(move.to, piece_data, enemy_pieces, board_state)
			if score > best_score:
				best_score = score
				best_move = {
					"type": "move",
					"piece": piece_data,
					"from": piece_data.get("position"),
					"to": move.to,
					"success": true
				}
	
	return best_move if best_score > -500 else {}

func evaluate_position(pos: Vector2, piece_data: Dictionary, enemy_pieces: Array, board_state: Dictionary) -> float:
	"""Evaluate the tactical value of a position"""
	var score = 0.0
	
	# Prefer central positions
	var center_distance = pos.distance_to(Vector2(4, 4))
	score += (8 - center_distance) * 3.0
	
	# Consider safety
	var threat = calculate_position_threat(pos, enemy_pieces)
	score -= threat * 2.0
	
	# Consider attack opportunities from this position
	var attack_count = count_attack_opportunities_from_position(pos, enemy_pieces)
	score += attack_count * 5.0
	
	return score

func find_piece_movement_options(piece_data: Dictionary, board_state: Dictionary) -> Array:
	"""Find all valid movement options for a piece"""
	var moves = []
	var piece_pos = piece_data.get("position", Vector2(-1, -1))
	
	if piece_pos == Vector2(-1, -1):
		return moves
	
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	var pieces = board_state.get("pieces", {})
	
	for direction in directions:
		var new_pos = piece_pos + direction
		
		if is_valid_board_position(new_pos, board_state) and not pieces.has(new_pos):
			moves.append({"from": piece_pos, "to": new_pos})
	
	return moves

func count_attack_opportunities_from_position(pos: Vector2, enemy_pieces: Array) -> int:
	"""Count how many enemies could be attacked from this position"""
	var count = 0
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	for direction in directions:
		var check_pos = pos + direction
		for enemy in enemy_pieces:
			if enemy.get("position", Vector2(-1, -1)) == check_pos:
				count += 1
				break
	
	return count

# Utility functions (shared with EasyAI, could be moved to base class)
func find_aggressive_move(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Dictionary:
	"""Fallback aggressive move"""
	# Same implementation as EasyAI for now
	if enemy_pieces.is_empty():
		return {}
	
	var best_move = null
	var shortest_distance = 999.0
	
	for piece_data in friendly_pieces:
		var piece_pos = piece_data.get("position", Vector2(-1, -1))
		if piece_pos == Vector2(-1, -1):
			continue
		
		# Find closest enemy
		var closest_enemy_pos = Vector2(-1, -1)
		var closest_distance = 999.0
		
		for enemy in enemy_pieces:
			var enemy_pos = enemy.get("position", Vector2(-1, -1))
			if enemy_pos == Vector2(-1, -1):
				continue
			
			var distance = piece_pos.distance_to(enemy_pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy_pos = enemy_pos
		
		if closest_enemy_pos == Vector2(-1, -1):
			continue
		
		# Find best move toward enemy
		var move_pos = find_move_toward(piece_pos, closest_enemy_pos, board_state)
		if move_pos != Vector2(-1, -1):
			var new_distance = move_pos.distance_to(closest_enemy_pos)
			if new_distance < shortest_distance:
				shortest_distance = new_distance
				best_move = {
					"type": "move",
					"piece": piece_data,
					"from": piece_pos,
					"to": move_pos,
					"success": true
				}
	
	return best_move if best_move else {}

func find_move_toward(from_pos: Vector2, target_pos: Vector2, board_state: Dictionary) -> Vector2:
	"""Find a valid adjacent position that moves toward the target"""
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	var best_pos = Vector2(-1, -1)
	var best_distance = 999.0
	var pieces = board_state.get("pieces", {})
	
	for direction in directions:
		var new_pos = from_pos + direction
		
		# Check if position is valid and empty
		if is_valid_board_position(new_pos, board_state) and not pieces.has(new_pos):
			var distance = new_pos.distance_to(target_pos)
			if distance < best_distance:
				best_distance = distance
				best_pos = new_pos
	
	return best_pos

func get_team_pieces(pieces: Dictionary, team: String) -> Array:
	"""Get all pieces belonging to a team"""
	var team_pieces = []
	for pos in pieces:
		var piece_data = pieces[pos]
		if piece_data.get("team", "") == team:
			var piece_with_pos = piece_data.duplicate()
			piece_with_pos.position = pos
			team_pieces.append(piece_with_pos)
	return team_pieces

func get_piece_health(piece_data: Dictionary) -> int:
	"""Get the current health of a piece"""
	if piece_data.has("piece_node"):
		return piece_data.piece_node.current_health
	return 100

func get_piece_max_health(piece_data: Dictionary) -> int:
	"""Get the maximum health of a piece"""
	if piece_data.has("piece_node"):
		return piece_data.piece_node.max_health
	return 100

func get_attack_damage(attack_type: String) -> int:
	"""Get base damage for attack type"""
	match attack_type:
		"heavy": return 40
		"quick": return 15
		_: return 25

func find_piece_attack_opportunities(piece_data: Dictionary, enemy_pieces: Array, board_state: Dictionary) -> Array:
	"""Find all attack opportunities for a specific piece"""
	var attacks = []
	var piece_pos = piece_data.get("position", Vector2(-1, -1))
	
	if piece_pos == Vector2(-1, -1):
		return attacks
	
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	for direction in directions:
		var target_pos = piece_pos + direction
		
		for enemy in enemy_pieces:
			if enemy.get("position", Vector2(-1, -1)) == target_pos:
				attacks.append({
					"type": "attack",
					"attacker": piece_data,
					"target": enemy,
					"attack_type": "basic",  # Could be enhanced to choose best attack
					"success": true
				})
				break
	
	return attacks

func find_all_attack_opportunities(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Array:
	"""Find all possible attack opportunities"""
	var all_attacks = []
	
	for piece in friendly_pieces:
		var piece_attacks = find_piece_attack_opportunities(piece, enemy_pieces, board_state)
		all_attacks.append_array(piece_attacks)
	
	return all_attacks

func calculate_control_zones(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Dictionary:
	"""Calculate board control zones (placeholder for advanced tactics)"""
	return {"friendly_control": 0.5, "enemy_control": 0.5}