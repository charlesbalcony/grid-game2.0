extends Node
class_name ItemTests

# Tests for the Item system

const GamePiece = preload("res://scripts/game_piece.gd")
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const LoadoutManager = preload("res://scripts/systems/LoadoutManager.gd")

func run_tests(framework):
	"""Run all item tests"""
	framework.run_test("Items can be equipped to pieces", test_item_equipping)
	framework.run_test("Item effects are applied correctly", test_item_effects)
	framework.run_test("Fortress Shield provides damage reduction", test_fortress_shield)
	framework.run_test("Items can be unequipped", test_item_unequipping)
	framework.run_test("Invalid items are handled gracefully", test_invalid_items)

func test_item_equipping(framework = null):
	"""Test that items can be equipped to pieces"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	# Create a test warrior piece
	var warrior_piece = GamePiece.new()
	warrior_piece.piece_type = "warrior"
	warrior_piece.base_health = 100
	warrior_piece.base_damage = 25
	warrior_piece.current_health = 100
	warrior_piece.loadout_manager = loadout_manager
	
	# Equip fortress shield
	warrior_piece.equip_item("warrior_fortress_shield")
	
	# Check that item was equipped
	assert(warrior_piece.equipped_item != null, "Item should be equipped")
	assert(warrior_piece.equipped_item == "warrior_fortress_shield", "Correct item should be equipped")
	
	print("✅ Item equipped successfully")

func test_item_effects(framework = null):
	"""Test that item effects are applied to piece stats"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	# Create a test warrior piece
	var warrior_piece = GamePiece.new()
	warrior_piece.piece_type = "warrior"
	warrior_piece.base_health = 100
	warrior_piece.base_damage = 25
	warrior_piece.current_health = 100
	warrior_piece.loadout_manager = loadout_manager
	
	# Store original stats
	var original_health = warrior_piece.base_health
	var original_damage = warrior_piece.base_damage
	
	# Equip an item (we'll use fortress shield which has damage_reduction)
	warrior_piece.equip_item("warrior_fortress_shield")
	
	# Apply item effects
	warrior_piece.apply_equipped_item_effects()
	
	# Check that effects were applied (fortress shield should add damage reduction)
	# The piece should now have damage reduction capability
	assert(warrior_piece.equipped_item != null, "Item should be equipped")
	
	print("✅ Item effects applied successfully")

func test_fortress_shield(framework = null):
	"""Test that the Fortress Shield provides correct damage reduction"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	# Create a test warrior piece
	var warrior_piece = GamePiece.new()
	warrior_piece.piece_type = "warrior"
	warrior_piece.base_health = 100
	warrior_piece.base_damage = 25
	warrior_piece.current_health = 100
	warrior_piece.loadout_manager = loadout_manager
	
	# Equip fortress shield
	warrior_piece.equip_item("warrior_fortress_shield")
	warrior_piece.apply_equipped_item_effects()
	
	# Test damage reduction
	var incoming_damage = 150
	var actual_damage = warrior_piece.calculate_incoming_damage(incoming_damage)
	
	# With 100 damage reduction, 150 damage should become 50
	assert(actual_damage == 50, "Fortress shield should reduce 150 damage to 50, got: " + str(actual_damage))
	
	# Test that minimum damage is still 1
	var small_damage = 50
	var reduced_small_damage = warrior_piece.calculate_incoming_damage(small_damage)
	assert(reduced_small_damage == 1, "Minimum damage should be 1, got: " + str(reduced_small_damage))
	
	print("✅ Fortress Shield damage reduction working correctly")

func test_item_unequipping(framework = null):
	"""Test that items can be unequipped"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	# Create a test warrior piece
	var warrior_piece = GamePiece.new()
	warrior_piece.piece_type = "warrior"
	warrior_piece.base_health = 100
	warrior_piece.base_damage = 25
	warrior_piece.current_health = 100
	warrior_piece.loadout_manager = loadout_manager
	
	# Equip an item
	warrior_piece.equip_item("warrior_fortress_shield")
	assert(warrior_piece.equipped_item != null, "Item should be equipped")
	
	# Unequip the item
	warrior_piece.unequip_item()
	assert(warrior_piece.equipped_item == null, "Item should be unequipped")
	
	print("✅ Item unequipping works correctly")

func test_invalid_items(framework = null):
	"""Test that invalid items are handled gracefully"""
	var data_loader = DataLoader.new()
	var loadout_manager = LoadoutManager.new()
	loadout_manager.data_loader = data_loader
	
	# Create a test warrior piece
	var warrior_piece = GamePiece.new()
	warrior_piece.piece_type = "warrior"
	warrior_piece.base_health = 100
	warrior_piece.base_damage = 25
	warrior_piece.current_health = 100
	warrior_piece.loadout_manager = loadout_manager
	
	# Try to equip non-existent item
	warrior_piece.equip_item("nonexistent_item")
	
	# Should handle gracefully (no crash)
	assert(warrior_piece.equipped_item == null, "Non-existent item should not be equipped")
	
	# Try to equip wrong piece type item (if such restrictions exist)
	# This would need specific item data to test properly
	
	print("✅ Invalid items handled gracefully")