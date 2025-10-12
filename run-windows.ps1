# Windows PowerShell script to run the Godot project
# Usage: .\run-windows.ps1 [--god-mode|--debug]

param(
    [string]$Mode
)

# Check for god mode argument
if ($Mode -eq "--god-mode" -or $Mode -eq "--debug") {
    Write-Host "🎮 Starting game in GOD MODE - instant kills enabled!" -ForegroundColor Yellow
    & ".\Godot_v4.3-stable_win64.exe" --path "my-first-game" --rendering-driver opengl3 --single-window --god-mode
} else {
    Write-Host "🎮 Starting Godot Windows version in normal mode..." -ForegroundColor Green
    & ".\Godot_v4.3-stable_win64.exe" --path "my-first-game" --rendering-driver opengl3 --single-window
}