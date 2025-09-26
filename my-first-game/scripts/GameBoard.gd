extends Node2D

# Simplified Game Board Controller - Coordinates all game systems

# Load component scripts
const GridSystem = preload("res://scripts/components/GridSystem.gd")
const PieceManager = preload("res://scripts/components/PieceManager.gd")
const InputHandler = preload("res://scripts/components/InputHandler.gd")
const UIManager = preload("res://scripts/components/UIManager.gd")
const GameBoardAI = preload("res://scripts/components/GameBoardAI.gd")
const ArmyManager = preload("res://scripts/systems/ArmyManager.gd")
const Army = preload("res://scripts/systems/Army.gd")

# Component references
var grid_system
var piece_manager
var input_handler
var ui_manager
var ai_system
var army_manager

# Game state
var game_manager = null
var turn_label = null
var end_turn_button = null
var player_indicator = null
var enemy_indicator = null
var ai_timer = null  # Store AI timer to cancel if needed

func _ready():
	# Initialize components
	initialize_components()
	
	# Get references to game manager and UI elements  
	game_manager = get_node("GameManager")
	turn_label = get_node("UI/TurnDisplay/TurnLabel")
	end_turn_button = get_node("UI/TurnDisplay/EndTurnButton")
	player_indicator = get_node("UI/PlayerIndicator")
	enemy_indicator = get_node("UI/EnemyIndicator")
	
	# Now that game_manager is available, set it in the input handler
	if input_handler and game_manager:
		input_handler.set_game_manager(game_manager)
	
	# Connect signals
	if game_manager:
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.actions_used_up.connect(_on_actions_used_up)
		game_manager.game_over.connect(_on_game_over)
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# Initialize the board
	setup_board()

func initialize_components():
	"""Initialize all game system components"""
	grid_system = GridSystem.new()
	grid_system.set_parent_node(self)
	add_child(grid_system)
	
	piece_manager = PieceManager.new()
	piece_manager.set_parent_node(self)
	piece_manager.set_grid_system(grid_system)
	piece_manager.piece_died.connect(_on_piece_died)
	add_child(piece_manager)
	
	input_handler = InputHandler.new()
	input_handler.set_parent_node(self)
	input_handler.set_grid_system(grid_system)
	input_handler.set_piece_manager(piece_manager)
	add_child(input_handler)
	
	ui_manager = UIManager.new()
	ui_manager.set_parent_node(self)
	ui_manager.set_grid_system(grid_system)
	add_child(ui_manager)
	
	# Wire ui_manager to input_handler
	input_handler.set_ui_manager(ui_manager)
	
	# Initialize attack UI
	ui_manager.create_attack_ui()
	
	# Load and initialize AI system
	var ai_script = load("res://scripts/components/GameBoardAI.gd")
	ai_system = ai_script.new()
	ai_system.set_parent_node(self)
	ai_system.set_grid_system(grid_system)
	ai_system.set_piece_manager(piece_manager)
	add_child(ai_system)
	print("AI system initialized: ", ai_system)
	
	# Initialize army manager
	army_manager = ArmyManager.new()
	army_manager.army_changed.connect(_on_army_changed)
	army_manager.level_completed.connect(_on_level_completed)
	add_child(army_manager)

func get_selected_piece():
	"""Get the currently selected piece from piece manager"""
	if piece_manager:
		return piece_manager.selected_piece
	return null

func get_army_manager():
	"""Get the army manager instance"""
	return army_manager

func setup_board():
	# Create the grid
	grid_system.create_grid()
	
	# Setup pieces
	piece_manager.setup_pieces()

func _input(event):
	# Let the InputHandler process input directly since it's in the scene tree
	# The InputHandler's _input method will handle the event automatically
	pass

func _on_piece_selected(piece, position):
	# Handle piece selection
	print("Piece selected at ", position)

func _on_piece_moved(piece, from_pos, to_pos):
	# Handle piece movement
	if game_manager:
		game_manager.use_action()
	print("Piece moved from ", from_pos, " to ", to_pos)

func _on_attack_performed(attacker_pos, target_pos, attack_type):
	# Handle attack execution
	perform_attack(attacker_pos, target_pos, attack_type)

func perform_attack(attacker_pos: Vector2, target_pos: Vector2, attack_type: String):
	var attacker = piece_manager.get_piece_at_position(attacker_pos)
	var target = piece_manager.get_piece_at_position(target_pos)
	
	if not attacker or not target:
		return
	
	# Calculate base damage based on attack type and attacker's stats
	var damage = 0
	if attacker.has("piece_node") and attacker.piece_node:
		var attacker_piece = attacker.piece_node
		# Look up the damage for the specific attack type
		for attack in attacker_piece.available_attacks:
			if attack.name.to_lower().contains(attack_type.to_lower()) or attack_type.to_lower().contains(attack.name.to_lower().split(" ")[0]):
				damage = attack.damage
				break
		# Fallback to basic attack power if no specific attack found
		if damage == 0:
			damage = attacker_piece.attack_power
	
	# Calculate flanking bonus
	var flanking_multiplier = 1.0
	var surrounding_allies = count_surrounding_allies(target_pos, attacker.team)
	if surrounding_allies > 0:
		flanking_multiplier = 1.0 + (surrounding_allies * 0.25)
		print("FLANKING BONUS: ", surrounding_allies, " allies surrounding target! Damage x", flanking_multiplier)
	
	# Apply flanking multiplier
	damage = int(damage * flanking_multiplier)
	
	# Apply damage
	print("Target piece structure: ", target)
	if target.has("piece_node") and target.piece_node:
		var piece_node = target.piece_node
		if piece_node.has_method("take_damage"):
			piece_node.take_damage(damage)
		else:
			print("Warning: piece_node doesn't have take_damage method")
	else:
		print("Warning: Could not find piece_node in target piece")
		return
	
	print("Attack: ", attacker_pos, " -> ", target_pos, " (", attack_type, ") for ", damage, " damage", 
		  " (flanking x%.1f)" % flanking_multiplier if flanking_multiplier > 1.0 else "")
	
	# Show attack notification
	var attacker_team = attacker.team if attacker else "unknown"
	ui_manager.show_attack_notification(attacker_team, attack_type, damage, target_pos)
	
	# Create attack effect
	ui_manager.create_attack_effect(grid_system.grid_to_world_pos(target_pos))
	
	# Check if target is defeated - piece death is handled by the piece itself
	# The piece will call die() which triggers _on_piece_died signal in PieceManager
	# No need to manually remove pieces here
	
	# Use action
	if game_manager:
		game_manager.use_action()
	
	# Clear UI state  
	ui_manager.clear_attack_ui()
	input_handler.set_mode("MOVE")

func count_surrounding_allies(target_pos: Vector2, attacker_team: String) -> int:
	"""Count how many allies of the attacker are adjacent to the target"""
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

func check_win_condition():
	var player_pieces = piece_manager.get_pieces_by_team("player")
	var enemy_pieces = piece_manager.get_pieces_by_team("enemy")
	
	# Check for king deaths first - this is an immediate game over condition
	var player_has_king = false
	var enemy_has_king = false
	
	for piece_data in player_pieces:
		if piece_data.piece_node.piece_type == "king":
			player_has_king = true
			break
	
	for piece_data in enemy_pieces:
		if piece_data.piece_node.piece_type == "king":
			enemy_has_king = true
			break
	
	# King death = immediate game over
	if not player_has_king:
		print("Player's King has fallen! Enemy wins!")
		game_manager.end_game("Enemy", "king_death")
		return
	elif not enemy_has_king:
		print("Enemy's King has fallen! Player wins!")
		game_manager.end_game("Player", "king_death")
		return
	
	# Traditional win condition - all pieces destroyed
	print("Win condition check: Player pieces: ", player_pieces.size(), ", Enemy pieces: ", enemy_pieces.size())
	
	if player_pieces.is_empty():
		print("Enemy wins!")
		game_manager.end_game("Enemy", "elimination")
	elif enemy_pieces.is_empty():
		print("Player wins!")
		game_manager.end_game("Player", "elimination")

func _on_turn_changed(player_index):
	print("=== TURN CHANGED to: ", player_index, " ===")
	
	# Cancel any existing AI timer
	if ai_timer:
		print("Cancelling existing AI timer")
		ai_timer = null
	
	# Update turn display
	if turn_label:
		if player_index == "player":
			turn_label.text = "Player's Turn"
			player_indicator.modulate = Color.WHITE
			enemy_indicator.modulate = Color(0.5, 0.5, 0.5)
		else:
			turn_label.text = "Enemy's Turn"
			player_indicator.modulate = Color(0.5, 0.5, 0.5)
			enemy_indicator.modulate = Color.WHITE
	
	# Clear any UI state - temporarily commented out
	# input_handler.clear_selection()
	# ui_manager.clear_all_highlights()
	
	# Handle enemy turn
	if player_index == "enemy":
		print("Starting enemy turn with 1.5s delay...")
		# AI turn with delay for better pacing
		ai_timer = get_tree().create_timer(1.5)
		ai_timer.timeout.connect(func(): 
			print("Timer finished, calling AI...")
			print("AI system status: ", ai_system)
			print("AI system is valid: ", is_instance_valid(ai_system))
			if ai_timer:  # Check if timer is still valid
				ai_timer = null
				if ai_system and is_instance_valid(ai_system):  # Check if AI system exists and is valid
					ai_system.process_enemy_turn(game_manager)
				else:
					print("ERROR: AI system is null or invalid! Skipping AI turn.")
					# End turn to prevent getting stuck
					if game_manager:
						game_manager.force_end_turn()
		)

func _on_actions_used_up():
	print("All actions used up for this turn")
	# Turn switching is already handled by game_manager.use_action()
	# Don't call force_end_turn() here to avoid double switching

func _on_piece_died(piece):
	"""Handle when any piece dies - check for game over"""
	print("Piece died: ", piece.piece_type, " (", piece.team, ")")
	check_win_condition()

func _on_game_over(winner: String, reason: String = "elimination"):
	"""Handle game over - show victory/defeat screen"""
	print("GAME OVER! Winner: ", winner, " (Reason: ", reason, ")")
	
	# Stop AI processing
	if ai_system:
		ai_system.set_process(false)
	
	# Don't advance army here - wait for player to click restart
	# The army advancement will happen in restart_battle() when appropriate
	
	# Show game over UI
	ui_manager.show_game_over(winner, reason)

func _on_end_turn_pressed():
	print("End turn button pressed")
	if game_manager:
		game_manager.force_end_turn()

func _on_army_changed(new_army: Army):
	"""Handle when the army changes (new level starts)"""
	print("New army deployed: ", new_army.army_name, " (Level ", new_army.level, ")")
	print("Army stats: HP x", new_army.health_multiplier, ", DMG x", new_army.damage_multiplier, ", DEF +", new_army.defense_bonus)

func _on_level_completed(completed_army: Army):
	"""Handle when a level is completed"""
	print("Level completed! Defeated: ", completed_army.army_name)

func restart_battle(winner: String = ""):
	"""Restart the battle while preserving army progression"""
	
	# Handle army progression based on winner
	if winner.to_lower() == "player" and army_manager:
		army_manager.advance_to_next_army()
		print("Player won - Advanced to next army level")
	elif winner.to_lower() != "player" and army_manager:
		army_manager.reset_to_first_army()
		print("Player defeated - Army reset to Level 1")
	
	print("Restarting battle with current army: ", army_manager.get_current_army().army_name)
	
	# Clear existing pieces
	piece_manager.clear_all_pieces()
	
	# Restart game manager
	if game_manager:
		game_manager.restart_game()
	
	# Re-setup pieces with current army stats
	piece_manager.setup_pieces()
	
	# Re-enable AI processing
	if ai_system and is_instance_valid(ai_system):
		ai_system.set_process(true)
	else:
		print("WARNING: AI system missing during restart!")