# UIManager.gd
# UI Manager - Handles attack UI, highlighting, and visual feedback

class_name UIManager
extends Node

# Signals
signal end_run_to_shop_signal
signal shop_closed_signal
signal start_new_run_signal

const HIGHLIGHT_COLOR = Color(1.0, 1.0, 0.5, 0.7)
const SELECTED_COLOR = Color(0.3, 0.7, 1.0, 0.4)
const ATTACK_HIGHLIGHT_COLOR = Color(1.0, 0.3, 0.3, 0.6)

var attack_ui = null
var attack_highlights = []
var drag_highlights = []  # Store references to drag highlight ColorRects
var hover_highlights = []  # Store references to hover target highlights
var game_over_overlay = null  # Store reference to game over screen
var glyph_display = null  # Store reference to glyph display UI
var shop_overlay = null  # Store reference to shop UI

var parent_node = null
var grid_system = null
var glyph_manager = null  # Reference to glyph manager
var shop_manager = null  # Reference to shop manager
var data_loader = null   # Reference to data loader

func _init():
	pass

func set_parent_node(node: Node2D):
	"""Set reference to the parent node"""
	parent_node = node

func set_grid_system(grid):
	"""Set reference to the grid system"""
	grid_system = grid

func set_managers(glyph_mgr, shop_mgr, loader):
	"""Set references to the managers"""
	glyph_manager = glyph_mgr
	shop_manager = shop_mgr
	data_loader = loader

func create_attack_ui():
	"""Create the attack selection UI (initially hidden)"""
	if not parent_node:
		return
	
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
	var ui_node = parent_node.get_parent().get_node_or_null("UI")
	if ui_node:
		ui_node.call_deferred("add_child", attack_ui)
	else:
		parent_node.get_parent().call_deferred("add_child", attack_ui)

func create_glyph_display():
	"""Create the glyph display UI"""
	print("UIManager.create_glyph_display called")
	
	if not parent_node:
		print("ERROR: parent_node is null!")
		return
	
	# Find the UI node in the same way as high score display
	var scene_root = parent_node.get_tree().current_scene
	var ui_node = null
	
	if scene_root and scene_root.has_node("UI"):
		ui_node = scene_root.get_node("UI")
		print("Found UI node in scene")
	elif parent_node.get_parent() and parent_node.get_parent().has_node("UI"):
		ui_node = parent_node.get_parent().get_node("UI")
		print("Found UI node in parent")
	
	if not ui_node:
		print("WARNING: Could not find UI node for glyph display")
		return
	
	# Create the glyph display as a simple label, similar to high score
	glyph_display = Label.new()
	glyph_display.name = "GlyphDisplay"
	glyph_display.text = "Glyphs: 0"
	glyph_display.position = Vector2(10, 50)  # Below high score display
	glyph_display.size = Vector2(250, 60)
	
	# Style the label
	glyph_display.add_theme_font_size_override("font_size", 16)
	glyph_display.add_theme_color_override("font_color", Color.GOLD)
	
	ui_node.add_child(glyph_display)
	print("Added glyph display to UI node as Label")

func update_glyph_display(current_glyphs: int, stuck_glyphs: int = 0, stuck_level: int = 0):
	"""Update the glyph display with current and stuck glyph counts"""
	print("UIManager.update_glyph_display called: current=", current_glyphs, ", stuck=", stuck_glyphs, ", level=", stuck_level)
	
	if not glyph_display:
		print("ERROR: glyph_display is null!")
		return
	
	# Update the label text with both current and stuck glyphs
	var glyph_text = "Glyphs: " + str(current_glyphs)
	
	if stuck_glyphs > 0 and stuck_level > 0:
		glyph_text += "\nStuck at Level " + str(stuck_level) + ": " + str(stuck_glyphs) + " Glyphs"
	
	glyph_display.text = glyph_text
	print("Updated glyph display text to: ", glyph_text)

func show_glyph_reward_notification(glyph_count: int, enemy_type: String, grid_pos: Vector2):
	"""Show a notification when glyphs are awarded"""
	if not parent_node:
		return
	
	# Create glyph reward notification text
	var notification = Label.new()
	var glyph_text = "+" + str(glyph_count) + " Glyph"
	if glyph_count > 1:
		glyph_text += "s"
	
	if enemy_type == "King":
		notification.text = "KING: " + glyph_text + "!"
	else:
		notification.text = glyph_text + "!"
	
	notification.size = Vector2(150, 40)
	
	# Position near the defeated enemy
	if grid_system:
		var world_pos = grid_system.grid_to_world_pos(grid_pos)
		notification.position = world_pos + Vector2(-50, -100)  # Above the enemy
	else:
		notification.position = Vector2(400, 200)  # Fallback position
	
	# Style the notification
	notification.modulate = Color.GOLD
	notification.z_index = 5
	notification.add_theme_font_size_override("font_size", 16)
	
	parent_node.add_child(notification)
	
	# Animate the notification
	var tween = parent_node.create_tween()
	tween.parallel().tween_property(notification, "position:y", notification.position.y - 40, 2.0)
	# Fade out after 2 seconds
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 2.5).set_delay(1.5)
	tween.tween_callback(notification.queue_free)

func show_attack_options(piece_data):
	"""Show attack options for a selected piece"""
	if not attack_ui:
		print("ERROR: attack_ui is null")
		return
	
	if not piece_data:
		print("ERROR: piece_data is null")
		return
	
	if not piece_data.has("piece_node"):
		print("ERROR: piece_data has no piece_node property")
		return
	
	var piece_node = piece_data.piece_node
	
	if not is_instance_valid(piece_node):
		print("ERROR: piece_node is not valid")
		return
	
	if not piece_node.has_method("get_available_attacks"):
		print("ERROR: piece_node has no get_available_attacks method")
		return
	
	var attacks = piece_node.get_available_attacks()
	
	if not attacks:
		print("WARNING: piece has no available attacks")
		attacks = []
	
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
	cancel_button.pressed.connect(func(): hide_attack_ui())
	vbox.add_child(cancel_button)
	
	attack_ui.visible = true

func hide_attack_ui():
	"""Hide the attack UI"""
	if attack_ui:
		attack_ui.visible = false
	
	# Switch back to move mode through input handler
	if parent_node and parent_node.input_handler and parent_node.input_handler.has_method("set_mode"):
		parent_node.input_handler.set_mode("MOVE")

func execute_attack(attack_data):
	"""Execute an attack selection"""
	print("Attack selected: ", attack_data.name, " - Click target to attack")
	
	# Set the selected attack on the currently selected piece
	if parent_node and parent_node.has_method("get_selected_piece"):
		var selected_piece = parent_node.get_selected_piece()
		if selected_piece:
			# Set the attack type based on attack name
			var attack_type = "basic"
			if "Heavy" in attack_data.name:
				attack_type = "Heavy"
			elif "Quick" in attack_data.name:
				attack_type = "Quick"
			else:
				attack_type = "Basic"
			
			selected_piece["selected_attack"] = attack_type
			print("Set selected_attack to: ", attack_type, " on piece")
			
			# Hide the attack UI
			hide_attack_ui()
			
			# Switch to attack mode - call method on parent's input handler
			if parent_node.input_handler and parent_node.input_handler.has_method("set_mode"):
				print("Setting attack mode after selecting attack type")
				parent_node.input_handler.set_mode("ATTACK")

func show_attack_targets(attacker_pos: Vector2, selected_piece):
	"""Highlight valid attack targets"""
	clear_attack_highlights()
	
	if not grid_system or not parent_node:
		return
	
	# Highlight adjacent enemy pieces (including diagonals)
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),  # Cardinal directions
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)  # Diagonal directions
	]
	
	for delta in directions:
		var target_pos = attacker_pos + delta
		
		if grid_system.is_valid_position(target_pos):
			# Check if there's an enemy piece at this position
			if parent_node.has_method("get_piece_at_position"):
				var target_piece = parent_node.get_piece_at_position(target_pos)
				if target_piece and target_piece.team != selected_piece.team:
					highlight_attack_target(target_pos)

func highlight_attack_target(grid_pos: Vector2):
	"""Create attack target highlight"""
	if not grid_system or not parent_node:
		return
	
	var highlight = ColorRect.new()
	highlight.size = Vector2(80, 80)  # TILE_SIZE = 80
	highlight.position = grid_system.grid_to_world_pos(grid_pos)
	highlight.color = ATTACK_HIGHLIGHT_COLOR
	highlight.z_index = 1
	parent_node.add_child(highlight)
	attack_highlights.append(highlight)

func clear_attack_highlights():
	"""Clear all attack target highlights"""
	for highlight in attack_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	attack_highlights.clear()

func highlight_drag_position(grid_pos: Vector2):
	"""Create drag selection highlight"""
	if not grid_system or not parent_node:
		return
	
	var highlight = ColorRect.new()
	highlight.size = Vector2(80, 80)  # TILE_SIZE = 80
	highlight.position = grid_system.grid_to_world_pos(grid_pos)
	highlight.color = SELECTED_COLOR
	highlight.z_index = 1
	parent_node.add_child(highlight)
	drag_highlights.append(highlight)

func clear_drag_highlights():
	"""Clear all drag selection highlights"""
	for highlight in drag_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	drag_highlights.clear()

func highlight_hover_position(grid_pos: Vector2):
	"""Create hover target highlight with different color"""
	if not grid_system or not parent_node:
		return
	
	var highlight = ColorRect.new()
	highlight.size = Vector2(80, 80)  # TILE_SIZE = 80
	highlight.position = grid_system.grid_to_world_pos(grid_pos)
	highlight.color = HIGHLIGHT_COLOR  # Use yellow highlight for hover target
	highlight.z_index = 1
	parent_node.add_child(highlight)
	hover_highlights.append(highlight)

func clear_hover_highlights():
	"""Clear all hover target highlights"""
	for highlight in hover_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	hover_highlights.clear()

func clear_attack_ui():
	"""Clear attack UI (alias for hide_attack_ui for compatibility)"""
	hide_attack_ui()
	clear_attack_highlights()

func create_attack_effect(grid_pos: Vector2):
	"""Create visual effect for attacks"""
	if not grid_system or not parent_node:
		return
	
	# Simple visual effect for attacks
	var effect = ColorRect.new()
	effect.size = Vector2(80, 80)  # TILE_SIZE = 80
	effect.position = grid_system.grid_to_world_pos(grid_pos)
	effect.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow flash
	effect.z_index = 3
	parent_node.add_child(effect)
	
	var tween = parent_node.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func show_attack_notification(attacker_team: String, attack_type: String, damage: int, target_pos: Vector2):
	"""Show a notification when an attack happens"""
	if not parent_node:
		return
	
	# Create attack notification text
	var notification = Label.new()
	var attack_name = attack_type.capitalize()
	notification.text = attacker_team.capitalize() + " " + attack_name + " Attack!\n" + str(damage) + " damage"
	notification.size = Vector2(200, 60)
	
	# Position near the target
	if grid_system:
		var world_pos = grid_system.grid_to_world_pos(target_pos)
		notification.position = world_pos + Vector2(-50, -80)  # Above the target
	else:
		notification.position = Vector2(400, 100)  # Fallback position
	
	# Style the notification
	notification.modulate = Color.YELLOW if attacker_team == "enemy" else Color.CYAN
	notification.z_index = 5
	notification.add_theme_font_size_override("font_size", 16)
	
	parent_node.add_child(notification)
	
	# Animate the notification
	var tween = parent_node.create_tween()
	tween.parallel().tween_property(notification, "position:y", notification.position.y - 30, 1.5)
	# Fade out after 1.5 seconds
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(notification.queue_free)

func update_ui_info(text: String):
	"""Update the UI info text"""
	if not parent_node:
		return
	
	# Try to find the info label
	var info_label = parent_node.get_parent().get_node_or_null("UI/GameInfo")
	if info_label:
		info_label.text = "Grid Battle Game\\n" + text
	else:
		print(text)  # Fallback to console if UI not found

func update_turn_display(game_manager = null):
	"""Update the turn display UI"""
	if not parent_node:
		return
	
	var turn_label = parent_node.get_node_or_null("../UI/TurnDisplay/TurnLabel")
	var player_indicator = parent_node.get_node_or_null("../UI/PlayerIndicator")
	var enemy_indicator = parent_node.get_node_or_null("../UI/EnemyIndicator")
	
	if not game_manager or not turn_label:
		return
	
	var current_team = game_manager.get_current_team()
	var game_info = game_manager.get_game_info()
	turn_label.text = game_info
	
	# Update team indicator colors
	if player_indicator and enemy_indicator:
		if current_team == "player":
			player_indicator.modulate = Color.WHITE
			enemy_indicator.modulate = Color(0.5, 0.5, 0.5)
		else:
			player_indicator.modulate = Color(0.5, 0.5, 0.5)
			enemy_indicator.modulate = Color.WHITE

func show_game_over(winner: String, reason: String = "elimination"):
	"""Show game over screen"""
	if not parent_node:
		return
	
	# Clear any existing game over screen
	clear_game_over()
	
	# Get current army info if available
	var army_info = ""
	var game_board = parent_node
	if game_board and game_board.has_method("get_army_manager"):
		var army_manager = game_board.get_army_manager()
		if army_manager:
			var current_army = army_manager.get_current_army()
			if current_army:
				army_info = "\nLevel " + str(current_army.level) + ": " + current_army.army_name
	
	# Create game over overlay
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0, 0, 0, 0.8)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.z_index = 10
	
	# Create game over panel
	var panel = Panel.new()
	panel.size = Vector2(400, 200)
	panel.position = Vector2(200, 150)
	panel.z_index = 11
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(360, 160)
	
	# Title
	var title = Label.new()
	title.text = "GAME OVER!"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Winner announcement
	var winner_label = Label.new()
	if winner.to_lower() == "player":
		if reason == "king_death":
			winner_label.text = "VICTORY!\nYou defeated the enemy King!" + army_info + "\n\nNext: Harder enemies await!"
		else:
			winner_label.text = "VICTORY!\nYou defeated all enemies!" + army_info + "\n\nNext: Harder enemies await!"
		winner_label.modulate = Color.GREEN
	else:
		if reason == "king_death":
			winner_label.text = "DEFEAT\nYour King has fallen!" + army_info
		else:
			winner_label.text = "DEFEAT\nAll your pieces were destroyed!" + army_info
		winner_label.modulate = Color.RED
	
	winner_label.add_theme_font_size_override("font_size", 18)
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(winner_label)
	
	# Restart button
	var restart_button = Button.new()
	# Set button text based on winner
	if winner.to_lower() == "player":
		restart_button.text = "Continue"  # Advancing to next army level
		
		# Add shop button for victories
		var shop_button = Button.new()
		shop_button.text = "End Run & Shop"
		shop_button.size = Vector2(150, 40)
		shop_button.pressed.connect(func():
			clear_game_over()
			end_run_to_shop()
		)
		vbox.add_child(shop_button)
		
	else:
		restart_button.text = "Play Again"  # Restarting at level 1
	restart_button.size = Vector2(150, 40)
	var game_winner = winner  # Capture winner in local scope
	restart_button.pressed.connect(func(): 
		clear_game_over()  # Clear the game over screen
		restart_battle(game_winner)   # Pass winner info for army reset decision
	)
	vbox.add_child(restart_button)
	
	panel.add_child(vbox)
	game_over_overlay.add_child(panel)
	
	# Add to scene
	parent_node.get_parent().add_child(game_over_overlay)

func clear_game_over():
	"""Clear any existing game over screen"""
	if game_over_overlay and is_instance_valid(game_over_overlay):
		game_over_overlay.queue_free()
		game_over_overlay = null

func restart_battle(winner: String = ""):
	"""Restart the battle while preserving army progression"""
	if parent_node and parent_node.has_method("restart_battle"):
		parent_node.restart_battle(winner)
	else:
		# Fallback to scene reload if restart_battle doesn't exist
		get_tree().reload_current_scene()

func show_error_message(message: String):
	"""Show a temporary error message"""
	if not parent_node:
		return
	
	# Create temporary error label
	var error_label = Label.new()
	error_label.text = message
	error_label.add_theme_font_size_override("font_size", 20)
	error_label.modulate = Color.RED
	error_label.position = Vector2(50, 50)
	error_label.z_index = 20
	
	parent_node.add_child(error_label)
	
	# Remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(error_label):
		error_label.queue_free()

func show_piece_info(grid_pos: Vector2):
	"""Show information about a piece at the given position"""
	if not parent_node or not parent_node.has_method("get_piece_manager"):
		return
	
	var piece_manager = parent_node.piece_manager
	if not piece_manager or not piece_manager.is_position_occupied(grid_pos):
		return
	
	var piece_data = piece_manager.get_piece_at_position(grid_pos)
	if not piece_data or not piece_data.has("piece_node"):
		return
	
	var piece = piece_data.piece_node
	var info_text = piece.piece_type.capitalize() + " (" + piece.team + ")"
	info_text += "\nHP: " + str(piece.current_health) + "/" + str(piece.max_health)
	info_text += "\nAttack: " + str(piece.attack_power)
	info_text += "\nDefense: " + str(piece.defense)
	
	# Create temporary info panel
	var info_panel = Panel.new()
	info_panel.size = Vector2(200, 120)
	info_panel.position = Vector2(100, 100)
	info_panel.z_index = 15
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(10, 10)
	info_label.size = Vector2(180, 100)
	info_label.add_theme_font_size_override("font_size", 14)
	
	info_panel.add_child(info_label)
	parent_node.add_child(info_panel)
	
	# Remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(info_panel):
		info_panel.queue_free()

# Shop-related functions
func end_run_to_shop():
	"""End run and open shop"""
	end_run_to_shop_signal.emit()

func clear_any_overlays():
	"""Clear any active overlays"""
	if game_over_overlay:
		game_over_overlay.queue_free()
		game_over_overlay = null
	if shop_overlay:
		shop_overlay.queue_free()
		shop_overlay = null

func create_overlay():
	"""Create a basic overlay structure for dialogs"""
	var overlay_data = {}
	
	# Create background overlay
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.z_index = 10
	parent_node.add_child(background)
	overlay_data.background = background
	
	# Create main panel
	var panel = Panel.new()
	panel.size = Vector2(500, 400)
	panel.position = Vector2(150, 100)
	panel.z_index = 11
	background.add_child(panel)
	overlay_data.panel = panel
	
	# Create content container
	var vbox_container = VBoxContainer.new()
	vbox_container.position = Vector2(20, 20)
	vbox_container.size = Vector2(460, 360)
	panel.add_child(vbox_container)
	overlay_data.vbox_container = vbox_container
	
	return overlay_data

func show_shop():
	"""Display the shop interface"""
	clear_any_overlays()
	
	var overlay_data = create_overlay()
	shop_overlay = overlay_data.background
	
	# Shop title
	var title = Label.new()
	title.text = "Mystic Shop"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_data.vbox_container.add_child(title)
	
	# Get current glyphs
	var current_glyphs = glyph_manager.get_current_glyphs()
	var glyphs_label = Label.new()
	glyphs_label.text = "Glyphs: " + str(current_glyphs)
	glyphs_label.add_theme_font_size_override("font_size", 16)
	glyphs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_data.vbox_container.add_child(glyphs_label)
	
	# Add separator
	overlay_data.vbox_container.add_child(HSeparator.new())
	
	# Shop items container
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(400, 300)
	var items_vbox = VBoxContainer.new()
	scroll_container.add_child(items_vbox)
	overlay_data.vbox_container.add_child(scroll_container)
	
	# Get shop items
	var shop_items = shop_manager.get_shop_items()
	
	for item_data in shop_items:
		if item_data:
			var item_container = create_shop_item_display(item_data, current_glyphs)
			items_vbox.add_child(item_container)
	
	# Buttons container
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Start New Run button
	var new_run_button = Button.new()
	new_run_button.text = "Start New Run"
	new_run_button.size = Vector2(140, 40)
	new_run_button.pressed.connect(func():
		start_new_run()
	)
	buttons_container.add_child(new_run_button)
	
	overlay_data.vbox_container.add_child(buttons_container)

func create_shop_item_display(item_data: Dictionary, current_glyphs: int) -> Control:
	"""Create a display for a single shop item"""
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(350, 50)
	
	# Item info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Item name with rarity color
	var name_label = Label.new()
	name_label.text = item_data.name
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Set color based on rarity
	var rarity_color = get_rarity_color(item_data.rarity)
	name_label.add_theme_color_override("font_color", rarity_color)
	
	info_vbox.add_child(name_label)
	
	# Item description
	var desc_label = Label.new()
	desc_label.text = item_data.get("effect", "No description available")
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)
	
	item_container.add_child(info_vbox)
	
	# Cost and purchase button container
	var purchase_vbox = VBoxContainer.new()
	
	# Cost label
	var cost_label = Label.new()
	cost_label.text = str(item_data.cost) + " Glyphs"
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purchase_vbox.add_child(cost_label)
	
	# Purchase button
	var purchase_button = Button.new()
	purchase_button.text = "Buy"
	purchase_button.size = Vector2(60, 25)
	
	# Check if affordable
	var can_afford = current_glyphs >= item_data.cost
	purchase_button.disabled = not can_afford
	
	if can_afford:
		purchase_button.pressed.connect(func():
			purchase_item(item_data.get("id", "unknown"))
		)
	
	purchase_vbox.add_child(purchase_button)
	
	item_container.add_child(purchase_vbox)
	
	return item_container

func get_rarity_color(rarity: String) -> Color:
	"""Get color for item rarity"""
	match rarity.to_lower():
		"common":
			return Color.WHITE
		"uncommon":
			return Color.CYAN
		"rare":
			return Color.YELLOW
		"epic":
			return Color.MAGENTA
		"legendary":
			return Color.ORANGE
		_:
			return Color.WHITE

func purchase_item(item_id: String):
	"""Attempt to purchase an item"""
	var current_glyphs = glyph_manager.get_current_glyphs()
	var result = shop_manager.purchase_item(item_id, current_glyphs)
	if result.get("success", false):
		print("Purchase successful!")
		# Refresh shop display
		show_shop()
	else:
		print("Failed to purchase item: ", item_id, " - ", result.get("error", "Unknown error"))

func close_shop():
	"""Close the shop interface"""
	if shop_overlay:
		shop_overlay.queue_free()
		shop_overlay = null
		
	# Emit signal to return to main menu or end run
	shop_closed_signal.emit()

func start_new_run():
	"""Start a new run from the shop"""
	if shop_overlay:
		shop_overlay.queue_free()
		shop_overlay = null
	
	# Emit signal to start new run
	start_new_run_signal.emit()