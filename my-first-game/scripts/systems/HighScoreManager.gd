extends Node
class_name HighScoreManager

# High Score Manager - Handles saving/loading and tracking of high scores

signal high_score_updated(new_high_score)

const SAVE_FILE_PATH = "user://high_scores.save"

var current_level: int = 1
var high_score_level: int = 1
var games_played: int = 0
var total_battles_won: int = 0

func _init():
	load_high_scores()

func _ready():
	print("HighScoreManager initialized - High Score: Level ", high_score_level)

func update_current_level(level: int):
	"""Update the current level and check if it's a new high score"""
	current_level = level
	
	if level > high_score_level:
		var old_high_score = high_score_level
		high_score_level = level
		print("NEW HIGH SCORE! Reached Level ", level, " (previous: ", old_high_score, ")")
		high_score_updated.emit(high_score_level)
		save_high_scores()
	
	print("Current Level: ", current_level, " | High Score: Level ", high_score_level)

func increment_games_played():
	"""Increment the number of games played"""
	games_played += 1
	save_high_scores()

func increment_battles_won():
	"""Increment the number of battles won"""
	total_battles_won += 1
	save_high_scores()

func reset_current_level():
	"""Reset current level to 1 (when player loses)"""
	current_level = 1
	print("Level reset to 1 | High Score remains: Level ", high_score_level)

func get_current_level() -> int:
	return current_level

func get_high_score() -> int:
	return high_score_level

func get_games_played() -> int:
	return games_played

func get_battles_won() -> int:
	return total_battles_won

func save_high_scores():
	"""Save high scores to disk"""
	var save_data = {
		"high_score_level": high_score_level,
		"games_played": games_played,
		"total_battles_won": total_battles_won,
		"save_version": "1.0"
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("High scores saved: Level ", high_score_level, ", Games: ", games_played, ", Battles: ", total_battles_won)
	else:
		print("ERROR: Could not save high scores to ", SAVE_FILE_PATH)

func load_high_scores():
	"""Load high scores from disk"""
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found, using defaults")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("high_score_level"):
				high_score_level = save_data.high_score_level
			if save_data.has("games_played"):
				games_played = save_data.games_played
			if save_data.has("total_battles_won"):
				total_battles_won = save_data.total_battles_won
			
			print("High scores loaded: Level ", high_score_level, ", Games: ", games_played, ", Battles: ", total_battles_won)
		else:
			print("ERROR: Could not parse high score save file")
	else:
		print("ERROR: Could not read high score save file")

func get_stats_summary() -> String:
	"""Get a formatted string with all stats"""
	return "Level %d/%d | Games: %d | Battles Won: %d" % [current_level, high_score_level, games_played, total_battles_won]