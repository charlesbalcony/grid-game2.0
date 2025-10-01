extends Node

# Simple test runner for basic validation

func _ready():
	print("🧪 Starting Basic Game Tests...")
	run_basic_tests()
	get_tree().quit()

func run_basic_tests():
	print("\n=== BASIC SYSTEM TESTS ===")
	
	test_data_loading()
	test_fortress_shield_item()
	test_piece_creation()
	
	print("\n✅ All basic tests completed!")

func test_data_loading():
	print("\n📂 Testing Data Loading...")
	
	var data_loader = preload("res://scripts/systems/DataLoader.gd").new()
	
	# Test items loading
	var items = data_loader.load_items()
	assert(items is Array, "Items should load as Array")
	assert(items.size() > 0, "Should have at least one item")
	
	# Check for fortress shield
	var found_fortress_shield = false
	for item in items:
		if item.get("id", "") == "warrior_fortress_shield":
			found_fortress_shield = true
			break
	assert(found_fortress_shield, "Should have fortress shield")
	print("  ✅ Items loaded: ", items.size(), " items")
	
	# Test pieces loading
	var pieces = data_loader.load_pieces()
	assert(pieces is Array, "Pieces should load as Array")
	assert(pieces.size() > 0, "Should have at least one piece type")
	
	# Check for warrior piece type
	var found_warrior = false
	for piece in pieces:
		if piece.get("id", "") == "warrior":
			found_warrior = true
			break
	assert(found_warrior, "Should have warrior piece type")
	print("  ✅ Pieces loaded: ", pieces.size(), " piece types")
	
	# Test armies loading
	var armies = data_loader.load_armies()
	assert(armies is Array, "Armies should load as Array")
	assert(armies.size() > 0, "Should have at least one army")
	print("  ✅ Armies loaded: ", armies.size(), " armies")

func test_fortress_shield_item():
	print("\n⚔️ Testing Fortress Shield...")
	
	var data_loader = preload("res://scripts/systems/DataLoader.gd").new()
	var items = data_loader.load_items()
	
	# Find the fortress shield item
	var fortress_shield = null
	for item in items:
		if item.get("id", "") == "warrior_fortress_shield":
			fortress_shield = item
			break
	
	assert(fortress_shield != null, "Should find fortress shield item")
	assert(fortress_shield.has("mechanics"), "Fortress shield should have mechanics")
	
	var mechanics = fortress_shield["mechanics"]
	assert(mechanics.has("damage_reduction"), "Should have damage_reduction mechanics")
	
	var damage_reduction = mechanics["damage_reduction"]
	assert(damage_reduction["melee"] == 100, "Should reduce melee damage by 100")
	assert(damage_reduction["ranged"] == 100, "Should reduce ranged damage by 100")
	assert(damage_reduction["magic"] == 100, "Should reduce magic damage by 100")
	
	print("  ✅ Fortress Shield validated: 100 damage reduction for all types")

func test_piece_creation():
	print("\n🎯 Testing Piece Creation...")
	
	var game_piece = preload("res://scripts/game_piece.gd").new()
	game_piece.piece_type = "warrior"
	game_piece.max_health = 100
	game_piece.attack_power = 25
	game_piece.current_health = 100
	
	assert(game_piece.piece_type == "warrior", "Piece type should be warrior")
	assert(game_piece.max_health == 100, "Max health should be 100")
	assert(game_piece.current_health == 100, "Current health should be 100")
	assert(game_piece.attack_power == 25, "Attack power should be 25")
	
	print("  ✅ Game piece created successfully")