extends Node
class_name DataLoaderTests

# Tests for the DataLoader system

const DataLoader = preload("res://scripts/systems/DataLoader.gd")

func run_tests(framework):
	"""Run all data loader tests"""
	framework.run_test("DataLoader loads items correctly", test_load_items)
	framework.run_test("DataLoader loads pieces correctly", test_load_pieces)
	framework.run_test("DataLoader loads armies correctly", test_load_armies)
	framework.run_test("DataLoader handles missing files gracefully", test_missing_files)

func test_load_items(framework = null):
	"""Test that items.json loads correctly"""
	var data_loader = DataLoader.new()
	var items = data_loader.load_items()
	
	# Should return a dictionary
	assert(items is Dictionary, "Items should be loaded as Dictionary")
	
	# Should have some items
	assert(items.size() > 0, "Should load at least one item")
	
	# Check for our test item
	assert(items.has("warrior_fortress_shield"), "Should contain fortress shield item")
	
	# Validate fortress shield structure
	var fortress_shield = items["warrior_fortress_shield"]
	assert(fortress_shield.has("name"), "Item should have name")
	assert(fortress_shield.has("description"), "Item should have description")
	assert(fortress_shield.has("effects"), "Item should have effects")
	assert(fortress_shield.has("piece_types"), "Item should have piece_types")
	
	# Check fortress shield effects
	var effects = fortress_shield["effects"]
	assert(effects.has("damage_reduction"), "Fortress shield should have damage_reduction")
	assert(effects["damage_reduction"] == 100, "Fortress shield should reduce damage by 100")
	
	print("✅ Items loaded successfully with", items.size(), "items")

func test_load_pieces(framework = null):
	"""Test that pieces data loads correctly"""
	var data_loader = DataLoader.new()
	var pieces = data_loader.load_pieces()
	
	# Should return a dictionary
	assert(pieces is Dictionary, "Pieces should be loaded as Dictionary")
	
	# Should have basic piece types
	assert(pieces.has("warrior"), "Should have warrior piece type")
	assert(pieces.has("archer"), "Should have archer piece type")
	assert(pieces.has("mage"), "Should have mage piece type")
	assert(pieces.has("king"), "Should have king piece type")
	
	# Validate warrior structure
	var warrior = pieces["warrior"]
	assert(warrior.has("base_health"), "Warrior should have base_health")
	assert(warrior.has("base_damage"), "Warrior should have base_damage")
	assert(warrior.has("movement_range"), "Warrior should have movement_range")
	assert(warrior.has("attack_range"), "Warrior should have attack_range")
	
	print("✅ Pieces loaded successfully with", pieces.size(), "piece types")

func test_load_armies(framework = null):
	"""Test that armies data loads correctly"""
	var data_loader = DataLoader.new()
	var armies = data_loader.load_armies()
	
	# Should return a dictionary
	assert(armies is Dictionary, "Armies should be loaded as Dictionary")
	
	# Should have some armies
	assert(armies.size() > 0, "Should load at least one army")
	
	# Each army should have required structure
	for army_name in armies.keys():
		var army = armies[army_name]
		assert(army.has("pieces"), "Army should have pieces array")
		assert(army["pieces"] is Array, "Army pieces should be an array")
		
		# Each piece in army should have type and position
		for piece in army["pieces"]:
			assert(piece.has("type"), "Army piece should have type")
			assert(piece.has("position"), "Army piece should have position")
			assert(piece["position"] is Array, "Position should be array")
			assert(piece["position"].size() == 2, "Position should have x,y coordinates")
	
	print("✅ Armies loaded successfully with", armies.size(), "armies")

func test_missing_files(framework = null):
	"""Test that missing files are handled gracefully"""
	var data_loader = DataLoader.new()
	
	# Test with non-existent file path
	var original_items_path = data_loader.items_file_path
	data_loader.items_file_path = "res://nonexistent/items.json"
	
	var items = data_loader.load_items()
	
	# Should return empty dictionary for missing file
	assert(items is Dictionary, "Should return Dictionary even for missing file")
	assert(items.size() == 0, "Should return empty Dictionary for missing file")
	
	# Restore original path
	data_loader.items_file_path = original_items_path
	
	print("✅ Missing files handled gracefully")