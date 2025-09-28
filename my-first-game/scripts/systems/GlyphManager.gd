extends Node

# Glyph Manager - Handles glyph accumulation, loss, and recovery mechanics

signal glyphs_changed(new_total, stuck_glyphs, stuck_at_level)
signal glyphs_lost(lost_amount, stuck_at_level)
signal glyphs_recovered(recovered_amount)
signal glyph_reward(glyph_count, enemy_type, grid_pos)

const SAVE_FILE_PATH = "user://glyphs.save"

# Glyph reward ranges
const ENEMY_GLYPH_MIN = 1
const ENEMY_GLYPH_MAX = 3
const KING_GLYPH_MIN = 8
const KING_GLYPH_MAX = 15

var current_glyphs: int = 0
var stuck_glyphs: int = 0  # Glyphs lost and stuck at a level
var stuck_at_level: int = 0  # Which level the glyphs are stuck at
var total_glyphs_earned: int = 0  # All-time total

func _init():
	# Don't load glyphs for now - start fresh each game
	# load_glyphs()
	print("GlyphManager starting fresh - no save/load yet")

func _ready():
	print("GlyphManager initialized - Current Glyphs: ", current_glyphs)
	if stuck_glyphs > 0:
		print("You have ", stuck_glyphs, " glyphs stuck at Level ", stuck_at_level, " - beat that level to recover them!")
	
	# Emit initial glyph state
	glyphs_changed.emit(current_glyphs, stuck_glyphs, stuck_at_level)

func award_enemy_glyph(grid_pos: Vector2 = Vector2.ZERO):
	"""Award glyphs for destroying a regular enemy"""
	var reward = randi_range(ENEMY_GLYPH_MIN, ENEMY_GLYPH_MAX)
	current_glyphs += reward
	total_glyphs_earned += reward
	print("Enemy destroyed! Earned ", reward, " glyphs (Total: ", current_glyphs, ")")
	glyphs_changed.emit(current_glyphs, stuck_glyphs, stuck_at_level)
	glyph_reward.emit(reward, "Enemy", grid_pos)
	# save_glyphs()  # Disabled for now - no persistent saves yet
	return reward

func award_king_glyph(grid_pos: Vector2 = Vector2.ZERO):
	"""Award bonus glyphs for destroying the king"""
	var reward = randi_range(KING_GLYPH_MIN, KING_GLYPH_MAX)
	current_glyphs += reward
	total_glyphs_earned += reward
	print("KING DESTROYED! Earned ", reward, " bonus glyphs (Total: ", current_glyphs, ")")
	glyphs_changed.emit(current_glyphs, stuck_glyphs, stuck_at_level)
	glyph_reward.emit(reward, "King", grid_pos)
	# save_glyphs()  # Disabled for now - no persistent saves yet
	return reward

func lose_glyphs(current_level: int):
	"""Lose glyphs when player is defeated - they become stuck at this level"""
	if current_glyphs == 0:
		print("No glyphs to lose!")
		return
	
	var glyphs_to_lose = current_glyphs
	stuck_glyphs += glyphs_to_lose  # Add to existing stuck glyphs
	stuck_at_level = current_level  # Update the level where glyphs are stuck
	current_glyphs = 0  # Player loses all current glyphs
	
	print("DEFEAT! ", glyphs_to_lose, " glyphs are now stuck at Level ", current_level)
	print("Total stuck glyphs: ", stuck_glyphs, " at Level ", stuck_at_level)
	print("Beat Level ", stuck_at_level, " to recover your ", stuck_glyphs, " glyphs!")
	
	glyphs_lost.emit(glyphs_to_lose, stuck_at_level)
	glyphs_changed.emit(current_glyphs, stuck_glyphs, stuck_at_level)
	# save_glyphs()  # Disabled for now - no persistent saves yet

func check_glyph_recovery(completed_level: int):
	"""Check if player has recovered their stuck glyphs by beating the required level"""
	if stuck_glyphs > 0 and completed_level >= stuck_at_level:
		var recovered = stuck_glyphs
		current_glyphs += recovered
		stuck_glyphs = 0
		stuck_at_level = 0
		
		print("GLYPHS RECOVERED! You've reclaimed ", recovered, " glyphs by beating Level ", completed_level)
		print("Current glyphs: ", current_glyphs)
		
		glyphs_recovered.emit(recovered)
		glyphs_changed.emit(current_glyphs, stuck_glyphs, stuck_at_level)
		# save_glyphs()  # Disabled for now - no persistent saves yet
		return recovered
	
	return 0

func save_glyphs():
	"""Save glyph data to file"""
	var save_data = {
		"current_glyphs": current_glyphs,
		"stuck_glyphs": stuck_glyphs,
		"stuck_at_level": stuck_at_level,
		"total_glyphs_earned": total_glyphs_earned
	}
	
	var json = JSON.new()
	var json_string = json.stringify(save_data)
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Glyphs saved: Current=", current_glyphs, ", Stuck=", stuck_glyphs, " at Level ", stuck_at_level)
	else:
		print("ERROR: Could not save glyphs to file")

func load_glyphs():
	"""Load glyph data from file"""
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if not file:
			print("ERROR: Could not open glyph save file for reading")
			return
			
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("current_glyphs"):
				current_glyphs = save_data.current_glyphs
			if save_data.has("stuck_glyphs"):
				stuck_glyphs = save_data.stuck_glyphs
			if save_data.has("stuck_at_level"):
				stuck_at_level = save_data.stuck_at_level
			if save_data.has("total_glyphs_earned"):
				total_glyphs_earned = save_data.total_glyphs_earned
			
			print("Glyphs loaded: Current=", current_glyphs, ", Stuck=", stuck_glyphs, " at Level ", stuck_at_level)
		else:
			print("ERROR: Could not parse glyph save file")
	else:
		print("No glyph save file found, starting fresh")

func get_current_glyphs() -> int:
	"""Get the current glyph count"""
	return current_glyphs

func get_stuck_glyphs() -> int:
	"""Get the stuck glyph count"""
	return stuck_glyphs

func get_stuck_at_level() -> int:
	"""Get the level where glyphs are stuck"""
	return stuck_at_level

func get_total_glyphs_earned() -> int:
	"""Get the total glyphs earned all-time"""
	return total_glyphs_earned