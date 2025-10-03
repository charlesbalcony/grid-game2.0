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
	
	# Get game over data from GameState singleton
	var data = GameState.get_game_over_data()
	winner_text = data.get("winner", "Unknown")
	reason = data.get("reason", "elimination")
	glyphs_recovered = data.get("glyphs_recovered", 0)
	army_info = data.get("army_info", "")
	
	print("GameOver: Winner = ", winner_text, " Reason = ", reason)
	
	# Connect buttons
	if shop_button:
		shop_button.pressed.connect(_on_shop_button_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_button_pressed)
	
	# Setup display with data from GameState
	setup_display()

func setup_display():
	"""Setup the game over display"""
	# Set title
	if title_label:
		title_label.text = "GAME OVER!"
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color.RED)
	
	# Set winner
	if winner_label:
		winner_label.text = winner_text + " Wins!"
		winner_label.add_theme_font_size_override("font_size", 18)
		if winner_text.to_lower() == "player":
			winner_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			winner_label.add_theme_color_override("font_color", Color.ORANGE)
	
	# Add results information
	if results_container:
		# Clear existing results
		for child in results_container.get_children():
			child.queue_free()
		
		# Add game details
		if reason != "elimination":
			var reason_label = Label.new()
			reason_label.text = "Reason: " + reason.capitalize()
			reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			results_container.add_child(reason_label)
		
		if army_info != "":
			var army_label = Label.new()
			army_label.text = army_info
			army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			results_container.add_child(army_label)
		
		if glyphs_recovered > 0:
			var glyphs_label = Label.new()
			glyphs_label.text = "Glyphs Recovered: " + str(glyphs_recovered)
			glyphs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyphs_label.add_theme_color_override("font_color", Color.YELLOW)
			results_container.add_child(glyphs_label)
			
			var recovery_message = Label.new()
			recovery_message.text = "Your fallen pieces have been recovered and can be used again!"
			recovery_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			recovery_message.add_theme_font_size_override("font_size", 12)
			recovery_message.add_theme_color_override("font_color", Color.LIGHT_BLUE)
			recovery_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			results_container.add_child(recovery_message)

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
	"""Go to the shop"""
	print("GameOver: Going to shop")
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")

func _on_new_game_button_pressed():
	"""Start a new game"""
	print("GameOver: Starting new game")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")