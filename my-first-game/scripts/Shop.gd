# Shop.gd
# Standalone shop scene for purchasing items with glyphs

extends Control

# References to child nodes
@onready var title_label = $MainContainer/Title
@onready var glyphs_label = $MainContainer/GlyphsLabel
@onready var shop_content = $MainContainer/ShopContainer/ShopContent
@onready var new_run_button = $MainContainer/ButtonsContainer/NewRunButton
@onready var back_button = $MainContainer/ButtonsContainer/BackButton

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
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
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
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 50)
	
	# Item info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = item_data.get("name", "Unknown Item")
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "No description")
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)
	
	container.add_child(info_vbox)
	
	# Price and buy button
	var price = item_data.get("glyph_cost", 10)
	var price_label = Label.new()
	price_label.text = str(price) + " Glyphs"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.custom_minimum_size = Vector2(80, 0)
	container.add_child(price_label)
	
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(60, 0)
	buy_button.disabled = current_glyphs < price
	buy_button.pressed.connect(func(): _on_buy_item(item_data))
	container.add_child(buy_button)
	
	return container

func _on_buy_item(item_data):
	# Handle buying an item
	var price = item_data.get("glyph_cost", 10)
	var current_glyphs = glyph_manager.get_current_glyphs()
	
	if current_glyphs >= price:
		# Deduct glyphs
		glyph_manager.spend_glyphs(price)
		
		# Save updated glyphs to GameState
		GameState.current_glyphs = glyph_manager.get_current_glyphs()
		
		# Add item to GameState inventory
		var item_id = item_data.get("id", item_data.get("name", "unknown"))
		GameState.add_purchased_item(item_id)
		print("Shop: Bought item: ", item_data.get("name", "Unknown"), " (ID: ", item_id, ")")
		
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
	# Go to loadout menu to set up the army
	get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")

func _on_back_button_pressed():
	# Go back to the game
	print("Shop: Returning to game")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

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
