extends Node2D

# Grid Battle Game - Main Board Controller with Combat System

const GRID_SIZE = 8
const TILE_SIZE = 80
const BOARD_OFFSET = Vector2(40, 40)

# Colors for the grid
const LIGHT_TILE_COLOR = Color(0.9, 0.9, 0.8)
const DARK_TILE_COLOR = Color(0.6, 0.4, 0.2)
const HIGHLIGHT_COLOR = Color(1.0, 1.0, 0.5, 0.7)
const SELECTED_COLOR = Color(0.3, 0.7, 1.0, 0.4)
const ATTACK_HIGHLIGHT_COLOR = Color(1.0, 0.3, 0.3, 0.6)

# Piece colors
const PLAYER_COLOR = Color(0.2, 0.6, 1.0)
const ENEMY_COLOR = Color(1.0, 0.3, 0.2)

# Game state
var grid_tiles = []
var pieces = {}
var selected_piece = null
var selected_position = Vector2(-1, -1)
var selection_highlight = null
var current_mode = "MOVE"  # "MOVE" or "ATTACK"
var attack_highlights = []

# UI references
var attack_ui = null

func _ready():
	create_grid()
	setup_pieces()
	create_attack_ui()
	print("Grid Battle Game Ready!")
	print("Left click: Select/Move pieces")
	print("Right click: Attack mode")

func create_grid():
	# Create the visual grid
	for row in range(GRID_SIZE):
		var tile_row = []
		for col in range(GRID_SIZE):
			var tile = create_tile(row, col)
			add_child(tile)
			tile_row.append(tile)
		grid_tiles.append(tile_row)

func create_tile(row: int, col: int) -> ColorRect:
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.position = Vector2(col * TILE_SIZE + BOARD_OFFSET.x, row * TILE_SIZE + BOARD_OFFSET.y)
	
	# Checkerboard pattern
	if (row + col) % 2 == 0:
		tile.color = LIGHT_TILE_COLOR
	else:
		tile.color = DARK_TILE_COLOR
	
	return tile

func setup_pieces():
	# Setup player pieces (blue) on rows 0 and 1
	for row in range(2):
		for col in range(GRID_SIZE):
			create_piece(Vector2(col, row), PLAYER_COLOR, "player")
	
	# Setup enemy pieces (red) on rows 6 and 7
	for row in range(6, 8):
		for col in range(GRID_SIZE):
			create_piece(Vector2(col, row), ENEMY_COLOR, "enemy")

func create_piece(grid_pos: Vector2, color: Color, team: String):
	# Load the piece scene
	var piece_scene = preload("res://scenes/GamePiece.tscn")
	var piece_instance = piece_scene.instantiate()
	
	# Set piece properties
	piece_instance.team = team
	piece_instance.position = grid_to_world_pos(grid_pos) + Vector2(TILE_SIZE/2, TILE_SIZE/2)
	piece_instance.set_grid_position(grid_pos)
	
	# Connect signals
	piece_instance.piece_died.connect(_on_piece_died)
	piece_instance.piece_damaged.connect(_on_piece_damaged)
	
	add_child(piece_instance)
	
	# Store piece data
	pieces[grid_pos] = {
		"piece_node": piece_instance,
		"team": team,
		"color": color
	}

func create_attack_ui():
	# Create attack selection UI (initially hidden)
	attack_ui = Control.new()
	attack_ui.visible = false
	
	var panel = Panel.new()
	panel.size = Vector2(200, 150)
	panel.position = Vector2(600, 50)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	
	var label = Label.new()
	label.text = "Select Attack:"
	vbox.add_child(label)
	
	# We'll add attack buttons dynamically when a piece is selected
	panel.add_child(vbox)
	attack_ui.add_child(panel)
	
	# Try to find UI node, if not found, add to parent
	var ui_node = get_parent().get_node_or_null("UI")
	if ui_node:
		ui_node.call_deferred("add_child", attack_ui)
	else:
		get_parent().call_deferred("add_child", attack_ui)

func show_attack_options(piece_data):
	var piece_node = piece_data.piece_node
	var attacks = piece_node.get_available_attacks()
	
	# Clear previous buttons
	var vbox = attack_ui.get_child(0).get_child(0)
	for child in vbox.get_children():
		if child is Button:
			child.queue_free()
	
	# Add attack buttons
	for i in range(attacks.size()):
		var attack = attacks[i]
		var button = Button.new()
		button.text = attack.name + " (" + str(attack.damage) + " dmg)"
		button.pressed.connect(func(): execute_attack(attack))
		vbox.add_child(button)
	
	# Add cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): set_mode("MOVE"))
	vbox.add_child(cancel_button)
	
	attack_ui.visible = true

func set_mode(new_mode: String):
	current_mode = new_mode
	clear_attack_highlights()
	
	if new_mode == "MOVE":
		attack_ui.visible = false
		update_ui_info("Click pieces to select, then click empty tiles to move")
	elif new_mode == "ATTACK":
		if selected_piece:
			show_attack_targets()
			update_ui_info("Click an enemy to attack")

func grid_to_world_pos(grid_pos: Vector2) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + BOARD_OFFSET.x, grid_pos.y * TILE_SIZE + BOARD_OFFSET.y)

func world_to_grid_pos(world_pos: Vector2) -> Vector2:
	var adjusted_pos = world_pos - BOARD_OFFSET
	return Vector2(floor(adjusted_pos.x / TILE_SIZE), floor(adjusted_pos.y / TILE_SIZE))

func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func highlight_attack_target(grid_pos: Vector2):
	var highlight = ColorRect.new()
	highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight.position = grid_to_world_pos(grid_pos)
	highlight.color = ATTACK_HIGHLIGHT_COLOR
	highlight.z_index = 1
	add_child(highlight)
	attack_highlights.append(highlight)

func clear_attack_highlights():
	for highlight in attack_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	attack_highlights.clear()

func execute_attack(attack_data):
	if not selected_piece or current_mode != "ATTACK":
		return
	
	print("Attack selected: ", attack_data.name, " - Click target to attack")
	# Store the selected attack for when user clicks a target
	selected_piece.selected_attack = attack_data
	set_mode("ATTACK")

func perform_attack(attacker_pos: Vector2, target_pos: Vector2, attack_data):
	var attacker = pieces[attacker_pos].piece_node
	var target = pieces[target_pos].piece_node
	
	print(attacker.piece_type, " attacks ", target.piece_type, " with ", attack_data.name)
	
	# Calculate damage
	var base_damage = attack_data.damage + attacker.attack_power
	target.take_damage(base_damage)
	
	# Visual effect
	create_attack_effect(target_pos)
	
	set_mode("MOVE")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Convert screen coordinates to world coordinates
		var world_pos = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(world_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(world_pos)

func handle_left_click(world_pos: Vector2):
	var grid_pos = world_to_grid_pos(world_pos)
	
	if not is_valid_position(grid_pos):
		return
	
	if current_mode == "MOVE":
		handle_move_click(grid_pos)
	elif current_mode == "ATTACK":
		handle_attack_click(grid_pos)

func handle_right_click(world_pos: Vector2):
	var grid_pos = world_to_grid_pos(world_pos)
	
	if not is_valid_position(grid_pos):
		return
	
	# Right click to enter attack mode if a piece is selected
	if selected_piece and pieces.has(grid_pos) and pieces[grid_pos].team == selected_piece.team:
		select_piece(grid_pos)
		show_attack_options(selected_piece)
		set_mode("ATTACK")

func handle_move_click(grid_pos: Vector2):
	# If we have a selected piece and clicked an empty tile, move the piece
	if selected_piece != null and not pieces.has(grid_pos):
		move_piece(selected_position, grid_pos)
		clear_selection()
	# If clicked on a piece, select it
	elif pieces.has(grid_pos):
		select_piece(grid_pos)
	# If clicked empty tile with no selection, do nothing
	else:
		clear_selection()

func handle_attack_click(grid_pos: Vector2):
	if not selected_piece or not selected_piece.has("selected_attack"):
		return
	
	# Check if clicking on a valid attack target
	if pieces.has(grid_pos):
		var target = pieces[grid_pos]
		if target.team != selected_piece.team:
			# Check if target is adjacent
			var distance = abs(grid_pos.x - selected_position.x) + abs(grid_pos.y - selected_position.y)
			if distance == 1:
				perform_attack(selected_position, grid_pos, selected_piece.selected_attack)
				clear_selection()
			else:
				print("Target too far away!")
		else:
			print("Cannot attack friendly units!")
	else:
		# Clicked empty space, cancel attack
		set_mode("MOVE")

func select_piece(grid_pos: Vector2):
	clear_selection()
	
	if pieces.has(grid_pos):
		selected_piece = pieces[grid_pos]
		selected_position = grid_pos
		create_selection_highlight(grid_pos)
		
		# Make the selected piece slightly brighter
		var piece_node = selected_piece.piece_node
		piece_node.set_selected(true)
		
		print("Selected ", piece_node.piece_type, " at: ", grid_pos, " (HP: ", piece_node.current_health, "/", piece_node.max_health, ")")

func move_piece(from_pos: Vector2, to_pos: Vector2):
	if pieces.has(from_pos) and not pieces.has(to_pos):
		var piece_data = pieces[from_pos]
		var piece_node = piece_data.piece_node
		
		# Move the piece node
		piece_node.position = grid_to_world_pos(to_pos) + Vector2(TILE_SIZE/2, TILE_SIZE/2)
		piece_node.set_grid_position(to_pos)
		
		# Update the pieces dictionary
		pieces[to_pos] = piece_data
		pieces.erase(from_pos)
		
		print("Moved ", piece_node.piece_type, " from ", from_pos, " to ", to_pos)

func create_attack_effect(grid_pos: Vector2):
	# Simple visual effect for attacks
	var effect = ColorRect.new()
	effect.size = Vector2(TILE_SIZE, TILE_SIZE)
	effect.position = grid_to_world_pos(grid_pos)
	effect.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow flash
	effect.z_index = 3
	add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func _on_piece_died(piece):
	# Remove piece from grid when it dies
	for pos in pieces.keys():
		if pieces[pos].piece_node == piece:
			pieces.erase(pos)
			break
	
	print("A ", piece.piece_type, " has been defeated!")

func _on_piece_damaged(piece, damage):
	print("Damage dealt: ", damage)

func create_selection_highlight(grid_pos: Vector2):
	if grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE:
		# Create a subtle border highlight instead of a full overlay
		selection_highlight = ColorRect.new()
		selection_highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
		selection_highlight.position = grid_to_world_pos(grid_pos)
		selection_highlight.color = Color.TRANSPARENT
		selection_highlight.z_index = 2
		
		# Add a glowing border effect
		var border_thickness = 3
		var border_color = Color(0.4, 0.8, 1.0, 0.8)
		
		# Top border
		var top_border = ColorRect.new()
		top_border.size = Vector2(TILE_SIZE, border_thickness)
		top_border.position = Vector2(0, 0)
		top_border.color = border_color
		selection_highlight.add_child(top_border)
		
		# Bottom border
		var bottom_border = ColorRect.new()
		bottom_border.size = Vector2(TILE_SIZE, border_thickness)
		bottom_border.position = Vector2(0, TILE_SIZE - border_thickness)
		bottom_border.color = border_color
		selection_highlight.add_child(bottom_border)
		
		# Left border
		var left_border = ColorRect.new()
		left_border.size = Vector2(border_thickness, TILE_SIZE)
		left_border.position = Vector2(0, 0)
		left_border.color = border_color
		selection_highlight.add_child(left_border)
		
		# Right border
		var right_border = ColorRect.new()
		right_border.size = Vector2(border_thickness, TILE_SIZE)
		right_border.position = Vector2(TILE_SIZE - border_thickness, 0)
		right_border.color = border_color
		selection_highlight.add_child(right_border)
		
		add_child(selection_highlight)

func update_ui_info(text: String):
	var info_label = get_parent().get_node_or_null("UI/GameInfo")
	if info_label:
		info_label.text = "Grid Battle Game\n" + text
	else:
		print(text)  # Fallback to console if UI not found

func show_attack_targets():
	clear_attack_highlights()
	if not selected_piece:
		return
	
	var attacker_pos = selected_position
	
	# Highlight adjacent enemy pieces
	for delta in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		var target_pos = attacker_pos + delta
		
		if is_valid_position(target_pos) and pieces.has(target_pos):
			var target_piece = pieces[target_pos]
			if target_piece.team != selected_piece.team:
				highlight_attack_target(target_pos)

func clear_selection():
	# Reset the piece appearance
	if selected_piece != null and selected_piece.has("piece_node"):
		selected_piece.piece_node.set_selected(false)
	
	selected_piece = null
	selected_position = Vector2(-1, -1)
	
	# Remove the selection highlight
	if selection_highlight != null:
		selection_highlight.queue_free()
		selection_highlight = null
	
	# Clear attack mode
	set_mode("MOVE")
	clear_attack_highlights()