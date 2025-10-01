# PieceManager.gd
# Handles piece creation, selection, movement, and data management

class_name PieceManager
extends Node2D

# Preload factory classes
const PieceFactory = preload("res://scripts/factories/PieceFactory.gd")
const ItemFactory = preload("res://scripts/factories/ItemFactory.gd")

# Piece colors
const PLAYER_COLOR = Color(0.2, 0.6, 1.0)
const ENEMY_COLOR = Color(1.0, 0.3, 0.2)

var pieces = {}
var selected_piece = null
var selected_position = Vector2(-1, -1)
var selection_highlight = null

var parent_node = null
var grid_system = null

# Factory instances for data-driven piece creation
var piece_factory: PieceFactory
var item_factory: ItemFactory

signal piece_selected(piece_data, position)
signal piece_moved(from_pos, to_pos)
signal piece_died(piece)

func _init():
	# Initialize factories
	piece_factory = PieceFactory.new()
	item_factory = ItemFactory.new()
	print("PieceManager: Initialized factories")

func set_parent_node(node: Node2D):
	"""Set reference to the parent node"""
	parent_node = node

func set_grid_system(grid):
	"""Set reference to the grid system"""
	grid_system = grid

func setup_pieces():
	"""Setup initial piece positions"""
	if not parent_node or not grid_system:
		push_error("PieceManager: Missing parent node or grid system!")
		return
	
	# Setup enemy pieces (red) on rows 0 and 1 (top)
	for row in range(2):
		for col in range(8):  # Use literal instead of GridSystem.GRID_SIZE
			# Place King in center-back position (col 3, row 0)
			if row == 0 and col == 3:
				create_piece(Vector2(col, row), ENEMY_COLOR, "enemy", "king")
			else:
				create_piece(Vector2(col, row), ENEMY_COLOR, "enemy", "warrior")
	
	# Setup player pieces (blue) on rows 6 and 7 (bottom)
	for row in range(6, 8):
		for col in range(8):  # Use literal instead of GridSystem.GRID_SIZE
			# Place King in center-back position (col 3, row 7)
			if row == 7 and col == 3:
				create_piece(Vector2(col, row), PLAYER_COLOR, "player", "king")
			else:
				create_piece(Vector2(col, row), PLAYER_COLOR, "player", "warrior")

func create_piece(grid_pos: Vector2, color: Color, team: String, piece_type: String = "warrior"):
	"""Create a new piece at the specified position"""
	if not parent_node or not grid_system:
		return
	
	# Load the piece scene
	var piece_scene = preload("res://scenes/GamePiece.tscn")
	var piece_instance = piece_scene.instantiate()
	
	# Generate unique but deterministic ID for this piece instance
	# Use team_type_position format so same pieces at same positions get same IDs across restarts
	var piece_id = team + "_" + piece_type + "_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	
	# Check if the method exists before calling it
	if piece_instance.has_method("set_piece_id"):
		piece_instance.set_piece_id(piece_id)
	else:
		print("ERROR: GamePiece instance does not have set_piece_id method!")
		print("Instance type: ", piece_instance.get_class())
		print("Script: ", piece_instance.get_script())
		print("Script is valid: ", piece_instance.get_script() != null)
	
	# Wait a frame to ensure script is fully loaded
	await parent_node.get_tree().process_frame
	
	# Set piece properties - check if they're accessible
	if "team" in piece_instance:
		piece_instance.team = team
	else:
		print("ERROR: Cannot set team property on piece instance")
		
	if "piece_type" in piece_instance:
		piece_instance.piece_type = piece_type
	else:
		print("ERROR: Cannot set piece_type property on piece instance")
	piece_instance.position = grid_system.grid_to_world_pos(grid_pos) + Vector2(grid_system.TILE_SIZE/2, grid_system.TILE_SIZE/2)
	piece_instance.set_grid_position(grid_pos)
	
	# Configure piece stats using PieceFactory data-driven approach
	var piece_type_data = piece_factory.create_piece_type(piece_type)
	if piece_type_data:
		piece_instance.max_health = piece_type_data.max_health
		piece_instance.current_health = piece_type_data.max_health
		piece_instance.attack_power = piece_type_data.base_attack_power
		piece_instance.defense = piece_type_data.base_defense
		
		# Store piece type data for attack handling
		if piece_instance.has_method("set_piece_type_data"):
			piece_instance.set_piece_type_data(piece_type_data)
		
		print("Created ", piece_type, " with stats from factory - HP:", piece_instance.max_health, " ATK:", piece_instance.attack_power, " DEF:", piece_instance.defense)
	else:
		# Fallback to hardcoded values
		print("WARNING: Failed to create piece type from factory, using hardcoded values")
		if piece_type == "king":
			piece_instance.max_health = 120
			piece_instance.current_health = 120
			piece_instance.attack_power = 35
			piece_instance.defense = 10
		else:
			piece_instance.max_health = 100
			piece_instance.current_health = 100
			piece_instance.attack_power = 25
			piece_instance.defense = 0
	
	# Apply army modifiers for enemy pieces
	if team == "enemy":
		apply_army_modifiers(piece_instance)
	
	# Register with LoadoutManager if it exists
	if parent_node.has_method("get_loadout_manager"):
		var loadout_manager = parent_node.get_loadout_manager()
		if loadout_manager:
			loadout_manager.register_piece_instance(piece_id, piece_type, grid_pos)
			print("Registered piece with LoadoutManager: ", piece_id)
	
	# Connect signals
	piece_instance.piece_died.connect(_on_piece_died)
	piece_instance.piece_damaged.connect(_on_piece_damaged)
	
	parent_node.add_child(piece_instance)
	
	# Store piece data
	pieces[grid_pos] = {
		"piece_node": piece_instance,
		"team": team,
		"color": color,
		"piece_id": piece_id
	}

func select_piece(grid_pos: Vector2) -> bool:
	"""Select a piece at the given position"""
	clear_selection()
	
	if pieces.has(grid_pos):
		selected_piece = pieces[grid_pos]
		selected_position = grid_pos
		create_selection_highlight(grid_pos)
		
		# Make the selected piece slightly brighter
		var piece_node = selected_piece.piece_node
		piece_node.set_selected(true)
		
		print("Selected ", piece_node.piece_type, " at: ", grid_pos, " (HP: ", piece_node.current_health, "/", piece_node.max_health, ")")
		piece_selected.emit(selected_piece, grid_pos)
		return true
	
	return false

func move_piece(from_pos: Vector2, to_pos: Vector2) -> bool:
	"""Move a piece from one position to another"""
	if not pieces.has(from_pos) or pieces.has(to_pos):
		return false
	
	if not grid_system:
		return false
	
	var piece_data = pieces[from_pos]
	var piece_node = piece_data.piece_node
	
	# Move the piece node
	piece_node.position = grid_system.grid_to_world_pos(to_pos) + Vector2(40, 40)  # TILE_SIZE/2 = 40
	piece_node.set_grid_position(to_pos)
	
	# Update the pieces dictionary
	pieces[to_pos] = piece_data
	pieces.erase(from_pos)
	
	print("Moved ", piece_node.piece_type, " from ", from_pos, " to ", to_pos)
	piece_moved.emit(from_pos, to_pos)
	return true

func clear_selection():
	"""Clear the current piece selection"""
	# Reset the piece appearance
	if selected_piece != null and selected_piece.has("piece_node"):
		selected_piece.piece_node.set_selected(false)
	
	selected_piece = null
	selected_position = Vector2(-1, -1)
	
	# Remove the selection highlight
	if selection_highlight != null:
		selection_highlight.queue_free()
		selection_highlight = null

func create_selection_highlight(grid_pos: Vector2):
	"""Create visual highlight for selected piece"""
	if not grid_system or not parent_node:
		return
	
	if grid_system.is_valid_position(grid_pos):
		# Create a subtle border highlight
		selection_highlight = ColorRect.new()
		selection_highlight.size = Vector2(80, 80)  # TILE_SIZE = 80
		selection_highlight.position = grid_system.grid_to_world_pos(grid_pos)
		selection_highlight.color = Color.TRANSPARENT
		selection_highlight.z_index = 2
		
		# Add a glowing border effect
		var border_thickness = 3
		var border_color = Color(0.4, 0.8, 1.0, 0.8)
		
		# Create border rectangles
		var borders = [
			{"size": Vector2(80, border_thickness), "pos": Vector2(0, 0)},  # Top
			{"size": Vector2(80, border_thickness), "pos": Vector2(0, 80 - border_thickness)},  # Bottom
			{"size": Vector2(border_thickness, 80), "pos": Vector2(0, 0)},  # Left
			{"size": Vector2(border_thickness, 80), "pos": Vector2(80 - border_thickness, 0)}  # Right
		]
		
		for border_data in borders:
			var border = ColorRect.new()
			border.size = border_data.size
			border.position = border_data.pos
			border.color = border_color
			selection_highlight.add_child(border)
		
		parent_node.add_child(selection_highlight)

func get_pieces_by_team(team: String) -> Array:
	"""Get all pieces belonging to a specific team"""
	var team_pieces = []
	for pos in pieces:
		var piece_data = pieces[pos]
		if piece_data.get("team", "") == team:
			# Add position information to the piece data
			var piece_with_pos = piece_data.duplicate()
			piece_with_pos.position = pos
			team_pieces.append(piece_with_pos)
	return team_pieces

func get_piece_at_position(pos: Vector2):
	"""Get piece data at a specific position"""
	return pieces.get(pos, null)

func is_position_occupied(pos: Vector2) -> bool:
	"""Check if a position has a piece"""
	return pieces.has(pos)

func can_piece_move_to(from_pos: Vector2, to_pos: Vector2) -> bool:
	"""Check if a piece can move to a specific position"""
	if not grid_system:
		return false
	
	# Basic checks
	if not grid_system.is_valid_position(to_pos):
		return false
	
	if is_position_occupied(to_pos):
		return false
	
	if not is_position_occupied(from_pos):
		return false
	
	# For now, allow movement to adjacent positions including diagonals
	# This can be enhanced with piece-specific movement rules
	var manhattan_distance = grid_system.get_manhattan_distance(from_pos, to_pos)
	var euclidean_distance = grid_system.get_distance(from_pos, to_pos)
	return manhattan_distance <= 2 and euclidean_distance <= 1.5

func get_selected_piece():
	"""Get the currently selected piece"""
	return selected_piece

func get_selected_position() -> Vector2:
	"""Get the position of the currently selected piece"""
	return selected_position

func _on_piece_died(piece):
	"""Handle when a piece dies"""
	# Remove piece from grid when it dies
	for pos in pieces.keys():
		if pieces[pos].piece_node == piece:
			pieces.erase(pos)
			break
	
	print("A ", piece.piece_type, " has been defeated!")
	piece_died.emit(piece)

func _on_piece_damaged(piece, damage):
	"""Handle when a piece takes damage"""
	print("Damage dealt: ", damage)

func apply_army_modifiers(piece_instance):
	"""Apply current army modifiers to enemy pieces"""
	# Get current army from parent GameBoard
	var game_board = parent_node
	if game_board and game_board.has_method("get_army_manager"):
		var army_manager = game_board.get_army_manager()
		if army_manager:
			var current_army = army_manager.get_current_army()
			if current_army:
				# Apply health multiplier
				piece_instance.max_health = int(piece_instance.max_health * current_army.health_multiplier)
				piece_instance.current_health = piece_instance.max_health
				
				# Apply damage multiplier
				piece_instance.attack_power = int(piece_instance.attack_power * current_army.damage_multiplier)
				
				# Apply defense bonus
				piece_instance.defense += current_army.defense_bonus
				
				print("Applied army modifiers to ", piece_instance.piece_type, ": HP=", piece_instance.max_health, ", ATK=", piece_instance.attack_power, ", DEF=", piece_instance.defense)

func clear_all_pieces():
	"""Clear all pieces from the board"""
	for piece_data in pieces.values():
		if piece_data.piece_node and is_instance_valid(piece_data.piece_node):
			piece_data.piece_node.queue_free()
	
	pieces.clear()
	clear_selection()
	print("All pieces cleared from board")