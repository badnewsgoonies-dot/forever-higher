@echo off
echo Creating Forever Higher project structure...

REM Create directory structure
mkdir scripts\autoload 2>nul
mkdir scripts\battle 2>nul
mkdir scripts\resources 2>nul
mkdir scripts\ui 2>nul
mkdir scenes\battle 2>nul
mkdir scenes\ui 2>nul

echo Directories created!
echo.
echo Please run the project in Godot and I'll create the script files through the editor.
echo.
pause
