#!/bin/bash

# Clear Godot cache to prevent freezing issues
echo "🧹 Clearing all caches..."
rm -rf my-first-game/.godot/shader_cache/ 2>/dev/null
rm -rf my-first-game/.godot/imported/ 2>/dev/null
rm -rf ~/.cache/godot/ 2>/dev/null

# Additional flags to reduce caching/freezing issues
GODOT_FLAGS="--rendering-driver opengl3 --single-window"

# Check if testing is requested
if [[ "$1" == "--test" ]]; then
    echo "🧪 Running comprehensive game test suite..."
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --headless tests/BasicTestScene.tscn
    exit $?
fi

# Check if debug/god mode is requested
if [[ "$1" == "--debug" ]] || [[ "$1" == "--god-mode" ]]; then
    echo "Starting game in GOD MODE - instant kills enabled!"
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game $GODOT_FLAGS --god-mode
else
    echo "🎮 Starting game in normal mode"
    # Run tests first to catch any issues
    echo "🧪 Running quick tests before game start..."
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --headless tests/BasicTestScene.tscn
    if [ $? -eq 0 ]; then
        echo "✅ All tests passed! Starting game..."
        ./godot --path my-first-game $GODOT_FLAGS
    else
        echo "❌ Tests failed! Please fix issues before running the game."
        exit 1
    fi
fi