extends Node

# Game Manager for Grid Battle Tactics
# Handles game state, turns, win conditions, etc.

signal turn_changed(current_team)
signal game_over(winner)
signal actions_used_up()

enum GameState {
	PLAYER_TURN,
	ENEMY_TURN,
	GAME_OVER
}

var current_state = GameState.PLAYER_TURN
var current_team = "player"
var turn_count = 1
var actions_per_turn = 1
var actions_used = 0

func _ready():
	print("Game Manager initialized")
	print("Turn ", turn_count, ": Player's turn")
	turn_changed.emit(current_team)

func use_action():
	actions_used += 1
	print("Action used: ", actions_used, "/", actions_per_turn)
	
	if actions_used >= actions_per_turn:
		actions_used_up.emit()
		# Auto-end turn after using all actions
		call_deferred("switch_turn")

func switch_turn():
	print("=== SWITCHING TURN from ", current_team, " ===")
	actions_used = 0
	
	if current_team == "player":
		current_team = "enemy"
		current_state = GameState.ENEMY_TURN
		turn_count += 1
		print("Switched to ENEMY turn, turn count: ", turn_count)
	else:
		current_team = "player"
		current_state = GameState.PLAYER_TURN
		print("Switched to PLAYER turn, turn count: ", turn_count)
	
	print("Turn ", turn_count, ": ", current_team.capitalize(), "'s turn")
	print("Emitting turn_changed signal with: ", current_team)
	turn_changed.emit(current_team)

func can_move_piece(team: String) -> bool:
	return current_team == team and current_state != GameState.GAME_OVER

func can_perform_action(team: String) -> bool:
	return current_team == team and current_state != GameState.GAME_OVER and actions_used < actions_per_turn

func end_game(winner: String, reason: String = "elimination"):
	current_state = GameState.GAME_OVER
	game_over.emit(winner, reason)
	print("Game Over! Winner: ", winner.capitalize(), " (Reason: ", reason, ")")

func get_current_team() -> String:
	return current_team

func get_game_info() -> String:
	var actions_left = actions_per_turn - actions_used
	match current_state:
		GameState.PLAYER_TURN:
			return "PLAYER'S TURN - Actions left: " + str(actions_left)
		GameState.ENEMY_TURN:
			return "ENEMY'S TURN - Actions left: " + str(actions_left)
		GameState.GAME_OVER:
			return "Game Over!"
		_:
			return "Unknown state"

func force_end_turn():
	switch_turn()

func restart_game():
	"""Restart the game state for a new battle"""
	current_team = "player"
	current_state = GameState.PLAYER_TURN
	actions_used = 0
	turn_count = 1
	print("Game restarted - Turn 1: Player's turn")
	turn_changed.emit(current_team)