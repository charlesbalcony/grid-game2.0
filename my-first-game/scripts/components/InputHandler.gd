# InputHandler.gd
# Handles mouse input processing and click event handling

class_name InputHandler
extends Node2D

var parent_node = null
var grid_system = null
var piece_manager = null
var ui_manager = null
var game_manager = null

var current_mode = "MOVE"  # "MOVE" or "ATTACK"

# Drag state tracking
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var drag_start_grid = Vector2.ZERO
var drag_hover_grid = Vector2(-1, -1)  # Current hover position during drag

signal left_click_processed(grid_pos)
signal right_click_processed(grid_pos)
signal mode_changed(new_mode)

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

func set_game_manager(gm):
	"""Set reference to the game manager"""
	game_manager = gm

func _ready():
	if parent_node:
		# Connect to parent's input processing
		if not parent_node.has_method("_input"):
			parent_node._input = _input

func _input(event):
	"""Process input events with drag support"""
	# Only allow input during player's turn
	if game_manager and game_manager.current_team != "player":
		print("Input blocked - current team: ", game_manager.current_team)
		return
	
	if event is InputEventMouseButton:
		var world_pos = parent_node.get_global_mouse_position()
		var grid_pos = grid_system.world_to_grid_pos(world_pos)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Mouse down - start potential drag
				start_drag(world_pos, grid_pos)
			else:
				# Mouse up - end drag or handle click
				end_drag(world_pos, grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click(world_pos)
	
	elif event is InputEventMouseMotion and is_dragging:
		# Handle drag motion
		handle_drag_motion(event.position)

func start_drag(world_pos: Vector2, grid_pos: Vector2):
	"""Start drag operation"""
	if not grid_system.is_valid_position(grid_pos):
		return
	
	# Check if there's a player piece to drag
	if piece_manager.is_position_occupied(grid_pos):
		var piece = piece_manager.get_piece_at_position(grid_pos)
		if piece.team == "player":
			is_dragging = true
			drag_start_pos = world_pos
			drag_start_grid = grid_pos
			drag_hover_grid = grid_pos  # Initialize hover position to start position
			
			# Highlight the piece being dragged
			if ui_manager:
				ui_manager.highlight_drag_position(grid_pos)
			
			print("Started dragging piece at: ", grid_pos)

func handle_drag_motion(screen_pos: Vector2):
	"""Handle drag motion with safe hover highlighting"""
	if not is_dragging or not ui_manager:
		return
	
	# Convert screen position to world position and then to grid
	var world_pos = parent_node.get_global_mouse_position()
	var grid_pos = grid_system.world_to_grid_pos(world_pos)
	
	# Only update if we're hovering over a different grid position
	if grid_pos != drag_hover_grid:
		# Clear previous hover highlight
		ui_manager.clear_hover_highlights()
		
		# Update hover position
		drag_hover_grid = grid_pos
		
		# Only highlight valid move positions: adjacent, empty squares
		if (grid_system.is_valid_position(grid_pos) and 
			grid_pos != drag_start_grid and
			drag_start_grid.distance_to(grid_pos) <= 1.5 and
			not piece_manager.is_position_occupied(grid_pos)):
			ui_manager.highlight_hover_position(grid_pos)

func end_drag(world_pos: Vector2, grid_pos: Vector2):
	"""End drag operation"""
	if is_dragging:
		# Clear drag and hover highlighting
		if ui_manager:
			ui_manager.clear_drag_highlights()
			ui_manager.clear_hover_highlights()
		
		var drag_distance = drag_start_pos.distance_to(world_pos)
		
		if drag_distance > 10.0:
			# This was a drag - attempt move/attack
			handle_drag_drop(drag_start_grid, grid_pos)
		else:
			# This was just a click
			handle_left_click(world_pos)
		
		# Reset drag state
		is_dragging = false
		drag_start_pos = Vector2.ZERO
		drag_start_grid = Vector2.ZERO
		drag_hover_grid = Vector2(-1, -1)
	else:
		# Normal click
		handle_left_click(world_pos)

func handle_drag_drop(start_grid: Vector2, end_grid: Vector2):
	"""Handle piece being dragged from start to end - MOVE ONLY"""
	if not grid_system.is_valid_position(end_grid):
		print("Invalid drop position")
		return
	
	if start_grid == end_grid:
		print("Dropped on same position")
		return
	
	# Check if move is adjacent
	var distance = start_grid.distance_to(end_grid)
	if distance > 1.5:  # Allow diagonal (sqrt(2) ≈ 1.41)
		print("Can only drag to adjacent squares")
		return
	
	print("Drag drop from ", start_grid, " to ", end_grid)
	
	# Only allow movement to empty squares - NO ATTACKS via drag
	if piece_manager.is_position_occupied(end_grid):
		print("Cannot drag to occupied square - use right-click for attacks")
		return
	
	# Perform move
	print("Drag move!")
	if piece_manager.move_piece(start_grid, end_grid):
		if game_manager:
			game_manager.use_action()

func handle_left_click(world_pos: Vector2):
	"""Handle left mouse click"""
	if not grid_system:
		return
	
	var grid_pos = grid_system.world_to_grid_pos(world_pos)
	
	if not grid_system.is_valid_position(grid_pos):
		return
	
	print("Left click at ", grid_pos, " in mode: ", current_mode)
	
	if current_mode == "MOVE":
		handle_move_click(grid_pos)
	elif current_mode == "ATTACK":
		handle_attack_click(grid_pos)
	
	left_click_processed.emit(grid_pos)

func handle_right_click(world_pos: Vector2):
	"""Handle right mouse click"""
	if not grid_system or not piece_manager:
		return
	
	var grid_pos = grid_system.world_to_grid_pos(world_pos)
	
	if not grid_system.is_valid_position(grid_pos):
		return
	
	print("Right click at ", grid_pos, " in mode: ", current_mode)
	
	# Right click on a piece to show attack options
	if piece_manager.is_position_occupied(grid_pos):
		var piece = piece_manager.get_piece_at_position(grid_pos)
		
		# Add safety checks
		if not piece:
			print("ERROR: piece is null at position ", grid_pos)
			return
		
		if not piece.has("team"):
			print("ERROR: piece has no team property at position ", grid_pos)
			return
		
		# Only allow right-clicking own pieces
		if piece.team == "player":
			piece_manager.select_piece(grid_pos)
			
			# Add safety check for UI manager and piece structure
			if ui_manager and piece.has("piece_node") and is_instance_valid(piece.piece_node):
				ui_manager.show_attack_options(piece)
			else:
				print("ERROR: Invalid piece structure or UI manager for attack options")
				return
			
			set_mode("ATTACK")
			print("Setting attack mode for piece at ", grid_pos)
		else:
			print("Cannot attack with enemy pieces!")
	else:
		# Right click on empty space - cancel any attack mode
		if current_mode == "ATTACK":
			print("Canceling attack mode - clicked empty space")
			set_mode("MOVE")
	
	right_click_processed.emit(grid_pos)

func handle_move_click(grid_pos: Vector2):
	"""Handle click in move mode"""
	if not piece_manager:
		return
	
	var selected_piece = piece_manager.get_selected_piece()
	var selected_position = piece_manager.get_selected_position()
	
	# If we have a selected piece and clicked an empty tile, move the piece
	if selected_piece != null and not piece_manager.is_position_occupied(grid_pos):
		if piece_manager.can_piece_move_to(selected_position, grid_pos):
			# Check if we can use an action
			if game_manager and not game_manager.can_perform_action("player"):
				print("No actions left this turn!")
				return
			
			piece_manager.move_piece(selected_position, grid_pos)
			
			# Use an action
			if game_manager:
				game_manager.use_action()
			
			piece_manager.clear_selection()
		else:
			print("Cannot move there!")
	# If clicked on a piece, show info briefly instead of persistent selection
	elif piece_manager.is_position_occupied(grid_pos):
		var piece = piece_manager.get_piece_at_position(grid_pos)
		if piece.team == "player":
			print("Player piece info: ", piece.piece_node.piece_type, " HP:", piece.piece_node.current_health, "/", piece.piece_node.max_health, " ATK:", piece.piece_node.attack_power)
		else:
			print("Enemy piece: ", piece.piece_node.piece_type, " HP:", piece.piece_node.current_health, "/", piece.piece_node.max_health)
	# If clicked empty tile, clear any lingering selection
	else:
		print("Empty space at ", grid_pos)
		piece_manager.clear_selection()

func handle_attack_click(grid_pos: Vector2):
	"""Handle click in attack mode"""
	if not piece_manager:
		return
	
	var selected_piece = piece_manager.get_selected_piece()
	var selected_position = piece_manager.get_selected_position()
	
	if not selected_piece or not selected_piece.has("selected_attack"):
		return
	
	# Check if clicking on a valid attack target
	if piece_manager.is_position_occupied(grid_pos):
		var target = piece_manager.get_piece_at_position(grid_pos)
		if target.team != selected_piece.team:
			# Check if target is adjacent (including diagonals)
			if grid_system:
				var distance = grid_system.get_manhattan_distance(grid_pos, selected_position)
				var euclidean_distance = grid_system.get_distance(grid_pos, selected_position)
				
				# Allow both adjacent and diagonal attacks
				if distance <= 2 and euclidean_distance <= 1.5:  # Adjacent or diagonal
					# Check if we can use an action
					if game_manager and not game_manager.can_perform_action("player"):
						print("No actions left this turn!")
						return
					
					# Emit signal for attack processing (handled by main game board)
					if parent_node and parent_node.has_method("perform_attack"):
						parent_node.perform_attack(selected_position, grid_pos, selected_piece.selected_attack)
					
					# Action usage is handled by perform_attack() in GameBoard
					
					piece_manager.clear_selection()
					set_mode("MOVE")
				else:
					print("Target too far away!")
		else:
			print("Cannot attack friendly units!")
	else:
		# Clicked empty space, cancel attack
		set_mode("MOVE")

func set_mode(new_mode: String):
	"""Set the current input mode"""
	if current_mode != new_mode:
		print("Mode changed from ", current_mode, " to ", new_mode)
		current_mode = new_mode
		
		if ui_manager:
			ui_manager.clear_attack_highlights()
			
			if new_mode == "MOVE":
				ui_manager.hide_attack_ui()
				ui_manager.update_ui_info("Click pieces to select, then click empty tiles to move")
			elif new_mode == "ATTACK":
				var selected_piece = piece_manager.get_selected_piece() if piece_manager else null
				if selected_piece:
					ui_manager.show_attack_targets(piece_manager.get_selected_position(), selected_piece)
					ui_manager.update_ui_info("Click an enemy to attack")
		
		mode_changed.emit(new_mode)

func get_current_mode() -> String:
	"""Get the current input mode"""
	return current_mode

func can_perform_action(team: String) -> bool:
	"""Check if a team can perform actions (to be connected to game manager)"""
	if parent_node and parent_node.has_method("can_act_with_piece"):
		return parent_node.can_act_with_piece({"team": team})
	return true