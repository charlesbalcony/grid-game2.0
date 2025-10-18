# GridSystem.gd
# Handles grid creation, coordinate conversion, and position validation

class_name GridSystem
extends Node2D

const GRID_SIZE = 8
const TILE_SIZE = 80
const BOARD_OFFSET = Vector2(40, 40)

# Colors for the grid (fallback if no textures)
const LIGHT_TILE_COLOR = Color(0.9, 0.9, 0.8)
const DARK_TILE_COLOR = Color(0.6, 0.4, 0.2)

var grid_tiles = []
var parent_node = null

# Textures for grid squares (loaded at runtime)
var light_square_texture: Texture2D = null
var dark_square_texture: Texture2D = null

func _init():
	# Try to load grid square textures
	light_square_texture = load_texture_if_exists("res://assets/grid_square_light.png")
	dark_square_texture = load_texture_if_exists("res://assets/grid_square_dark.png")
	
	if light_square_texture and dark_square_texture:
		print("GridSystem: Using textured grid squares")
	else:
		print("GridSystem: Using colored grid squares (no textures found)")

func set_parent_node(node: Node2D):
	"""Set reference to the parent node for adding grid tiles"""
	parent_node = node

func create_grid():
	"""Create the visual grid"""
	if not parent_node:
		push_error("GridSystem: No parent node set!")
		return
		
	for row in range(GRID_SIZE):
		var tile_row = []
		for col in range(GRID_SIZE):
			var tile = create_tile(row, col)
			parent_node.add_child(tile)
			tile_row.append(tile)
		grid_tiles.append(tile_row)

func create_tile(row: int, col: int) -> CanvasItem:
	"""Create a single grid tile (textured or colored)"""
	var is_light = (row + col) % 2 == 0
	var position = Vector2(col * TILE_SIZE + BOARD_OFFSET.x, row * TILE_SIZE + BOARD_OFFSET.y)
	
	# Use textures if available
	if light_square_texture and dark_square_texture:
		var sprite = Sprite2D.new()
		sprite.texture = light_square_texture if is_light else dark_square_texture
		sprite.centered = false
		sprite.position = position
		
		# Scale texture to fit tile size
		var tex_size = sprite.texture.get_size()
		sprite.scale = Vector2(TILE_SIZE / tex_size.x, TILE_SIZE / tex_size.y)
		
		return sprite
	else:
		# Fall back to colored rectangles
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.position = position
		tile.color = LIGHT_TILE_COLOR if is_light else DARK_TILE_COLOR
		return tile

func grid_to_world_pos(grid_pos: Vector2) -> Vector2:
	"""Convert grid coordinates to world coordinates"""
	return Vector2(grid_pos.x * TILE_SIZE + BOARD_OFFSET.x, grid_pos.y * TILE_SIZE + BOARD_OFFSET.y)

func world_to_grid_pos(world_pos: Vector2) -> Vector2:
	"""Convert world coordinates to grid coordinates"""
	var adjusted_pos = world_pos - BOARD_OFFSET
	return Vector2(floor(adjusted_pos.x / TILE_SIZE), floor(adjusted_pos.y / TILE_SIZE))

func is_valid_position(pos: Vector2) -> bool:
	"""Check if a grid position is within bounds"""
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func get_adjacent_positions(pos: Vector2, include_diagonals: bool = true) -> Array[Vector2]:
	"""Get all adjacent positions to a given position"""
	var positions: Array[Vector2] = []
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)  # Cardinal directions
	]
	
	if include_diagonals:
		directions.append_array([
			Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)  # Diagonal directions
		])
	
	for direction in directions:
		var new_pos = pos + direction
		if is_valid_position(new_pos):
			positions.append(new_pos)
	
	return positions

func get_distance(pos1: Vector2, pos2: Vector2) -> float:
	"""Get the distance between two grid positions"""
	return pos1.distance_to(pos2)

func get_manhattan_distance(pos1: Vector2, pos2: Vector2) -> int:
	"""Get the Manhattan (grid) distance between two positions"""
	return int(abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y))

func load_texture_if_exists(path: String) -> Texture2D:
	"""Try to load a texture, return null if it doesn't exist"""
	# First try the normal Godot resource loading (for imported assets)
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded != null:
			return loaded
		# If ResourceLoader failed, fall through to direct loading
	
	# If not imported or ResourceLoader failed, try loading directly from file system
	var absolute_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var image = Image.new()
		var error = image.load(absolute_path)
		if error == OK:
			return ImageTexture.create_from_image(image)
	
	return null