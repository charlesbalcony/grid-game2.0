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

# Attack types available to this piece
var available_attacks = [
	{"name": "Basic Attack", "damage": 25, "range": 1, "description": "Standard melee attack"},
	{"name": "Heavy Strike", "damage": 40, "range": 1, "description": "Powerful attack with high damage"},
	{"name": "Quick Jab", "damage": 15, "range": 1, "description": "Fast attack with low damage"}
]

signal piece_died(piece)
signal piece_damaged(piece, damage)

func _ready():
	current_health = max_health
	setup_appearance()
	create_health_bar()

func setup_appearance():
	# Set initial appearance based on team
	var sprite = $PieceSprite
	var border = $Border
	
	if team == "player":
		sprite.color = Color(0.1, 0.5, 0.9)  # Bright blue
		border.color = Color(0.0, 0.2, 0.6)  # Dark blue border
	else:
		sprite.color = Color(0.9, 0.2, 0.1)  # Bright red
		border.color = Color(0.6, 0.0, 0.0)  # Dark red border

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

func take_damage(damage: int):
	var actual_damage = max(1, damage - defense)  # Minimum 1 damage
	current_health -= actual_damage
	current_health = max(0, current_health)
	
	update_health_bar()
	piece_damaged.emit(self, actual_damage)
	
	print(piece_type, " (", team, ") took ", actual_damage, " damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

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