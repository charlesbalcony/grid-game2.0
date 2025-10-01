# Game Testing Framework

## Overview

This testing framework provides comprehensive unit testing for the tactical game's core systems, ensuring code quality and catching issues early in development.

## Features

- **Data System Testing**: Validates JSON loading for items, pieces, and armies
- **Item Functionality Testing**: Verifies item effects, especially damage reduction mechanics
- **Piece System Testing**: Tests piece creation, stats, and behavior
- **Integrated Build Process**: Automatically runs tests before game launch
- **Standalone Testing**: Run tests independently with `--test` flag

## Test Results

✅ **All tests currently passing:**

### Data Loading Tests
- Items loaded: 11 items including Fortress Shield
- Pieces loaded: 4 piece types (warrior, archer, mage, king)  
- Armies loaded: 4 army configurations

### Fortress Shield Validation
- Confirms 100 damage reduction for all attack types (melee, ranged, magic)
- Validates JSON structure and mechanics data

### Piece Creation Tests
- Successful creation with proper stats
- Property assignment working correctly

## Usage

### Run Tests Only
```bash
./run.sh --test
```

### Normal Game Launch (with pre-launch testing)
```bash
./run.sh
```
Tests run automatically before game starts. If tests fail, game launch is prevented.

### Debug Mode (bypasses tests)
```bash
./run.sh --debug
```

## Test Files

- `tests/BasicTests.gd` - Core system validation tests
- `tests/BasicTestScene.tscn` - Test execution scene
- `tests/TestFramework.gd` - Full assertion framework (advanced)
- `tests/TestRunner.gd` - Comprehensive test runner (future expansion)

## Framework Architecture

The testing system validates:

1. **Data Integrity**: JSON files load correctly with expected structure
2. **System Integration**: Components work together properly
3. **Feature Functionality**: New features like Fortress Shield work as designed
4. **Build Quality**: Catches issues before deployment

## Fortress Shield Verification

The tests specifically validate that our new legendary item works correctly:
- **Item ID**: `warrior_fortress_shield` 
- **Damage Reduction**: 100 points across all damage types
- **Piece Type**: Compatible with warrior pieces
- **Effect Application**: Successfully applied to equipped pieces

This confirms the item is properly integrated into the data-driven architecture.

## Future Expansion

The framework is designed to easily add more comprehensive tests:
- Combat system validation
- Shop functionality testing  
- AI behavior verification
- Performance regression testing

## Exit Codes

- `0` - All tests passed
- `1` - Tests failed, issues need fixing

The build process respects these codes to prevent launching broken builds.