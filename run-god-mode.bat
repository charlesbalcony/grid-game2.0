@echo off
REM Simple script to run the game in GOD MODE
REM Usage: run-god-mode.bat

echo 🎮 Starting game in GOD MODE - instant kills enabled! ⚡
echo.

REM Use pushd to temporarily map the UNC path
pushd "\\wsl.localhost\Ubuntu\home\hoggb\gdot-game-test"
.\Godot_v4.3-stable_win64.exe --path my-first-game --rendering-driver opengl3 --single-window --god-mode
popd