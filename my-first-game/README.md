# Grid Battle Tactics

A tactical grid-based battle game inspired by chess and Dark Souls, built with Godot 4.3. Players command units on an 8x8 grid in turn-based combat with a rogue-like progression system.

## Current Features

- **8x8 Grid Board**: Checkerboard pattern tactical battlefield
- **Chess-like Setup**: Player pieces (blue) on rows 0-1, enemy pieces (red) on rows 6-7  
- **Click-to-Move**: Select pieces by clicking, then click destination tiles to move
- **Visual Feedback**: Selected pieces are highlighted
- **Turn-based Foundation**: Basic structure ready for turn-based gameplay

## Planned Features (Dark Souls-like Progression)

- **Multiple Unit Types**: Warriors, Archers, Mages with unique abilities
- **Rogue-like Elements**: Procedural encounters, permadeath, persistent upgrades
- **Souls System**: Collect souls from defeated enemies to upgrade units
- **Progressive Difficulty**: Face increasingly challenging AI opponents
- **Equipment & Abilities**: Weapons, armor, and special skills to unlock

## How to Run

1. Open Godot 4 by running `./godot` from the main directory
2. Import this project by selecting the `project.godot` file in the `my-first-game` folder
3. Press F5 or click the play button to run the game

## Controls

- **Left Click**: Select piece / Move to tile
- **Mouse**: Navigate the grid battlefield

## Project Structure

```
my-first-game/
├── project.godot          # Main project configuration
├── scenes/
│   ├── Main.tscn         # Main game board scene
│   └── GamePiece.tscn    # Individual piece scene
├── scripts/
│   ├── game_board.gd     # Grid system and piece management
│   ├── game_piece.gd     # Individual piece logic
│   └── game_manager.gd   # Game state and turn management
└── assets/               # For future assets (sprites, sounds, etc.)
```

## Development Roadmap

1. ✅ Basic grid system with piece movement
2. 🔄 Turn-based mechanics
3. 📋 Multiple piece types with different abilities
4. 📋 Combat system with damage calculation
5. 📋 AI opponent logic
6. 📋 Souls collection and upgrade system
7. 📋 Rogue-like progression and encounters

## Learning Resources

- [Godot Official Documentation](https://docs.godotengine.org/)
- [Turn-based Strategy Games in Godot](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html)
- [Grid-based Movement Systems](https://kidscancode.org/godot_recipes/)