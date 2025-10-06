# GameOver.gd
# Standalone game over scene

extends Control

# References to child nodes
@onready var title_label = $CenterContainer/Panel/MainContainer/Title
@onready var winner_label = $CenterContainer/Panel/MainContainer/WinnerLabel
@onready var results_container = $CenterContainer/Panel/MainContainer/ResultsContainer
@onready var shop_button = $CenterContainer/Panel/MainContainer/ButtonsContainer/ShopButton
@onready var new_game_button = $CenterContainer/Panel/MainContainer/ButtonsContainer/NewGameButton

# Game over data
var winner_text = "Unknown"
var reason = "elimination"
var glyphs_recovered = 0
var army_info = ""

func _ready():
	print("GameOver: _ready() called")
	
	# Enforce fullscreen
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Get game over data from GameState singleton
	var data = GameState.get_game_over_data()
	winner_text = data.get("winner", "Unknown")
	reason = data.get("reason", "elimination")
	glyphs_recovered = data.get("glyphs_recovered", 0)
	army_info = data.get("army_info", "")
	
	print("GameOver: Winner = ", winner_text, " Reason = ", reason)
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Connect buttons
	if shop_button:
		shop_button.pressed.connect(_on_shop_button_pressed)
		shop_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_button_pressed)
		new_game_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup display with data from GameState
	setup_display()

func setup_display():
	"""Setup the game over display"""
	# Set title
	if title_label:
		title_label.text = "GAME OVER!"
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.RED)
	
	# Set winner
	if winner_label:
		if winner_text.to_lower() == "player":
			winner_label.text = "VICTORY!"
			winner_label.add_theme_color_override("font_color", Color.GOLD)
		else:
			winner_label.text = "DEFEAT!"
			winner_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		winner_label.add_theme_font_size_override("font_size", 32)
	
	# Add results information
	if results_container:
		# Clear existing results
		for child in results_container.get_children():
			child.queue_free()
		
		# Add army info
		if army_info != "":
			var army_label = Label.new()
			army_label.text = army_info
			army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			army_label.add_theme_font_size_override("font_size", 18)
			army_label.add_theme_color_override("font_color", Color.WHITE)
			results_container.add_child(army_label)
			
			# Add spacer
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 20)
			results_container.add_child(spacer)
		
		# Add reason if not standard elimination
		if reason != "elimination":
			var reason_label = Label.new()
			reason_label.text = "Reason: " + reason.capitalize().replace("_", " ")
			reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reason_label.add_theme_font_size_override("font_size", 14)
			results_container.add_child(reason_label)
		
		# Add glyph recovery info
		if glyphs_recovered > 0:
			var spacer2 = Control.new()
			spacer2.custom_minimum_size = Vector2(0, 10)
			results_container.add_child(spacer2)
			
			var glyphs_label = Label.new()
			glyphs_label.text = "⚡ Glyphs Recovered: " + str(glyphs_recovered) + " ⚡"
			glyphs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyphs_label.add_theme_font_size_override("font_size", 20)
			glyphs_label.add_theme_color_override("font_color", Color.YELLOW)
			results_container.add_child(glyphs_label)
			
			var recovery_message = Label.new()
			recovery_message.text = "Your fallen pieces have been recovered!"
			recovery_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			recovery_message.add_theme_font_size_override("font_size", 14)
			recovery_message.add_theme_color_override("font_color", Color.LIGHT_BLUE)
			recovery_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			results_container.add_child(recovery_message)
	
	# Update button labels based on outcome
	if winner_text.to_lower() == "player":
		if new_game_button:
			new_game_button.text = "Next Level"
			new_game_button.add_theme_color_override("font_color", Color.GREEN)
		if shop_button:
			shop_button.text = "End Run & Visit Shop"
	else:
		if new_game_button:
			new_game_button.text = "Try Again"
			new_game_button.add_theme_color_override("font_color", Color.ORANGE)
		if shop_button:
			shop_button.text = "Main Menu"

func set_game_over_data(winner: String, end_reason: String = "elimination", recovered_glyphs: int = 0, army_details: String = ""):
	"""Set the game over data before display"""
	winner_text = winner
	reason = end_reason
	glyphs_recovered = recovered_glyphs
	army_info = army_details
	
	# If we're already ready, update the display
	if is_node_ready():
		setup_display()

func _on_shop_button_pressed():
	"""Go to the shop or main menu depending on outcome"""
	print("GameOver: Shop/Menu button pressed")
	if winner_text.to_lower() == "player":
		# Victory - go to shop
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")
	else:
		# Defeat - go to main menu
		GameState.save_current()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_new_game_button_pressed():
	"""Continue to next level or try again"""
	print("GameOver: New game button pressed")
	if winner_text.to_lower() == "player":
		# Victory - go to LoadoutMenu to prepare for next level
		get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
	else:
		# Defeat - restart at level 1
		get_tree().change_scene_to_file("res://scenes/Main.tscn")