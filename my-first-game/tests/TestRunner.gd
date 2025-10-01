extends Node
# Test runner that executes all unit tests

const TestFramework = preload("res://tests/TestFramework.gd")

# Import all test classes
const ItemTests = preload("res://tests/ItemTests.gd")
const PieceTests = preload("res://tests/PieceTests.gd")
const CombatTests = preload("res://tests/CombatTests.gd")
const DataLoaderTests = preload("res://tests/DataLoaderTests.gd")
const ShopTests = preload("res://tests/ShopTests.gd")

var test_framework: TestFramework

func _ready():
	print("🧪 Starting Game Test Suite...")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Connect to framework signals
	test_framework.all_tests_completed.connect(_on_all_tests_completed)
	
	# Run all test suites
	run_all_tests()

func run_all_tests():
	"""Run all test suites in order"""
	print("\n🚀 Running comprehensive game tests...\n")
	
	# Run each test suite
	run_data_loader_tests()
	run_item_tests()
	run_piece_tests()
	run_combat_tests()
	run_shop_tests()
	
	# Print final summary
	test_framework.print_summary()

func run_data_loader_tests():
	"""Test data loading system"""
	print("\n📂 Running Data Loader Tests...")
	var tests = DataLoaderTests.new()
	add_child(tests)
	tests.run_tests(test_framework)
	tests.queue_free()

func run_item_tests():
	"""Test item system"""
	print("\n⚔️ Running Item Tests...")
	var tests = ItemTests.new()
	add_child(tests)
	tests.run_tests(test_framework)
	tests.queue_free()

func run_piece_tests():
	"""Test piece system"""
	print("\n🎯 Running Piece Tests...")
	var tests = PieceTests.new()
	add_child(tests)
	tests.run_tests(test_framework)
	tests.queue_free()

func run_combat_tests():
	"""Test combat system"""
	print("\n⚔️ Running Combat Tests...")
	var tests = CombatTests.new()
	add_child(tests)
	tests.run_tests(test_framework)
	tests.queue_free()

func run_shop_tests():
	"""Test shop system"""
	print("\n🛒 Running Shop Tests...")
	var tests = ShopTests.new()
	add_child(tests)
	tests.run_tests(test_framework)
	tests.queue_free()

func _on_all_tests_completed(total: int, passed: int, failed: int):
	"""Handle test completion"""
	if failed == 0:
		print("\n🎉 All tests completed successfully!")
		get_tree().quit(0)  # Exit with success code
	else:
		print("\n❌ Tests failed. Exiting with error code.")
		get_tree().quit(1)  # Exit with error code