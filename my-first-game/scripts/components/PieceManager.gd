# PieceManager.gd
# Handles piece creation, selection, movement, and data management

class_name PieceManager
extends Node2D

# Piece colors
const PLAYER_COLOR = Color(0.2, 0.6, 1.0)
const ENEMY_COLOR = Color(1.0, 0.3, 0.2)

var pieces = {}
var selected_piece = null
var selected_position = Vector2(-1, -1)
var selection_highlight = null

var parent_node = null
var grid_system = null

signal piece_selected(piece_data, position)
signal piece_moved(from_pos, to_pos)
signal piece_died(piece)

func _init():
	pass

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
			create_piece(Vector2(col, row), ENEMY_COLOR, "enemy")
	
	# Setup player pieces (blue) on rows 6 and 7 (bottom)
	for row in range(6, 8):
		for col in range(8):  # Use literal instead of GridSystem.GRID_SIZE
			create_piece(Vector2(col, row), PLAYER_COLOR, "player")

func create_piece(grid_pos: Vector2, color: Color, team: String):
	"""Create a new piece at the specified position"""
	if not parent_node or not grid_system:
		return
	
	# Load the piece scene
	var piece_scene = preload("res://scenes/GamePiece.tscn")
	var piece_instance = piece_scene.instantiate()
	
	# Set piece properties
	piece_instance.team = team
	piece_instance.position = grid_system.grid_to_world_pos(grid_pos) + Vector2(grid_system.TILE_SIZE/2, grid_system.TILE_SIZE/2)
	piece_instance.set_grid_position(grid_pos)
	
	# Connect signals
	piece_instance.piece_died.connect(_on_piece_died)
	piece_instance.piece_damaged.connect(_on_piece_damaged)
	
	parent_node.add_child(piece_instance)
	
	# Store piece data
	pieces[grid_pos] = {
		"piece_node": piece_instance,
		"team": team,
		"color": color
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
	
	# For now, allow movement to any adjacent position
	# This can be enhanced with piece-specific movement rules
	var distance = grid_system.get_manhattan_distance(from_pos, to_pos)
	return distance == 1

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