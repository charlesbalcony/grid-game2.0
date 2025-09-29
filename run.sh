#!/bin/bash

# Check if debug/god mode is requested
if [[ "$1" == "--debug" ]] || [[ "$1" == "--god-mode" ]]; then
    echo "Starting game in GOD MODE - instant kills enabled!"
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game --god-mode
else
    echo "Starting game in normal mode"
    cd /home/hoggb/gdot-game-test && ./godot --path my-first-game
fi