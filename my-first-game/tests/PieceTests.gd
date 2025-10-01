extends Node
class_name PieceTests

# Tests for the GamePiece system

const GamePiece = preload("res://scripts/game_piece.gd")
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const LoadoutManager = preload("res://scripts/systems/LoadoutManager.gd")

func run_tests(framework):
	"""Run all piece tests"""
	framework.run_test("Pieces initialize with correct stats", test_piece_initialization)
	framework.run_test("Pieces take damage correctly", test_damage_system)
	framework.run_test("Pieces die when health reaches zero", test_death_system)
	framework.run_test("Pieces can be healed", test_healing_system)
	framework.run_test("Piece positioning works correctly", test_positioning)

func test_piece_initialization(framework = null):
	"""Test that pieces initialize with correct base stats"""
	var data_loader = DataLoader.new()
	var piece_data = data_loader.load_pieces()
	
	# Test warrior initialization
	var warrior = GamePiece.new()
	warrior.piece_type = "warrior"
	warrior.initialize_from_data(piece_data["warrior"])
	
	assert(warrior.base_health > 0, "Warrior should have positive base health")
	assert(warrior.base_damage > 0, "Warrior should have positive base damage")
	assert(warrior.current_health == warrior.base_health, "Current health should equal base health initially")
	assert(warrior.movement_range > 0, "Warrior should have movement range")
	assert(warrior.attack_range > 0, "Warrior should have attack range")
	
	# Test archer initialization
	var archer = GamePiece.new()
	archer.piece_type = "archer"
	archer.initialize_from_data(piece_data["archer"])
	
	assert(archer.base_health > 0, "Archer should have positive base health")
	assert(archer.base_damage > 0, "Archer should have positive base damage")
	assert(archer.current_health == archer.base_health, "Current health should equal base health initially")
	assert(archer.attack_range > warrior.attack_range, "Archer should have longer range than warrior")
	
	print("✅ Pieces initialize with correct stats")

func test_damage_system(framework = null):
	"""Test that pieces take damage correctly"""
	var warrior = create_test_warrior()
	var initial_health = warrior.current_health
	
	# Deal some damage
	var damage_amount = 30
	warrior.take_damage(damage_amount)
	
	assert(warrior.current_health == initial_health - damage_amount, 
		"Health should be reduced by damage amount. Expected: " + str(initial_health - damage_amount) + 
		", Got: " + str(warrior.current_health))
	assert(warrior.current_health > 0, "Warrior should still be alive")
	assert(not warrior.is_dead, "Warrior should not be marked as dead")
	
	print("✅ Damage system working correctly")

func test_death_system(framework = null):
	"""Test that pieces die when health reaches zero"""
	var warrior = create_test_warrior()
	
	# Deal lethal damage
	var lethal_damage = warrior.current_health + 10
	warrior.take_damage(lethal_damage)
	
	assert(warrior.current_health <= 0, "Health should be zero or negative after lethal damage")
	assert(warrior.is_dead, "Warrior should be marked as dead")
	
	print("✅ Death system working correctly")

func test_healing_system(framework = null):
	"""Test that pieces can be healed"""
	var warrior = create_test_warrior()
	var initial_health = warrior.current_health
	
	# Deal some damage first
	warrior.take_damage(50)
	var damaged_health = warrior.current_health
	assert(damaged_health < initial_health, "Piece should be damaged")
	
	# Heal the piece
	warrior.heal(30)
	
	assert(warrior.current_health == damaged_health + 30, "Health should increase by heal amount")
	assert(warrior.current_health <= warrior.base_health, "Health should not exceed maximum")
	
	# Test healing beyond maximum
	warrior.heal(1000)
	assert(warrior.current_health == warrior.base_health, "Health should be capped at maximum")
	
	print("✅ Healing system working correctly")

func test_positioning(framework = null):
	"""Test that piece positioning works correctly"""
	var warrior = create_test_warrior()
	
	# Test initial position
	assert(warrior.grid_position != null, "Piece should have grid position")
	assert(warrior.grid_position is Vector2, "Grid position should be Vector2")
	
	# Test position updates
	var new_position = Vector2(5, 3)
	warrior.set_grid_position(new_position)
	
	assert(warrior.grid_position == new_position, "Grid position should update correctly")
	
	print("✅ Positioning system working correctly")

func create_test_warrior() -> GamePiece:
	"""Helper function to create a test warrior piece"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	var warrior = GamePiece.new()
	warrior.piece_type = "warrior"
	warrior.base_health = 100
	warrior.base_damage = 25
	warrior.current_health = 100
	warrior.movement_range = 2
	warrior.attack_range = 1
	warrior.grid_position = Vector2(0, 0)
	warrior.player_id = 1
	warrior.is_dead = false
	warrior.loadout_manager = loadout_manager
	
	return warrior