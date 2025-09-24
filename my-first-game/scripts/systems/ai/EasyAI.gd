extends AIController
class_name EasyAI

# Easy AI - Simple aggressive behavior, prioritizes attacks

func _init():
	ai_name = "Easy AI"
	difficulty_level = DifficultyLevel.EASY
	thinking_time = 0.8

func make_decision(board_state: Dictionary, team: String) -> Dictionary:
	"""Simple AI decision making - attack first, then move toward enemies"""
	var pieces = board_state.get("pieces", {})
	var friendly_pieces = get_team_pieces(pieces, team)
	var enemy_pieces = get_team_pieces(pieces, get_enemy_team(team))
	
	if friendly_pieces.is_empty():
		return {"type": "pass", "success": false}
	
	# First priority: Find attack opportunities
	for piece_data in friendly_pieces:
		var attack_decision = find_attack_opportunity(piece_data, enemy_pieces, board_state)
		if attack_decision.has("type") and attack_decision.type == "attack":
			return attack_decision
	
	# Second priority: Move toward enemies
	var move_decision = find_aggressive_move(friendly_pieces, enemy_pieces, board_state)
	if move_decision.has("type") and move_decision.type == "move":
		return move_decision
	
	# No good moves found
	return {"type": "pass", "success": false}

func find_attack_opportunity(piece_data: Dictionary, enemy_pieces: Array, board_state: Dictionary) -> Dictionary:
	"""Find the best attack opportunity for a piece"""
	var piece_pos = piece_data.get("position", Vector2(-1, -1))
	if piece_pos == Vector2(-1, -1):
		return {}
	
	# Check for adjacent enemies
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
	]
	
	var best_target = null
	var lowest_health = 999
	
	for direction in directions:
		var target_pos = piece_pos + direction
		
		# Find enemy at this position
		for enemy in enemy_pieces:
			if enemy.get("position", Vector2(-1, -1)) == target_pos:
				var enemy_health = get_piece_health(enemy)
				if enemy_health < lowest_health:
					lowest_health = enemy_health
					best_target = enemy
				break
	
	if best_target:
		# Choose a random attack (simple AI doesn't optimize attack choice)
		var attack_types = ["basic", "heavy", "quick"]
		var chosen_attack = attack_types[randi() % attack_types.size()]
		
		return {
			"type": "attack",
			"attacker": piece_data,
			"target": best_target,
			"attack_type": chosen_attack,
			"success": true
		}
	
	return {}

func find_aggressive_move(friendly_pieces: Array, enemy_pieces: Array, board_state: Dictionary) -> Dictionary:
	"""Find the most aggressive move (move toward closest enemy)"""
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

func get_enemy_team(team: String) -> String:
	"""Get the opposing team name"""
	return "enemy" if team == "player" else "player"

func get_piece_health(piece_data: Dictionary) -> int:
	"""Get the current health of a piece"""
	if piece_data.has("piece_node"):
		return piece_data.piece_node.current_health
	return 100  # Default health