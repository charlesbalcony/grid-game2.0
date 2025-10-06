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
	
	# Wait for tree to be ready
	await get_tree().process_frame
	
	# Connect buttons
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Style the menu
	setup_styling()
	
	# Update save info
	update_save_info()
	
	# Check if we have a save to continue from
	if GameState and GameState.save_manager:
		if GameState.current_save_name == "" or not GameState.save_manager.save_exists(GameState.current_save_name):
			continue_button.disabled = true

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
	
	# Save info
	if save_info_label:
		save_info_label.add_theme_font_size_override("font_size", 14)
		save_info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

func update_save_info():
	if not save_info_label or not GameState.save_manager:
		return
	
	var save_name = GameState.current_save_name
	if save_name != "" and GameState.save_manager.save_exists(save_name):
		var info = GameState.save_manager.get_save_info(save_name)
		save_info_label.text = "Save: %s | Glyphs: %d | High Score: %d" % [
			save_name,
			info.get("glyphs", 0),
			info.get("high_score", 0)
		]
	else:
		save_info_label.text = ""  # Clear the text instead of showing "No save file found"
		continue_button.disabled = true

func _on_continue_pressed():
	print("MainMenu: Continue game")
	GameState.load_save(GameState.current_save_name)
	get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")

func _on_new_game_pressed():
	print("MainMenu: New game")
	show_new_game_dialog()

func _on_load_game_pressed():
	print("MainMenu: Load game")
	show_load_game_dialog()

func _on_quit_pressed():
	print("MainMenu: Quit game")
	GameState.save_current()
	get_tree().quit()

func show_new_game_dialog():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = ""  # Clear this to avoid overlap with custom content
	dialog.title = "New Game"
	dialog.min_size = Vector2(400, 150)
	
	# Add text input for save name
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = "Save Name:"
	vbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.text = "save_" + str(Time.get_unix_time_from_system())
	line_edit.placeholder_text = "Enter save name..."
	line_edit.custom_minimum_size = Vector2(300, 40)
	vbox.add_child(line_edit)
	
	dialog.add_child(vbox)
	
	dialog.confirmed.connect(func():
		var save_name = line_edit.text.strip_edges()
		if save_name.is_empty():
			save_name = "save_" + str(Time.get_unix_time_from_system())
		
		# Check if save already exists
		if GameState.save_manager.save_exists(save_name):
			print("MainMenu: Save already exists, asking for overwrite confirmation")
			show_overwrite_confirmation(save_name)
			dialog.queue_free()
		else:
			# Create new save with the given name
			print("MainMenu: Creating new save: ", save_name)
			GameState.create_new_save(save_name)
			GameState.start_new_run()
			update_save_info()
			get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
			dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	
	add_child(dialog)
	dialog.popup_centered()

func show_load_game_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Load Game"
	dialog.dialog_text = ""  # Clear this to avoid overlap with custom content
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
			
			# Create horizontal container for save button and delete button
			var save_row = HBoxContainer.new()
			save_row.add_theme_constant_override("separation", 5)
			
			var save_button = Button.new()
			save_button.text = "%s\nGlyphs: %d | High Score: %d | Last played: %s" % [
				save_name,
				save_info.get("glyphs", 0),
				save_info.get("high_score", 0),
				save_info.get("last_played", "Unknown")
			]
			save_button.custom_minimum_size = Vector2(0, 60)
			save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			save_button.pressed.connect(func():
				GameState.load_save(save_name)
				update_save_info()
				# Load and continue directly to LoadoutMenu
				print("MainMenu: Loaded save '", save_name, "' and continuing to LoadoutMenu")
				get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
				dialog.queue_free()
			)
			save_row.add_child(save_button)
			
			# Add delete button
			var delete_button = Button.new()
			delete_button.text = "✖"
			delete_button.custom_minimum_size = Vector2(40, 60)
			delete_button.tooltip_text = "Delete this save"
			delete_button.add_theme_color_override("font_color", Color.RED)
			delete_button.pressed.connect(func():
				show_delete_confirmation(save_name, dialog)
			)
			save_row.add_child(delete_button)
			
			save_list.add_child(save_row)
	
	scroll.add_child(save_list)
	dialog.add_child(scroll)
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func show_overwrite_confirmation(save_name: String):
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "A save named '" + save_name + "' already exists. Overwrite it?"
	confirm.title = "Overwrite Save?"
	
	confirm.confirmed.connect(func():
		print("MainMenu: Overwriting save: ", save_name)
		GameState.create_new_save(save_name)
		GameState.start_new_run()
		update_save_info()
		get_tree().change_scene_to_file("res://scenes/LoadoutMenu.tscn")
		confirm.queue_free()
	)
	
	confirm.canceled.connect(func():
		confirm.queue_free()
		show_new_game_dialog()  # Show the save name dialog again
	)
	
	add_child(confirm)
	confirm.popup_centered()

func show_delete_confirmation(save_name: String, parent_dialog: Window):
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Delete '%s'?\nThis cannot be undone." % save_name
	confirm.title = "Delete Save?"
	confirm.ok_button_text = "Delete"
	
	# Make the delete button red
	confirm.confirmed.connect(func():
		print("MainMenu: Deleting save: ", save_name)
		GameState.save_manager.delete_save(save_name)
		
		# If we deleted the current save, clear it from GameState
		if GameState.current_save_name == save_name:
			GameState.current_save_name = ""
			GameState.current_glyphs = 0
			GameState.permanent_items.clear()
			GameState.piece_loadouts.clear()
		
		update_save_info()
		confirm.queue_free()
		parent_dialog.queue_free()
		# Reopen the load dialog with updated list
		show_load_game_dialog()
	)
	
	confirm.canceled.connect(func():
		confirm.queue_free()
	)
	
	add_child(confirm)
	confirm.popup_centered()
