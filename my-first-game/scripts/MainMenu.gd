# MainMenu.gd
# Main menu for the game

extends Control

@onready var continue_button = $MenuContainer/ContinueButton
@onready var new_game_button = $MenuContainer/NewGameButton
@onready var load_game_button = $MenuContainer/LoadGameButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var save_info_label = $MenuContainer/SaveInfo
@onready var title_label = $MenuContainer/Title

func _ready():
	print("MainMenu: _ready() called")
	
	# Enforce fullscreen
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("MainMenu: Set fullscreen mode")
	
	# Wait for tree to be ready
	await get_tree().process_frame
	
	print("MainMenu: Tree ready, connecting buttons")
	
	# Connect buttons
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		print("MainMenu: Continue button connected")
	else:
		print("MainMenu: ERROR - continue_button is null!")
	
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
		print("MainMenu: New game button connected")
	else:
		print("MainMenu: ERROR - new_game_button is null!")
	
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
		print("MainMenu: Load game button connected")
	else:
		print("MainMenu: ERROR - load_game_button is null!")
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("MainMenu: Quit button connected")
	else:
		print("MainMenu: ERROR - quit_button is null!")
	
	# Style the menu
	setup_styling()
	
	print("MainMenu: About to update save info")
	# Update save info
	update_save_info()
	print("MainMenu: Save info updated")
	
	# Check if we have a save to continue from
	if GameState and GameState.save_manager:
		if not GameState.save_manager.save_exists(GameState.current_save_name):
			continue_button.disabled = true
			print("MainMenu: No save exists, disabling continue button")
		else:
			print("MainMenu: Save exists, continue button enabled")
	else:
		print("MainMenu: ERROR - GameState or save_manager is null!")
	
	# Ensure input processing is enabled
	set_process_input(true)
	set_process_unhandled_input(true)
	
	print("MainMenu: _ready() complete")

func _process(_delta):
	# Keyboard shortcuts since mouse isn't working
	if Input.is_key_pressed(KEY_C):
		_on_continue_pressed()
	if Input.is_key_pressed(KEY_N):
		_on_new_game_pressed()
	if Input.is_key_pressed(KEY_L):
		_on_load_game_pressed()
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_ESCAPE):
		_on_quit_pressed()

func _input(event):
	print("MainMenu: _input called with event: ", event)
	if event is InputEventMouseButton:
		print("MainMenu: Mouse click detected at: ", event.position, " pressed: ", event.pressed)

func setup_styling():
	# Title
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Buttons
	for button in [continue_button, new_game_button, load_game_button, quit_button]:
		if button:
			button.add_theme_font_size_override("font_size", 20)
			button.focus_mode = Control.FOCUS_ALL
			print("MainMenu: Styled button: ", button.name)
	
	# Save info
	if save_info_label:
		save_info_label.add_theme_font_size_override("font_size", 14)
		save_info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

func update_save_info():
	if not save_info_label or not GameState.save_manager:
		return
	
	var save_name = GameState.current_save_name
	if GameState.save_manager.save_exists(save_name):
		var info = GameState.save_manager.get_save_info(save_name)
		save_info_label.text = "Save: %s | Glyphs: %d | Items: %d | High Score: %d" % [
			save_name,
			info.get("glyphs", 0),
			info.get("permanent_items", 0),
			info.get("high_score", 0)
		]
	else:
		save_info_label.text = "No save file found"

func _on_continue_pressed():
	print("MainMenu: Continue button PRESSED!")
	print("MainMenu: Continue game")
	# Load the existing save and go to loadout menu
	GameState.load_save(GameState.current_save_name)
	get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")

func _on_new_game_pressed():
	print("MainMenu: New Game button PRESSED!")
	print("MainMenu: New game")
	# Show dialog to create new save or overwrite
	show_new_game_dialog()

func _on_load_game_pressed():
	print("MainMenu: Load Game button PRESSED!")
	print("MainMenu: Load game")
	# Show load game dialog
	show_load_game_dialog()

func _on_quit_pressed():
	print("MainMenu: Quit button PRESSED!")
	print("MainMenu: Quit game")
	# Save before quitting
	GameState.save_current()
	get_tree().quit()

func show_new_game_dialog():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Start a new game? This will reset your current progress."
	dialog.title = "New Game"
	
	dialog.confirmed.connect(func():
		# Reset current save or create new one
		GameState.create_new_save("default")
		GameState.start_new_run()
		get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	
	add_child(dialog)
	dialog.popup_centered()

func show_load_game_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Load Game"
	dialog.dialog_text = "Select a save file:"
	dialog.min_size = Vector2(400, 300)
	
	# Create list of save files
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 200)
	
	var save_list = VBoxContainer.new()
	save_list.add_theme_constant_override("separation", 10)
	
	var saves = GameState.save_manager.get_save_list()
	
	if saves.size() == 0:
		var no_saves_label = Label.new()
		no_saves_label.text = "No save files found"
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list.add_child(no_saves_label)
	else:
		for save_name in saves:
			var save_info = GameState.save_manager.get_save_info(save_name)
			
			var save_button = Button.new()
			save_button.text = "%s - Glyphs: %d | Items: %d | Score: %d\nLast played: %s" % [
				save_name,
				save_info.get("glyphs", 0),
				save_info.get("permanent_items", 0),
				save_info.get("high_score", 0),
				save_info.get("last_played", "Unknown")
			]
			save_button.custom_minimum_size = Vector2(0, 60)
			save_button.pressed.connect(func():
				GameState.load_save(save_name)
				update_save_info()
				continue_button.disabled = false
				dialog.queue_free()
			)
			save_list.add_child(save_button)
	
	scroll.add_child(save_list)
	dialog.add_child(scroll)
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
