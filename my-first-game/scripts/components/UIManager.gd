# UIManager.gd
# UI Manager - Handles attack UI, highlighting, and visual feedback

class_name UIManager
extends Node

# Signals
signal end_run_to_shop_signal
signal shop_closed_signal
signal start_new_run_signal
signal loadout_complete_signal

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
var loadout_overlay = null  # Store reference to loadout UI

var parent_node = null
var grid_system = null
var glyph_manager = null  # Reference to glyph manager
var shop_manager = null  # Reference to shop manager
var data_loader = null   # Reference to data loader
var loadout_manager = null  # Reference to loadout manager

# Input blocking for modal overlays
var is_blocking_input = false

func _init():
	pass

func _unhandled_input(event):
	"""Block all unhandled input when modal overlays are active"""
	if is_blocking_input:
		if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey:
			get_viewport().set_input_as_handled()
			# Removed debug print - was causing massive slowdown on mouse motion

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

func set_loadout_manager(loadout_mgr):
	"""Set reference to the loadout manager"""
	loadout_manager = loadout_mgr

func reset_input_blocking():
	"""Force reset input blocking - for debugging stuck input"""
	is_blocking_input = false
	print("UIManager: FORCE RESET input blocking")
	
	# Re-enable game input - try multiple approaches
	if parent_node:
		# Method 1: Direct reference to input handler
		if parent_node.has_method("get_node"):
			var input_handler = parent_node.get_node_or_null("InputHandler")
			if input_handler and input_handler.has_method("set_input_enabled"):
				input_handler.set_input_enabled(true)
				print("UIManager: FORCE RE-ENABLED input via InputHandler")
		
		# Method 2: Try to find input handler by searching children
		for child in parent_node.get_children():
			if child.get_script() and child.get_script().get_global_name() == "InputHandler":
				if child.has_method("set_input_enabled"):
					child.set_input_enabled(true)
					print("UIManager: FORCE RE-ENABLED input via child search")
				break

func create_attack_ui():
	"""Create the attack selection UI (initially hidden)"""
	if not parent_node:
		return
	
	attack_ui = Control.new()
	attack_ui.visible = false
	attack_ui.size = Vector2(get_viewport().size)  # Convert Vector2i to Vector2
	
	var panel = Panel.new()
	panel.size = Vector2(300, 250)  # Made larger to accommodate item lists
	# Center the panel on screen
	panel.position = (Vector2(get_viewport().size) - panel.size) / 2  # Convert Vector2i to Vector2
	panel.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.3, 0.9))
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(panel.size.x - 20, panel.size.y - 20)  # Leave margins
	vbox.add_theme_constant_override("separation", 5)
	
	var label = Label.new()
	label.text = "Select Attack:"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.CYAN)
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
	
	# Clear previous buttons and items completely
	if not attack_ui or attack_ui.get_child_count() == 0:
		print("ERROR: attack_ui not properly initialized")
		return
	
	var panel = attack_ui.get_child(0)  # Should be the Panel
	if not panel or panel.get_child_count() == 0:
		print("ERROR: attack_ui panel not found")
		return
	
	var vbox = panel.get_child(0)  # Should be the VBoxContainer
	if not vbox:
		print("ERROR: attack_ui vbox not found")
		return
	
	# Clear all children except the first label
	var children_to_remove = []
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if i > 0:  # Keep the first child (the "Select Attack:" label)
			children_to_remove.append(child)
	
	for child in children_to_remove:
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Add health display
	var health_container = HBoxContainer.new()
	health_container.add_theme_constant_override("separation", 5)
	
	# Health label
	var health_label = Label.new()
	health_label.text = "HP: " + str(piece_node.current_health) + "/" + str(piece_node.max_health)
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_container.add_child(health_label)
	
	# Health bar
	var health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(120, 12)
	health_bar_bg.color = Color(0.2, 0.2, 0.2)
	health_container.add_child(health_bar_bg)
	
	var health_bar = ColorRect.new()
	var health_percentage = float(piece_node.current_health) / float(piece_node.max_health)
	health_bar.size = Vector2(118 * health_percentage, 10)
	health_bar.position = Vector2(1, 1)
	
	# Color based on health percentage
	if health_percentage > 0.6:
		health_bar.color = Color(0.0, 0.8, 0.0)  # Green
	elif health_percentage > 0.3:
		health_bar.color = Color(0.8, 0.8, 0.0)  # Yellow
	else:
		health_bar.color = Color(0.8, 0.0, 0.0)  # Red
	
	health_bar_bg.add_child(health_bar)
	vbox.add_child(health_container)
	
	# Add separator after health
	var health_separator = HSeparator.new()
	vbox.add_child(health_separator)
	
	# Add attack buttons
	for i in range(attacks.size()):
		var attack = attacks[i]
		var button = Button.new()
		
		# Check if attack is on cooldown
		var cooldown_remaining = piece_node.get_attack_cooldown_remaining(attack)
		var on_cooldown = piece_node.is_attack_on_cooldown(attack)
		
		# Get attack properties (handle both Dictionary and AttackData object)
		var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "Unknown")
		var attack_damage = attack.damage if typeof(attack) == TYPE_OBJECT else attack.get("damage", 0)
		var attack_description = attack.description if typeof(attack) == TYPE_OBJECT else attack.get("description", "")
		var attack_cooldown_max = attack.cooldown_max if typeof(attack) == TYPE_OBJECT else attack.get("cooldown_max", 0)
		
		# Check if this attack is currently selected
		var attack_type = "basic"
		if "Heavy" in attack_name:
			attack_type = "Heavy"
		elif "Quick" in attack_name:
			attack_type = "Quick"
		else:
			attack_type = "Basic"
		
		var is_selected = piece_data.has("selected_attack") and piece_data.selected_attack == attack_type
		
		# Build button text with cooldown info and selection indicator
		var button_text = attack_name + " (" + str(attack_damage) + " dmg)"
		if is_selected:
			button_text = "► " + button_text + " ◄"
		
		if on_cooldown:
			button.text = button_text + " [CD: " + str(cooldown_remaining) + "]"
			button.disabled = true
			button.add_theme_color_override("font_color", Color.DARK_GRAY)
			button.tooltip_text = attack_description + "\nCooldown: " + str(cooldown_remaining) + " turn(s) remaining"
		else:
			button.text = button_text
			button.tooltip_text = attack_description
			if attack_cooldown_max > 0:
				button.tooltip_text += "\n(Cooldown: " + str(attack_cooldown_max) + " turns after use)"
			
			# Highlight selected attack
			if is_selected:
				button.add_theme_color_override("font_color", Color.YELLOW)
		
		# Pass both attack and button to execute_attack so we can update the UI
		button.pressed.connect(func(): execute_attack(attack, piece_data))
		vbox.add_child(button)
	
	# Add separator before items
	if vbox.get_children().size() > 0:
		var separator = HSeparator.new()
		vbox.add_child(separator)
	
	# Add equipped items section
	var items_label = Label.new()
	items_label.text = "Equipped Items:"
	items_label.add_theme_font_size_override("font_size", 12)
	items_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(items_label)
	
	# Get piece ID and all equipped items
	var piece_id = piece_data.get("piece_id", "")
	if piece_id != "" and loadout_manager:
		var all_equipped_items = loadout_manager.get_equipped_items(piece_id)  # Get all items
		
		if all_equipped_items.size() > 0:
			# Group items by slot type for better organization
			var items_by_slot = {}
			for item_id in all_equipped_items:
				var item_data = data_loader.get_item_by_id(item_id) if data_loader else null
				if item_data:
					var slot_type = item_data.get("type", "unknown")
					if not items_by_slot.has(slot_type):
						items_by_slot[slot_type] = []
					items_by_slot[slot_type].append({item_id = item_id, item_data = item_data})
			
			# Display items grouped by slot type
			var slot_order = ["permanent", "run", "level", "use"]
			for slot_type in slot_order:
				if items_by_slot.has(slot_type):
					# Add slot type header
					var slot_header = Label.new()
					var slot_name = slot_type.capitalize() + " Items:"
					slot_header.text = slot_name
					slot_header.add_theme_font_size_override("font_size", 10)
					match slot_type:
						"permanent":
							slot_header.add_theme_color_override("font_color", Color.GOLD)
						"run":
							slot_header.add_theme_color_override("font_color", Color.LIGHT_BLUE)
						"level":
							slot_header.add_theme_color_override("font_color", Color.YELLOW)
						"use":
							slot_header.add_theme_color_override("font_color", Color.LIGHT_GREEN)
					vbox.add_child(slot_header)
					
					# Add items in this slot
					for item_info in items_by_slot[slot_type]:
						var item_id = item_info.item_id
						var item_data = item_info.item_data
						
						if slot_type == "use":
							# Use items get clickable buttons
							var item_button = Button.new()
							item_button.text = "Use: " + item_data.name
							item_button.add_theme_font_size_override("font_size", 10)
							
							# Create item description tooltip or label
							var item_container = VBoxContainer.new()
							item_container.add_child(item_button)
							
							var item_desc = Label.new()
							item_desc.text = item_data.get("description", "No description")
							item_desc.add_theme_font_size_override("font_size", 8)
							item_desc.modulate = Color(0.8, 0.8, 0.8)
							item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
							item_container.add_child(item_desc)
							
							# Connect button to use item
							item_button.pressed.connect(func(): use_item_in_combat(piece_id, item_id, item_data))
							
							vbox.add_child(item_container)
						else:
							# Non-use items are displayed as info labels
							var item_container = VBoxContainer.new()
							
							var item_name = Label.new()
							item_name.text = "• " + item_data.name
							item_name.add_theme_font_size_override("font_size", 10)
							item_name.add_theme_color_override("font_color", Color.WHITE)
							item_container.add_child(item_name)
							
							var item_desc = Label.new()
							item_desc.text = "  " + item_data.get("effect", item_data.get("description", "No description"))
							item_desc.add_theme_font_size_override("font_size", 8)
							item_desc.modulate = Color(0.8, 0.8, 0.8)
							item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
							item_container.add_child(item_desc)
							
							vbox.add_child(item_container)
		else:
			var no_items_label = Label.new()
			no_items_label.text = "No items equipped"
			no_items_label.add_theme_font_size_override("font_size", 10)
			no_items_label.modulate = Color(0.6, 0.6, 0.6)
			vbox.add_child(no_items_label)
	
	# Add cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): hide_attack_ui())
	vbox.add_child(cancel_button)
	
	# Auto-select the first available attack (not on cooldown)
	if attacks.size() > 0:
		var selected_attack = null
		for attack in attacks:
			if not piece_node.is_attack_on_cooldown(attack):
				selected_attack = attack
				break
		
		# If all attacks are on cooldown, select the first one anyway (but it will be disabled)
		if selected_attack == null and attacks.size() > 0:
			selected_attack = attacks[0]
		
		# Set the default selected attack
		if selected_attack:
			var attack_type = "basic"
			var attack_name = selected_attack.name if typeof(selected_attack) == TYPE_OBJECT else selected_attack.get("name", "")
			if "Heavy" in attack_name:
				attack_type = "Heavy"
			elif "Quick" in attack_name:
				attack_type = "Quick"
			else:
				attack_type = "Basic"
			
			piece_data["selected_attack"] = attack_type
			print("Auto-selected attack: ", attack_type)
	
	# Make the attack UI visible!
	attack_ui.visible = true
	print("Attack UI shown for piece: ", piece_node.piece_type)

func use_item_in_combat(piece_id: String, item_id: String, item_data: Dictionary):
	"""Use a consumable item during combat"""
	if not loadout_manager:
		print("No loadout manager available")
		return
	
	# Consume the item (remove from loadout)
	if loadout_manager.use_item(piece_id, item_id):
		print("Used item: ", item_data.name)
		
		# Apply item effects (this would be game-specific logic)
		apply_item_effects(piece_id, item_data)
		
		# Hide attack UI and end turn
		hide_attack_ui()
		
		# End turn since using an item consumes the turn  
		if parent_node and parent_node.has_method("end_turn"):
			parent_node.end_turn()
	else:
		print("Failed to use item: ", item_data.name)

func apply_item_effects(piece_id: String, item_data: Dictionary):
	"""Apply the effects of a used item to the piece"""
	# Get the piece node from the piece manager
	var piece_manager = parent_node.piece_manager if parent_node else null
	if not piece_manager:
		return
	
	# Find the piece by ID
	var piece_node = null
	for pos in piece_manager.pieces.keys():
		var piece_data = piece_manager.pieces[pos]
		if piece_data.get("piece_id", "") == piece_id:
			piece_node = piece_data.piece_node
			break
	
	if not piece_node:
		print("Could not find piece node for ID: ", piece_id)
		return
	
	# Apply effects based on item type
	var effect = item_data.get("effect", "").to_lower()
	
	if "heal" in effect:
		# Extract heal amount from effect string
		var heal_amount = extract_number_from_string(effect)
		if heal_amount > 0:
			piece_node.current_health = min(piece_node.max_health, piece_node.current_health + heal_amount)
			piece_node.update_health_bar()
			print("Healed ", piece_id, " for ", heal_amount, " HP")
			
			# Show healing notification
			show_item_use_notification(piece_node.grid_position, item_data.name + " (+" + str(heal_amount) + " HP)")
	
	elif "damage" in effect:
		# Damage boost items might temporarily increase attack power
		var damage_boost = extract_number_from_string(effect)
		if damage_boost > 0:
			# This would need a temporary effect system, for now just show notification
			show_item_use_notification(piece_node.grid_position, item_data.name + " (+" + str(damage_boost) + " ATK this turn)")
			print("Applied damage boost of ", damage_boost, " to ", piece_id)
	
	else:
		# Generic item use
		show_item_use_notification(piece_node.grid_position, "Used " + item_data.name)
		print("Used item ", item_data.name, " on ", piece_id)

func extract_number_from_string(text: String) -> int:
	"""Extract the first number found in a string"""
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(text)
	if result:
		return result.get_string().to_int()
	return 0

func show_item_use_notification(grid_pos: Vector2, message: String):
	"""Show a notification when an item is used"""
	# Create a temporary label that fades out
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 14)
	notification.add_theme_color_override("font_color", Color.GREEN)
	
	# Position it above the piece
	if grid_system:
		var world_pos = grid_system.grid_to_world_pos(grid_pos)
		notification.position = world_pos + Vector2(0, -60)
	
	parent_node.add_child(notification)
	
	# Animate the notification
	var tween = create_tween()
	tween.parallel().tween_property(notification, "position", notification.position + Vector2(0, -30), 2.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): notification.queue_free())
	
	attack_ui.visible = true

func hide_attack_ui():
	"""Hide the attack UI"""
	if attack_ui:
		attack_ui.visible = false
	
	# Switch back to move mode through input handler
	if parent_node and parent_node.input_handler and parent_node.input_handler.has_method("set_mode"):
		parent_node.input_handler.set_mode("MOVE")

func execute_attack(attack_data, piece_data = null):
	"""Execute an attack selection"""
	print("Attack selected: ", attack_data.name, " - Click target to attack")
	
	# Set the selected attack on the currently selected piece
	var selected_piece = piece_data if piece_data else (parent_node.get_selected_piece() if parent_node and parent_node.has_method("get_selected_piece") else null)
	
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
		
		# Don't hide the attack UI - keep it visible to show selection
		# Just update the button highlights without rebuilding
		if piece_data:
			update_attack_selection_display(piece_data)
		
		# Switch to attack mode - call method on parent's input handler
		if parent_node.input_handler and parent_node.input_handler.has_method("set_mode"):
			print("Setting attack mode after selecting attack type")
			parent_node.input_handler.set_mode("ATTACK")

func update_attack_selection_display(piece_data):
	"""Update the visual display of which attack is selected without rebuilding the UI"""
	if not attack_ui or not piece_data:
		return
	
	var panel = attack_ui.get_child(0) if attack_ui.get_child_count() > 0 else null
	if not panel:
		return
	
	var vbox = panel.get_child(0) if panel.get_child_count() > 0 else null
	if not vbox:
		return
	
	var piece_node = piece_data.get("piece_node")
	if not piece_node or not is_instance_valid(piece_node):
		return
	
	var attacks = piece_node.get_available_attacks()
	var selected_attack_type = piece_data.get("selected_attack", "Basic")
	
	# Check if the currently selected attack is on cooldown
	# If so, auto-select the first available attack
	var selected_attack_on_cooldown = false
	for attack in attacks:
		var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "Unknown")
		var attack_type = "basic"
		if "Heavy" in attack_name:
			attack_type = "Heavy"
		elif "Quick" in attack_name:
			attack_type = "Quick"
		else:
			attack_type = "Basic"
		
		if attack_type == selected_attack_type and piece_node.is_attack_on_cooldown(attack):
			selected_attack_on_cooldown = true
			break
	
	# Auto-select first available attack if current selection is on cooldown
	if selected_attack_on_cooldown:
		for attack in attacks:
			if not piece_node.is_attack_on_cooldown(attack):
				var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "Unknown")
				if "Heavy" in attack_name:
					selected_attack_type = "Heavy"
				elif "Quick" in attack_name:
					selected_attack_type = "Quick"
				else:
					selected_attack_type = "Basic"
				piece_data["selected_attack"] = selected_attack_type
				print("Auto-switched to available attack: ", selected_attack_type)
				break
	
	# Find and update attack buttons (they're after the health display and separator)
	var button_index = 0
	for child in vbox.get_children():
		if child is Button and button_index < attacks.size():
			var attack = attacks[button_index]
			
			# Get attack properties
			var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "Unknown")
			var attack_damage = attack.damage if typeof(attack) == TYPE_OBJECT else attack.get("damage", 0)
			var attack_cooldown_max = attack.cooldown_max if typeof(attack) == TYPE_OBJECT else attack.get("cooldown_max", 0)
			
			# Determine attack type
			var attack_type = "basic"
			if "Heavy" in attack_name:
				attack_type = "Heavy"
			elif "Quick" in attack_name:
				attack_type = "Quick"
			else:
				attack_type = "Basic"
			
			var is_selected = (attack_type == selected_attack_type)
			
			# Check if on cooldown
			var cooldown_remaining = piece_node.get_attack_cooldown_remaining(attack)
			var on_cooldown = piece_node.is_attack_on_cooldown(attack)
			
			# Update button text and color
			var button_text = attack_name + " (" + str(attack_damage) + " dmg)"
			if is_selected:
				button_text = "► " + button_text + " ◄"
			
			if on_cooldown:
				child.text = button_text + " [CD: " + str(cooldown_remaining) + "]"
				child.disabled = true
				child.add_theme_color_override("font_color", Color.DARK_GRAY)
			else:
				child.text = button_text
				child.disabled = false
				# Highlight selected attack
				if is_selected:
					child.add_theme_color_override("font_color", Color.YELLOW)
				else:
					child.remove_theme_color_override("font_color")
			
			button_index += 1

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

func show_game_over(winner: String, reason: String = "elimination", glyphs_recovered: int = 0):
	"""Show game over screen as an overlay"""
	print("UIManager: Showing game over overlay")
	print("Winner: ", winner, " Reason: ", reason, " Glyphs recovered: ", glyphs_recovered)
	
	# Clear any existing game over screen
	clear_game_over()
	
	# Get current army info if available
	var army_info = ""
	if parent_node and parent_node.has_method("get_army_manager"):
		var army_manager = parent_node.get_army_manager()
		if army_manager:
			var current_army = army_manager.get_current_army()
			if current_army:
				army_info = "\nLevel " + str(current_army.level) + ": " + current_army.army_name
	
	# Create fullscreen overlay
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0, 0, 0, 0.9)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.z_index = 100
	
	# Add to parent scene
	if parent_node:
		parent_node.add_child(game_over_overlay)
	
	# Use CenterContainer for proper centering
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)
	
	# Create panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 400)
	center.add_child(panel)
	
	# Content container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "GAME OVER!"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Winner
	var winner_label = Label.new()
	if winner.to_lower() == "player":
		winner_label.text = "VICTORY!" + army_info
		winner_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		winner_label.text = "DEFEAT!" + army_info
		winner_label.add_theme_color_override("font_color", Color.ORANGE)
	winner_label.add_theme_font_size_override("font_size", 18)
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(winner_label)
	
	# Glyphs recovered
	if glyphs_recovered > 0:
		vbox.add_child(HSeparator.new())
		var glyphs_label = Label.new()
		glyphs_label.text = "Glyphs Recovered: " + str(glyphs_recovered)
		glyphs_label.add_theme_color_override("font_color", Color.YELLOW)
		glyphs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(glyphs_label)
	
	vbox.add_child(HSeparator.new())
	
	# Buttons
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	if winner.to_lower() == "player":
		# Continue button
		var continue_btn = Button.new()
		continue_btn.text = "Continue to Next Level"
		continue_btn.custom_minimum_size = Vector2(200, 40)
		continue_btn.pressed.connect(func():
			clear_game_over()
			if parent_node and parent_node.has_method("restart_battle"):
				parent_node.restart_battle("player")
		)
		button_container.add_child(continue_btn)
		
		# Shop button
		var shop_btn = Button.new()
		shop_btn.text = "End Run & Visit Shop"
		shop_btn.custom_minimum_size = Vector2(200, 40)
		shop_btn.pressed.connect(func():
			clear_game_over()
			show_shop()
		)
		button_container.add_child(shop_btn)
	else:
		# Restart button for defeat
		var restart_btn = Button.new()
		restart_btn.text = "Play Again"
		restart_btn.custom_minimum_size = Vector2(200, 40)
		restart_btn.pressed.connect(func():
			clear_game_over()
			if parent_node and parent_node.has_method("restart_battle"):
				parent_node.restart_battle("enemy")
		)
		button_container.add_child(restart_btn)
	
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
	print("UIManager.end_run_to_shop() called - emitting signal")
	end_run_to_shop_signal.emit()
	print("Signal emitted successfully")

func clear_any_overlays():
	"""Clear any active overlays"""
	# Disable input blocking
	is_blocking_input = false
	print("UIManager: Input blocking DISABLED (clearing overlays)")
	
	# Re-enable game input when clearing overlays
	if parent_node and parent_node.has_method("get_node"):
		var input_handler = parent_node.get_node_or_null("InputHandler")
		if input_handler and input_handler.has_method("set_input_enabled"):
			input_handler.set_input_enabled(true)
	
	if game_over_overlay:
		game_over_overlay.queue_free()
		game_over_overlay = null
	if shop_overlay:
		shop_overlay.queue_free()
		shop_overlay = null
	if loadout_overlay:
		loadout_overlay.queue_free()
		loadout_overlay = null

func create_overlay():
	"""Create a basic overlay structure for dialogs"""
	# Enable input blocking at the UIManager level
	is_blocking_input = true
	print("UIManager: Input blocking ENABLED for overlay")
	
	# Disable game input while overlay is active
	if parent_node and parent_node.has_method("get_node"):
		var input_handler = parent_node.get_node_or_null("InputHandler")
		if input_handler and input_handler.has_method("set_input_enabled"):
			input_handler.set_input_enabled(false)
	
	var overlay_data = {}
	
	# Create background overlay
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # Block mouse events from passing through
	background.z_index = 10
	parent_node.add_child(background)
	overlay_data.background = background
	
	# Create a center container for proper centering
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center_container)
	
	# Create main panel (will be centered by CenterContainer)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 400)
	panel.z_index = 11
	center_container.add_child(panel)
	overlay_data.panel = panel
	
	# Create content container
	var vbox_container = VBoxContainer.new()
	vbox_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox_container.add_theme_constant_override("margin_left", 20)
	vbox_container.add_theme_constant_override("margin_right", 20)
	vbox_container.add_theme_constant_override("margin_top", 20)
	vbox_container.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox_container)
	overlay_data.vbox_container = vbox_container
	
	return overlay_data

func show_shop():
	"""Display the shop interface"""
	print("UIManager: Transitioning to Shop scene")
	
	# Save current glyphs to GameState before changing scenes
	if glyph_manager:
		var current_glyphs = glyph_manager.get_current_glyphs()
		GameState.current_glyphs = current_glyphs
		print("UIManager: Saved ", current_glyphs, " glyphs to GameState")
	
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")

func show_loadout_menu():
	"""Transition to the dedicated LoadoutMenu scene"""
	print("UIManager: Transitioning to LoadoutMenu scene")
	
	# Store current scene info for returning
	var current_scene = get_tree().current_scene
	if current_scene:
		# Store the scene path so we can return to it
		var scene_path = current_scene.scene_file_path
		print("Current scene path: ", scene_path)
	
	# Clear any existing overlays first
	clear_any_overlays()
	
	# Change to the LoadoutMenu scene directly
	get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
	
	print("UIManager: Scene changed to LoadoutMenu")

func show_loadout_screen(screen_type: String):
	"""Show the dedicated loadout screen with only player pieces in formation (DEPRECATED - use show_loadout_menu instead)"""
	# Redirect to the new scene-based loadout menu
	show_loadout_menu()
	return
	
	clear_any_overlays()
	
	# Enable input blocking at the UIManager level
	is_blocking_input = true
	print("UIManager: Input blocking ENABLED for loadout screen")
	
	# Disable game input while loadout is active - try multiple approaches
	if parent_node:
		# Method 1: Direct reference to input handler
		if parent_node.has_method("get_node"):
			var input_handler = parent_node.get_node_or_null("InputHandler")
			if input_handler and input_handler.has_method("set_input_enabled"):
				input_handler.set_input_enabled(false)
				print("UIManager: Disabled input via InputHandler")
		
		# Method 2: Try to find input handler by searching children
		for child in parent_node.get_children():
			if child.get_script() and child.get_script().get_global_name() == "InputHandler":
				if child.has_method("set_input_enabled"):
					child.set_input_enabled(false)
					print("UIManager: Disabled input via child search")
				break
	
	# Create full-screen background that blocks input
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.15, 0.95)  # Dark blue-gray background
	background.size = Vector2(get_viewport().size)  # Convert Vector2i to Vector2
	background.position = Vector2.ZERO
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # Block mouse events from passing through
	
	# Add to the scene tree at the highest level to ensure it's on top and blocks input
	var scene_root = parent_node.get_tree().current_scene
	scene_root.add_child(background)
	loadout_overlay = background
	
	# Make sure the overlay has the highest z-index
	background.z_index = 1000
	
	# Add custom input handling to consume all input events
	background.gui_input.connect(func(event): 
		# Consume all input events to prevent them from reaching the background
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			background.accept_event()
			# Removed debug print - was causing massive slowdown on mouse motion
	)
	
	# Main container
	var main_container = VBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.add_theme_constant_override("separation", 20)
	background.add_child(main_container)
	
	# Title
	var title = Label.new()
	if screen_type == "run":
		title.text = "⚔ PREPARE YOUR ARMY ⚔"
	else:
		title.text = "⚔ LEVEL PREPARATIONS ⚔"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.GOLD)
	main_container.add_child(title)
	
	# Subtitle instructions
	var instructions = Label.new()
	instructions.text = "Click on any piece below to equip items to that warrior"
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	main_container.add_child(instructions)
	
	# Content area - horizontal split
	var content_container = HBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 40)
	main_container.add_child(content_container)
	
	# Left side: Player piece formation
	var formation_section = VBoxContainer.new()
	formation_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var formation_title = Label.new()
	formation_title.text = "Your Army:"
	formation_title.add_theme_font_size_override("font_size", 20)
	formation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_title.add_theme_color_override("font_color", Color.CYAN)
	formation_section.add_child(formation_title)
	
	# Player piece grid (only rows 6 and 7)
	var pieces_container = create_player_formation_view(screen_type)
	formation_section.add_child(pieces_container)
	
	content_container.add_child(formation_section)
	
	# Right side: Selected piece loadout
	var loadout_section = VBoxContainer.new()
	loadout_section.name = "LoadoutSection"
	loadout_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_section.custom_minimum_size = Vector2(400, 0)
	
	var loadout_title = Label.new()
	loadout_title.text = "Equipment:"
	loadout_title.add_theme_font_size_override("font_size", 20)
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_title.add_theme_color_override("font_color", Color.CYAN)
	loadout_section.add_child(loadout_title)
	
	var placeholder_label = Label.new()
	placeholder_label.text = "Select a piece to view and equip items"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_color_override("font_color", Color.GRAY)
	placeholder_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loadout_section.add_child(placeholder_label)
	
	content_container.add_child(loadout_section)
	
	# Bottom buttons
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	
	var back_button = Button.new()
	back_button.text = "◀ Back to Shop"
	back_button.size = Vector2(150, 50)
	back_button.add_theme_font_size_override("font_size", 16)
	back_button.pressed.connect(func():
		# Disable input blocking
		is_blocking_input = false
		print("UIManager: Input blocking DISABLED (back button)")
		
		# Re-enable game input
		if parent_node and parent_node.has_method("get_node"):
			var input_handler = parent_node.get_node_or_null("InputHandler")
			if input_handler and input_handler.has_method("set_input_enabled"):
				input_handler.set_input_enabled(true)
		
		if loadout_overlay:
			loadout_overlay.queue_free()
			loadout_overlay = null
		# Go back to shop
		if parent_node.has_method("_on_shop_closed_from_ui"):
			parent_node._on_shop_closed_from_ui()
	)
	buttons_container.add_child(back_button)
	
	var start_button = Button.new()
	if screen_type == "run":
		start_button.text = "⚔ BEGIN RUN ⚔"
	else:
		start_button.text = "⚔ START LEVEL ⚔"
	start_button.size = Vector2(200, 50)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.add_theme_color_override("font_color", Color.BLACK)
	start_button.modulate = Color.GOLD
	start_button.pressed.connect(func():
		complete_loadout(screen_type)
	)
	buttons_container.add_child(start_button)
	
	main_container.add_child(buttons_container)

func create_player_formation_view(screen_type: String) -> Control:
	"""Create a formation view showing only player pieces in their starting positions"""
	var formation_container = VBoxContainer.new()
	formation_container.add_theme_constant_override("separation", 10)
	
	# Get piece manager to access current pieces
	var piece_manager = parent_node.piece_manager if parent_node else null
	if not piece_manager:
		var error_label = Label.new()
		error_label.text = "Error: Could not access pieces"
		return error_label
	
	# Create two rows for player pieces (rows 6 and 7 in the actual game)
	var rows = [6, 7]  # Player piece rows
	
	for row in rows:
		var row_container = HBoxContainer.new()
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER
		row_container.add_theme_constant_override("separation", 8)
		
		# Add row label
		var row_label = Label.new()
		if row == 6:
			row_label.text = "Front:"
		else:
			row_label.text = "Back:"
		row_label.add_theme_font_size_override("font_size", 14)
		row_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		row_label.custom_minimum_size = Vector2(60, 0)
		row_container.add_child(row_label)
		
		# Create piece buttons for this row
		for col in range(8):
			var grid_pos = Vector2(col, row)
			var piece_button = create_formation_piece_button(grid_pos, screen_type, piece_manager)
			row_container.add_child(piece_button)
		
		formation_container.add_child(row_container)
	
	# Add some spacing and decorative elements
	var frame = PanelContainer.new()
	frame.add_child(formation_container)
	
	# Style the frame
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	frame.add_theme_stylebox_override("panel", style_box)
	
	return frame

func create_formation_piece_button(grid_pos: Vector2, screen_type: String, piece_manager) -> Control:
	"""Create a button representing a piece in the formation view"""
	var piece_button = Button.new()
	piece_button.custom_minimum_size = Vector2(60, 60)
	
	# Check if there's a piece at this position
	if piece_manager.pieces.has(grid_pos):
		var piece_data = piece_manager.pieces[grid_pos]
		var piece_node = piece_data.piece_node
		
		# Only show player pieces
		if piece_node.team == "player":
			# Set button appearance and text
			if piece_node.piece_type == "king":
				piece_button.text = "♔\nKING"
				piece_button.modulate = Color.GOLD
			else:
				piece_button.text = "⚔\nWAR"
				piece_button.modulate = Color(0.4, 0.7, 1.0)  # Light blue
			
			piece_button.add_theme_font_size_override("font_size", 10)
			
			# Make piece clickable for loadout
			piece_button.pressed.connect(func(): select_piece_for_formation_loadout(grid_pos, screen_type))
			
			# Check if piece has items equipped and show indicator
			if loadout_manager:
				var piece_id = piece_data.get("piece_id", "")
				if piece_id != "":
					var equipped_items = loadout_manager.get_equipped_items(piece_id)
					if equipped_items.size() > 0:
						# Add equipped items indicator
						piece_button.modulate = piece_button.modulate * Color(1.2, 1.2, 1.2)  # Brighten
						piece_button.text += "\n●"  # Add dot indicator
		else:
			# This shouldn't happen in formation view, but just in case
			piece_button.visible = false
	else:
		# Empty position
		piece_button.text = "□"
		piece_button.disabled = true
		piece_button.modulate = Color(0.3, 0.3, 0.3)
	
	return piece_button

func select_piece_for_formation_loadout(grid_pos: Vector2, screen_type: String):
	"""Handle when a piece is selected in the formation view"""
	var piece_manager = parent_node.piece_manager if parent_node else null
	if not piece_manager or not piece_manager.pieces.has(grid_pos):
		return
	
	var piece_data = piece_manager.pieces[grid_pos]
	var piece_node = piece_data.piece_node
	var piece_id = piece_data.get("piece_id", "")
	
	print("Selected piece for formation loadout: ", piece_id, " (", piece_node.piece_type, ") at ", grid_pos)
	
	# Find the LoadoutSection and update it - need to search through the full-screen background
	var loadout_section = find_node_by_name_recursive(loadout_overlay, "LoadoutSection")
	if loadout_section:
		show_formation_piece_loadout(piece_id, piece_node, screen_type, loadout_section)



func create_loadout_board_view(screen_type: String, overlay_data: Dictionary) -> Control:
	"""Create a miniature board view for piece selection"""
	var board_grid = GridContainer.new()
	board_grid.columns = 8
	board_grid.custom_minimum_size = Vector2(320, 320)  # 8x8 grid, 40px per cell
	
	# Get piece manager to access current pieces
	var piece_manager = parent_node.piece_manager if parent_node else null
	
	# Create 8x8 grid of buttons representing board positions
	for row in range(8):
		for col in range(8):
			var grid_pos = Vector2(col, row)
			var cell_button = Button.new()
			cell_button.custom_minimum_size = Vector2(38, 38)
			cell_button.text = ""
			
			# Check if there's a piece at this position
			if piece_manager and piece_manager.pieces.has(grid_pos):
				var piece_data = piece_manager.pieces[grid_pos]
				var piece_node = piece_data.piece_node
				
				# Set button appearance based on piece
				if piece_node.team == "player":
					if piece_node.piece_type == "king":
						cell_button.text = "K"
						cell_button.modulate = Color(0.5, 0.7, 1.0)  # Light blue for player king
					else:
						cell_button.text = "P"
						cell_button.modulate = Color(0.3, 0.6, 1.0)  # Blue for player piece
					
					# Make player pieces clickable for loadout
					cell_button.pressed.connect(func(): select_piece_for_loadout(grid_pos, screen_type, overlay_data))
				else:  # enemy
					if piece_node.piece_type == "king":
						cell_button.text = "K"
						cell_button.modulate = Color(1.0, 0.7, 0.5)  # Light red for enemy king
					else:
						cell_button.text = "E"
						cell_button.modulate = Color(1.0, 0.4, 0.3)  # Red for enemy piece
					
					# Enemy pieces are not clickable for loadout
					cell_button.disabled = true
					cell_button.modulate = cell_button.modulate * Color(0.6, 0.6, 0.6)  # Darken disabled enemies
			else:
				# Empty cell
				cell_button.modulate = Color(0.3, 0.3, 0.3)
				cell_button.disabled = true
			
			board_grid.add_child(cell_button)
	
	return board_grid

func select_piece_for_loadout(grid_pos: Vector2, screen_type: String, overlay_data: Dictionary):
	"""Handle when a piece is selected for loadout editing"""
	var piece_manager = parent_node.piece_manager if parent_node else null
	if not piece_manager or not piece_manager.pieces.has(grid_pos):
		return
	
	var piece_data = piece_manager.pieces[grid_pos]
	var piece_node = piece_data.piece_node
	var piece_id = piece_data.piece_id
	
	print("Selected piece for loadout: ", piece_id, " (", piece_node.piece_type, ") at ", grid_pos)
	
	# Find the LoadoutSection and update it
	var loadout_section = find_node_by_name(overlay_data.vbox_container, "LoadoutSection")
	if loadout_section:
		show_piece_instance_loadout(piece_id, piece_node, screen_type, loadout_section)

func find_node_by_name(parent: Node, node_name: String) -> Node:
	"""Recursively find a child node by name"""
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

func show_piece_instance_loadout(piece_id: String, piece_node: Node, screen_type: String, loadout_section: VBoxContainer):
	"""Show loadout options for a specific piece instance"""
	# Clear existing content
	for child in loadout_section.get_children():
		child.queue_free()
	
	# Piece info header
	var piece_header = Label.new()
	piece_header.text = piece_node.piece_type.capitalize() + " at " + str(piece_node.grid_position)
	piece_header.add_theme_font_size_override("font_size", 18)
	piece_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_section.add_child(piece_header)
	
	# Current loadout display
	var current_loadout_label = Label.new()
	current_loadout_label.text = "Current Equipment:"
	current_loadout_label.add_theme_font_size_override("font_size", 14)
	loadout_section.add_child(current_loadout_label)
	
	# Show equipped items
	if loadout_manager:
		var equipped_items = loadout_manager.get_equipped_items(piece_id)
		if equipped_items.size() > 0:
			for item_id in equipped_items:
				var item_data = data_loader.get_item_by_id(item_id) if data_loader else null
				if item_data:
					var item_label = Label.new()
					item_label.text = "• " + item_data.name + " (" + item_data.type + ")"
					item_label.add_theme_font_size_override("font_size", 10)
					loadout_section.add_child(item_label)
		else:
			var no_items_label = Label.new()
			no_items_label.text = "No items equipped"
			no_items_label.add_theme_font_size_override("font_size", 10)
			no_items_label.modulate = Color(0.7, 0.7, 0.7)
			loadout_section.add_child(no_items_label)
	
	# Add separator
	loadout_section.add_child(HSeparator.new())
	
	# Available items for this piece type
	var available_label = Label.new()
	available_label.text = "Available Items:"
	available_label.add_theme_font_size_override("font_size", 14)
	loadout_section.add_child(available_label)
	
	# Show available items from inventory
	if loadout_manager and data_loader:
		var available_items = loadout_manager.get_available_items_for_piece(piece_node.piece_type, data_loader)
		
		if available_items.size() > 0:
			# Create scrollable area for items
			var scroll_container = ScrollContainer.new()
			scroll_container.custom_minimum_size = Vector2(350, 200)
			var items_vbox = VBoxContainer.new()
			
			for item_data in available_items:
				var item_container = create_equippable_item_display(item_data, piece_id, screen_type)
				items_vbox.add_child(item_container)
			
			scroll_container.add_child(items_vbox)
			loadout_section.add_child(scroll_container)
		else:
			var no_items_label = Label.new()
			no_items_label.text = "No items available for this piece type"
			no_items_label.add_theme_font_size_override("font_size", 10)
			no_items_label.modulate = Color(0.7, 0.7, 0.7)
			loadout_section.add_child(no_items_label)

func create_equippable_item_display(item_data: Dictionary, piece_id: String, screen_type: String) -> Control:
	"""Create a display for an item that can be equipped"""
	var item_container = VBoxContainer.new()
	
	# Item name and equip button
	var header_container = HBoxContainer.new()
	
	var item_name_label = Label.new()
	item_name_label.text = item_data.name
	item_name_label.add_theme_font_size_override("font_size", 12)
	header_container.add_child(item_name_label)
	
	header_container.add_child(Control.new())  # Spacer
	header_container.get_child(-1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var equip_button = Button.new()
	equip_button.text = "Equip"
	equip_button.size = Vector2(60, 25)
	equip_button.pressed.connect(func(): equip_item_to_piece(item_data, piece_id, screen_type))
	header_container.add_child(equip_button)
	
	item_container.add_child(header_container)
	
	# Item description
	var description_label = Label.new()
	description_label.text = item_data.get("description", "No description available")
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.modulate = Color(0.8, 0.8, 0.8)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_container.add_child(description_label)
	
	# Item stats/effects
	if item_data.has("effect") and item_data.effect != "":
		var effect_label = Label.new()
		effect_label.text = "Effect: " + item_data.effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.modulate = Color(0.5, 1.0, 0.5)
		item_container.add_child(effect_label)
	
	# Add separator
	item_container.add_child(HSeparator.new())
	
	return item_container

func equip_item_to_piece(item_data: Dictionary, piece_id: String, screen_type: String):
	"""Equip an item to a specific piece instance"""
	print("DEBUG: Attempting to equip item ", item_data.get("name", "Unknown"), " to piece ", piece_id)
	
	if not loadout_manager:
		print("ERROR: No loadout manager available")
		return
	
	# Determine slot type based on item type and screen type
	var slot_type = determine_slot_type(item_data, screen_type)
	print("DEBUG: Determined slot type: ", slot_type, " for item type: ", item_data.get("type", ""), " in screen: ", screen_type)
	
	# Equip the item
	if loadout_manager.equip_item(piece_id, item_data.id, slot_type):
		print("SUCCESS: Equipped ", item_data.name, " to piece ", piece_id, " in slot ", slot_type)
		# Refresh the loadout display
		# Note: This would need the overlay_data passed through, but for now just print success
	else:
		print("ERROR: Failed to equip ", item_data.name, " to piece ", piece_id)

func determine_slot_type(item_data: Dictionary, screen_type: String) -> String:
	"""Determine what slot type an item should go into"""
	var item_type = item_data.get("type", "").to_lower()
	
	# Use items always go to use slot
	if item_type == "use":
		return "use"
	
	# For run screen, allow permanent and run items
	if screen_type == "run":
		if item_type == "permanent":
			return "permanent"
		else:
			return "run"
	
	# For level screen, only level items
	return "level"

# Old show_piece_loadout function removed - now using piece-instance based loadout system

func complete_loadout(screen_type: String):
	"""Complete the loadout process and continue"""
	# Disable input blocking
	is_blocking_input = false
	print("UIManager: Input blocking DISABLED")
	
	# Re-enable game input - try multiple approaches
	if parent_node:
		# Method 1: Direct reference to input handler
		if parent_node.has_method("get_node"):
			var input_handler = parent_node.get_node_or_null("InputHandler")
			if input_handler and input_handler.has_method("set_input_enabled"):
				input_handler.set_input_enabled(true)
				print("UIManager: Re-enabled input via InputHandler")
		
		# Method 2: Try to find input handler by searching children
		for child in parent_node.get_children():
			if child.get_script() and child.get_script().get_global_name() == "InputHandler":
				if child.has_method("set_input_enabled"):
					child.set_input_enabled(true)
					print("UIManager: Re-enabled input via child search")
				break
	
	if loadout_overlay:
		loadout_overlay.queue_free()
		loadout_overlay = null
	
	loadout_complete_signal.emit(screen_type)

func show_formation_piece_loadout(piece_id: String, piece_node: Node, screen_type: String, loadout_section: VBoxContainer):
	"""Show loadout options for a selected piece in the formation view"""
	# Clear existing content
	for child in loadout_section.get_children():
		child.queue_free()
	
	# Title remains
	var loadout_title = Label.new()
	loadout_title.text = "Equipment:"
	loadout_title.add_theme_font_size_override("font_size", 20)
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_title.add_theme_color_override("font_color", Color.CYAN)
	loadout_section.add_child(loadout_title)
	
	# Piece info header with styling
	var piece_header = Label.new()
	if piece_node.piece_type == "king":
		piece_header.text = "♔ " + piece_node.piece_type.capitalize() + " ♔"
		piece_header.add_theme_color_override("font_color", Color.GOLD)
	else:
		piece_header.text = "⚔ " + piece_node.piece_type.capitalize() + " ⚔"
		piece_header.add_theme_color_override("font_color", Color.CYAN)
	
	piece_header.add_theme_font_size_override("font_size", 18)
	piece_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_section.add_child(piece_header)
	
	# Add separator
	loadout_section.add_child(HSeparator.new())
	
	# Current equipment display
	var current_equipment = VBoxContainer.new()
	
	var current_label = Label.new()
	current_label.text = "Currently Equipped:"
	current_label.add_theme_font_size_override("font_size", 14)
	current_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	current_equipment.add_child(current_label)
	
	if loadout_manager:
		var equipped_items = loadout_manager.get_equipped_items(piece_id)
		if equipped_items.size() > 0:
			for item_id in equipped_items:
				var item_data = data_loader.get_item_by_id(item_id) if data_loader else null
				if item_data:
					var item_display = create_equipped_item_display(item_data, piece_id)
					current_equipment.add_child(item_display)
		else:
			var no_items_label = Label.new()
			no_items_label.text = "• No items equipped"
			no_items_label.add_theme_font_size_override("font_size", 12)
			no_items_label.add_theme_color_override("font_color", Color.GRAY)
			current_equipment.add_child(no_items_label)
	
	loadout_section.add_child(current_equipment)
	
	# Add separator
	loadout_section.add_child(HSeparator.new())
	
	# Available items section
	var available_section = VBoxContainer.new()
	
	var available_label = Label.new()
	available_label.text = "Available Items:"
	available_label.add_theme_font_size_override("font_size", 14)
	available_label.add_theme_color_override("font_color", Color.YELLOW)
	available_section.add_child(available_label)
	
	if loadout_manager and data_loader:
		var available_items = loadout_manager.get_available_items_for_piece(piece_node.piece_type, data_loader)
		
		if available_items.size() > 0:
			# Create scrollable area for items
			var scroll_container = ScrollContainer.new()
			scroll_container.custom_minimum_size = Vector2(350, 300)
			var items_vbox = VBoxContainer.new()
			
			for item_data in available_items:
				var item_container = create_equippable_item_display_enhanced(item_data, piece_id, screen_type)
				items_vbox.add_child(item_container)
			
			scroll_container.add_child(items_vbox)
			available_section.add_child(scroll_container)
		else:
			var no_items_label = Label.new()
			no_items_label.text = "• No items available\n• Purchase items from the shop first"
			no_items_label.add_theme_font_size_override("font_size", 12)
			no_items_label.add_theme_color_override("font_color", Color.GRAY)
			available_section.add_child(no_items_label)
	
	loadout_section.add_child(available_section)

func create_equipped_item_display(item_data: Dictionary, piece_id: String) -> Control:
	"""Create display for an equipped item with unequip option"""
	var item_container = HBoxContainer.new()
	
	var item_info = VBoxContainer.new()
	item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = "• " + item_data.get("name", "Unknown Item")
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	item_info.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = "  " + item_data.get("description", "No description")
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_info.add_child(desc_label)
	
	item_container.add_child(item_info)
	
	var unequip_button = Button.new()
	unequip_button.text = "Remove"
	unequip_button.size = Vector2(70, 25)
	unequip_button.add_theme_font_size_override("font_size", 10)
	unequip_button.pressed.connect(func(): unequip_item_from_piece(item_data, piece_id))
	item_container.add_child(unequip_button)
	
	return item_container

func create_equippable_item_display_enhanced(item_data: Dictionary, piece_id: String, screen_type: String) -> Control:
	"""Create enhanced display for an equippable item"""
	var item_container = VBoxContainer.new()
	
	# Item header with name and equip button
	var header_container = HBoxContainer.new()
	
	var item_name_label = Label.new()
	item_name_label.text = item_data.get("name", "Unknown Item")
	item_name_label.add_theme_font_size_override("font_size", 12)
	item_name_label.add_theme_color_override("font_color", Color.WHITE)
	header_container.add_child(item_name_label)
	
	header_container.add_child(Control.new())  # Spacer
	header_container.get_child(-1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var equip_button = Button.new()
	equip_button.text = "Equip"
	equip_button.size = Vector2(60, 25)
	equip_button.add_theme_font_size_override("font_size", 10)
	equip_button.pressed.connect(func(): equip_item_to_formation_piece(item_data, piece_id, screen_type))
	header_container.add_child(equip_button)
	
	item_container.add_child(header_container)
	
	# Item description
	var description_label = Label.new()
	description_label.text = item_data.get("description", "No description available")
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_container.add_child(description_label)
	
	# Item effects
	if item_data.has("effect") and item_data.effect != "":
		var effect_label = Label.new()
		effect_label.text = "⚡ " + item_data.effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		item_container.add_child(effect_label)
	
	# Add separator
	item_container.add_child(HSeparator.new())
	
	return item_container

func equip_item_to_formation_piece(item_data: Dictionary, piece_id: String, screen_type: String):
	"""Equip an item to a piece in formation view"""
	if not loadout_manager:
		print("ERROR: No loadout manager available")
		return
	
	var slot_type = determine_slot_type(item_data, screen_type)
	
	if loadout_manager.equip_item(piece_id, item_data.id, slot_type):
		print("SUCCESS: Equipped ", item_data.name, " to piece ", piece_id)
		# Refresh the loadout section to show updated equipment
		var loadout_section = find_node_by_name_recursive(loadout_overlay, "LoadoutSection")
		if loadout_section:
			var piece_manager = parent_node.piece_manager if parent_node else null
			if piece_manager:
				for pos in piece_manager.pieces.keys():
					var piece_data = piece_manager.pieces[pos]
					if piece_data.get("piece_id", "") == piece_id:
						show_formation_piece_loadout(piece_id, piece_data.piece_node, screen_type, loadout_section)
						break
	else:
		print("ERROR: Failed to equip ", item_data.name, " to piece ", piece_id)

func unequip_item_from_piece(item_data: Dictionary, piece_id: String):
	"""Unequip an item from a piece"""
	if not loadout_manager:
		return
	
	# Find the slot type for this item
	var slot_types = ["permanent", "run", "level", "use"]
	var found_slot = ""
	
	for slot_type in slot_types:
		var equipped_items = loadout_manager.get_equipped_items(piece_id, slot_type)
		if equipped_items.has(item_data.id):
			found_slot = slot_type
			break
	
	if found_slot != "" and loadout_manager.unequip_item(piece_id, item_data.id, found_slot):
		print("SUCCESS: Unequipped ", item_data.name, " from piece ", piece_id)
		# Refresh the current loadout display
		var loadout_section = find_node_by_name_recursive(loadout_overlay, "LoadoutSection")
		if loadout_section:
			var piece_manager = parent_node.piece_manager if parent_node else null
			if piece_manager:
				for pos in piece_manager.pieces.keys():
					var piece_data = piece_manager.pieces[pos]
					if piece_data.get("piece_id", "") == piece_id:
						show_formation_piece_loadout(piece_id, piece_data.piece_node, "run", loadout_section)
						break
	else:
		print("ERROR: Failed to unequip ", item_data.name, " from piece ", piece_id)

func refresh_formation_view():
	"""Refresh the formation view to update equipment indicators"""
	if not loadout_overlay or not loadout_manager or not parent_node or not parent_node.piece_manager:
		return
	
	var formation_container = find_node_by_name_recursive(loadout_overlay, "FormationContainer")
	if not formation_container:
		return
	
	# Update all piece buttons with current equipment status
	for child in formation_container.get_children():
		if child is HBoxContainer:  # This is a row container
			for piece_button in child.get_children():
				if piece_button is Button and piece_button.has_meta("piece_id"):
					var piece_id = piece_button.get_meta("piece_id")
					var equipped_count = 0
					
					if loadout_manager:
						var all_equipped = loadout_manager.get_equipped_items(piece_id)
						equipped_count = all_equipped.size()
					
					# Update button text to show equipment status
					var piece_data = get_piece_data_by_id(piece_id)
					if piece_data:
						var base_text = piece_data.piece_node.piece_type.capitalize()
						if equipped_count > 0:
							piece_button.text = base_text + " ●".repeat(equipped_count)
						else:
							piece_button.text = base_text

func get_piece_data_by_id(piece_id: String) -> Dictionary:
	"""Helper function to get piece data by ID"""
	if not parent_node or not parent_node.piece_manager:
		return {}
	
	for pos in parent_node.piece_manager.pieces.keys():
		var piece_data = parent_node.piece_manager.pieces[pos]
		if piece_data.get("piece_id", "") == piece_id:
			return piece_data
	
	return {}

# Utility function for finding nodes recursively
func find_node_by_name_recursive(node: Node, target_name: String) -> Node:
	"""Recursively find a node by name"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_node_by_name_recursive(child, target_name)
		if result:
			return result
	
	return null