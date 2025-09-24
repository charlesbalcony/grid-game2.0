extends Node2D

# Simplified Game Board Controller - Coordinates all game systems

# Load component scripts
const GridSystem = preload("res://scripts/components/GridSystem.gd")
const PieceManager = preload("res://scripts/components/PieceManager.gd")
const InputHandler = preload("res://scripts/components/InputHandler.gd")
const UIManager = preload("res://scripts/components/UIManager.gd")
const GameBoardAI = preload("res://scripts/components/GameBoardAI.gd")

# Component references
var grid_system
var piece_manager
var input_handler
var ui_manager
var ai_system

# Game state
var game_manager = null
var turn_label = null
var end_turn_button = null
var player_indicator = null
var enemy_indicator = null

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
	add_child(piece_manager)
	
	input_handler = InputHandler.new()
	input_handler.set_parent_node(self)
	input_handler.set_grid_system(grid_system)
	input_handler.set_piece_manager(piece_manager)
	add_child(input_handler)
	
	ui_manager = UIManager.new()
	ui_manager.set_parent_node(self)
	add_child(ui_manager)
	
	ai_system = GameBoardAI.new()
	ai_system.set_parent_node(self)
	ai_system.set_grid_system(grid_system)
	ai_system.set_piece_manager(piece_manager)
	add_child(ai_system)

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
	
	# Calculate damage based on attack type
	var damage = 0
	match attack_type:
		"Basic":
			damage = 1
		"Heavy":
			damage = 2
		"Quick":
			damage = 1
	
	# Apply damage
	print("Target piece structure: ", target)
	if target.has("hp"):
		target.hp -= damage
	elif target.has("HP"):
		target.HP -= damage
	else:
		print("Warning: Could not find HP field in target piece")
		return
	
	print("Attack: ", attacker_pos, " -> ", target_pos, " (", attack_type, ") for ", damage, " damage")
	
	# Create attack effect
	ui_manager.create_attack_effect(grid_system.grid_to_world_pos(attacker_pos), 
									 grid_system.grid_to_world_pos(target_pos))
	
	# Check if target is defeated
	var current_hp = target.hp if target.has("hp") else (target.HP if target.has("HP") else 0)
	if current_hp <= 0:
		print("Piece defeated at ", target_pos)
		piece_manager.remove_piece_at(target_pos)
		
		# Check win condition
		check_win_condition()
	
	# Use action
	if game_manager:
		game_manager.use_action()
	
	# Clear UI state
	ui_manager.clear_attack_ui()
	input_handler.set_mode("MOVE")

func check_win_condition():
	var player_pieces = piece_manager.get_pieces_by_team(0)
	var enemy_pieces = piece_manager.get_pieces_by_team(1)
	
	if player_pieces.is_empty():
		print("Enemy wins!")
		game_manager.end_game("Enemy")
	elif enemy_pieces.is_empty():
		print("Player wins!")
		game_manager.end_game("Player")

func _on_turn_changed(player_index):
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
		# AI turn with delay
		ai_system.process_enemy_turn(game_manager)

func _on_actions_used_up():
	print("All actions used up for this turn")
	if game_manager:
		game_manager.force_end_turn()

func _on_end_turn_pressed():
	print("End turn button pressed")
	if game_manager:
		game_manager.force_end_turn()