extends Node

# Game Manager for Grid Battle Tactics
# Handles game state, turns, win conditions, etc.

signal turn_changed(current_team)
signal game_over(winner)

enum GameState {
	PLAYER_TURN,
	ENEMY_TURN,
	GAME_OVER
}

var current_state = GameState.PLAYER_TURN
var current_team = "player"
var turn_count = 0

func _ready():
	print("Game Manager initialized")
	print("Current turn: Player")

func switch_turn():
	turn_count += 1
	
	if current_team == "player":
		current_team = "enemy"
		current_state = GameState.ENEMY_TURN
	else:
		current_team = "player"
		current_state = GameState.PLAYER_TURN
	
	turn_changed.emit(current_team)
	print("Turn ", turn_count, ": ", current_team.capitalize(), "'s turn")

func can_move_piece(team: String) -> bool:
	return current_team == team and current_state != GameState.GAME_OVER

func end_game(winner: String):
	current_state = GameState.GAME_OVER
	game_over.emit(winner)
	print("Game Over! Winner: ", winner.capitalize())

func get_game_info() -> String:
	match current_state:
		GameState.PLAYER_TURN:
			return "Player's Turn - Click to move your pieces"
		GameState.ENEMY_TURN:
			return "Enemy's Turn - Thinking..."
		GameState.GAME_OVER:
			return "Game Over!"
		_:
			return "Unknown state"