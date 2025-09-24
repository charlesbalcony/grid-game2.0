# UIManager.gd
# UI Manager - Handles attack UI, highlighting, and visual feedback

class_name UIManager
extends Node

const HIGHLIGHT_COLOR = Color(1.0, 1.0, 0.5, 0.7)
const SELECTED_COLOR = Color(0.3, 0.7, 1.0, 0.4)
const ATTACK_HIGHLIGHT_COLOR = Color(1.0, 0.3, 0.3, 0.6)

var attack_ui = null
var attack_highlights = []

var parent_node = null
var grid_system = null

func _init():
	pass

func set_parent_node(node: Node2D):
	"""Set reference to the parent node"""
	parent_node = node

func set_grid_system(grid):
	"""Set reference to the grid system"""
	pass

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

func show_attack_options(piece_data):
	"""Show attack options for a selected piece"""
	if not attack_ui:
		return
	
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
			
			# Hide the attack UI
			hide_attack_ui()
			
			# Switch to attack mode - call method on parent's input handler
			if parent_node.input_handler and parent_node.input_handler.has_method("set_mode"):
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