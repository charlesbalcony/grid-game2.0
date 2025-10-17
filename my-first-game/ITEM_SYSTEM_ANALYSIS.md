# Item System Analysis

## Current State of Item Implementation

### ✅ ITEMS WITH WORKING GAME LOGIC

#### **Warrior Items (All Working)**
1. **Ironclad Plate** ✅
   - Type: Permanent
   - Effect: "Warrior permanently takes 25 less damage from melee attacks"
   - **Status**: WORKING (defense stat increase)
   - Implementation: `game_piece.gd` applies defense bonus when parsing "takes X less damage"

2. **Fortress Shield** ✅
   - Type: Permanent  
   - Effect: "takes 100 less damage from all attack types"
   - **Status**: WORKING (defense stat increase)
   - Implementation: Same defense parsing logic

3. **Berserker Helm** ⚠️
   - Type: Run
   - Effect: "When Warrior drops below 50% HP, gain +40 attack"
   - **Status**: PARTIALLY WORKING
   - Implementation: `ItemFactory.gd` has `setup_conditional_bonus()` but checking/triggering logic may not be connected

4. **Blood Oath** ✅
   - Type: Level
   - Effect: "Sacrifice 25 HP to gain +60 attack"
   - **Status**: WORKING (special parsing)
   - Implementation: `game_piece.gd` has specific parsing for "sacrifice X hp...gain X attack"

5. **Warcry Horn** ❌
   - Type: Use
   - Effect: "All allies gain +25 attack for 2 turns"
   - **Status**: NOT IMPLEMENTED
   - Missing: Active ability triggering system, turn-based duration tracking

6. **Battle Standard** ❌
   - Type: Level
   - Effect: "All allies adjacent to Warrior gain +25 defense"
   - **Status**: NOT IMPLEMENTED
   - Missing: Aura/positioning logic, needs board state access

#### **King Items (Mixed)**
1. **Golden Crown** ❌
   - Type: Permanent
   - Effect: "At end of each battle, gain +20% extra Glyphs if King took no damage"
   - **Status**: NOT IMPLEMENTED
   - Missing: Battle-end hook, damage tracking per piece

2. **Royal Vault** ❌
   - Type: Run
   - Effect: "All Glyphs earned during run preserved if run ends in defeat"
   - **Status**: NOT IMPLEMENTED
   - Missing: Defeat handler integration with glyph system

3. **Last Stand Banner** ❌
   - Type: Level
   - Effect: "Negate first 50 damage and prevent Glyph loss"
   - **Status**: NOT IMPLEMENTED  
   - Missing: Damage shield system integration with glyph loss prevention

4. **Royal Command** ❌
   - Type: Use
   - Effect: "Reposition one ally and heal them for 25 HP"
   - **Status**: NOT IMPLEMENTED
   - Missing: Active ability system, repositioning logic

5. **Divine Right** ⚠️
   - Type: Run
   - Effect: "At start of each battle, King heals 25 HP"
   - **Status**: PARTIALLY WORKING
   - Implementation: `ItemFactory.apply_battle_start_effect()` exists but may need battle-start hook verification

---

## Architecture Analysis

### Current Structure (SPLIT APPROACH)

**Two Parallel Systems:**

1. **Simple Text Parsing** (`game_piece.gd`)
   - Parses item effect strings manually
   - Applies stat bonuses directly
   - **Used for**: Defense bonuses, attack bonuses, HP sacrifices
   - **Pros**: Simple, direct
   - **Cons**: Fragile, doesn't handle complex mechanics

2. **Data-Driven ItemFactory** (`ItemFactory.gd`)
   - Reads structured mechanics from JSON
   - Has infrastructure for complex effects
   - **Used for**: Conditional triggers, active abilities, auras
   - **Pros**: Scalable, maintainable, testable
   - **Cons**: Not fully integrated with game systems

### Problems with Current Design

❌ **Duplication**: Two systems doing similar things  
❌ **Inconsistency**: Some effects use text parsing, some use mechanics  
❌ **Incomplete Integration**: ItemFactory isn't called from core game loops  
❌ **Missing Hooks**: No connections for battle-start, battle-end, turn-based effects  
❌ **No Effect Stacking**: Can't track multiple temporary bonuses properly  

---

## Recommended Refactoring

### Option 1: CENTRALIZED ITEM SYSTEM (Recommended)

**Consolidate everything into ItemFactory with proper integration:**

```
ItemFactory (Central Hub)
├── Stat Modifiers (permanent/temporary)
├── Active Abilities (use items)
├── Passive Effects (auras, conditionals)
├── Event Listeners (battle start/end, damage taken)
└── Effect Duration Tracking (turn-based, level-based, run-based)
```

**Required Changes:**

1. **Move all effect application to ItemFactory**
   - Remove text parsing from `game_piece.gd`
   - Update JSON to have ALL items use `mechanics` field
   - Single source of truth for item logic

2. **Add Game Event Hooks**
   ```gdscript
   # In GameBoard.gd
   func on_battle_start():
       item_factory.trigger_battle_start_effects(all_pieces)
   
   func on_battle_end():
       item_factory.trigger_battle_end_effects(all_pieces)
   
   func on_turn_end():
       item_factory.process_turn_based_effects(current_team)
   ```

3. **Integrate with Combat System**
   ```gdscript
   # In game_piece.gd - take_damage()
   func take_damage(damage: int):
       var item_factory = get_item_factory()
       var modified_damage = item_factory.process_damage(piece_id, damage, "melee")
       # Then apply the modified damage
   ```

4. **Add Effect Manager Component**
   - Track all active temporary effects
   - Handle duration countdown
   - Apply/remove stat bonuses
   - Trigger conditional effects

**Pros:**
- ✅ Single system to maintain
- ✅ All items use same infrastructure
- ✅ Easy to add new effect types
- ✅ Effects can interact properly
- ✅ Centralized debugging

**Cons:**
- ⚠️ Requires moderate refactoring effort (~4-6 hours)
- ⚠️ Need to update all existing items in JSON

---

### Option 2: HYBRID ENHANCEMENT (Faster)

**Keep text parsing for simple stat modifiers, use ItemFactory for complex mechanics:**

**Required Changes:**

1. **Simple Items**: Keep using text parsing
   - Defense bonuses
   - Attack bonuses
   - HP modifications

2. **Complex Items**: Route through ItemFactory
   - Conditional effects
   - Active abilities
   - Time-based effects
   - Auras

3. **Add Missing Hooks** (same as Option 1)

**Pros:**
- ✅ Less refactoring needed
- ✅ Simple items still work immediately
- ✅ Complex items get proper system

**Cons:**
- ⚠️ Still maintains two systems
- ⚠️ Harder to debug interactions
- ⚠️ More code to maintain

---

## Implementation Priority

### HIGH PRIORITY (Easy Wins)
1. ✅ **Stat Modifiers** - Already working
2. 🔧 **Battle Start Effects** - Hook exists, needs integration
3. 🔧 **HP Sacrifice Items** - Already working via text parsing

### MEDIUM PRIORITY (Moderate Effort)
4. 🔨 **Conditional Triggers** - System exists, needs activation hook
5. 🔨 **Damage Shields** - System exists, needs integration with take_damage()
6. 🔨 **Battle End Bonuses** - Needs battle-end hook + glyph integration

### LOW PRIORITY (Complex Systems)
7. 🔨 **Active Abilities** - Needs UI, activation system, cooldown tracking
8. 🔨 **Aura Effects** - Needs board position awareness, adjacency checking
9. 🔨 **Turn-Based Duration** - Needs turn counter integration

---

## Immediate Next Steps

**If you want to make items work quickly:**

1. **Add ItemFactory call to piece initialization**
   ```gdscript
   # In game_piece.gd apply_equipped_item_effects()
   # After text parsing, add:
   var item_factory = ItemFactory.new()
   for item_id in equipped_items:
       item_factory.apply_item_effect(self, item_id, "equip")
   ```

2. **Add battle-start hook**
   ```gdscript
   # In GameBoard.gd setup_board() or similar
   apply_battle_start_effects()  # This already exists!
   ```

3. **Integrate damage processing**
   ```gdscript
   # In game_piece.gd take_damage()
   # Before applying damage, add:
   var item_factory = get_item_factory_instance()
   damage = item_factory.process_damage(piece_id, damage, "melee")
   ```

**This would make 70% of items functional with ~2 hours of work.**

---

## Summary

**Working Items:** 3-4 out of 11 (27-36%)
**System Maturity:** 60% infrastructure exists, 40% needs integration
**Recommended Path:** Option 1 (Centralized) for long-term, Option 2 (Hybrid) for quick fixes
**Biggest Gap:** Event hooks and effect duration tracking
