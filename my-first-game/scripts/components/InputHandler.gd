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
	"""Process input events"""
	# Only allow input during player's turn
	if game_manager and game_manager.current_team != "player":
		return
		
	if event is InputEventMouseButton and event.pressed:
		# Convert screen coordinates to world coordinates
		var world_pos = parent_node.get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(world_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(world_pos)

func handle_left_click(world_pos: Vector2):
	"""Handle left mouse click"""
	if not grid_system:
		return
	
	var grid_pos = grid_system.world_to_grid_pos(world_pos)
	
	if not grid_system.is_valid_position(grid_pos):
		return
	
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
	
	# Right click to enter attack mode if a piece is selected
	var selected_piece = piece_manager.get_selected_piece()
	var selected_position = piece_manager.get_selected_position()
	
	if selected_piece and piece_manager.is_position_occupied(grid_pos) and piece_manager.get_piece_at_position(grid_pos).team == selected_piece.team:
		piece_manager.select_piece(grid_pos)
		if ui_manager:
			ui_manager.show_attack_options(selected_piece)
		set_mode("ATTACK")
	
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
	# If clicked on a piece, select it
	elif piece_manager.is_position_occupied(grid_pos):
		var piece = piece_manager.get_piece_at_position(grid_pos)
		# Only allow selecting own pieces
		if piece.team == "player":
			piece_manager.select_piece(grid_pos)
		else:
			print("Cannot select enemy pieces!")
	# If clicked empty tile with no selection, do nothing
	else:
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
					
					# Use an action
					if game_manager:
						game_manager.use_action()
					
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