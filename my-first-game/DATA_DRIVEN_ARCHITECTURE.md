# Data-Driven Game Architecture

This document describes the new data-driven architecture that replaces hardcoded game logic with JSON configuration files and factory classes.

## Overview

The refactoring moves from hardcoded piece types, items, and armies to a flexible data-driven system that makes it easier to add new content without touching code.

## Key Components

### 1. Data Files (`/data/`)

#### `pieces.json`
Defines all piece types with their stats, attacks, and abilities:
```json
{
  "pieces": [
    {
      "id": "warrior",
      "name": "Warrior", 
      "max_health": 100,
      "base_attack_power": 25,
      "attacks": [...],
      "passive_abilities": [...]
    }
  ]
}
```

#### `items.json` (Enhanced)
Items now include mechanical effect definitions:
```json
{
  "id": "warrior_ironclad_plate",
  "mechanics": {
    "damage_reduction": {
      "melee": 25,
      "ranged": 0,
      "magic": 0
    }
  }
}
```

#### `armies.json`
Army definitions with composition and scaling rules:
```json
{
  "armies": [
    {
      "id": "militia",
      "composition": {"warrior": 15, "king": 1},
      "health_multiplier": 1.0,
      "special_abilities": []
    }
  ]
}
```

### 2. Factory Classes (`/scripts/factories/`)

#### `PieceFactory.gd`
- Creates `PieceType` instances from JSON data
- Handles attack creation and movement types
- Replaces hardcoded piece type classes (`WarriorType.gd`, etc.)

#### `ItemFactory.gd`
- Applies item effects mechanically based on JSON definitions
- Handles damage reduction, stat bonuses, conditional effects
- Tracks active effects and durations

#### `ArmyFactory.gd`
- Creates armies from JSON templates
- Handles level scaling and composition
- Replaces hardcoded army creation methods

### 3. Updated Systems

#### `PieceManager.gd`
- Now uses `PieceFactory` to create pieces
- Applies data-driven stats instead of hardcoded values

#### `ArmyManager.gd`
- Uses `ArmyFactory` for army creation
- Simplified scaling logic

#### `DataLoader.gd`
- Enhanced with methods for pieces and armies
- Centralized data access

## Benefits

### For Development
1. **Easy Content Addition**: Add new pieces/items by editing JSON, no code changes
2. **Rapid Balancing**: Tweak stats in JSON files without recompilation
3. **Better Organization**: Clear separation of data and logic
4. **Validation**: JSON structure is easier to validate than code

### For AI Assistant (Me)
1. **Structured Data**: Much easier to work with JSON than complex inheritance
2. **Single Source of Truth**: Reduces inconsistencies across files
3. **Targeted Changes**: Can modify specific items without affecting unrelated code
4. **Reliable Validation**: Can check JSON syntax and structure

## Adding New Content

### New Piece Type
1. Add entry to `pieces.json` with stats and attacks
2. No code changes needed - PieceFactory handles creation

### New Item
1. Add to `items.json` with mechanical effects
2. ItemFactory automatically applies effects

### New Army
1. Add to `armies.json` with composition
2. ArmyFactory handles creation and scaling

## Migration Notes

- Old piece type classes (`WarriorType.gd`, etc.) are now deprecated
- Old army creation methods in `Army.gd` are replaced by ArmyFactory
- Existing save files and loadouts remain compatible
- New system is backward compatible during transition

## Testing

Run `validation_test.gd` to verify all factories work correctly:
```bash
# In Godot, add validation_test.gd to a scene and run it
```

## Future Enhancements

1. **Abilities System**: Define reusable abilities in JSON
2. **Terrain System**: Add terrain effects via data
3. **Condition System**: More complex trigger conditions for items
4. **Validation Schema**: JSON schema validation for data integrity
5. **Hot Reloading**: Live updates during development

## File Structure
```
my-first-game/
├── data/
│   ├── pieces.json      # Piece definitions
│   ├── items.json       # Item definitions (enhanced)
│   └── armies.json      # Army definitions
├── scripts/
│   ├── factories/
│   │   ├── PieceFactory.gd
│   │   ├── ItemFactory.gd
│   │   └── ArmyFactory.gd
│   └── systems/
│       └── DataLoader.gd (enhanced)
└── validation_test.gd   # Test script
```

This architecture makes the game much more maintainable and easier to expand with new content!