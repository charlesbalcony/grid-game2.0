# Shop.gd
# Standalone shop scene for purchasing items with glyphs

extends Control

# References to child nodes
@onready var title_label = $MainContainer/Title
@onready var glyphs_label = $MainContainer/GlyphsLabel
@onready var shop_content = $MainContainer/ShopContainer/ShopContent
@onready var new_run_button = $MainContainer/ButtonsContainer/NewRunButton
@onready var quit_to_menu_button = $MainContainer/ButtonsContainer/BackButton  # Repurposed as Quit to Menu

# Managers
var shop_manager = null
var glyph_manager = null
var data_loader = null

func _ready():
	print("Shop: _ready() called")
	
	# Set up our own managers
	setup_managers()
	
	# Connect buttons
	if new_run_button:
		new_run_button.pressed.connect(_on_new_run_button_pressed)
	if quit_to_menu_button:
		quit_to_menu_button.pressed.connect(_on_quit_to_menu_button_pressed)
		quit_to_menu_button.text = "Quit to Menu"  # Update button text
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Setup shop content
	setup_shop_display()

func setup_managers():
	"""Initialize the managers we need"""
	# Data loader for item information
	data_loader = preload("res://scripts/systems/DataLoader.gd").new()
	data_loader.load_items()
	
	# Glyph manager for currency
	glyph_manager = preload("res://scripts/systems/GlyphManager.gd").new()
	
	# Load glyphs from GameState if available
	if GameState.current_glyphs > 0:
		glyph_manager.current_glyphs = GameState.current_glyphs
		print("Shop: Loaded ", GameState.current_glyphs, " glyphs from GameState")
	
	# Shop manager for shop logic
	shop_manager = preload("res://scripts/systems/ShopManager.gd").new()
	shop_manager.data_loader = data_loader
	
	print("Shop: Managers initialized")

func setup_shop_display():
	"""Setup the shop items display"""
	if not shop_manager or not glyph_manager:
		print("Shop: Managers not ready")
		return
	
	# Update glyphs display
	var current_glyphs = glyph_manager.get_current_glyphs()
	if glyphs_label:
		glyphs_label.text = "Glyphs: " + str(current_glyphs)
	
	# Clear existing shop content
	for child in shop_content.get_children():
		child.queue_free()
	
	# Get and display shop items
	var shop_items = shop_manager.get_shop_items()
	for item_data in shop_items:
		if item_data:
			var item_display = create_shop_item_display(item_data, current_glyphs)
			shop_content.add_child(item_display)

func create_shop_item_display(item_data, current_glyphs):
	"""Create a display for a shop item"""
	# Main container with margin and separator
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 5)
	
	# Center container to constrain width
	var center_container = CenterContainer.new()
	
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(800, 80)  # Fixed width to keep content together
	container.add_theme_constant_override("separation", 15)
	
	# Item info section (left side)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	
	# Count how many of this item we already own
	var item_id = item_data.get("id", item_data.get("name", "unknown"))
	var item_type = item_data.get("type", "consumable")
	var owned_count = 0
	
	# Check permanent items
	if item_type == "permanent":
		var permanent_items = GameState.get_permanent_items()
		for owned_id in permanent_items:
			if owned_id == item_id:
				owned_count += 1
	else:
		# Check purchased (run) items
		var purchased_items = GameState.get_purchased_items()
		for owned_id in purchased_items:
			if owned_id == item_id:
				owned_count += 1
	
	# Item name with rarity color
	var name_label = Label.new()
	var item_name = item_data.get("name", "Unknown Item")
	# Show owned count if any
	if owned_count > 0:
		name_label.text = item_name + " (Owned: " + str(owned_count) + ")"
	else:
		name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 16)
	
	# Apply rarity color
	var rarity = item_data.get("rarity", "common")
	name_label.modulate = get_rarity_color(rarity)
	info_vbox.add_child(name_label)
	
	# Piece type and item type
	var piece_type = item_data.get("piece", "Unknown")
	var type_text = get_type_display_text(item_type)
	var meta_label = Label.new()
	meta_label.text = "For: " + piece_type + " | Type: " + type_text
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.modulate = Color(0.9, 0.9, 0.5)
	info_vbox.add_child(meta_label)
	
	# Effect/Description
	var effect_label = Label.new()
	effect_label.text = item_data.get("effect", "No description")
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.modulate = Color(0.85, 0.85, 0.85)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.custom_minimum_size = Vector2(400, 0)
	info_vbox.add_child(effect_label)
	
	container.add_child(info_vbox)
	
	# Right side container for price and button
	var right_vbox = VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 8)
	right_vbox.custom_minimum_size = Vector2(120, 0)
	
	# Price and buy button
	var price = item_data.get("cost", item_data.get("glyph_cost", 10))
	var price_label = Label.new()
	price_label.text = str(price) + " Glyphs"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 13)
	right_vbox.add_child(price_label)
	
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(100, 35)
	buy_button.disabled = current_glyphs < price
	buy_button.pressed.connect(func(): _on_buy_item(item_data))
	right_vbox.add_child(buy_button)
	
	container.add_child(right_vbox)
	center_container.add_child(container)
	main_container.add_child(center_container)
	
	# Add separator line
	var separator = HSeparator.new()
	separator.modulate = Color(0.5, 0.5, 0.5, 0.5)
	main_container.add_child(separator)
	
	return main_container

func get_type_display_text(item_type: String) -> String:
	"""Convert item type to display text"""
	match item_type:
		"permanent":
			return "Permanent"
		"run":
			return "Run"
		"level":
			return "Level"
		"use":
			return "Active"
		_:
			return "Consumable"

func get_rarity_color(rarity: String) -> Color:
	"""Get color for item rarity"""
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color(0.3, 1.0, 0.3)  # Green
		"rare":
			return Color(0.4, 0.6, 1.0)  # Blue
		"epic":
			return Color(0.8, 0.4, 1.0)  # Purple
		"legendary":
			return Color(1.0, 0.84, 0.0)  # Gold
		_:
			return Color.GRAY

func _on_buy_item(item_data):
	# Handle buying an item
	var price = item_data.get("cost", item_data.get("glyph_cost", 10))
	var current_glyphs = glyph_manager.get_current_glyphs()
	
	if current_glyphs >= price:
		# Deduct glyphs
		glyph_manager.spend_glyphs(price)
		
		# Save updated glyphs to GameState
		GameState.current_glyphs = glyph_manager.get_current_glyphs()
		
		# Add item to GameState inventory (check if it's permanent or temporary)
		var item_id = item_data.get("id", item_data.get("name", "unknown"))
		var item_type = item_data.get("type", "consumable")
		
		if item_type == "permanent":
			GameState.add_permanent_item(item_id)
			print("Shop: Bought permanent item: ", item_data.get("name", "Unknown"), " (ID: ", item_id, ")")
		else:
			GameState.add_purchased_item(item_id)
			print("Shop: Bought temporary item: ", item_data.get("name", "Unknown"), " (ID: ", item_id, ")")
		
		# Show purchase confirmation popup
		show_purchase_confirmation(item_data.get("name", "Item"), price, glyph_manager.get_current_glyphs())
		
		# Refresh display
		setup_shop_display()
	else:
		# Show error popup
		show_insufficient_glyphs_popup(price, current_glyphs)

func _on_new_run_button_pressed():
	# Start a new run
	print("Shop: Starting new run - going to loadout menu")
	# Save before starting new run
	GameState.save_current()
	# Go to loadout menu to set up the army
	get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")

func _on_quit_to_menu_button_pressed():
	# Return to main menu and save
	print("Shop: Quitting to main menu")
	# Save before returning
	GameState.save_current()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_purchase_confirmation(item_name: String, glyphs_spent: int, remaining_glyphs: int):
	# Show a popup confirming the purchase
	var popup = AcceptDialog.new()
	popup.title = "Purchase Successful!"
	popup.dialog_text = "Purchased: %s\n\nGlyphs Spent: %d\nRemaining Glyphs: %d" % [item_name, glyphs_spent, remaining_glyphs]
	popup.ok_button_text = "OK"
	
	# Style the popup
	popup.min_size = Vector2(400, 200)
	
	# Add to scene and show
	add_child(popup)
	popup.popup_centered()
	
	# Clean up when closed
	popup.confirmed.connect(func(): popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())

func show_insufficient_glyphs_popup(price: int, current_glyphs: int):
	# Show a popup when player doesn't have enough glyphs
	var popup = AcceptDialog.new()
	popup.title = "Insufficient Glyphs"
	popup.dialog_text = "Not enough glyphs!\n\nRequired: %d\nYou have: %d\nNeed: %d more" % [price, current_glyphs, price - current_glyphs]
	popup.ok_button_text = "OK"
	
	# Style the popup
	popup.min_size = Vector2(400, 200)
	
	# Add to scene and show
	add_child(popup)
	popup.popup_centered()
	
	# Clean up when closed
	popup.confirmed.connect(func(): popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())
