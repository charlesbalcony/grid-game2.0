# LoadoutMenu.gd
# Standalone loadout menu scene that shows clean starting formation
# Independent of current game state for proper equipment management

extends Control

# References to child nodes
@onready var formation_container = $MainContainer/ContentContainer/FormationSection/FormationContainer
@onready var items_container = $MainContainer/ContentContainer/ItemsSection/ItemsContainer/ItemsContent
@onready var loadout_container = $MainContainer/ContentContainer/LoadoutSection/LoadoutContainer/LoadoutContent
@onready var back_to_menu_button = $MainContainer/ButtonsContainer/BackToMenuButton
@onready var start_battle_button = $MainContainer/ButtonsContainer/StartBattleButton
@onready var title_label = $MainContainer/Title
@onready var formation_title = $MainContainer/ContentContainer/FormationSection/FormationTitle
@onready var items_title = $MainContainer/ContentContainer/ItemsSection/ItemsTitle
@onready var loadout_title = $MainContainer/ContentContainer/LoadoutSection/LoadoutTitle

# Default starting formation layout (independent of game state)
var default_formation = {
	# Back rank (row 7) - King in center, warriors around
	Vector2(0, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(1, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(2, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(3, 7): {"type": "king", "name": "King"},  # King in center-back
	Vector2(4, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(5, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(6, 7): {"type": "warrior", "name": "Warrior"},
	Vector2(7, 7): {"type": "warrior", "name": "Warrior"},
	
	# Front rank (row 6) - All warriors
	Vector2(0, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(1, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(2, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(3, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(4, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(5, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(6, 6): {"type": "warrior", "name": "Warrior"},
	Vector2(7, 6): {"type": "warrior", "name": "Warrior"}
}

# Currently selected piece for loadout management
var selected_piece_pos = null
var selected_piece_data = null

# Manager references (will be set from outside)
var loadout_manager = null
var data_loader = null

signal back_to_menu_requested
signal start_battle_requested

func _ready():
	print("LoadoutMenu: _ready() called")
	
	# Set up our own data loader for item names
	if not data_loader:
		data_loader = preload("res://scripts/systems/DataLoader.gd").new()
		data_loader.load_items()
		print("LoadoutMenu: Created and initialized DataLoader")
	
	# Set up our own loadout manager for equipment handling
	if not loadout_manager:
		loadout_manager = preload("res://scripts/systems/LoadoutManager.gd").new()
		print("LoadoutMenu: Created LoadoutManager")
		
		# Load equipment data from GameState first (if it exists)
		if GameState and GameState.piece_loadouts.size() > 0:
			loadout_manager.piece_loadouts = GameState.piece_loadouts.duplicate(true)
			print("LoadoutMenu: Loaded ", GameState.piece_loadouts.size(), " piece loadouts from GameState")
			# Debug: show what was loaded
			for piece_id in loadout_manager.piece_loadouts.keys():
				var loadout = loadout_manager.piece_loadouts[piece_id]
				print("  - ", piece_id, ": permanent=", loadout.get("permanent", []), " run=", loadout.get("run", []))
		
		# Register all pieces from the default formation (this will preserve existing loadouts)
		for pos in default_formation:
			var piece_data = default_formation[pos]
			var piece_id = generate_piece_id(pos, piece_data.type)
			
			# Only register if not already in loadouts (to preserve equipment)
			if not loadout_manager.piece_loadouts.has(piece_id):
				loadout_manager.register_piece_instance(piece_id, piece_data.type, pos)
				print("LoadoutMenu: Registered new piece: ", piece_id, " at ", pos)
			else:
				print("LoadoutMenu: Piece already has loadout data: ", piece_id)
		
		# Level items should already be cleared when the level was completed
		# This is just a safety check in case something went wrong
		if GameState.current_level > 1:
			print("LoadoutMenu: Advancing from level ", GameState.current_level - 1, " to ", GameState.current_level)
			print("LoadoutMenu: Level items should already be cleared, doing safety check...")
			loadout_manager.clear_level_items()
			GameState.clear_level_items_from_purchased()
		else:
			print("LoadoutMenu: Starting new run at level 1, keeping all purchased items")
		
		# Load purchased items from GameState (temporary items for this run)
		var purchased_items = GameState.get_purchased_items()
		if purchased_items.size() > 0:
			print("LoadoutMenu: Loading ", purchased_items.size(), " purchased items from GameState")
			for item_id in purchased_items:
				loadout_manager.add_available_item(item_id)
				print("LoadoutMenu: Added purchased item to available: ", item_id)
		
		# Load permanent items from GameState (add all copies, accounting for equipped ones)
		var permanent_items = GameState.get_permanent_items()
		if permanent_items.size() > 0:
			print("LoadoutMenu: Loading ", permanent_items.size(), " permanent items from GameState")
			
			# Count how many of each item are equipped
			var equipped_counts = {}
			for piece_id in loadout_manager.piece_loadouts.keys():
				var loadout = loadout_manager.piece_loadouts[piece_id]
				for equipped_item in loadout.get("permanent", []):
					if not equipped_counts.has(equipped_item):
						equipped_counts[equipped_item] = 0
					equipped_counts[equipped_item] += 1
			
			# Count how many of each item we own
			var owned_counts = {}
			for item_id in permanent_items:
				if not owned_counts.has(item_id):
					owned_counts[item_id] = 0
				owned_counts[item_id] += 1
			
			# Add unequipped copies to available
			for item_id in owned_counts.keys():
				var owned = owned_counts[item_id]
				var equipped = equipped_counts.get(item_id, 0)
				var available = owned - equipped
				
				print("LoadoutMenu: Item ", item_id, " - Owned: ", owned, " Equipped: ", equipped, " Available: ", available)
				
				# Add the available copies
				for i in range(available):
					loadout_manager.add_available_item(item_id)
					print("LoadoutMenu: Added unequipped permanent item to available: ", item_id)
	
	# Ensure this node can process input
	set_process_input(true)
	set_process_unhandled_input(true)
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	print("LoadoutMenu: Nodes should be ready now")
	print("LoadoutMenu size: ", size)
	print("LoadoutMenu visible: ", visible)
	print("LoadoutMenu position: ", position)
	print("LoadoutMenu: anchors: ", anchor_left, ",", anchor_top, ",", anchor_right, ",", anchor_bottom)
	
	# Connect button signals
	if back_to_menu_button:
		back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	
	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_button_pressed)
		print("LoadoutMenu: Start battle button connected")
	else:
		print("LoadoutMenu: Start battle button is null!")
	
	# Style the UI
	setup_ui_styling()
	
	# Create the formation display
	create_formation_display()
	
	# Populate items display
	populate_items_display()
	
	# Show initial loadout message
	show_loadout_instructions()
	
	print("LoadoutMenu: Initialization complete")

func setup_ui_styling():
	"""Apply styling to the loadout menu"""
	# Ensure the control is properly set up for fullscreen and blocks all input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Make sure background blocks all input too
	var background = $Background
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Title styling
	if title_label:
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Section title styling
	if formation_title:
		formation_title.add_theme_font_size_override("font_size", 20)
		formation_title.add_theme_color_override("font_color", Color.CYAN)
	if items_title:
		items_title.add_theme_font_size_override("font_size", 20)
		items_title.add_theme_color_override("font_color", Color.CYAN)
	if loadout_title:
		loadout_title.add_theme_font_size_override("font_size", 20)
		loadout_title.add_theme_color_override("font_color", Color.CYAN)
	
	# Button styling
	if back_to_menu_button:
		back_to_menu_button.add_theme_font_size_override("font_size", 16)
	if start_battle_button:
		start_battle_button.add_theme_font_size_override("font_size", 16)
		start_battle_button.modulate = Color.GOLD

func create_formation_display():
	"""Create the visual formation showing default starting positions"""
	# Wait for nodes to be ready
	if not formation_container:
		formation_container = $MainContainer/ContentContainer/FormationSection/FormationContainer
	
	if not formation_container:
		print("ERROR: formation_container still null, cannot create formation display")
		return
	
	# Clear any existing content
	for child in formation_container.get_children():
		child.queue_free()
	
	# Create two rows for player pieces (front rank first, then back rank to match original layout)
	var rows = [6, 7]  # Front rank (6) and back rank (7) - same as original
	
	for row in rows:
		var row_container = HBoxContainer.new()
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER
		row_container.add_theme_constant_override("separation", 5)
		
		# Add row label
		var row_label = Label.new()
		if row == 6:
			row_label.text = "Front:"
		else:
			row_label.text = "Back:"
		row_label.add_theme_font_size_override("font_size", 14)
		row_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		row_label.custom_minimum_size = Vector2(50, 0)
		row_container.add_child(row_label)
		
		# Create piece buttons for this row
		for col in range(8):
			var grid_pos = Vector2(col, row)
			var piece_button = create_formation_piece_button(grid_pos)
			row_container.add_child(piece_button)
		
		formation_container.add_child(row_container)
	
	# Add frame styling
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
	formation_container.add_theme_stylebox_override("panel", style_box)

func create_formation_piece_button(grid_pos: Vector2) -> Button:
	"""Create a button representing a piece in the default formation"""
	var piece_button = Button.new()
	piece_button.custom_minimum_size = Vector2(50, 50)  # Smaller buttons to fit better
	
	# Get piece data from default formation
	if default_formation.has(grid_pos):
		var piece_data = default_formation[grid_pos]
		
		# Set button appearance based on piece type
		if piece_data.type == "king":
			piece_button.text = "♔\nK"
			piece_button.modulate = Color.GOLD
		else:  # warrior
			piece_button.text = "⚔\nW"
			piece_button.modulate = Color(0.4, 0.7, 1.0)  # Light blue
		
		# Connect to selection handler
		piece_button.pressed.connect(func(): select_piece_for_loadout(grid_pos, piece_data))
		
		# Check if this piece has equipped items (when loadout_manager is available)
		if loadout_manager:
			var piece_id = generate_piece_id(grid_pos, piece_data.type)
			if has_equipped_items(piece_id):
				# Add equipped items indicator
				piece_button.modulate = piece_button.modulate * Color(1.2, 1.2, 1.2)  # Brighten
				piece_button.text += "\n●"  # Add dot indicator
	else:
		# This shouldn't happen with our default formation, but just in case
		piece_button.text = "□"
		piece_button.disabled = true
		piece_button.modulate = Color(0.3, 0.3, 0.3)
	
	return piece_button

func generate_piece_id(grid_pos: Vector2, piece_type: String) -> String:
	"""Generate consistent piece ID for loadout management"""
	return "player_" + piece_type + "_" + str(int(grid_pos.x)) + "_" + str(int(grid_pos.y))

func has_equipped_items(piece_id: String) -> bool:
	"""Check if a piece has any equipped items"""
	if not loadout_manager:
		print("LoadoutMenu: has_equipped_items - no loadout_manager")
		return false
	
	# Check if this piece exists in loadouts
	if not loadout_manager.piece_loadouts.has(piece_id):
		print("LoadoutMenu: Piece ", piece_id, " not found in loadouts")
		return false
	
	# Check all item slots for this piece using the actual LoadoutManager API
	var item_slots = ["permanent", "run", "level", "use"]
	for slot in item_slots:
		var equipped_items = loadout_manager.get_equipped_items(piece_id, slot)
		if equipped_items.size() > 0:
			print("LoadoutMenu: Piece ", piece_id, " has ", equipped_items.size(), " items in ", slot, " slot")
			return true
	return false

func select_piece_for_loadout(grid_pos: Vector2, piece_data: Dictionary):
	"""Handle when a piece is selected for loadout management"""
	selected_piece_pos = grid_pos
	selected_piece_data = piece_data
	
	var piece_id = generate_piece_id(grid_pos, piece_data.type)
	print("Selected piece for loadout: ", piece_id, " (", piece_data.type, ") at ", grid_pos)
	
	# Update the loadout display for this piece
	show_piece_loadout(piece_id, piece_data)

func show_piece_loadout(piece_id: String, piece_data: Dictionary):
	"""Display the loadout options for the selected piece"""
	# Wait for nodes to be ready
	if not loadout_container:
		loadout_container = $MainContainer/ContentContainer/LoadoutSection/LoadoutContainer/LoadoutContent
	
	if not loadout_container:
		print("ERROR: loadout_container still null, cannot show piece loadout")
		return
	
	# Clear existing loadout display
	for child in loadout_container.get_children():
		child.queue_free()
	
	# Create loadout header
	var header = Label.new()
	header.text = piece_data.name + " Equipment"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_container.add_child(header)
	
	# Add separator
	var separator = HSeparator.new()
	loadout_container.add_child(separator)
	
	# Create item slot sections
	var item_slots = [
		{"id": "permanent", "name": "Permanent Item", "description": "Permanent upgrade"},
		{"id": "run", "name": "Run Item", "description": "Lasts entire run"},
		{"id": "level", "name": "Level Item", "description": "Lasts this level only"},
		{"id": "use", "name": "Consumable", "description": "One-time use"}
	]
	
	for slot_info in item_slots:
		create_item_slot_section(piece_id, slot_info)

func create_item_slot_section(piece_id: String, slot_info: Dictionary):
	"""Create a section for one item slot type"""
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	
	# Slot label
	var slot_label = Label.new()
	slot_label.text = slot_info.name + ":"
	slot_label.add_theme_font_size_override("font_size", 14)
	slot_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	section.add_child(slot_label)
	
	# Item display
	var item_container = VBoxContainer.new()
	
	# Get currently equipped items for this slot
	var equipped_items = []
	if loadout_manager:
		equipped_items = loadout_manager.get_equipped_items(piece_id, slot_info.id)
		print("LoadoutMenu: Piece ", piece_id, " slot ", slot_info.id, " has items: ", equipped_items)
	else:
		print("LoadoutMenu: No loadout_manager available")
	
	if equipped_items.size() > 0:
		# Show equipped items
		for item_id in equipped_items:
			var item_row = HBoxContainer.new()
			
			var item_button = Button.new()
			var display_name = item_id.replace("_", " ").capitalize()
			item_button.text = display_name
			item_button.custom_minimum_size = Vector2(200, 35)
			item_button.add_theme_font_size_override("font_size", 12)
			item_button.add_theme_color_override("font_color", Color.WHITE)
			print("LoadoutMenu: Displaying item: ", display_name)
			item_row.add_child(item_button)
			
			var unequip_button = Button.new()
			unequip_button.text = "Remove"
			unequip_button.custom_minimum_size = Vector2(80, 35)
			unequip_button.add_theme_font_size_override("font_size", 12)
			unequip_button.pressed.connect(func(): unequip_item(piece_id, slot_info.id, item_id))
			item_row.add_child(unequip_button)
			
			item_container.add_child(item_row)
	else:
		# Show empty slot
		var empty_row = HBoxContainer.new()
		
		var empty_label = Label.new()
		empty_label.text = "No item equipped"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.custom_minimum_size = Vector2(150, 35)
		empty_row.add_child(empty_label)
		
		var equip_button = Button.new()
		equip_button.text = "Equip Item"
		equip_button.custom_minimum_size = Vector2(100, 35)
		equip_button.add_theme_font_size_override("font_size", 12)
		equip_button.pressed.connect(func(): show_item_selection(piece_id, slot_info.id))
		empty_row.add_child(equip_button)
		
		item_container.add_child(empty_row)
	
	section.add_child(item_container)
	
	# Add description
	var desc_label = Label.new()
	desc_label.text = slot_info.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.DARK_GRAY)
	section.add_child(desc_label)
	
	loadout_container.add_child(section)

func show_item_selection(piece_id: String, slot_type: String):
	"""Show available items for equipping in the specified slot"""
	if not loadout_manager:
		print("No loadout manager available")
		return
	
	# Get available items 
	var all_items = loadout_manager.get_available_items()
	print("LoadoutMenu: All available items: ", all_items)
	
	# Filter items by slot type using data_loader
	var available_items = []
	for item_id in all_items:
		if data_loader:
			var item_data = data_loader.get_item_by_id(item_id)
			if item_data:
				print("LoadoutMenu: Item ", item_id, " has type: ", item_data.get("type", "NO_TYPE"))
				if item_data.get("type", "") == slot_type:
					available_items.append(item_id)
			else:
				print("LoadoutMenu: Could not get item data for: ", item_id)
	
	print("LoadoutMenu: Filtered items for slot type '", slot_type, "': ", available_items)
	
	if available_items.is_empty():
		print("No items available for slot: ", slot_type, " - no items in inventory")
		
		# Create a simple dialog to inform the user
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No " + slot_type + " items available to equip. Items are earned by completing levels or found in shops."
		dialog.title = "No Items Available"
		add_child(dialog)
		dialog.popup_centered()
		dialog.confirmed.connect(func(): dialog.queue_free())
		return
	
	# Create item selection dialog
	create_item_selection_dialog(piece_id, slot_type, available_items)

func create_item_selection_dialog(piece_id: String, slot_type: String, available_items: Array):
	"""Create a dialog showing all available items to choose from"""
	# Create main dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Select Item for " + slot_type.capitalize() + " Slot"
	dialog.set_flag(Window.FLAG_RESIZE_DISABLED, false)
	dialog.size = Vector2(400, 300)
	
	# Create scroll container for items
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 200)
	
	var item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 5)
	
	# Add each available item as a selectable button
	for item_id in available_items:
		var item_row = HBoxContainer.new()
		
		# Get item display name (convert ID to readable name)
		var display_name = format_item_name(item_id)
		
		var item_button = Button.new()
		item_button.text = display_name
		item_button.custom_minimum_size = Vector2(250, 40)
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.add_theme_font_size_override("font_size", 12)
		
		# Connect to equip this specific item
		item_button.pressed.connect(func(): 
			print("LoadoutMenu: Item button pressed - item_id: ", item_id, ", piece_id: ", piece_id, ", slot_type: ", slot_type)
			equip_item(piece_id, slot_type, item_id)
			dialog.queue_free()
		)
		
		item_row.add_child(item_button)
		
		# Add item type indicator
		var type_label = Label.new()
		type_label.text = get_item_type_from_id(item_id)
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", Color.GRAY)
		type_label.custom_minimum_size = Vector2(80, 40)
		type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_row.add_child(type_label)
		
		item_list.add_child(item_row)
	
	scroll.add_child(item_list)
	dialog.add_child(scroll)
	
	# Add to scene and show
	add_child(dialog)
	dialog.popup_centered()
	
	# Clean up when dialog closes
	dialog.confirmed.connect(func(): dialog.queue_free())

func format_item_name(item_id: String) -> String:
	# Convert item ID to a readable display name
	# Try to get actual item name from data if available
	if data_loader:
		var item_data = data_loader.get_item_by_id(item_id)
		if item_data and item_data.has("name"):
			return item_data.name
	
	# Fallback to formatting the ID
	var display_name = item_id.replace("_", " ")
	var words = display_name.split(" ")
	var formatted_words = []
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	return " ".join(formatted_words)

func get_item_type_from_id(item_id: String) -> String:
	"""Extract item type from ID or data"""
	if data_loader:
		var item_data = data_loader.get_item_by_id(item_id)
		if item_data and item_data.has("type"):
			return item_data.type.capitalize()
	
	# Fallback - guess from ID patterns
	if "permanent" in item_id:
		return "Permanent"
	elif "run" in item_id:
		return "Run"
	elif "level" in item_id:
		return "Level"
	elif "use" in item_id:
		return "Consumable"
	else:
		return "Unknown"

func equip_item(piece_id: String, slot_type: String, item_id: String):
	"""Equip an item to the specified piece and slot"""
	print("LoadoutMenu: equip_item() called - piece_id: ", piece_id, ", slot_type: ", slot_type, ", item_id: ", item_id)
	
	if not loadout_manager:
		print("LoadoutMenu: ERROR - loadout_manager is null!")
		return
	
	print("LoadoutMenu: Calling loadout_manager.equip_item()")
	var success = loadout_manager.equip_item(piece_id, item_id, slot_type)
	print("LoadoutMenu: equip_item returned: ", success)
	
	if success:
		print("Equipped ", item_id, " to ", piece_id, " in ", slot_type, " slot")
		
		# Refresh the loadout display
		if selected_piece_data:
			show_piece_loadout(generate_piece_id(selected_piece_pos, selected_piece_data.type), selected_piece_data)
		
		# Refresh formation display to show equipment indicators
		create_formation_display()
		
		# Refresh items display
		populate_items_display()
	else:
		print("Failed to equip ", item_id, " to ", piece_id)

func unequip_item(piece_id: String, slot_type: String, item_id: String):
	"""Remove an item from the specified piece and slot"""
	if not loadout_manager:
		return
	
	var success = loadout_manager.unequip_item(piece_id, item_id, slot_type)
	if success:
		print("Unequipped ", item_id, " from ", piece_id, " ", slot_type, " slot")
		
		# Refresh the loadout display
		if selected_piece_data:
			show_piece_loadout(generate_piece_id(selected_piece_pos, selected_piece_data.type), selected_piece_data)
		
		# Refresh formation display to update equipment indicators
		create_formation_display()
		
		# Refresh items display
		populate_items_display()
	else:
		print("Failed to unequip ", item_id, " from ", piece_id)

func populate_items_display():
	"""Populate the items display showing all owned items by category"""
	if not items_container:
		print("ERROR: items_container is null")
		return
	
	if not loadout_manager or not data_loader:
		print("ERROR: managers not initialized")
		return
	
	# Clear existing display
	for child in items_container.get_children():
		child.queue_free()
	
	var all_items = loadout_manager.get_available_items()
	
	# Group items by type and count duplicates
	var items_by_type = {
		"permanent": {},
		"run": {},
		"level": {},
		"consumable": {}
	}
	
	for item_id in all_items:
		var item_data = data_loader.get_item_by_id(item_id)
		if item_data:
			var item_type = item_data.get("type", "consumable")
			if items_by_type.has(item_type):
				# Count items - if already exists, increment count
				if not items_by_type[item_type].has(item_id):
					items_by_type[item_type][item_id] = {"data": item_data, "count": 0}
				items_by_type[item_type][item_id]["count"] += 1
	
	# Display each category
	var type_labels = {
		"permanent": "Permanent Items",
		"run": "Run Items",
		"level": "Level Items",
		"consumable": "Consumables"
	}
	
	var type_colors = {
		"permanent": Color.GOLD,
		"run": Color.CYAN,
		"level": Color.LIGHT_GREEN,
		"consumable": Color.ORANGE
	}
	
	for type in ["permanent", "run", "level", "consumable"]:
		var items_dict = items_by_type[type]
		
		# Calculate total count
		var total_count = 0
		for item_id in items_dict.keys():
			total_count += items_dict[item_id]["count"]
		
		# Category header
		var category_label = Label.new()
		category_label.text = type_labels[type] + " (" + str(total_count) + ")"
		category_label.add_theme_font_size_override("font_size", 16)
		category_label.add_theme_color_override("font_color", type_colors[type])
		items_container.add_child(category_label)
		
		if items_dict.size() == 0:
			var empty_label = Label.new()
			empty_label.text = "  (none)"
			empty_label.add_theme_font_size_override("font_size", 12)
			empty_label.add_theme_color_override("font_color", Color.GRAY)
			items_container.add_child(empty_label)
		else:
			for item_id in items_dict.keys():
				var item_info = items_dict[item_id]
				var item_label = Label.new()
				# Show count if more than 1
				var count_text = ""
				if item_info["count"] > 1:
					count_text = " x" + str(item_info["count"])
				item_label.text = "  • " + item_info["data"].get("name", item_id) + count_text
				item_label.add_theme_font_size_override("font_size", 12)
				item_label.tooltip_text = item_info["data"].get("description", "")
				items_container.add_child(item_label)
		
		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		items_container.add_child(spacer)

func show_loadout_instructions():
	"""Show initial instructions when no piece is selected"""
	# Wait for nodes to be ready
	if not loadout_container:
		loadout_container = $MainContainer/ContentContainer/LoadoutSection/LoadoutContainer/LoadoutContent
	
	if not loadout_container:
		print("ERROR: loadout_container still null, cannot show instructions")
		return
	
	# Clear existing loadout display
	for child in loadout_container.get_children():
		child.queue_free()
	
	var instructions = Label.new()
	instructions.text = "Click on a piece in your formation to manage its equipment.\n\nEach piece can have:\n• Permanent items (permanent upgrades)\n• Run items (last entire run)\n• Level items (last this level only)\n• Consumables (one-time use)"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loadout_container.add_child(instructions)

func set_managers(loadout_mgr, data_ldr):
	"""Set manager references from the main game"""
	loadout_manager = loadout_mgr
	data_loader = data_ldr
	
	print("LoadoutMenu: Managers set - LoadoutManager: ", loadout_manager != null, " DataLoader: ", data_loader != null)
	
	if loadout_manager:
		print("LoadoutMenu: Available items: ", loadout_manager.get_available_items())
	
	# Refresh display now that we have manager access
	create_formation_display()
	if selected_piece_data:
		show_piece_loadout(generate_piece_id(selected_piece_pos, selected_piece_data.type), selected_piece_data)

func _on_back_to_menu_pressed():
	# Save loadout data to GameState and save
	print("LoadoutMenu: Returning to main menu")
	if loadout_manager:
		GameState.piece_loadouts = loadout_manager.piece_loadouts.duplicate(true)
		print("LoadoutMenu: Saved ", GameState.piece_loadouts.size(), " piece loadouts to GameState")
	GameState.save_current()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_start_battle_button_pressed():
	# Handle start battle button press
	print("LoadoutMenu: Starting battle, returning to main game scene")
	# Save loadout data to GameState before starting battle
	if loadout_manager:
		GameState.piece_loadouts = loadout_manager.piece_loadouts.duplicate(true)
		print("LoadoutMenu: Saved ", GameState.piece_loadouts.size(), " piece loadouts to GameState")
	# Save before starting battle
	GameState.save_current()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
