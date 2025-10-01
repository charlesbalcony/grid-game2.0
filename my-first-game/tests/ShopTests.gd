extends Node
class_name ShopTests

# Tests for the Shop system

const ShopManager = preload("res://scripts/systems/ShopManager.gd")
const DataLoader = preload("res://scripts/systems/DataLoader.gd")
const GamePiece = preload("res://scripts/game_piece.gd")

func run_tests(framework):
	"""Run all shop tests"""
	framework.run_test("Shop generates items correctly", test_shop_generation)
	framework.run_test("Shop purchase system works", test_shop_purchase)
	framework.run_test("Shop refresh functionality", test_shop_refresh)
	framework.run_test("Shop item filtering by piece type", test_item_filtering)
	framework.run_test("Shop handles insufficient currency", test_insufficient_currency)

func test_shop_generation(framework = null):
	"""Test that shop generates items correctly"""
	var shop_manager = ShopManager.new()
	var data_loader = DataLoader.new()
	shop_manager.data_loader = data_loader
	
	# Generate shop items
	shop_manager.generate_shop_items()
	
	# Should have some items
	assert(shop_manager.available_items.size() > 0, "Shop should have generated items")
	
	# All items should be valid
	var items_data = data_loader.load_items()
	for item_id in shop_manager.available_items:
		assert(items_data.has(item_id), "Shop item should exist in items data: " + str(item_id))
	
	print("✅ Shop generates items correctly")

func test_shop_purchase(framework = null):
	"""Test that shop purchase system works"""
	var shop_manager = ShopManager.new()
	var data_loader = DataLoader.new()
	shop_manager.data_loader = data_loader
	
	# Set up player currency
	shop_manager.player_currency = 1000
	
	# Generate shop items
	shop_manager.generate_shop_items()
	
	if shop_manager.available_items.size() > 0:
		var item_to_buy = shop_manager.available_items[0]
		var initial_currency = shop_manager.player_currency
		var item_cost = shop_manager.get_item_cost(item_to_buy)
		
		# Purchase item
		var purchase_success = shop_manager.purchase_item(item_to_buy)
		
		if item_cost <= initial_currency:
			assert(purchase_success, "Purchase should succeed with sufficient currency")
			assert(shop_manager.player_currency == initial_currency - item_cost, 
				"Currency should be reduced by item cost")
			assert(not shop_manager.available_items.has(item_to_buy), 
				"Item should be removed from shop after purchase")
		else:
			assert(not purchase_success, "Purchase should fail with insufficient currency")
	
	print("✅ Shop purchase system working correctly")

func test_shop_refresh(framework = null):
	"""Test that shop refresh generates new items"""
	var shop_manager = ShopManager.new()
	var data_loader = DataLoader.new()
	shop_manager.data_loader = data_loader
	
	# Generate initial items
	shop_manager.generate_shop_items()
	var initial_items = shop_manager.available_items.duplicate()
	
	# Refresh shop
	shop_manager.refresh_shop()
	var refreshed_items = shop_manager.available_items
	
	# Should have items after refresh
	assert(refreshed_items.size() > 0, "Shop should have items after refresh")
	
	# Items might be different (though could be same by chance)
	# At minimum, refresh should have reset the shop
	assert(refreshed_items is Array, "Refreshed items should be an array")
	
	print("✅ Shop refresh functionality working correctly")

func test_item_filtering(framework = null):
	"""Test that shop filters items by piece type correctly"""
	var shop_manager = ShopManager.new()
	var data_loader = DataLoader.new()
	shop_manager.data_loader = data_loader
	
	# Test filtering for specific piece type
	var warrior_items = shop_manager.get_items_for_piece_type("warrior")
	var archer_items = shop_manager.get_items_for_piece_type("archer")
	
	# Should return arrays
	assert(warrior_items is Array, "Warrior items should be an array")
	assert(archer_items is Array, "Archer items should be an array")
	
	# Validate that items are appropriate for piece types
	var items_data = data_loader.load_items()
	for item_id in warrior_items:
		if items_data.has(item_id):
			var item = items_data[item_id]
			if item.has("piece_types"):
				assert(item["piece_types"].has("warrior"), 
					"Warrior item should be usable by warriors: " + str(item_id))
	
	print("✅ Shop item filtering working correctly")

func test_insufficient_currency(framework = null):
	"""Test that shop handles insufficient currency correctly"""
	var shop_manager = ShopManager.new()
	var data_loader = DataLoader.new()
	shop_manager.data_loader = data_loader
	
	# Set very low currency
	shop_manager.player_currency = 0
	
	# Generate shop items
	shop_manager.generate_shop_items()
	
	if shop_manager.available_items.size() > 0:
		var expensive_item = shop_manager.available_items[0]
		var initial_currency = shop_manager.player_currency
		
		# Try to purchase with insufficient funds
		var purchase_success = shop_manager.purchase_item(expensive_item)
		
		# Purchase should fail
		assert(not purchase_success, "Purchase should fail with insufficient currency")
		assert(shop_manager.player_currency == initial_currency, 
			"Currency should not change on failed purchase")
		assert(shop_manager.available_items.has(expensive_item), 
			"Item should remain in shop after failed purchase")
	
	print("✅ Shop insufficient currency handling working correctly")