# Simple PowerShell script to run the game in GOD MODE
# Usage: .\run-god-mode.ps1

Write-Host "🎮 Starting game in GOD MODE - instant kills enabled! ⚡" -ForegroundColor Yellow
Write-Host ""

# Use full paths to avoid UNC path issues
$godotPath = "\\wsl.localhost\Ubuntu\home\hoggb\gdot-game-test\Godot_v4.3-stable_win64.exe"
$gamePath = "\\wsl.localhost\Ubuntu\home\hoggb\gdot-game-test\my-first-game"

& $godotPath --path $gamePath --rendering-driver opengl3 --single-window --god-mode