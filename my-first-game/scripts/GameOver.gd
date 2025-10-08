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
	# Set title based on outcome
	if title_label:
		if winner_text.to_lower() == "player":
			# Victory - show level completed
			var level_num = ""
			# Extract level number from army_info if available
			if army_info != "" and army_info.begins_with("Level "):
				var parts = army_info.split(":")
				if parts.size() > 0:
					level_num = parts[0]  # "Level X"
			
			if level_num != "":
				title_label.text = level_num.to_upper() + " COMPLETE!"
			else:
				title_label.text = "VICTORY!"
			title_label.add_theme_color_override("font_color", Color.GOLD)
		else:
			# Defeat - show game over
			title_label.text = "GAME OVER!"
			title_label.add_theme_color_override("font_color", Color.RED)
		
		title_label.add_theme_font_size_override("font_size", 48)
	
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
		
		# Add glyph loss info on defeat
		if winner_text.to_lower() != "player" and GameState.stuck_glyphs > 0:
			var spacer3 = Control.new()
			spacer3.custom_minimum_size = Vector2(0, 10)
			results_container.add_child(spacer3)
			
			var glyphs_lost_label = Label.new()
			glyphs_lost_label.text = "⚠ " + str(GameState.stuck_glyphs) + " Glyphs Lost! ⚠"
			glyphs_lost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyphs_lost_label.add_theme_font_size_override("font_size", 20)
			glyphs_lost_label.add_theme_color_override("font_color", Color.ORANGE_RED)
			results_container.add_child(glyphs_lost_label)
			
			var stuck_message = Label.new()
			stuck_message.text = "Your glyphs are stuck at Level " + str(GameState.stuck_at_level) + "!\nBeat that level to recover them."
			stuck_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stuck_message.add_theme_font_size_override("font_size", 14)
			stuck_message.add_theme_color_override("font_color", Color.LIGHT_CORAL)
			stuck_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			results_container.add_child(stuck_message)
	
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
		# Victory - end run and go to shop
		GameState.start_new_run()  # Reset level to 1, clear run items
		GameState.save_current()
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