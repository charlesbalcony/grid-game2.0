# Grid Battle Tactics

A tactical grid-based battle game inspired by chess and Dark Souls, built with Godot 4.3. Command units on an 8x8 grid in turn-based combat with a rogue-like progression system.

## Quick Start

1. **Download Godot 4.3**: The project requires Godot 4.3+ (binaries not included in repo)
2. **Open Project**: Launch Godot and import `my-first-game/project.godot`
3. **Play**: Press F5 or click the play button

## Game Features

- **8x8 Grid Battlefield**: Chess-like tactical positioning
- **Combat System**: Multiple attack types with HP management
- **Interactive Controls**: Click to select/move pieces, right-click to attack
- **Visual Feedback**: Health bars, selection highlights, damage effects

## Controls

- **Left Click**: Select piece / Move to tile
- **Right Click**: Enter attack mode
- **Attack UI**: Choose from Basic Attack, Heavy Strike, or Quick Jab

## Project Structure

```
my-first-game/              # Godot project folder
├── project.godot          # Main project configuration
├── scenes/                # Game scenes
│   ├── Main.tscn         # Main battlefield scene
│   └── GamePiece.tscn    # Individual piece template
├── scripts/               # Game logic
│   ├── game_board.gd     # Grid system and combat
│   ├── game_piece.gd     # Piece stats and behavior
│   └── game_manager.gd   # Turn management
└── README.md             # Detailed game documentation
```

## Development

This project uses Godot 4.3 with GDScript. The game is designed to be expanded with:
- Different unit types and abilities
- AI opponents with increasing difficulty  
- Rogue-like progression and soul collection
- Equipment and upgrade systems

## Running Without Audio

If you encounter audio driver issues on Linux:
```bash
./godot --path my-first-game --audio-driver Dummy
```