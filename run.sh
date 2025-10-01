#!/bin/bash

# Check if testing is requested
if [[ "$1" == "--test" ]]; then
    echo "🧪 Running comprehensive game test suite..."
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --headless tests/BasicTestScene.tscn
    exit $?
fi

# Check if debug/god mode is requested
if [[ "$1" == "--debug" ]] || [[ "$1" == "--god-mode" ]]; then
    echo "Starting game in GOD MODE - instant kills enabled!"
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --god-mode
else
    echo "🎮 Starting game in normal mode"
    # Run tests first to catch any issues
    echo "🧪 Running quick tests before game start..."
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --headless tests/BasicTestScene.tscn
    if [ $? -eq 0 ]; then
        echo "✅ All tests passed! Starting game..."
        ./godot --path my-first-game
    else
        echo "❌ Tests failed! Please fix issues before running the game."
        exit 1
    fi
fi