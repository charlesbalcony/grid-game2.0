@echo off
REM Windows batch script to run the Godot project
REM Usage: run-windows.bat [--god-mode|--debug]

REM Check for god mode argument
if "%1"=="--god-mode" goto godmode
if "%1"=="--debug" goto godmode

REM Normal mode
echo Starting Godot Windows version in normal mode...
Godot_v4.3-stable_win64.exe --path my-first-game --rendering-driver opengl3 --single-window
goto end

:godmode
echo Starting game in GOD MODE - instant kills enabled!
Godot_v4.3-stable_win64.exe --path my-first-game --rendering-driver opengl3 --single-window --god-mode

:end