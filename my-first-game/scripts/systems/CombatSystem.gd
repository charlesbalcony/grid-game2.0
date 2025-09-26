extends Node
class_name CombatSystem

# Centralized combat system for handling attacks, damage, and special effects

signal damage_dealt(attacker, target, damage, attack_data)
signal piece_eliminated(piece, eliminator)
signal special_effect_triggered(effect_type, target, data)

var board_reference = null

func _init():
	pass

func set_board_reference(board_node):
	"""Set reference to the game board for accessing pieces and effects"""
	board_reference = board_node

func count_surrounding_enemies(target_pos: Vector2, attacker_team: String, piece_manager = null) -> int:
	"""Count how many allies of the attacker are adjacent to the target"""
	if not piece_manager:
		return 0
	
	var surrounding_count = 0
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),  # Cardinal directions
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)  # Diagonal directions
	]
	
	for direction in directions:
		var check_pos = target_pos + direction
		
		# Check if there's a piece at this position
		var piece_data = piece_manager.get_piece_at_position(check_pos)
		if piece_data and piece_data.has("piece_node"):
			# If it's an ally of the attacker, count it
			if piece_data.piece_node.team == attacker_team:
				surrounding_count += 1
	
	return surrounding_count

func attack_at_positions(attacker_pos: Vector2, target_pos: Vector2, attack_data: AttackData) -> Dictionary:
	"""Execute an attack and return the results"""
	if not board_reference:
		print("Combat system has no board reference!")
		return {"success": false, "error": "No board reference"}
	
	var pieces = board_reference.pieces
	
	if not pieces.has(attacker_pos) or not pieces.has(target_pos):
		return {"success": false, "error": "Invalid positions"}
	
	var attacker_data = pieces[attacker_pos]
	var target_data = pieces[target_pos]
	var attacker = attacker_data.piece_node
	var target = target_data.piece_node
	
	# Calculate attack result with flanking bonuses
	var attack_result = calculate_attack_result(attacker, target, attack_data, attacker_pos, target_pos)
	
	# Apply damage/effects
	apply_attack_effects(attacker, target, attack_data, attack_result)
	
	# Visual feedback
	create_combat_effects(attacker_pos, target_pos, attack_data, attack_result)
	
	# Log the attack
	log_attack(attacker, target, attack_data, attack_result)
	
	return attack_result

func calculate_attack_result(attacker, target, attack_type_or_data, attacker_pos: Vector2, target_pos: Vector2, piece_manager = null):
	"""Calculate the result of an attack with flanking bonuses"""
	var result = {
		"success": true,
		"hit": true,
		"damage": 0,
		"critical": false,
		"status_effects": [],
		"target_eliminated": false,
		"flanking_bonus": 0
	}
	
	# Find attack data based on attack type string or use provided attack data
	var attack_data = null
	if typeof(attack_type_or_data) == TYPE_STRING:
		var attack_type = attack_type_or_data
		# Look up attack in attacker's available attacks
		for attack in attacker.available_attacks:
			if attack.name.to_lower().contains(attack_type.to_lower()) or attack_type.to_lower().contains(attack.name.to_lower().split(" ")[0]):
				attack_data = attack
				break
		# Fallback to basic attack if not found
		if not attack_data:
			attack_data = {"name": "Basic Attack", "damage": attacker.attack_power, "accuracy": 0.95}
	else:
		attack_data = attack_type_or_data
	
	# Check if attack hits (based on accuracy)
	var accuracy = attack_data.get("accuracy", 0.95)
	if randf() > accuracy:
		result.hit = false
		return result
	
	# Calculate base damage
	var base_damage = attack_data.get("damage", attacker.attack_power)
	# Apply target defense
	base_damage = max(1, base_damage - target.defense)
	
	# Calculate flanking bonus if positions are provided
	var flanking_multiplier = 1.0
	if target_pos != Vector2.ZERO and piece_manager:
		var surrounding_enemies = count_surrounding_enemies(target_pos, attacker.team, piece_manager)
		if surrounding_enemies > 0:
			# 25% damage bonus per surrounding ally (up to 100% bonus for 4+ allies)
			flanking_multiplier = 1.0 + (surrounding_enemies * 0.25)
			result.flanking_bonus = surrounding_enemies
			print("Flanking attack! ", surrounding_enemies, " allies surrounding target. Damage multiplier: ", flanking_multiplier)
	
	# Apply flanking multiplier to damage
	base_damage = int(base_damage * flanking_multiplier)
	
	# Check for critical hit (5% chance for now)
	if randf() < 0.05:
		result.critical = true
		base_damage = int(base_damage * 1.5)
	
	result.damage = base_damage
	
	# Check if target would be eliminated
	result.target_eliminated = (target.current_health - base_damage) <= 0
	
	# Handle status effects
	result.status_effects = attack_data.status_effects.duplicate()
	
	return result

func apply_attack_effects(attacker, target, attack_data: AttackData, attack_result: Dictionary):
	"""Apply the effects of an attack"""
	if not attack_result.hit:
		return
	
	var damage = attack_result.damage
	
	# Handle healing attacks (negative damage)
	if damage < 0:
		apply_healing(target, -damage)
	else:
		apply_damage(target, damage)
	
	# Apply status effects
	for effect in attack_result.status_effects:
		apply_status_effect(target, effect)
	
	# Emit signals
	damage_dealt.emit(attacker, target, damage, attack_data)
	
	if attack_result.target_eliminated:
		piece_eliminated.emit(target, attacker)

func apply_damage(target, damage: int):
	"""Apply damage to a target"""
	target.take_damage(damage)

func apply_healing(target, healing: int):
	"""Apply healing to a target"""
	target.current_health = min(target.max_health, target.current_health + healing)
	target.update_health_display()

func apply_status_effect(target, effect: String):
	"""Apply a status effect to a target"""
	# This could be expanded for various status effects
	match effect:
		"poison":
			apply_poison(target)
		"burn":
			apply_burn(target)
		"freeze":
			apply_freeze(target)
		"buff_attack":
			apply_attack_buff(target)
		"debuff_defense":
			apply_defense_debuff(target)
		_:
			print("Unknown status effect: ", effect)

func apply_poison(target):
	"""Apply poison status effect"""
	# Placeholder for poison implementation
	print(target.piece_type, " is poisoned!")
	special_effect_triggered.emit("poison", target, {"duration": 3, "damage_per_turn": 5})

func apply_burn(target):
	"""Apply burn status effect"""
	print(target.piece_type, " is burning!")
	special_effect_triggered.emit("burn", target, {"duration": 2, "damage_per_turn": 8})

func apply_freeze(target):
	"""Apply freeze status effect"""
	print(target.piece_type, " is frozen!")
	special_effect_triggered.emit("freeze", target, {"duration": 1})

func apply_attack_buff(target):
	"""Apply attack power buff"""
	target.attack_power += 5
	print(target.piece_type, " attack power increased!")
	special_effect_triggered.emit("buff_attack", target, {"increase": 5, "duration": 3})

func apply_defense_debuff(target):
	"""Apply defense debuff"""
	target.defense = max(0, target.defense - 3)
	print(target.piece_type, " defense decreased!")
	special_effect_triggered.emit("debuff_defense", target, {"decrease": 3, "duration": 3})

func create_combat_effects(attacker_pos: Vector2, target_pos: Vector2, attack_data: AttackData, attack_result: Dictionary):
	"""Create visual effects for combat"""
	if not board_reference:
		return
	
	# Create attack effect at target position
	board_reference.create_attack_effect(target_pos)
	
	# Special effects based on attack type
	match attack_data.attack_type:
		AttackData.AttackType.MAGIC:
			create_magic_effect(target_pos, attack_data)
		AttackData.AttackType.RANGED:
			create_projectile_effect(attacker_pos, target_pos, attack_data)
		AttackData.AttackType.HEAL:
			create_healing_effect(target_pos, attack_data)
		_:
			pass  # Default melee effect already created

func create_magic_effect(pos: Vector2, attack_data: AttackData):
	"""Create magical attack effects"""
	if not board_reference:
		return
	
	var effect = ColorRect.new()
	effect.size = Vector2(80, 80)
	effect.color = Color(0.8, 0.2, 1.0, 0.7)  # Purple magic effect
	effect.position = board_reference.grid_to_world_pos(pos)
	board_reference.add_child(effect)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func create_projectile_effect(from_pos: Vector2, to_pos: Vector2, attack_data: AttackData):
	"""Create projectile effect for ranged attacks"""
	if not board_reference:
		return
	
	var projectile = ColorRect.new()
	projectile.size = Vector2(8, 8)
	projectile.color = Color(0.8, 0.6, 0.2)  # Arrow color
	projectile.position = board_reference.grid_to_world_pos(from_pos) + Vector2(36, 36)
	board_reference.add_child(projectile)
	
	# Animate projectile movement
	var target_world_pos = board_reference.grid_to_world_pos(to_pos) + Vector2(36, 36)
	var tween = create_tween()
	tween.tween_property(projectile, "position", target_world_pos, 0.3)
	tween.tween_callback(projectile.queue_free)

func create_healing_effect(pos: Vector2, attack_data: AttackData):
	"""Create healing effect"""
	if not board_reference:
		return
	
	var effect = ColorRect.new()
	effect.size = Vector2(80, 80)
	effect.color = Color(0.2, 1.0, 0.2, 0.6)  # Green healing effect
	effect.position = board_reference.grid_to_world_pos(pos)
	board_reference.add_child(effect)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect.queue_free)

func log_attack(attacker, target, attack_data: AttackData, attack_result: Dictionary):
	"""Log attack details"""
	if attack_result.hit:
		var damage_text = str(attack_result.damage)
		if attack_result.critical:
			damage_text += " (CRITICAL!)"
		if attack_result.get("flanking_bonus", 0) > 0:
			damage_text += " (FLANKING x" + str(attack_result.flanking_bonus) + "!)"
		
		print(attacker.piece_type, " attacks ", target.piece_type, " with ", attack_data.name, " for ", damage_text, " damage")
		
		if attack_result.target_eliminated:
			print(target.piece_type, " has been eliminated!")
	else:
		print(attacker.piece_type, " misses ", target.piece_type, " with ", attack_data.name)

func get_attack_range_positions(center_pos: Vector2, attack_data: AttackData, board_size: int = 8) -> Array[Vector2]:
	"""Get all positions within attack range"""
	var positions: Array[Vector2] = []
	var range = attack_data.range
	
	for x in range(max(0, center_pos.x - range), min(board_size, center_pos.x + range + 1)):
		for y in range(max(0, center_pos.y - range), min(board_size, center_pos.y + range + 1)):
			var pos = Vector2(x, y)
			if pos != center_pos and center_pos.distance_to(pos) <= range:
				positions.append(pos)
	
	return positions

func can_attack_position(attacker_pos: Vector2, target_pos: Vector2, attack_data: AttackData) -> bool:
	"""Check if a position can be attacked with the given attack"""
	return attack_data.is_valid_target(attacker_pos, target_pos)