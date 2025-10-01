extends Node
class_name CombatTests

# Tests for the Combat system

const GamePiece = preload("res://scripts/game_piece.gd")
const CombatSystem = preload("res://scripts/systems/CombatSystem.gd")
const AttackData = preload("res://scripts/systems/AttackData.gd")
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const LoadoutManager = preload("res://scripts/systems/LoadoutManager.gd")

func run_tests(framework):
	"""Run all combat tests"""
	framework.run_test("Basic combat damage calculation", test_basic_combat)
	framework.run_test("Combat with item effects", test_combat_with_items)
	framework.run_test("Combat range validation", test_combat_range)
	framework.run_test("Combat with different piece types", test_piece_type_combat)
	framework.run_test("Combat system death handling", test_combat_death)

func test_basic_combat(framework = null):
	"""Test basic combat between two pieces"""
	var attacker = create_test_piece("warrior", 100, 25)
	var defender = create_test_piece("archer", 80, 20)
	
	var combat_system = CombatSystem.new()
	
	# Create attack data
	var attack_data = AttackData.new()
	attack_data.attacker = attacker
	attack_data.defender = defender
	attack_data.base_damage = attacker.base_damage
	
	# Execute attack
	var initial_defender_health = defender.current_health
	combat_system.execute_attack(attack_data)
	
	# Verify damage was dealt
	assert(defender.current_health < initial_defender_health, "Defender should have taken damage")
	assert(defender.current_health == initial_defender_health - attacker.base_damage, 
		"Defender should have lost exactly attacker's base damage")
	
	print("✅ Basic combat working correctly")

func test_combat_with_items(framework = null):
	"""Test combat when pieces have items equipped"""
	var attacker = create_test_piece("warrior", 100, 25)
	var defender = create_test_piece("warrior", 100, 25)
	
	# Equip fortress shield to defender (100 damage reduction)
	defender.equip_item("warrior_fortress_shield")
	defender.apply_equipped_item_effects()
	
	var combat_system = CombatSystem.new()
	
	# Create attack data
	var attack_data = AttackData.new()
	attack_data.attacker = attacker
	attack_data.defender = defender
	attack_data.base_damage = attacker.base_damage
	
	# Execute attack
	var initial_defender_health = defender.current_health
	combat_system.execute_attack(attack_data)
	
	# With 25 damage and 100 reduction, defender should take only 1 damage (minimum)
	var expected_health = initial_defender_health - 1
	assert(defender.current_health == expected_health, 
		"Defender with fortress shield should take only 1 damage. Expected: " + str(expected_health) + 
		", Got: " + str(defender.current_health))
	
	print("✅ Combat with items working correctly")

func test_combat_range(framework = null):
	"""Test that combat respects range limitations"""
	var attacker = create_test_piece("warrior", 100, 25)  # Range 1
	var defender = create_test_piece("archer", 80, 20)    # Range 3
	
	# Place pieces at different distances
	attacker.grid_position = Vector2(0, 0)
	defender.grid_position = Vector2(3, 0)  # 3 tiles away
	
	var combat_system = CombatSystem.new()
	
	# Warrior (range 1) should not be able to attack archer at distance 3
	var can_warrior_attack = combat_system.can_attack(attacker, defender)
	assert(not can_warrior_attack, "Warrior should not be able to attack at range 3")
	
	# Archer (range 3) should be able to attack warrior at distance 3
	var can_archer_attack = combat_system.can_attack(defender, attacker)
	assert(can_archer_attack, "Archer should be able to attack at range 3")
	
	# Move defender closer
	defender.grid_position = Vector2(1, 0)  # 1 tile away
	
	# Now warrior should be able to attack
	can_warrior_attack = combat_system.can_attack(attacker, defender)
	assert(can_warrior_attack, "Warrior should be able to attack at range 1")
	
	print("✅ Combat range validation working correctly")

func test_piece_type_combat(framework = null):
	"""Test combat between different piece types"""
	var warrior = create_test_piece("warrior", 100, 25)
	var archer = create_test_piece("archer", 80, 20)
	var mage = create_test_piece("mage", 60, 30)
	var king = create_test_piece("king", 120, 15)
	
	var combat_system = CombatSystem.new()
	
	# Test warrior vs archer
	var attack_data = AttackData.new()
	attack_data.attacker = warrior
	attack_data.defender = archer
	attack_data.base_damage = warrior.base_damage
	
	var initial_archer_health = archer.current_health
	combat_system.execute_attack(attack_data)
	
	assert(archer.current_health == initial_archer_health - warrior.base_damage,
		"Archer should take warrior's full damage")
	
	# Test mage vs king (mage has higher damage)
	attack_data.attacker = mage
	attack_data.defender = king
	attack_data.base_damage = mage.base_damage
	
	var initial_king_health = king.current_health
	combat_system.execute_attack(attack_data)
	
	assert(king.current_health == initial_king_health - mage.base_damage,
		"King should take mage's full damage")
	
	print("✅ Combat between different piece types working correctly")

func test_combat_death(framework = null):
	"""Test that combat system handles piece death correctly"""
	var attacker = create_test_piece("warrior", 100, 50)  # High damage
	var defender = create_test_piece("archer", 30, 20)    # Low health
	
	var combat_system = CombatSystem.new()
	
	# Create lethal attack
	var attack_data = AttackData.new()
	attack_data.attacker = attacker
	attack_data.defender = defender
	attack_data.base_damage = attacker.base_damage
	
	# Execute lethal attack
	combat_system.execute_attack(attack_data)
	
	# Verify defender died
	assert(defender.current_health <= 0, "Defender should have zero or negative health")
	assert(defender.is_dead, "Defender should be marked as dead")
	
	print("✅ Combat death handling working correctly")

func create_test_piece(piece_type: String, health: int, damage: int) -> GamePiece:
	"""Helper function to create test pieces"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	var piece = GamePiece.new()
	piece.piece_type = piece_type
	piece.base_health = health
	piece.base_damage = damage
	piece.current_health = health
	piece.grid_position = Vector2(0, 0)
	piece.player_id = 1
	piece.is_dead = false
	piece.loadout_manager = loadout_manager
	
	# Set type-specific stats
	match piece_type:
		"warrior":
			piece.movement_range = 2
			piece.attack_range = 1
		"archer":
			piece.movement_range = 2
			piece.attack_range = 3
		"mage":
			piece.movement_range = 2
			piece.attack_range = 2
		"king":
			piece.movement_range = 1
			piece.attack_range = 1
	
	return piece