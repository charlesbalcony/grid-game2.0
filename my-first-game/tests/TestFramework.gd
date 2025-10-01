extends Node
class_name TestFramework

# Simple test framework for the game
# Provides assertion methods and test reporting

var tests_run: int = 0
var tests_passed: int = 0
var tests_failed: int = 0
var current_test_name: String = ""

signal test_completed(test_name: String, passed: bool, message: String)
signal all_tests_completed(total: int, passed: int, failed: int)

func run_test(test_name: String, test_function: Callable):
	"""Run a single test function"""
	current_test_name = test_name
	tests_run += 1
	
	print("\n--- Running Test: ", test_name, " ---")
	
	# Reset failure flag
	var test_failed = false
	
	# Call the test function
	test_function.call()
	
	# Check if test failed during execution
	if not test_failed:
		tests_passed += 1
		print("✅ PASS: ", test_name)
		test_completed.emit(test_name, true, "Test passed")
	else:
		print("❌ FAIL: ", test_name)
		test_completed.emit(test_name, false, "Test failed")

func assert_equal(actual, expected, message: String = ""):
	"""Assert that two values are equal"""
	if actual != expected:
		var error_msg = "Expected: " + str(expected) + ", Got: " + str(actual)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_not_equal(actual, expected, message: String = ""):
	"""Assert that two values are not equal"""
	if actual == expected:
		var error_msg = "Expected values to be different, but both were: " + str(actual)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_true(condition: bool, message: String = ""):
	"""Assert that condition is true"""
	if not condition:
		var error_msg = "Expected true, got false"
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_false(condition: bool, message: String = ""):
	"""Assert that condition is false"""
	if condition:
		var error_msg = "Expected false, got true"
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_not_null(value, message: String = ""):
	"""Assert that value is not null"""
	if value == null:
		var error_msg = "Expected non-null value, got null"
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_null(value, message: String = ""):
	"""Assert that value is null"""
	if value != null:
		var error_msg = "Expected null, got: " + str(value)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_greater_than(actual, expected, message: String = ""):
	"""Assert that actual is greater than expected"""
	if actual <= expected:
		var error_msg = "Expected " + str(actual) + " to be greater than " + str(expected)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_less_than(actual, expected, message: String = ""):
	"""Assert that actual is less than expected"""
	if actual >= expected:
		var error_msg = "Expected " + str(actual) + " to be less than " + str(expected)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_contains(container: Array, item, message: String = ""):
	"""Assert that array contains item"""
	if not container.has(item):
		var error_msg = "Expected array to contain: " + str(item)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func assert_dict_has_key(dict: Dictionary, key, message: String = ""):
	"""Assert that dictionary has key"""
	if not dict.has(key):
		var error_msg = "Expected dictionary to have key: " + str(key)
		if message != "":
			error_msg = message + " - " + error_msg
		print("❌ ASSERTION FAILED: ", error_msg)
		assert(false, error_msg)

func fail_test(message: String):
	"""Explicitly fail the current test"""
	tests_failed += 1
	tests_passed = max(0, tests_passed - 1)  # Undo the increment from run_test
	print("❌ FAIL: ", current_test_name, " - ", message)
	test_completed.emit(current_test_name, false, message)
	# Set a flag that can be checked by run_test
	get_meta("test_failed", true)

func print_summary():
	"""Print final test summary"""
	print("\n" + "=".repeat(50))
	print("TEST SUMMARY")
	print("=".repeat(50))
	print("Total Tests: ", tests_run)
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	
	if tests_failed == 0:
		print("🎉 ALL TESTS PASSED!")
	else:
		print("⚠️  ", tests_failed, " TESTS FAILED")
	
	print("=".repeat(50))
	all_tests_completed.emit(tests_run, tests_passed, tests_failed)

func reset_counters():
	"""Reset test counters for a new test run"""
	tests_run = 0
	tests_passed = 0
	tests_failed = 0
	current_test_name = ""