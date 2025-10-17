extends Node2D

# Individual game piece script with combat stats

@export var piece_type: String = "warrior"
@export var team: String = "player"
@export var max_health: int = 100
@export var current_health: int = 100
@export var attack_power: int = 25
@export var defense: int = 0
@export var movement_range: int = 1

var piece_id: String = ""  # Unique identifier for this piece instance
var grid_position: Vector2
var is_selected: bool = false
var is_alive: bool = true

# Attack cooldown tracking (attack_name -> turns_remaining)
var attack_cooldowns: Dictionary = {}

# Base stats (before item bonuses)
var base_attack_power: int
var base_defense: int
var base_max_health: int

# Attack types available to this piece
var available_attacks = [
	{"name": "Basic Attack", "damage": 25, "range": 1, "description": "Standard melee attack"},
	{"name": "Heavy Strike", "damage": 40, "range": 1, "description": "Powerful attack with high damage"},
	{"name": "Quick Jab", "damage": 15, "range": 1, "description": "Fast attack with low damage"}
]

# Store piece type data for attacks and abilities (from PieceFactory)
var piece_type_data = null

signal piece_died(piece)
signal piece_damaged(piece, damage)

func _ready():
	# Store base stats before any item modifications
	base_attack_power = attack_power
	base_defense = defense
	base_max_health = max_health
	
	current_health = max_health
	setup_appearance()
	create_health_bar()
	
	# Apply item effects after setup - try multiple times to ensure it works
	call_deferred("apply_equipped_item_effects")
	# Also try again after a short delay in case systems aren't ready
	await get_tree().create_timer(0.1).timeout
	apply_equipped_item_effects()

func setup_appearance():
	"""Set up visual appearance - tries to load PNG texture first, falls back to colored rectangles"""
	# Try to load texture from assets folder
	var texture_path = "res://assets/%s_%s.png" % [piece_type, team]
	var texture = load_texture_if_exists(texture_path)
	
	var sprite = $PieceSprite
	var border = $Border
	
	if texture:
		# Use texture - need to replace ColorRect with Sprite2D
		print("✓ Loading texture for ", piece_type, " (", team, "): ", texture_path)
		
		# Check if we already converted to Sprite2D
		if sprite and sprite is Sprite2D:
			sprite.texture = texture
			var tex_size = texture.get_size()
			var scale_factor = 70.0 / max(tex_size.x, tex_size.y)
			sprite.scale = Vector2(scale_factor, scale_factor)
		elif sprite and sprite is ColorRect:
			# Remove the ColorRect and create Sprite2D
			var sprite_index = sprite.get_index()
			sprite.queue_free()
			
			# Create new Sprite2D
			var new_sprite = Sprite2D.new()
			new_sprite.name = "PieceSprite"
			new_sprite.texture = texture
			new_sprite.centered = true
			new_sprite.position = Vector2(0, 0)
			
			# Scale to fit approximately 70x70 pixels
			var tex_size = texture.get_size()
			var scale_factor = 70.0 / max(tex_size.x, tex_size.y)
			new_sprite.scale = Vector2(scale_factor, scale_factor)
			
			add_child(new_sprite)
			move_child(new_sprite, sprite_index)  # Keep same position in hierarchy
		
		# Hide border when using texture
		if border:
			border.visible = false
	else:
		# Fall back to colored rectangles
		print("✗ No texture found for ", piece_type, " (", team, "), using colored rectangle")
		if sprite and sprite is ColorRect:
			if team == "player":
				sprite.color = Color(0.1, 0.5, 0.9)  # Bright blue
				border.color = Color(0.0, 0.2, 0.6)  # Dark blue border
			else:
				sprite.color = Color(0.9, 0.2, 0.1)  # Bright red
				border.color = Color(0.6, 0.0, 0.0)  # Dark red border

func load_texture_if_exists(path: String) -> Texture2D:
	"""Try to load a texture, return null if it doesn't exist"""
	print("  Checking path: ", path)
	
	# First try the normal Godot resource loading (for imported assets)
	if ResourceLoader.exists(path):
		print("  ResourceLoader.exists(): true - loading via ResourceLoader")
		var loaded = load(path)
		print("  Loaded successfully: ", loaded != null)
		return loaded
	
	# If not imported yet, try loading directly from file system
	print("  ResourceLoader.exists(): false - trying direct file load")
	var absolute_path = ProjectSettings.globalize_path(path)
	print("  Absolute path: ", absolute_path)
	
	if FileAccess.file_exists(absolute_path):
		print("  File exists! Loading as Image...")
		var image = Image.new()
		var error = image.load(absolute_path)
		if error == OK:
			print("  Image loaded successfully, creating texture...")
			var texture = ImageTexture.create_from_image(image)
			return texture
		else:
			print("  Failed to load image, error code: ", error)
	else:
		print("  File not found at absolute path")
	
	return null

func create_health_bar():
	# Create a health bar above the piece
	var health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(60, 8)
	health_bar_bg.position = Vector2(-30, -45)
	health_bar_bg.color = Color(0.2, 0.2, 0.2)
	health_bar_bg.name = "HealthBarBG"
	add_child(health_bar_bg)
	
	var health_bar = ColorRect.new()
	health_bar.size = Vector2(56, 6)
	health_bar.position = Vector2(-28, -44)
	health_bar.color = Color(0.0, 0.8, 0.0)
	health_bar.name = "HealthBar"
	add_child(health_bar)
	
	# Add team indicator
	var team_indicator = Label.new()
	team_indicator.position = Vector2(-15, -65)
	team_indicator.size = Vector2(30, 15)
	team_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	team_indicator.add_theme_font_size_override("font_size", 10)
	
	if team == "player":
		if piece_type == "king":
			team_indicator.text = "K"
		else:
			team_indicator.text = "P"
		team_indicator.add_theme_color_override("font_color", Color.BLACK)
	else:
		if piece_type == "king":
			team_indicator.text = "K"
		else:
			team_indicator.text = "E"
		team_indicator.add_theme_color_override("font_color", Color.BLACK)
	
	team_indicator.name = "TeamIndicator"
	add_child(team_indicator)
	
	update_health_bar()

func update_health_bar():
	var health_bar = get_node("HealthBar")
	if health_bar:
		var health_percent = float(current_health) / float(max_health)
		health_bar.size.x = 56 * health_percent
		
		# Change color based on health
		if health_percent > 0.6:
			health_bar.color = Color(0.0, 0.8, 0.0)  # Green
		elif health_percent > 0.3:
			health_bar.color = Color(0.8, 0.8, 0.0)  # Yellow
		else:
			health_bar.color = Color(0.8, 0.0, 0.0)  # Red

func set_grid_position(pos: Vector2):
	grid_position = pos

func set_selected(selected: bool):
	is_selected = selected
	if selected:
		$PieceSprite.color = $PieceSprite.color.lightened(0.4)
		$Border.color = Color.WHITE  # White border when selected
	else:
		setup_appearance()

func set_piece_type_data(type_data):
	"""Set piece type data from PieceFactory for attacks and abilities"""
	piece_type_data = type_data
	if type_data and type_data.available_attacks:
		# Use the AttackData objects directly to preserve all properties including cooldowns
		available_attacks = type_data.available_attacks.duplicate()
		print("Set ", available_attacks.size(), " attacks for ", piece_type)

func take_damage(damage: int):
	var original_damage = damage
	var blocked_damage = defense
	var actual_damage = max(1, damage - defense)  # Minimum 1 damage
	
	current_health -= actual_damage
	current_health = max(0, current_health)
	
	update_health_bar()
	piece_damaged.emit(self, actual_damage)
	
	# Enhanced damage logging with blocking information
	if blocked_damage > 0:
		var effective_blocked = min(blocked_damage, original_damage - 1)  # Can't block below 1 damage
		print(piece_type, " (", team, ") took ", actual_damage, " damage (", original_damage, " - ", effective_blocked, " blocked). Health: ", current_health, "/", max_health)
		
		# Show damage blocking notification
		show_damage_block_notification(effective_blocked)
	else:
		print(piece_type, " (", team, ") took ", actual_damage, " damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func show_damage_block_notification(blocked_amount: int):
	"""Show a notification about damage being blocked"""
	if blocked_amount <= 0:
		return
	
	# Add to event feed via UI manager (no more floating text)
	var scene_root = get_tree().current_scene
	if scene_root and scene_root.has_method("get_ui_manager"):
		var ui_manager = scene_root.get_ui_manager()
		if ui_manager:
			ui_manager.show_defense_notification(team, piece_type, blocked_amount)

func die():
	is_alive = false
	piece_died.emit(self)
	
	# Visual feedback for death
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(queue_free)
	
	print(piece_type, " (", team, ") has died!")

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	update_health_bar()
	print(piece_type, " (", team, ") healed for ", amount, ". Health: ", current_health, "/", max_health)

func get_available_attacks() -> Array:
	return available_attacks

func get_stats() -> Dictionary:
	return {
		"type": piece_type,
		"team": team,
		"current_health": current_health,
		"max_health": max_health,
		"attack_power": attack_power,
		"defense": defense,
		"movement_range": movement_range,
		"is_alive": is_alive
	}

func apply_equipped_item_effects():
	"""Apply effects from equipped items to this piece"""
	print("=== APPLYING ITEM EFFECTS FOR PIECE ===")
	print("Piece ID: ", piece_id)
	print("Piece Type: ", piece_type, " (", team, ")")
	
	# Get the game board to access LoadoutManager
	var game_board = get_tree().get_first_node_in_group("game_board")
	if not game_board:
		# Try to find the game board through parent nodes
		var current_node = get_parent()
		while current_node:
			if current_node.has_method("get_loadout_manager"):
				game_board = current_node
				break
			current_node = current_node.get_parent()
	
	if not game_board or not game_board.has_method("get_loadout_manager"):
		print("ERROR: Could not find LoadoutManager to apply item effects for piece: ", piece_id)
		return
	
	var loadout_manager = game_board.get_loadout_manager()
	if not loadout_manager:
		print("ERROR: LoadoutManager is null")
		return
	
	print("Found LoadoutManager, checking equipped items...")
	
	# Reset stats to base values first
	attack_power = base_attack_power
	defense = base_defense
	max_health = base_max_health
	print("Reset to base stats - ATK:", attack_power, " DEF:", defense, " HP:", max_health)
	
	# Get equipped items for this piece instance
	var equipped_items = loadout_manager.get_equipped_items(piece_id)
	print("Found ", equipped_items.size(), " equipped items: ", equipped_items)
	
	if equipped_items.is_empty():
		print("No items equipped for this piece")
		return
	
	# Get data loader to look up item details
	var data_loader = null
	
	# Try to get data loader from shop manager
	if game_board.has_method("get_shop_manager"):
		var shop_manager = game_board.get_shop_manager()
		if shop_manager and "data_loader" in shop_manager:
			data_loader = shop_manager.data_loader
			print("Found data_loader through shop_manager")
	
	# If still no data loader, try direct access to shop_manager property
	if not data_loader and "shop_manager" in game_board:
		var shop_manager = game_board.shop_manager
		if shop_manager and "data_loader" in shop_manager:
			data_loader = shop_manager.data_loader
			print("Found data_loader through direct shop_manager access")
	
	# Try alternative access through UI manager
	if not data_loader and game_board.has_method("get_ui_manager"):
		var ui_manager = game_board.get_ui_manager()
		if ui_manager and "data_loader" in ui_manager:
			data_loader = ui_manager.data_loader
			print("Found data_loader through ui_manager")
	
	if not data_loader:
		print("ERROR: Could not find data loader to apply item effects for piece: ", piece_id)
		print("Available shop_manager: ", game_board.shop_manager)
		if game_board.shop_manager:
			print("Shop manager properties: ", game_board.shop_manager.get_property_list())
		return
	
	print("Applying item effects for piece ", piece_id, " - Found ", equipped_items.size(), " equipped items")
	
	# Apply effects from each equipped item
	for item_id in equipped_items:
		var item_data = data_loader.get_item_by_id(item_id)
		if not item_data:
			continue
		
		var effect = item_data.get("effect", "").to_lower()
		print("Applying effect: ", effect, " from item: ", item_data.get("name", item_id))
		
		# Parse and apply different types of effects
		if "takes" in effect and "less damage" in effect:
			# Damage reduction effects (like "takes 25 less damage")
			var damage_reduction = extract_number_from_effect(effect)
			if damage_reduction > 0:
				defense += damage_reduction
				print("  -> Added ", damage_reduction, " defense")
		
		elif "gain" in effect and "attack" in effect:
			# Attack bonus effects (like "gain +40 attack")
			var attack_bonus = extract_number_from_effect(effect)
			if attack_bonus > 0:
				attack_power += attack_bonus
				print("  -> Added ", attack_bonus, " attack power")
		
		elif "sacrifice" in effect and "hp" in effect and "gain" in effect and "attack" in effect:
			# Sacrifice HP for attack (like "Sacrifice 25 HP to gain +60 attack")
			var hp_cost = extract_first_number_from_effect(effect)
			var attack_bonus = extract_second_number_from_effect(effect)
			if hp_cost > 0 and attack_bonus > 0:
				max_health = max(1, max_health - hp_cost)  # Don't go below 1 HP
				current_health = min(current_health, max_health)
				attack_power += attack_bonus
				print("  -> Sacrificed ", hp_cost, " HP for ", attack_bonus, " attack")
		
		# Additional effect types can be added here
	
	# Update health bar in case max health changed
	update_health_bar()
	
	print("Final stats for ", piece_id, ": ATK=", attack_power, " DEF=", defense, " HP=", current_health, "/", max_health)

func extract_number_from_effect(effect_text: String) -> int:
	"""Extract a number from effect text (looks for numbers after + or standalone numbers)"""
	var regex = RegEx.new()
	regex.compile("[+]?(\\d+)")
	var result = regex.search(effect_text)
	if result:
		return result.get_string(1).to_int()
	return 0

func extract_first_number_from_effect(effect_text: String) -> int:
	"""Extract the first number from effect text"""
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	var result = regex.search(effect_text)
	if result:
		return result.get_string(1).to_int()
	return 0

func extract_second_number_from_effect(effect_text: String) -> int:
	"""Extract the second number from effect text"""
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	var results = regex.search_all(effect_text)
	if results.size() >= 2:
		return results[1].get_string(1).to_int()
	return 0

func refresh_item_effects():
	"""Call this when items are equipped/unequipped to refresh effects"""
	apply_equipped_item_effects()
	debug_show_stats()

func debug_show_stats():
	"""Debug method to show current piece stats"""
	print("=== PIECE STATS DEBUG ===")
	print("Piece ID: ", piece_id)
	print("Type: ", piece_type, " (", team, ")")
	print("Base Stats - ATK:", base_attack_power, " DEF:", base_defense, " HP:", base_max_health)
	print("Current Stats - ATK:", attack_power, " DEF:", defense, " HP:", current_health, "/", max_health)
	print("=========================")

func reduce_cooldowns():
	"""Reduce all attack cooldowns by 1 at the start of this piece's turn"""
	for attack_name in attack_cooldowns.keys():
		if attack_cooldowns[attack_name] > 0:
			attack_cooldowns[attack_name] -= 1
			print(piece_type, " cooldown reduced: ", attack_name, " -> ", attack_cooldowns[attack_name], " turns remaining")

func trigger_attack_cooldown(attack):
	"""Start cooldown for an attack after it's used"""
	var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "")
	var cooldown_max = attack.cooldown_max if typeof(attack) == TYPE_OBJECT else attack.get("cooldown_max", 0)
	
	if cooldown_max > 0:
		attack_cooldowns[attack_name] = cooldown_max
		print(piece_type, " used ", attack_name, " - cooldown: ", cooldown_max, " turns")

func is_attack_on_cooldown(attack) -> bool:
	"""Check if an attack is currently on cooldown"""
	var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "")
	var cooldown_max = attack.cooldown_max if typeof(attack) == TYPE_OBJECT else attack.get("cooldown_max", 0)
	
	if cooldown_max == 0:
		return false  # No cooldown, always available
	return attack_cooldowns.get(attack_name, 0) > 0

func get_attack_cooldown_remaining(attack) -> int:
	"""Get the number of turns remaining on an attack's cooldown"""
	var attack_name = attack.name if typeof(attack) == TYPE_OBJECT else attack.get("name", "")
	return attack_cooldowns.get(attack_name, 0)

func set_piece_id(id: String):
	"""Set the piece ID from external code"""
	piece_id = id
	print("Piece ID set to: ", piece_id)