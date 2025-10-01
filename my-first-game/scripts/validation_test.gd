extends Node

# Simple validation script to test the new data-driven system

# Preload required classes
const PieceFactory = preload("res://scripts/factories/PieceFactory.gd")
const ArmyFactory = preload("res://scripts/factories/ArmyFactory.gd")
const DataLoader = preload("res://scripts/systems/DataLoader.gd")

func _ready():
	print("=== Testing Data-Driven Game System ===")
	test_piece_factory()
	test_army_factory()
	test_data_loader()
	print("=== All Tests Completed ===")

func test_piece_factory():
	print("\n--- Testing PieceFactory ---")
	var piece_factory = PieceFactory.new()
	
	# Test creating different piece types
	var warrior = piece_factory.create_piece_type("warrior")
	if warrior:
		print("✅ Warrior created - HP:", warrior.max_health, " ATK:", warrior.base_attack_power, " DEF:", warrior.base_defense)
		print("   Attacks available: ", warrior.available_attacks.size())
	else:
		print("❌ Failed to create warrior")
	
	var king = piece_factory.create_piece_type("king")
	if king:
		print("✅ King created - HP:", king.max_health, " ATK:", king.base_attack_power, " DEF:", king.base_defense)
	else:
		print("❌ Failed to create king")
	
	var archer = piece_factory.create_piece_type("archer")
	if archer:
		print("✅ Archer created - HP:", archer.max_health, " ATK:", archer.base_attack_power, " DEF:", archer.base_defense, " Move:", archer.movement_range)
	else:
		print("❌ Failed to create archer")
	
	var mage = piece_factory.create_piece_type("mage")
	if mage:
		print("✅ Mage created - HP:", mage.max_health, " ATK:", mage.base_attack_power, " DEF:", mage.base_defense)
	else:
		print("❌ Failed to create mage")
	
	print("Available piece types: ", piece_factory.get_available_piece_types())

func test_army_factory():
	print("\n--- Testing ArmyFactory ---")
	var army_factory = ArmyFactory.new()
	
	# Test creating armies by level
	for level in range(1, 6):
		var army = army_factory.create_army_by_level(level)
		if army:
			print("✅ Level ", level, " army: ", army.army_name)
			print("   Stats - Health: ", army.health_multiplier, " Damage: ", army.damage_multiplier, " Defense: +", army.defense_bonus)
		else:
			print("❌ Failed to create army for level ", level)
	
	print("Available armies: ", army_factory.get_available_armies())

func test_data_loader():
	print("\n--- Testing DataLoader ---")
	var data_loader = DataLoader.new()
	
	# Test loading different data types
	var items = data_loader.load_items()
	print("✅ Loaded ", items.size(), " items")
	
	var pieces = data_loader.load_pieces()
	print("✅ Loaded ", pieces.size(), " pieces")
	
	var armies = data_loader.load_armies()
	print("✅ Loaded ", armies.size(), " armies")
	
	# Test specific lookups
	var test_item = data_loader.get_item_by_id("warrior_ironclad_plate")
	if test_item:
		print("✅ Found item: ", test_item.name)
		if test_item.has("mechanics"):
			print("   Has mechanical effects: ", test_item.mechanics.keys())
	
	var test_piece = data_loader.get_piece_by_id("warrior")
	if test_piece:
		print("✅ Found piece: ", test_piece.name, " with ", test_piece.attacks.size(), " attacks")
	
	var test_army = data_loader.get_army_by_id("militia")
	if test_army:
		print("✅ Found army: ", test_army.name, " (Level ", test_army.level, ")")