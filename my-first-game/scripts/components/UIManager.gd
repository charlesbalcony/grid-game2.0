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
	
	# Emit signal to switch back to move mode
	if parent_node and parent_node.has_method("set_mode"):
		parent_node.set_mode("MOVE")

func execute_attack(attack_data):
	"""Execute an attack selection"""
	if parent_node and parent_node.has_method("on_attack_selected"):
		parent_node.on_attack_selected(attack_data)
	
	print("Attack selected: ", attack_data.name, " - Click target to attack")

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